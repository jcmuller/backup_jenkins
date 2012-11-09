module BackupJenkins
  class CLI
    class << self
      def run
        cli = self.new
        cli.parse_options
        cli.run
      end
    end

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

    def run
      do_backup
      upload_file unless @only_local
    rescue Interrupt
      clean_up_backup
    end

    private

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
      File.expand_path("../../..//LICENSE", __FILE__)
    end

    def version_info
      <<-EOV
backup_jenkins (#{BackupJenkins::VERSION})
https://github.com/jcmuller/backup_jenkins
(c) 2012 Juan C. Muller
Work on this has been proudly backed by ChallengePost, Inc.
      EOV
    end

    def help_info
      <<-EOH
Usage: #{File.basename($0)} [options]
  [#{options_possible.map{ |o| short_hand_option(o)}.join('], [')}]

  Options:
#{option_details}

#{version_info}
      EOH
    end

    def short_hand_option(option)
      if option[2] == GetoptLong::REQUIRED_ARGUMENT
        [option[0], option[1]].join('|') << " argument"
      else
        [option[0], option[1]].join('|')
      end
    end

    def option_details
      <<-EOO
#{options_possible.map{ |o| expand_option(o) }.join("\n")}
      EOO
    end

    def longest_width
      @max_width ||= options_possible.map{ |o| o[0] }.max{ |a, b| a.length <=> b.length }.length
    end

    def expand_option(option)
      sprintf("    %-#{longest_width + 6}s %s", option.first(2).join(', '), option[3])
    end
  end
end
