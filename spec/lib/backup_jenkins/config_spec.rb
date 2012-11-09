require 'spec_helper'
require 'tempfile'

describe BackupJenkins::Config do
  before do
    config = {
      "aws" => { "access_key" => "some_key", "secret" => "some_secret" },
      "backup" => { "file_name_base" => "jenkins" }
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
    after { subject.hostname.should == 'hostname' }
    it { subject.should_receive(:`).with("hostname -s").and_return("hostname\n") }
  end

  describe "#config_file" do
    it "should load file" do
      YAML.should_receive(:load_file).and_return("configuration")
      subject.instance_variable_get(:"@config").should == "configuration"
    end

    it "should exit with non 0 on error" do
      YAML.should_receive(:load_file).and_raise(Errno::ENOENT)
      expect{ subject }.to raise_error SystemExit
    end

    it "should print some helpful text if config file doesn't exist" do
      subject.should_receive(:default_config_file_path).and_return("config")

      YAML.should_receive(:load_file).and_raise(Errno::ENOENT)
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
end
