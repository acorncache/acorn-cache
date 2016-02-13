class AcornCache::Config
  def initialize
    config_path = root_directory + "/.acorncache.yml"
    config_yml = File.read(config_path)
    @config = YAML.load(config_yml)
  end

  def paths_whitelist
    @config["paths_whitelist"]
  end

  def root_directory
    @root_dir ||= Rack::Directory.new("").root
  end
end
