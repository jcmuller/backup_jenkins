module BackupJenkins
  class Config
    attr_reader :s3

    def initialize(path = default_config_file_path)
      @config = config_file(path)
    end

    def method_missing(meth, *args, &block)
      return config[meth.to_s] if config.has_key?(meth.to_s)
      super
    end

    def respond_to?(meth)
      config.has_key?(meth.to_s) || super
    end

    def base_file_name
      "#{backup["file_name_base"]}_#{hostname}"
    end

    def hostname
      %x{hostname -s}.chomp
    end

    def override(options = {})
      @config.merge!(options)
    end

    private

    attr_reader :config

    def config_file(config_file_path)
      YAML.load_file(config_file_path)
    rescue Errno::ENOENT
      STDERR.puts "Please create a config file in #{default_config_file_path}"
      STDERR.puts "\nIt should look like:\n\n#{config_file_example}"

      exit 1
    end

    def default_config_file_path
      "#{ENV['HOME']}/.config/backup_jenkins/config.yml"
    end

    def config_file_example
      File.read(config_file_example_path)
    end

    def config_file_example_path
      File.expand_path('../../../config/config-example.yml', __FILE__)
    end
  end
end
