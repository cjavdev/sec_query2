include SecQuery

describe SecQuery::Poll do
  subject(:poller) { SecQuery::Poll.new }

  it "#url returns a good url" do
    expect(poller.url.to_s)
      .to eq("http://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&count=100&output=atom&owner=only&start=0")
  end

  it "#fetch_links fetches the most recent links" do
    links = []
    poller.fetch_links(0, 40, 41) do |link|
      links << link
    end
    expect(links.uniq.length).to eq(40)
  end
end
