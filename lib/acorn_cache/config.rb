class Rack::AcornCache
  class Config
    def paths_whitelist
      options["paths_whitelist"] ? options["paths_whitelist"] : []
    end

    def root_directory
      Rack::Directory.new("").root
    end

    def options
      @options ||= YAML.load(config_yml) || {}
    end

    private

    def config_yml
      config_path = root_directory + "/.acorncache.yml"
      return "" unless File.exist?(config_path)
      File.read(config_path)
    end
  end
end
