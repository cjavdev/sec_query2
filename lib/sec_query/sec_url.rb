module SecQuery
  class SecUrl
    attr_reader :base

    # from entity
    def self.url(args)
      if args.is_a?(Hash)
        if args[:symbol] != nil
          string = "CIK=#{ args[:symbol] }"
        elsif args[:cik] != nil
          string = "CIK="+args[:cik]
        elsif args[:first] != nil and args[:last]
          string = "company="+args[:last]+" "+args[:first]
        elsif args[:name] != nil
          string = "company="+args[:name].gsub(/[(,?!\''"":.)]/, '')
        end
      elsif args.is_a?(String)
        begin Float(args)
          string = "CIK=#{ args }"
        rescue
          if args.length <= 4
            string = "CIK=#{ args }"
          else
            string = "company=#{ args.gsub(/[(,?!\''"":.)]/, '') }"
          end
        end
      end
      # TODO: this should probably use url encode?
      string = string.to_s.gsub(" ", "+")
      "http://www.sec.gov/cgi-bin/browse-edgar?#{ string }&action=getcompany"
    end

    def initialize(options = {})
      @base = options.fetch(:base, "http://www.sec.gov/cgi-bin/browse-edgar?")
    end

    def to_s
      "#{ base }"
    end
  end
end
