require 'spec_helper'
require 'tempfile'

describe BackupJenkins::Config do
  before do
    config = {
      "aws" => { "access_key" => "some_key", "secret" => "some_secret" },
      "backup" => { "file_name_base" => "jenkins" },
      "verbose" => true
    }

    YAML.stub(:load_file).and_return(config)
  end

  it { expect{ subject.foo }.to raise_error NoMethodError }
  it { should be_respond_to(:aws) }
  it { should_not be_respond_to(:foo) }
  it { subject.aws["access_key"].should == "some_key" }
  it { subject.aws["secret"].should == "some_secret" }

  describe "#base_file_name" do
    before { subject.stub(:hostname).and_return("hostname") }
    it { subject.base_file_name.should == "jenkins_hostname" }
  end

  describe "#hostname" do
    after { subject.send(:hostname).should == 'hostname' }
    it { subject.should_receive(:`).with("hostname -s").and_return("hostname\n") }
  end

  describe "#config_file" do
    it "should load file" do
      YAML.should_receive(:load_file).and_return("configuration")
      subject.instance_variable_get(:"@config").should == "configuration"
    end

    it "should exit with non 0 on error" do
      YAML.should_receive(:load_file).and_raise(Errno::ENOENT.new)
      expect{ subject }.to raise_error SystemExit
    end

    it "should print some helpful text if config file doesn't exist" do
      subject.should_receive(:default_config_file_path).and_return("config")

      YAML.should_receive(:load_file).and_raise(Errno::ENOENT.new)
      File.should_receive(:read).and_return("sample")

      STDERR.should_receive(:puts).with("Please create a config file in config")
      STDERR.should_receive(:puts).with("\nIt should look like:\n\nsample")

      expect{ subject.send(:config_file, nil) }.to raise_error SystemExit
    end
  end

  describe "#config_file_example" do
    regexp = %r{config/config-example.yml$}
    it { subject.send(:config_file_example_path).should match regexp }
  end

  describe "#override" do
    it "should override config file" do
      subject.verbose.should be_true
      subject.override("verbose" => false)
      subject.verbose.should be_false
    end
  end

  describe "#valid?" do
    let(:config) {
      {
        "aws" => {
          "access_key" => "AWS_ACCESS_KEY",
          "secret" => "AWS_SECRET",
          "bucket_name" => "BUCKET_NAME"
        },
        "backup" => {
          "dir_base" => "PATH_TO_BACKUP_DIRECTORY",
          "file_name_base" => "SOME_BASE_NAME",
          "backups_to_keep" => {
            "remote" => 2,
            "local" => 5
          }
        },
        "jenkins" => {
          "home" => "PATH_TO_JENKINS_HOME"
        },
        "verbose" => false
      }
    }

    before do
      YAML.stub(:load_file).and_return(config)
    end

    it "should make sure that the config loaded has the necessary options" do
      should be_valid
    end

    it "should be valid if verbose is false" do
      config["verbose"] = false
      should be_valid
    end

    it "should not be valid if verbose option is missing" do
      config.delete("verbose")
      expect{ should_not be_valid }.to raise_error NameError
    end

    it "should not be valid if aws[access_key] option is missing" do
      config["aws"].delete("access_key")
      should_not be_valid
    end

    it "should not be valid if backup section is missing" do
      config.delete("backup")
      expect{ should_not be_valid }.to raise_error NameError
    end
  end
end
