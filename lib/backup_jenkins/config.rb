module BackupJenkins
  class Config
    attr_reader :s3

    def initialize
      @config = config_file
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

    private

    attr_reader :config

    def config_file
      YAML.load_file(config_file_path)
    rescue Errno::ENOENT
      STDERR.puts "Please create a config file in #{config_file_path}"
      STDERR.puts "\nIt should look like:\n\n#{File.read('config/config-example.yml')}"

      exit 1
    end

    def config_file_path
      "#{ENV['HOME']}/.config/backup_jenkins/config.yml"
    end
  end
end
