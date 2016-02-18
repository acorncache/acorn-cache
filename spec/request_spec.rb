require 'spec_helper'

describe Rack::AcornCache::Request do
  describe "#accepts_cached_response?" do
    it "returns false if request is not a get" do
      request = Rack::AcornCache::Request.new({})
      allow(request).to receive(:get?) { false }
      allow(request).to receive(:path) { "/" }
      allow(request).to receive(:caching_restrictions?) { false }
      paths_whitelist = ["/"]

      expect(request.accepts_cached_response?(paths_whitelist)).to be_falsy
    end

    it "returns false if the path is not whitelisted" do
      request = Rack::AcornCache::Request.new({})
      paths_whitelist = []
      allow(request).to receive(:get?) { true }
      allow(request).to receive(:path) { "/" }
      allow(request).to receive(:caching_restrictions?) { false }

      expect(request.accepts_cached_response?(paths_whitelist)).to be_falsy
    end

    it "returns false if there are caching restrictions" do
      request = Rack::AcornCache::Request.new({})
      paths_whitelist = ["/"]
      allow(request).to receive(:get?) { true }
      allow(request).to receive(:path) { "/" }
      allow(request).to receive(:caching_restrictions?) { true }
      expect(request.accepts_cached_response?(paths_whitelist)).to be_falsy
    end

    it "returns true if request is get, path is whitelisted, no caching restrictions" do
      request = Rack::AcornCache::Request.new({})
      paths_whitelist = ["/"]
      allow(request).to receive(:get?) { true }
      allow(request).to receive(:path) { "/" }
      allow(request).to receive(:caching_restrictions?) { false }

      expect(request.accepts_cached_response?(paths_whitelist)).to be_truthy
    end
  end

  describe "#cache_control_header" do
    it "returns the content of http cache control header" do
      request = Rack::AcornCache::Request.new({"HTTP_CACHE_CONTROL" => "foo" })

      expect(request.cache_control_header).to eq("foo")
    end

    it "returns nil if no http cache control header is defined" do
      request = Rack::AcornCache::Request.new({})

      expect(request.cache_control_header).to be_nil
    end
  end

  it "responds to CacheControlRestrictable methods" do
    Rack::AcornCache::CacheControlRestrictable.public_instance_methods.each do |method|
      expect(Rack::AcornCache::Request.new({})).to respond_to(method)
    end
  end
end
