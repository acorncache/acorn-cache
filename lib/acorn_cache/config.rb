class Rack::AcornCache
  class Config

    attr_reader :options

    def initialize
      @options = options_hash
    end

    def paths_whitelist
      options ? options["paths_whitelist"] : []
    end

    def root_directory
      Rack::Directory.new("").root
    end

    private

    def options_hash
      config_path = root_directory + "/.acorncache.yml"
      return unless File.exist?(config_path)
      config_yml = File.read(config_path)
      YAML.load(config_yml)
    end
  end
end
