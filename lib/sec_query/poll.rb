module SecQuery
  class Poll
    attr_reader :url
    attr_accessor :start, :count, :links_stack

    def initialize(start = 0, count = 100)
      @start, @count, @links_stack = start, count, []
    end

    def url(local_start = start, local_count = count)
      SecQuery::SecUrl.build({ owner: "only", start: local_start, count: local_count })
    end

    def fetch_links(local_start = start, local_count = count, max = 10000, &blk)
      while(local_start + local_count < max)
        begin
          open(self.url(local_start, local_count)) do |rss|
            feed = RSS::Parser.parse(rss)
            p "found #{ feed.entries.length } more entries"
            feed.entries.each do |entry|
              link = entry.link.href.gsub("-index.htm", ".txt")
              blk.call(link)
              # title = entry.title.to_s.gsub("<title>", "")
              # cik = title[title.index("(")+1...title.index(")")]
              # type = title[0...title.index(" -")].strip
              # filed_on = entry.updated.to_s.gsub("<updated>", "").gsub("</updated>", "")
            end
          end
          local_start += local_count
        rescue OpenURI::HTTPError
          return
        end
      end
    end

    def poll
      debugger
      fetch_links(0, 40, 41) do |link|
        links_stack.push(link)
      end
    end
  end
end
