module BackupJenkins
  class CLI
    class << self
      def run
        config = BackupJenkins::Config.new
        backup = BackupJenkins::Backup.new(config)
        aws = BackupJenkins::AWS.new(config)

        backup.do_backup

        full_filename = backup.tarball_filename
        filename = File.basename(full_filename)

        aws.upload_file(filename, File.open(full_filename))
        aws.remove_old_files # Clean up!
      end
    end
  end
end
