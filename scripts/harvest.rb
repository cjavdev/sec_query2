require "cgi"
require "csv"
require "json"
require "sec_query"

filename = "./data/companies.csv"
::CSV.foreach(filename, {:col_sep => ";"}) do |row|
  symbol = row[0]
  puts symbol
  res = SecQuery::Entity.find(symbol, :transactions=> true, :filings=>true) 
  if res
    if !res.transactions.empty?
      # add in symbol
      hashes = JSON.parse(res.transactions.to_json)
      hashes.each do |hash| 
        hash['symbol'] = symbol
      end

      File.open("./results/transactions/#{symbol}.json", "w") { |f| f.write(hashes.to_json) }
      puts "\tWrote transactions"
    end

    if !res.filings.empty?
      # unescape summary
      hashes = JSON.parse(res.filings.to_json)
      hashes.each do |hash| 
        hash['summary'] = CGI.unescapeHTML(hash['summary'])
      end

      File.open("./results/filings/#{symbol}.json", "w") { |f| f.write(hashes.to_json) }
      puts "\tWrote filings"
    end
  end
end



