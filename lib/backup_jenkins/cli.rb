require 'command_line_helper'

module BackupJenkins
  class CLI
    include CommandLineHelper::HelpText

    class << self
      def run
        change_program_name
        cli = self.new
        cli.parse_options
        cli.check_config
        cli.run
      end
    end

    # TODO Some options depend on the config file being correct. Some other
    # options exit. Mark different options with whether they do one thing or
    # another.
    def parse_options
      options.each do |opt, arg|
        case opt
        when '--config'
          override_config_file_with(arg)
        when '--download'
          download_file(arg)
        when '--help'
          show_help
        when '--license'
          show_license
        when '--list'
          list_remote_backups
        when '--list-local'
          list_local_backups
        when '--only-local'
          @only_local = true
        when '--verbose'
          override_config_file_with_option("verbose" => true)
        when '--version'
          show_version
        end
      end
    rescue GetoptLong::MissingArgument, GetoptLong::InvalidOption
      # GetoptLong Already outputs the error.
      puts "\n"
      show_help
    end

    def check_config
      if !config.valid?
        STDERR.puts "Config file is incorrect."
        show_help
      end
    end

    def run
      do_backup
      upload_file unless @only_local
    rescue Interrupt
      clean_up_backup
      exit 0
    end

    private

    def self.change_program_name
      $0 = "#{File.basename($0)} (#{VERSION})"
    end

    def options_possible
      [
        [
          '--config', '-c', GetoptLong::REQUIRED_ARGUMENT,
          'Override config file location. Path to this file is required.'
        ],
        [
          '--download', '-d', GetoptLong::REQUIRED_ARGUMENT,
          'Download a backup file to current directory. File name is required.'
        ],
        ['--help', '-h', GetoptLong::NO_ARGUMENT, 'Print this message.'],
        ['--license', '-L', GetoptLong::NO_ARGUMENT, 'Print license.'],
        ['--list', '-l', GetoptLong::NO_ARGUMENT, 'List backups available on S3.'],
        ['--list-local', '-o', GetoptLong::NO_ARGUMENT, 'List local backups available.'],
        ['--only-local', '-O', GetoptLong::NO_ARGUMENT, 'Only create local backup file.'],
        ['--verbose', '-v', GetoptLong::NO_ARGUMENT, 'Be verbose. This overrides config file.'],
        ['--version', '-V', GetoptLong::NO_ARGUMENT, 'Print version number and exit,']
      ]
    end

    def do_backup
      backup.do_backup
    end

    def upload_file
      full_filename = backup.tarball_filename
      filename = File.basename(full_filename)
      aws.upload_file(filename, File.open(full_filename))
      aws.remove_old_files # Clean up!
    end

    def clean_up_backup
      backup.clean_up
    end

    def config
      @config ||= Config.new
    end

    def aws
      @aws ||= AWS.new(config)
    end

    def backup
      @backup ||= Backup.new(config)
    end

    def options
      @options ||= GetoptLong.new(*options_possible.map{ |o| o.first(3) })
    end

    # Entry points

    def show_help
      STDOUT.puts help_info
      exit
    end

    def show_version
      STDOUT.puts version_info
      exit
    end

    def show_license
      STDOUT.puts license_info
      exit
    end

    def list_remote_backups
      STDOUT.puts aws.list_backup_files
      exit
    end

    def list_local_backups
      STDOUT.puts backup.list_local_files
      exit
    end

    def download_file(filename)
      aws.download_file(filename)
      exit
    end

    def override_config_file_with(config_file_name)
      raise "File not found or not readable" unless File.readable?(config_file_name)
      @config = Config.new(config_file_name)
    end

    def override_config_file_with_option(options = {})
      config.override(options)
    end

    # Data

    def license_info
      "#{File.read(license_file_path)}\n\n"
    end

    def license_file_path
      File.expand_path("../../../LICENSE", __FILE__)
    end

    def version_info
      <<-EOV
backup_jenkins (#{version_number})
https://github.com/jcmuller/backup_jenkins
(c) 2012 Juan C. Muller
Work on this has been proudly backed by ChallengePost, Inc.
      EOV
    end

    def version_number
      VERSION
    end

  end
end
