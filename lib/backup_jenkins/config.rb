module BackupJenkins
  class Config
    attr_reader :s3

    def initialize
      @config = YAML.load_file("config/config.yml")
    end

    def method_missing(meth, *args, &block)
      return config[meth.to_s] if config.has_key?(meth.to_s)
      super
    end

    def respond_to?(meth)
      config.has_key?(meth.to_s) || super
    end

    private

    attr_reader :config

  end
end
