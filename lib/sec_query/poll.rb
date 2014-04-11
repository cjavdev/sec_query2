# encoding: utf-8

module SecQuery
  class Poll
    attr_reader :url
    attr_accessor :start, :count, :links_stack

    def initialize(start = 0, count = 100)
      @start, @count, @links_stack = start, count, []
    end

    def url(l_start = start, l_count = count)
      SecQuery::SecUrl.build(
        action: "getcurrent",
        owner: 'only',
        start: l_start,
        count: l_count).output_atom
    end

    def fetch_links(l_start = start, l_count = count, max = 10_000, &blk)
      while(l_start + l_count < max)
        begin
          open(url(l_start, l_count)) do |rss|
            feed = RSS::Parser.parse(rss)
            p "found #{ feed.entries.length } more entries"
            feed.entries.each do |entry|
              link = entry.link.href.gsub('-index.htm', '.txt')
              blk.call(link)
            end
          end
          l_start += l_count
        rescue OpenURI::HTTPError
          return
        end
      end
    end

    def poll
      fetch_links(0, 40, 41) do |link|
        links_stack.push(link)
      end
    end
  end
end
