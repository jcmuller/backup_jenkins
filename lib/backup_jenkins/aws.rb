module BackupJenkins
  class AWS
    class UploadFileError < StandardError; end

    def initialize(config = Config.new)
      @config = config
      setup_aws
    end

    def populate_files
      @files = []
      backup_files.each{ |o| files << o }
      @files.sort!{ |a, b| a.key <=> b.key }
    end

    def backup_files
      s3_files.with_prefix(config.base_file_name)
    end

    def remove_old_files
      puts "Looking for old files..." if config.verbose
      populate_files
      do_remove_old_files
      puts "Done." if config.verbose
    end

    def do_remove_old_files
      files_to_remove.each do |file|
        puts "Removing #{file.key}..." if config.verbose
        file.delete
      end
    end

    # TODO change this to use a time decay algorithm
    def files_to_remove
      files - files.last(config.backup["backups_to_keep"])
    end

    def upload_file(filename, file)
      puts "About to upload #{filename}..." if config.verbose
      new_file = s3_files.create(filename, file)
      puts "Done" if config.verbose
      raise UploadFileError unless new_file.class == ::AWS::S3::S3Object
    end

    private

    attr_reader :config, :bucket, :files

    def setup_aws
      s3 = ::AWS::S3.new(
        :access_key_id => config.aws["access_key"],
        :secret_access_key => config.aws["secret"]
      )
      @bucket = s3.buckets[config.aws["bucket_name"]]
      @bucket = s3.buckets.create(config.aws["bucket_name"]) unless @bucket.exists?
      raise "Couldn't create bucket!" unless @bucket.exists?
    end

    def s3_files
      bucket.objects
    end

  end
end
