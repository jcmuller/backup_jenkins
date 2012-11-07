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
end
