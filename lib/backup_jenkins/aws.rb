module BackupJenkins
  class AWS
    class UploadFileError < StandardError; end

    include BackupJenkins::Formatter

    def initialize(config = Config.new)
      @config = config
      setup_aws
    end

    def list_backup_files
      file_hashes = backup_files_for_all_hosts.map{ |f| s3_object_to_hash(f) }
      format_backup_file_data(file_hashes)
    end

    def remove_old_files
      puts "Looking for old files..." if config.verbose
      do_remove_old_files
      puts "Done." if config.verbose
    end

    def upload_file(filename, file)
      puts "About to upload #{filename}..." if config.verbose
      new_file = s3_files.create(filename, file)
      puts "Done" if config.verbose
      raise UploadFileError unless new_file.class == ::AWS::S3::S3Object
    end

    def download_file(filename)
      remote_file = bucket.objects[filename]

      File.open(filename, 'w') do |file|
        count = 0
        remote_file.read do |chunk|
          file.write(chunk)
          STDOUT.print "." if count % 512 == 0
          count += 1
        end
        STDOUT.puts "."
      end
    end

    private

    attr_reader :config, :bucket

    def do_remove_old_files
      files_to_remove.each do |file|
        puts "Removing #{file.key}..." if config.verbose
        file.delete
      end
    end

    # TODO change this to use a time decay algorithm
    def files_to_remove
      files - files.last(config.backup["backups_to_keep"]["remote"])
    end

    def files
      @files ||= backup_files_for_this_host.sort{ |a, b| a.key <=> b.key }
    end

    def backup_files_for_this_host
      s3_files.with_prefix(config.base_file_name)
    end

    def backup_files_for_all_hosts
      s3_files.with_prefix(config.backup["file_name_base"])
    end

    def setup_aws
      s3 = initialize_s3_object
      @bucket = s3.buckets[config.aws["bucket_name"]]
      @bucket = s3.buckets.create(config.aws["bucket_name"]) unless @bucket.exists?
      raise "Couldn't create bucket!" unless @bucket.exists?
    end

    def initialize_s3_object
      ::AWS::S3.new(
        :access_key_id => config.aws["access_key"],
        :secret_access_key => config.aws["secret"]
      )
    end

    # Returns a structure like:
    # [
    #   { :key => "jenkins_berman_20121107_1721.tar.bz2", :content_length => 88762813 },
    #   { :key => "jenkins_berman_20121107_1745.tar.bz2", :content_length => 88762572 }
    # ]
    def s3_object_to_hash(s3_object)
      {}.tap do |hash|
        [:key, :content_length, :metadata].each do |key|
          hash[key] = s3_object.send(key)
        end
      end
    end

    def s3_files
      bucket.objects
    end

  end
end
