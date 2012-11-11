module BackupJenkins
  class Config
    attr_reader :s3

    def initialize(path = default_config_file_path)
      @config = config_file(path)
    end

    def valid?
      !verbose.nil? && jenkins_valid? && aws_valid? && backup_valid?
    end

    def base_file_name
      "#{backup["file_name_base"]}_#{hostname}"
    end

    def override(options = {})
      @config.merge!(options)
    end

    private

    attr_reader :config

    def default_config_file_path
      "#{ENV['HOME']}/.config/backup_jenkins/config.yml"
    end

    def config_file(config_file_path)
      YAML.load_file(config_file_path)
    rescue Errno::ENOENT
      STDERR.puts "Please create a config file in #{default_config_file_path}"
      STDERR.puts "\nIt should look like:\n\n#{config_file_example}"

      exit 1
    end

    def config_file_example
      File.read(config_file_example_path)
    end

    def config_file_example_path
      File.expand_path('../../../config/config-example.yml', __FILE__)
    end

    def aws_valid?
      aws["access_key"] && aws["secret"] && aws["bucket_name"]
    end

    def jenkins_valid?
      !!jenkins["home"]
    end

    def backup_valid?
      backup["dir_base"] && backup["file_name_base"] &&
        backup["backups_to_keep"] &&
        backup["backups_to_keep"]["remote"] &&
        backup["backups_to_keep"]["local"]
    end

    def hostname
      %x{hostname -s}.chomp
    end

    def method_missing(meth, *args, &block)
      return config[meth.to_s] if config.has_key?(meth.to_s)
      super
    end

    def respond_to?(meth)
      config.has_key?(meth.to_s) || super
    end
  end
end
