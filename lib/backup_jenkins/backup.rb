require 'fileutils'

module BackupJenkins
  class Backup
    include BackupJenkins::Formatter

    def initialize(config = Config.new)
      @config = config
    end

    def do_backup
      raise "Backup directory already exists! (#{backup_directory})" if FileTest.directory?(backup_directory)

      copy_files
      create_tarball
      remove_temporary_files
      remove_old_backups
    rescue Interrupt
      puts "Cleaning up..."
      clean_up
    end

    def tarball_filename
      "#{backup_directory}.tar.bz2"
    end

    def list_local_files
      format_backup_file_data(backup_files)
    end

    def clean_up
      puts "Removing #{backup_directory}"
      remove_temporary_files

      puts "Removing #{tarball_filename}"
      FileUtils.rm_rf(tarball_filename)
    rescue Errno::ENOENT
    end

    private

    attr_reader :config

    def backup_directory
      @backup_directory ||= "#{config.backup.dir_base}/#{config.base_file_name}_#{timestamp}"
    end

    def timestamp
      Time.now.strftime("%Y%m%d_%H%M")
    end

    def copy_files
      create_dir_and_copy(config_file)
      create_dir_and_copy(plugin_files)
      create_dir_and_copy(user_content_files)
      create_dir_and_copy(user_files)
      create_dir_and_copy(jobs_files)
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
      "#{backup_directory}/#{file_name.gsub(%r{#{config.jenkins.home}}, "")}".gsub(%r{//}, '/')
    end

    def config_file
      Dir["#{config.jenkins.home}/config.xml"]
    end

    def plugin_files
      plugin_files_jpis + plugin_files_hpis
    end

    def plugin_files_jpis
      Dir["#{config.jenkins.home}/plugins/*.jpi"] +
        Dir["#{config.jenkins.home}/plugins/*.jpi.pinned"] +
        Dir["#{config.jenkins.home}/plugins/*.jpi.disabled"]
    end

    def plugin_files_hpis
      Dir["#{config.jenkins.home}/plugins/*.hpi"] +
        Dir["#{config.jenkins.home}/plugins/*.hpi.pinned"] +
        Dir["#{config.jenkins.home}/plugins/*.hpi.disabled"]
    end

    def user_content_files
      Dir["#{config.jenkins.home}/userContent/*"]
    end

    def user_files
      find_files('users', 'config.xml')
    end

    def jobs_files
      find_files('jobs', 'config.xml', 'nextBuildNumber')
    end

    def find_files(base, *names)
      `#{find_file_command(base, names)}`.split(%r{#{$/}})
    end

    def find_file_command(base, names)
      path = File.join(config.jenkins.home, base)
      names_str = names * " -or -name "
      "find #{path} -maxdepth 3 -name #{names_str}"
    end

    def create_tarball
      puts "Creating #{tarball_filename}..." if config.verbose
      Dir.chdir(backup_directory)
      %x{tar #{tar_options} #{tarball_filename} .}
      raise "Error creating tarball" unless FileTest.file?(tarball_filename)
    end

    def tar_options
      %w(j c f).tap do |options|
        options.unshift('v') if config.verbose
      end.join('')
    end

    def remove_old_backups
      files_to_remove.each do |file|
        FileUtils.rm(file)
      end
    end

    def files_to_remove
      glob_of_backup_files -
        glob_of_backup_files.last(config.backup.backups_to_keep.local)
    end

    def glob_of_backup_files
      Dir["#{config.backup.dir_base}/#{config.base_file_name}_*tar.bz2"]
    end

    def backup_files
      glob_of_backup_files.sort.map do |file|
        {
          :key => file.gsub(%r{#{config.backup.dir_base}/}, ''),
          :content_length => File.size(file)
        }
      end
    end

    def remove_temporary_files
      FileUtils.rm_rf(backup_directory, :verbose => config.verbose)
    end
  end
end
