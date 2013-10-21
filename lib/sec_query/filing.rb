module SecQuery
    class Filing
        include MongoMapper::Document

        attr_accessor :symbol, :cik, :title, :summary, :link, :term, :date, :file_id

        key :symbol, String
        key :cik, String
        key :title, String
        key :summary, String
        key :link, String
        key :term, String
        key :date, Time
        key :file_id, String

        def initialize(filing)
            @cik = filing[:cik]
            @title = filing[:title]
            @summary = filing[:summary]
            @link = filing[:link]
            @term = filing[:term]
            @date = filing[:date]
            @file_id = filing[:file_id]
        end
  
    
        def self.find(entity, start, count, limit)

            if start == nil; start = 0; end
            if count == nil; count = 80; end
            url ="http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK="+entity[:cik]+"&output=atom&count="+count.to_s+"&start="+start.to_s
            response = Entity.query(url)
            doc = Hpricot::XML(response)
            entries = doc.search(:entry);
            query_more = false;
            for entry in entries
                query_more = true;
                filing={}
                filing[:symbol] = entity[:symbol]
                filing[:cik] = entity[:cik]
                filing[:title] = (entry/:title).innerHTML
                filing[:summary] = CGI.unescapeHTML((entry/:summary).innerHTML)
                filing[:link] =  (entry/:link)[0].get_attribute("href")
                filing[:term] = (entry/:category)[0].get_attribute("term")
                if filing[:date] != nil and filing[:date] != "-"
                  filing[:date] = DateTime.iso8601((entry/:updated).innerHTML).to_time
                end
                filing[:file_id] = (entry/:id).innerHTML.split("=").last

                entity[:filings] << Filing.new(filing)              
            end
            if query_more and limit == nil || query_more and !limit
                Filing.find(entity, start+count, count, limit);
            else
                return entity
            end
        end 
        timestamps!
    end
end
