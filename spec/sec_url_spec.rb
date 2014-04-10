include SecQuery

describe SecQuery::SecUrl do
  it "builds urls from options hashes" do
    expect(SecQuery::SecUrl.new.to_s).to eq("http://www.sec.gov/cgi-bin/browse-edgar?")
  end
end

