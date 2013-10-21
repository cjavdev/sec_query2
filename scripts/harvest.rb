require "cgi"
require "csv"
require "json"
require "sec_query"
require "mongo"

=begin
@conn         = Mongo::Connection.new
@db           = @conn['sec-db']
@transactions = @db['transactions']
@filings      = @db['filings']
=end

filename = "./data/companies.csv"
::CSV.foreach(filename, {:col_sep => ";"}) do |row|
  symbol = row[0]
  puts symbol
  res = SecQuery::Entity.find(:symbol=> symbol, :transactions=> true, :filings=>true) 
  if res
    if !res.transactions.nil?
      res.transactions.each do |trans|
        trans.save
      end
    end

=begin
    if !res.filings.empty?
      # unescape summary
      hashes = JSON.parse(res.filings.to_json)
      hashes.each do |hash| 
        hash['summary'] = CGI.unescapeHTML(hash['summary'])
        @filings.insert(hash)
      end

      File.open("./results/filings/#{symbol}.json", "w") { |f| f.write(hashes.to_json) }
      puts "\tWrote filings"
    end
=end
  end
end
