module BackupJenkins
  class CLI
    class << self
      def run
        cli = self.new
        cli.run
      end
    end

    def run
      backup.do_backup

      full_filename = backup.tarball_filename
      filename = File.basename(full_filename)

      aws.upload_file(filename, File.open(full_filename)) unless @only_local
      aws.remove_old_files # Clean up!
    end

    private

    def config
      @config ||= BackupJenkins::Config.new
    end

    def aws
      @aws ||= BackupJenkins::AWS.new(config)
    end

    def backup
      @backup ||= BackupJenkins::Backup.new(config)
    end

  end
end
