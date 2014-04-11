include SecQuery

describe SecQuery::SecUrl do
  it "builds urls from options hashes" do
    expect(SecQuery::SecUrl.new("").to_s).to eq("http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany")
  end

  it "#build_from_hash will build correctly from hash with symbol things" do
    expect(SecQuery::SecUrl.new({ :symbol => "AAPL" }).to_s)
      .to eq("http://www.sec.gov/cgi-bin/browse-edgar?CIK=AAPL&action=getcompany")
  end

  it "#build_from_hash will build correctly from hash with cik things" do
    expect(SecQuery::SecUrl.new({ :cik => "12345" }).to_s)
      .to eq("http://www.sec.gov/cgi-bin/browse-edgar?CIK=12345&action=getcompany")
  end

  it "#build_from_hash will build correctly from hash with less than needed things" do
    expect { SecQuery::SecUrl.new({ :last => "AAPL" }) }
      .to raise_exception
  end

  it "#build_from_hash will build correctly from hash with less than needed things" do
    expect(SecQuery::SecUrl.new({ :last => "last", :first => "first" }).to_s)
      .to eq("http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&company=last+first")
  end
end

