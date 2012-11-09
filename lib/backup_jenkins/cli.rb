module BackupJenkins
  class CLI
    class << self
      def run
        cli = self.new
        cli.parse_options
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
      @config = BackupJenkins::Config.new(config_file_name)
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
