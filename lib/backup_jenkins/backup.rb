require 'fileutils'

module BackupJenkins
  class Backup
    def initialize(config = Config.new)
      @config = config
    end

    def backup_directory
      @backup_directory ||= "#{config.backup["dir_base"]}/#{config.base_file_name}_#{timestamp}"
    end

    def create_dir_and_copy(file_names)
      file_names.each do |file_name|
        create_dir_and_copy_impl(file_name)
      end
    end

    def create_dir_and_copy_impl(file_name)
      raise "file '#{file_name}' does not exist" unless FileTest.file?(file_name)

      new_file_name = new_file_path(file_name)
      new_file_dir = File.dirname(new_file_name)

      FileUtils.mkdir_p(new_file_dir, :verbose => config.verbose)
      FileUtils.cp(file_name, new_file_name, :verbose => config.verbose)
    end

    def new_file_path(file_name)
      "#{backup_directory}/#{file_name.gsub(%r{#{config.jenkins["home"]}}, "")}".gsub(%r{//}, '/')
    end

    def do_backup
      raise "Backup directory already exists! (#{backup_directory})" if FileTest.directory?(backup_directory)

      copy_files

      create_tarball
      remove_temporary_files
    end

    def copy_files
      create_dir_and_copy(plugin_files)
      create_dir_and_copy(user_content_files)
      create_dir_and_copy(jobs_files)
    end

    def plugin_files
      Dir["#{config.jenkins["home"]}/plugins/*.jpi"] +
        Dir["#{config.jenkins["home"]}/plugins/*.jpi.pinned"] +
        Dir["#{config.jenkins["home"]}/plugins/*.jpi.disabled"]
    end

    def user_content_files
      Dir["#{config.jenkins["home"]}/userContent/*"]
    end

    def jobs_files
      `find #{config.jenkins["home"]}/jobs -maxdepth 3 -name config.xml -or -name nextBuildNumber`.split(/\n/)
    end

    def create_tarball
      Dir.chdir(backup_directory)
      %x{tar #{tar_options} #{tarball_filename} .}
      raise "Error creating tarball" unless FileTest.file?(tarball_filename)
    end

    def remove_temporary_files
      FileUtils.rm_rf(backup_directory, :verbose => config.verbose)
    end

    def tarball_filename
      "#{backup_directory}.tar.bz2"
    end

    def tar_options
      %w(j c f).tap do |options|
        options.unshift('v') if config.verbose
      end.join('')
    end

    private

    attr_reader :config

    def timestamp
      Time.now.strftime(config.backup["timestamp"])
    end
  end
end
