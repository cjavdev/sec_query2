# encoding: utf-8

module SecQuery
  class Entity
    COLUMNS = [:symbol, :first, :middle, :last, :name, :symbol, :cik, :url,
               :type, :sic, :location, :state_of_inc, :formerly,
               :mailing_address, :business_address, :relationships,
               :transactions, :filings]

    attr_accessor *COLUMNS

    def initialize(entity)
      COLUMNS.each do |col|
        instance_variable_set("@#{ col }".to_sym, entity[col])
      end
    end

    def self.find(entity_args, *options)
      temp = {}
      if entity_args.is_a?(Hash)
        temp[:symbol] = entity_args[:symbol]
      elsif entity_args.is_a?(String)
        temp[:symbol] = entity_args
      end

      temp[:url] = SecUrl.new(entity_args) # Entity.url(entity_args)
      temp[:cik] = Entity.cik(temp[:url], entity_args)

      if !temp[:cik] || temp[:cik] == ''
        puts "No Entity found for query: #{ temp[:url] }"
        return false
      end

      ### Get Document and Entity Type
      doc = Entity.document(temp[:cik])
      temp = Entity.parse_document(temp, doc)

      ### Get Additional Arguments and Query Additional Details
      unless options.empty?
        temp[:transactions] = []
        temp[:filings] = []
        options = Entity.options(temp, options)
        temp = Entity.details(temp, options)
      end

      ###  Return entity Object
      @entity = Entity.new(temp)
      @entity
    end

    # maybe this should be moved into the URL?
    def self.query(url)
      RestClient.get(url) do |response, request, result, &block|
        case response.code
        when 200
          return response
        else
          response.return!(request, result, &block)
        end
      end
    end

#     def self.url(args)
#       if args.is_a?(Hash)
#         if args[:symbol] != nil
#           string = "CIK=#{ args[:symbol] }"
#         elsif args[:cik] != nil
#           string = "CIK="+args[:cik]
#         elsif args[:first] != nil and args[:last]
#           string = "company="+args[:last]+" "+args[:first]
#         elsif args[:name] != nil
#           string = "company="+args[:name].gsub(/[(,?!\''"":.)]/, '')
#         end
#       elsif args.is_a?(String)
#         begin Float(args)
#           string = "CIK=#{ args }"
#         rescue
#           if args.length <= 4
#             string = "CIK=#{ args }"
#           else
#             string = "company=#{ args.gsub(/[(,?!\''"":.)]/, '') }"
#           end
#         end
#       end
#       # TODO: this should probably use url encode?
#       string = string.to_s.gsub(" ", "+")
#       "http://www.sec.gov/cgi-bin/browse-edgar?#{ string }&action=getcompany"
#     end

    # TODO: sometimes this returns false and
    # sometimes this returns the actual cik?
    def self.cik(url, entity)
      response = Entity.query(url.output_atom)
      doc = Hpricot::XML(response)
      data = doc.search('//feed/title')[0]
      return false if data.nil?

      if data.inner_text == 'EDGAR Search Results'
        tbl =  doc.search("//span[@class='companyMatch']")
        if tbl && tbl.innerHTML != ''
          tbl = tbl[0].parent.search('table')[0].search('tr')
          for tr in tbl
            td = tr.search('td')
            if td[1] != nil && entity[:middle] != nil && td[1].innerHTML.downcase == (entity[:last]+" "+entity[:first]+" "+entity[:middle]).downcase or td[1] != nil && td[1].innerHTML.downcase == (entity[:last]+" "+entity[:first]).downcase
              cik = td[0].search("a").innerHTML
              return cik
            end
          end
        else
          return false
        end
      else
        cik = data.inner_text.scan(/\(([^)]+)\)/).to_s
        cik = cik.gsub('[["', '').gsub('"]]','')
        return cik
      end
    end

    def self.document(cik)
      url = "http://www.sec.gov/cgi-bin/own-disp?action=getissuer&CIK=#{ cik }"
      response = query(url)
      doc = Hpricot(response)
      text = "Ownership Reports from:"
      type = "issuer"
      entity = doc.search("//table").search("//td").search("b[text()*='#{ text }']")
      if entity.empty?
        url = "http://www.sec.gov/cgi-bin/own-disp?action=getowner&CIK=#{ cik }"
        response = query(url)
        doc = Hpricot(response)
        text = "Ownership Reports for entitys:"
        type = "owner"
        entity = doc.search("//table").search("//td").search("b[text()*='#{ text }']")
      end
      [doc, type]
    end

    def self.parse_document(temp, doc)
      info = Entity.info(doc[0])

      temp[:type] = doc[1]
      temp[:name] = info[:name]
      temp[:location] = info[:location]
      temp[:sic] = info[:sic]
      temp[:state_of_inc] = info[:state_of_inc]
      temp[:formerly] = info[:formerly]

      ### Get Mailing Address
      temp[:mailing_address] = Entity.mailing_address(doc[0])

      ### Get Business Address
      temp[:business_address] = Entity.business_address(doc[0])

      temp
    end

    def self.info(doc)
      info = {}
      node = doc.search("//td[@bgcolor='#E6E6E6']")[0]
      unless node.nil?
        lines = node.parent.parent.search("//tr")
        td = lines[0].search("//td//b").innerHTML
        info[:name] = td.gsub(td.scan(/\(([^)]+)\)/).to_s, "").gsub("()", "").gsub("\n", "")
        lines = lines[1].search("//table")[0].search("//tr//td")
        if lines[0].search("a")[0] != nil
          info[:sic] = lines[0].search("a")[0].innerHTML
        end

        if lines[0].search("a")[1] != nil
          info[:location] = lines[0].search("a")[1].innerHTML
        end

        if lines[0].search("b")[0] != nil and lines[0].search("b")[0].innerHTML.squeeze(" ") != " "
          info[:state_of_inc] = lines[0].search("b")[0].innerHTML
        end

        if lines[1] != nil and lines[1].search("font")
          info[:formerly] = lines[1].search("font").innerHTML.gsub("formerly: ", "").gsub("<br />", "").gsub("\n", "; ")
        end
      end
      info
    end

    def self.business_address(doc)
      addie = doc.search("//table").search("//td").search("b[text()*='Business Address']")
      if !addie.empty?
        business_address = addie[0].parent.innerHTML.gsub('<b class="blue">Business Address</b>', '').gsub('<br />', ' ')
        return business_address
      else
        return false
      end
    end

    def self.mailing_address(doc)
      addie = doc.search("//table").search("//td").search("b[text()*='Mailing Address']")
      if !addie.empty?
        mailing_address = addie[0].parent.innerHTML.gsub('<b class="blue">Mailing Address</b>', '').gsub('<br />', ' ')
        return mailing_address
      else
        return false
      end
    end

    def self.options(temp, options)
      args = {}
      if options.is_a?(Array) && options.length == 1 && options[0] == true
        args[:relationships] = true
        args[:transactions]= true
        args[:filings] = true
      elsif options.is_a?(Array) && options.length > 1
        args[:relationships] = options[0]
        args[:transactions]= options[1]
        args[:filings] = options[2]
      elsif options[0].is_a?(Hash)
        args[:relationships] = options[0][:relationships]
        args[:transactions]= options[0][:transactions]
        args[:filings] = options[0][:filings]
      end
      args
    end

    def self.details(temp, options)
      ## Get Relationships for entity
      if options[:relationships] == true
        relationships = Relationship.find(temp)
        temp[:relationships] =relationships
      end

      ## Get Transactions for entity
      if options[:transactions].is_a?(Hash)
        temp = Transaction.find(temp, options[:transactions][:start], options[:transactions][:count], options[:transactions][:limit])
      elsif !!options[:transactions]
        temp = Transaction.find(temp, nil, nil, nil)
      end

      ## Get Filings for entity
      if options[:filings].is_a?(Hash)
        temp = Filing.find(temp, options[:filings][:start], options[:filings][:count], options[:filings][:limit])
      elsif !!options[:filings]
        temp = Filing.find(temp, nil, nil, nil)
      end
      temp
    end

    def self.log(entity)
      if entity != false
        puts "\n\t# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n\n"
        puts "\t#{ entity.name }"
        puts "\t(#{ entity.cik })"
        if entity.formerly && entity.formerly != ""
          puts "\tFormerly: #{ entity.formerly }"
        end

        if entity.sic
          puts "\tSIC = #{ entity.sic }"
        end

        if entity.location
          puts "\tLocation: #{ entity.location }, "
        end

        if entity.state_of_inc
          puts "\tState of Incorporation: #{ entity.state_of_inc }"
        end

        if entity.mailing_address
          puts "\tMailing Address:\t"+ entity.mailing_address.inspect.gsub('\n', ' ').squeeze(" ")
        end

        if entity.business_address
          puts "\tBusiness Address:\t"+ entity.business_address.inspect.gsub('\n', ' ').squeeze(" ")
        end

        if !entity.relationships
          puts "\n\tRELATIONSHIPS:\t0 Total"
        else
          puts "\n\tRELATIONSHIPS:\t#{ entity.relationships.count.to_s } Total"
          printf("\t%-40s %-15s %-30s %-10s\n\n","Entity", "CIK", "Position", "Date")
          for relationship in entity.relationships
            printf("\t%-40s %-15s %-30s %-10s\n",relationship.name, relationship.cik, relationship.position, relationship.date)
          end
        end

        if entity.transactions
          puts "\n\tTRANSACTIONS:\t#{ entity.transactions.count.to_s } Total"
          printf("\t%-20s %-10s %-5s %-10s %-10s %-10s %-15s %-10s\n\n","Owner", "CIK", "Modes", "Type","Shares","Price","Owned","Date")
          for transaction in entity.transactions
            printf("\t%-20s %-10s %-5s %-10s%-10s %-10s %-15s %-10s\n", transaction.reporting_owner,transaction.owner_cik,transaction.modes, transaction.type,transaction.shares,transaction.price,transaction.owned,transaction.date)
          end
        end

        if entity.filings
          puts "\n\tFILINGS:\t"+ entity.filings.count.to_s+" Total"
          printf("\t%-10s %-30s %-20s\n\n","Type", "File ID", "Date")

          for filing in entity.filings
            printf("\t%-10s %-30s %-20s\n",filing.term, filing.file_id, filing.date)
          end
        end
        puts "\t#{ entity.url }\n\n"
      else
        return "No Entity found."
      end
    end
  end
end
