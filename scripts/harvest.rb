require 'csv'
require 'sec_query'
require 'debugger'

filename = "./data/companies.csv"
::CSV.foreach(filename, { :col_sep => ";" }) do |row|
  symbol = row[0]
  puts symbol
  res = SecQuery::Entity.find(symbol, :transactions => true, :filings => true)
  debugger
  if res
    if !res.transactions.nil?
      res.transactions.each do |trans|
        trans.save
      end
      puts "\twrote transactions"
    end

    if !res.filings.nil?
      res.filings.each do |filing|
        filing.save
      end
      puts "\twrote filings"
    end
  end
end
