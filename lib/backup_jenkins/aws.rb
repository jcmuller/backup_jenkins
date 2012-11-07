module BackupJenkins
  class AWS
    def initialize(config = Config.new)
      @config = config
      setup_aws
    end

    def populate_files
      @files = []
      bucket.objects.with_prefix(config.backup["file_name_base"]).each{ |o| files << o }
      @files.sort!{ |a, b| a.key <=> b.key }
    end

    # TODO change this to use a time decay algorithm
    def remove_old_files
      puts "Looking for old files..." if config.verbose

      populate_files

      files_to_remove.each do |file|
        puts "Removing #{file.key}..." if config.verbose
        file.delete
      end

      puts "Done." if config.verbose
    end

    def files_to_remove
      files - files.last(config.backup["backups_to_keep"])
    end

    def upload_file(filename, file)
      puts "About to upload #{filename}..." if config.verbose
      new_file = bucket.objects.create(filename, file)
      puts "Done" if config.verbose
      raise "Error uploading" unless new_file.class == ::AWS::S3::S3Object
    end

    private

    attr_reader :config, :bucket, :files

    def setup_aws
      s3 = ::AWS::S3.new(
        access_key_id: config.aws["access_key"],
        secret_access_key: config.aws["secret"]
      )
      @bucket = s3.buckets[config.aws["bucket_name"]]
      @bucket = s3.buckets.create(config.aws["bucket_name"]) unless @bucket.exists?
      raise "Couldn't create bucket!" unless @bucket.exists?
    end

  end
end
