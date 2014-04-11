module SecQuery
  class SecUrl
    attr_accessor :query_hash, :base

    def self.build(options = {})
      instance = allocate
      instance.base = options.fetch(:base, "http://www.sec.gov/cgi-bin/browse-edgar?")
      instance.query_hash = options
      instance
    end

    def initialize(args)
      @base = "http://www.sec.gov/cgi-bin/browse-edgar?"
      @query_hash = { :action => "getcompany" }

      if args.is_a?(Hash)
        build_from_hash(args)
      elsif args.is_a?(String)
        build_from_string(args)
      end
    end

    def to_s
      "#{ base }#{ query_hash.to_query }"
    end

    def to_str
      to_s
    end

    def output_atom
      query_hash[:output] = "atom"
      to_s
    end

    def build_from_hash(args)
      if (args[:symbol] || args[:cik])
        return query_hash[:CIK] = (args[:symbol] || args[:cik])
      end
      query_hash[:company] = company_name_from_hash_args(args)
    end

    def build_from_string(args)
      return if args.length == 0
      # Uhhhg. I hate this method.
      begin Float(args)
        query_hash[:CIK] = args
      rescue
        if args.length <= 4
          query_hash[:CIK] = args
        else
          query_hash[:company] = args.gsub(/[(,?!\''"":.)]/, '')
        end
      end
    end

    def company_name_from_hash_args(args)
      return "#{ args[:last] } #{ args[:first] }" if args[:first] && args[:last]
      args.fetch(:name) { :company_name_not_found }.gsub(/[(,?!\''"":.)]/, '')
    end
  end
end
