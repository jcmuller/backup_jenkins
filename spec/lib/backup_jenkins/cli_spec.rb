require 'spec_helper'

describe BackupJenkins::CLI do
  let(:aws) { stub }
  let(:backup) { stub }
  let(:config) { stub }

  before do
    BackupJenkins::AWS.stub(:new).and_return(aws)
    BackupJenkins::Backup.stub(:new).and_return(backup)
    BackupJenkins::Config.stub(:new).and_return(config)

    File.stub(:open).and_return(:IO)

    backup.stub(:do_backup)
    backup.stub(:tarball_filename).and_return("tarball_filename")

    aws.stub(:upload_file)
    aws.stub(:remove_old_files)

    config.stub(:valid?).and_return(true)
  end

  describe ".run" do
    after { BackupJenkins::CLI.run }

    it { BackupJenkins::CLI.any_instance.should_receive(:check_config) }
    it { BackupJenkins::CLI.any_instance.should_receive(:parse_options) }
    it { BackupJenkins::CLI.any_instance.should_receive(:run) }
  end

  describe "#check_config" do
    it "doesn't show help" do
      config.should_receive(:valid?).and_return(true)
      subject.should_not_receive(:show_help)
      STDERR.should_not_receive(:puts).with("Config file is incorrect.")

      subject.check_config
    end

    it "shows help if config is invalid" do
      config.should_receive(:valid?).and_return(false)
      subject.should_receive(:show_help)
      STDERR.should_receive(:puts).with("Config file is incorrect.")

      subject.check_config
    end
  end

  describe "#parse_options" do
    let(:options) { { } }

    before { subject.stub(:options).and_return(options) }
    after { subject.parse_options }

    it "should call override_config_file_with argument" do
      options["--config"] = "arg"
      subject.should_receive(:override_config_file_with).with("arg")
    end

    it "should call download_file with arg" do
      options["--download"] = "file"
      subject.should_receive(:download_file).with("file")
    end

    it "should call show_help" do
      options["--help"] = nil
      subject.should_receive(:show_help)
      subject.should_not_receive(:show_license)
    end

    it "should call show_license" do
      options["--license"] = nil
      subject.should_receive(:show_license)
    end

    it "should call list_remote_backups" do
      options["--list"] = nil
      subject.should_receive(:list_remote_backups)
    end

    it "should call list_local_backups" do
      options["--list-local"] = nil
      subject.should_receive(:list_local_backups)
    end

    it "should set only_local" do
      options["--only-local"] = nil
      subject.parse_options
      subject.instance_variable_get(:"@only_local").should be_true
    end

    it "should call override_config_file_with_option" do
      options["--verbose"] = nil
      subject.should_receive(:override_config_file_with_option).with("verbose" => true)
    end

    it "should call show_version" do
      options["--version"] = nil
      subject.should_receive(:show_version)
      subject.should_not_receive(:show_license)
    end

    it "should show help if arguments are missing" do
      subject.should_receive(:options).and_raise(GetoptLong::MissingArgument)
      subject.should_receive(:show_help)
    end

    it "should show help if invalid option is passed" do
      subject.should_receive(:options).and_raise(GetoptLong::InvalidOption)
      subject.should_receive(:show_help)
    end
  end

  describe "#run" do
    after { subject.run }

    it { subject.should_receive(:do_backup) }
    it { subject.should_receive(:upload_file) }

    it "should not upload file if only_local is set" do
      subject.instance_variable_set(:"@only_local", true)

      subject.should_receive(:do_backup)
      subject.should_not_receive(:upload_file)
    end

    it "should clean up" do
      subject.should_receive(:do_backup).and_raise(Interrupt)
      backup.should_receive(:clean_up)
    end
  end

  describe "#do_backup" do
    after { subject.send(:do_backup) }

    it { BackupJenkins::Backup.should_receive(:new).with(config) }
    it { BackupJenkins::Config.should_receive(:new) }
    it { backup.should_receive(:do_backup) }
  end

  describe "#upload_file" do
    after { subject.send(:upload_file) }

    it { backup.should_receive(:tarball_filename) }
    it { BackupJenkins::AWS.should_receive(:new).with(config) }
    it { aws.should_receive(:upload_file).with("tarball_filename", :IO) }
    it { aws.should_receive(:remove_old_files) }
  end


  describe "#show_help" do
    it "should call help info and exit" do
      subject.should_receive(:help_info).and_return("help_info")
      STDOUT.should_receive(:puts).with("help_info")
      expect{ subject.send(:show_help) }.to raise_error SystemExit
    end
  end

  describe "#show_version" do
    it "should get version info and exit" do
      subject.should_receive(:version_info).and_return("version_info")
      STDOUT.should_receive(:puts).with("version_info")
      expect{ subject.send(:show_version) }.to raise_error SystemExit
    end
  end

  describe "#show_license" do
    it "should call license_info and exit" do
      subject.should_receive(:license_info).and_return("license_info")
      STDOUT.should_receive(:puts).with("license_info")
      expect{ subject.send(:show_license) }.to raise_error SystemExit
    end
  end

  describe "#list_remote_backups" do
    it "should call aws with list_backup_files and exit" do
      aws.should_receive(:list_backup_files).and_return("list_backup_files")
      STDOUT.should_receive(:puts).with("list_backup_files")
      expect{ subject.send(:list_remote_backups) }.to raise_error SystemExit
    end
  end

  describe "#list_local_backups" do
    it "should call backup with list_local_files and exit" do
      backup.should_receive(:list_local_files).and_return("list_local_files")
      STDOUT.should_receive(:puts).with("list_local_files")
      expect{ subject.send(:list_local_backups) }.to raise_error SystemExit
    end
  end

  describe "#download_file" do
    it "should call aws with download_file and pass it the argument and then exit" do
      aws.should_receive(:download_file).with("filename")
      expect{ subject.send(:download_file, "filename") }.to raise_error SystemExit
    end
  end

  describe "#override_config_file_with" do
    it "should instantiate the config object with the passed in file_name" do
      File.should_receive(:readable?).and_return(true)
      config = mock
      BackupJenkins::Config.should_receive(:new).with("file_name").and_return(config)
      subject.send(:override_config_file_with, "file_name")
      subject.instance_variable_get(:"@config").should == config
    end

    it "should raise exception if file not readable" do
      expect{ subject.send(:override_config_file_with, "foo") }.to raise_error RuntimeError
    end
  end

  describe "#override_config_file_with_option" do
    it "should set options on config" do
      options = mock
      config.should_receive(:override).with(options)
      subject.send(:override_config_file_with_option, options)
    end
  end

  describe "#license_info" do
    it "should get the contents of license path" do
      subject.should_receive(:license_file_path).and_return("license_file_path")
      File.should_receive(:read).with("license_file_path").and_return("license_file_content")
      subject.send(:license_info).should == "license_file_content\n\n"
    end
  end

  describe "#license_file_path" do
    it { subject.send(:license_file_path).should =~ %r{/LICENSE} }
  end

  describe "#longest_width" do
    before { subject.stub(:options_possible).and_return([%w(1234), %w(1234567890), %w(123)]) }
    it { subject.send(:longest_width).should == 10 }
  end

  describe "#expand_option" do
    it {
      subject.send(:expand_option, ['--this-option', '-t', 0, 'This is my explanation']).should(
        eq "    --this-option, -t  This is my explanation"
      )
    }
  end

  describe "#help_info" do
    it "should return helpful information based on options" do
      subject.stub(:options_possible).and_return(
        [
          ['--foo', '-f', 1, 'Fooism'],
          ['--bar', '-b', 2, 'Bark']
        ]
      )
      File.stub(:basename).and_return("program_name")
      subject.stub(:version_number).and_return("version")
      subject.send(:help_info).should == <<-EOH
Usage: program_name [options]
  [--foo|-f argument], [--bar|-b]

  Options:
    --foo, -f   Fooism
    --bar, -b   Bark

backup_jenkins (version)
https://github.com/jcmuller/backup_jenkins
(c) 2012 Juan C. Muller
Work on this has been proudly backed by ChallengePost, Inc.

      EOH
    end
  end

  describe "#option_details" do
    it "should return nice things" do
      subject.stub(:options_possible).and_return(
        [
          ['--foo', '-f', 1, 'Fooism'],
          ['--bar', '-b', 2, 'Bark']
        ]
      )
      subject.send(:option_details).should ==
        "    --foo, -f   Fooism\n    --bar, -b   Bark\n"
    end
  end

  describe "#short_hand_option" do
    it "should return '--foo|-f argument'" do
      option = ["--foo", "-f", GetoptLong::REQUIRED_ARGUMENT]
      subject.send(:short_hand_option, option).should == "--foo|-f argument"
    end

    it "should return '--bar|-b'" do
      option = ["--bar", "-b", nil]
      subject.send(:short_hand_option, option).should == "--bar|-b"
    end
  end

  describe "#version_number" do
    it "returns version" do
      BackupJenkins::VERSION = "foo"
      subject.send(:version_number).should == "foo"
    end
  end
end
