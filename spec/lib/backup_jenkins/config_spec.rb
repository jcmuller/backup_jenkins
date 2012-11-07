require 'spec_helper'
require 'tempfile'

describe BackupJenkins::Config do
  before do
    YAML.stub(:load_file).and_return({
      "aws" => {
        "access_key" => "some_key",
        "secret" => "some_secret"
      }
    })
  end

  it "should get from YAML and define aws_key" do
    subject.aws["access_key"].should == "some_key"
  end

  it "should get from YAML and define secret" do
    subject.aws["secret"].should == "some_secret"
  end
end
