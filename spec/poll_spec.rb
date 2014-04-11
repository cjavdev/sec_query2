include SecQuery

describe SecQuery::Poll do
  subject(:poller) { SecQuery::Poll.new }

  it "#url returns a good url" do
    expect(poller.url.to_s).to eq("http://www.sec.gov/cgi-bin/browse-edgar?count=100&owner=only&start=0")
  end
end
