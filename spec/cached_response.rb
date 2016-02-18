require 'spec_helper'

describe Rack::AcornCache::CachedResponse do
  describe "#new" do
    it "sets body, status, and headers from args hash" do
      args = { status: 200, headers: { foo: "bar" }, body: "foobar" }
      response = Rack::AcornCache::CachedResponse.new(args)
      expect(response.status).to eq(200)
      expect(response.headers).to eq({ foo: bar })
      expect(response.status).to eq("foobar")
    end
  end

  describe "#fresh?" do
    context "when no cache control header or expiration is present on the cached response or request" do
    end
  end
end
