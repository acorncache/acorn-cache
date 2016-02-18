require 'spec_helper'

describe Rack::AcornCache::Config do
  describe "#options" do
    it "loads in the config YAML file from the root path if present" do
      config = Rack::AcornCache::Config.new
      allow(config).to receive(:root_directory) { File.dirname(__FILE__) }
      config_yml = { "paths_whitelist" => ["/"] }

      expect(config.options).to eq(config_yml)
    end

    it "does not crash if no whitelist file provided" do
      config = Rack::AcornCache::Config.new
      allow(config).to receive(:root_directory) { "/some/path/doesntexist" }

      expect(config.options).to eq({})
    end
  end

   describe "#paths_whitelist" do
    it "returns an array of whitelisted paths" do
      config = Rack::AcornCache::Config.new
      allow(config).to receive(:options) { { "paths_whitelist" => ["/"] } }

      expect(config.paths_whitelist).to eq(["/"])
    end

    it "returns an empty array if @config is nil" do
      config = Rack::AcornCache::Config.new
      allow(config).to receive(:options) { {} }

      expect(config.paths_whitelist).to eq([])
    end

    it "returns an empty array if paths_whitelist key is not specified" do
      config = Rack::AcornCache::Config.new
      allow(config).to receive(:options) { { "some_key" => ["/"] } }

      expect(config.paths_whitelist).to eq([])
    end
  end
end
