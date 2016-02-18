require 'spec_helper'

describe Rack::AcornCache::Config do
  describe "#new" do
    it "loads in the config YAML file from the root path if present" do
      allow_any_instance_of(Rack::AcornCache::Config).to receive(:root_directory) { File.dirname(__FILE__) }
      config_yml = { "paths_whitelist" => ["/"] }

      config = Rack::AcornCache::Config.new

      expect(config.options).to eq(config_yml)
    end

    it "does not crash if no whitelist file provided" do
      allow_any_instance_of(Rack::AcornCache::Config).to receive(:root_directory) { "/some/path/doesntexist" }

      config = Rack::AcornCache::Config.new

      expect(config).to be_truthy
      expect(config.options).to be_nil
    end
  end

   describe "#paths_whitelist" do
    it "returns an array of whitelisted paths" do
      allow_any_instance_of(Rack::AcornCache::Config).to receive(:options_hash) { "paths_whitelist" => ["/"] }

      config = Rack::AcornCache::Config.new

      expect(config.paths_whitelist).to eq(["/"])
    end

    it "returns an empty array if @config is nil" do
      allow_any_instance_of(Rack::AcornCache::Config).to receive(:options_hash) { nil }

      config = Rack::AcornCache::Config.new

      expect(config.paths_whitelist).to eq([])
    end

    it "returns an empty array if paths_whitelist key is not specified" do
      allow_any_instance_of(Rack::AcornCache::Config).to receive(:options_hash) {}
    end
  end
end
