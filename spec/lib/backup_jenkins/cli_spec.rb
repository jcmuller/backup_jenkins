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
  end

  describe ".run" do
    after { BackupJenkins::CLI.run }
    it { BackupJenkins::CLI.any_instance.should_receive(:run) }
  end

  describe "#run" do
    after { subject.run }
    it { BackupJenkins::AWS.should_receive(:new).with(config) }
    it { BackupJenkins::Backup.should_receive(:new).with(config) }
    it { BackupJenkins::Config.should_receive(:new) }
    it { backup.should_receive(:do_backup) }
    it { backup.should_receive(:tarball_filename).and_return("tarball_filename") }
    it { aws.should_receive(:upload_file).with("tarball_filename", :IO) }
    it { aws.should_receive(:remove_old_files) }
  end

end
