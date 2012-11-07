require 'spec_helper'

describe BackupJenkins::AWS do
  let(:config) { stub }
  let(:s3_mocks) {
    stub(
      buckets: stub(
        :[] => stub(exists?: true),
        create: true
      )
    )
  }

  before do
    BackupJenkins::Config.should_receive(:new).and_return(config)

    config.stub(:aws).and_return({ "access_key" => "some_key", "secret" => "some_secret" })
    config.stub(:backup).and_return({ "backups_to_keep" => 2 })

    ::AWS::S3.stub(:new).and_return(s3_mocks)
  end

  describe "#setup_aws" do
    after do
      subject
    end

    it "should instantiate an S3 object" do
      ::AWS::S3.should_receive(:new).and_return(s3_mocks)
    end

    it "shuld create bucket" do
      s3_mocks.buckets.should_receive(:[]).and_return(mock(exists?: false))
      s3_mocks.buckets.should_receive(:create).and_return(mock(exists?: true))
    end
  end

  describe "#populate_files" do
    it "should get objects with prefix"
  end

  describe "#remove_old_files" do
    it "should populate_files"
    it "should iterate over files_to_remove"
    it "should call delete"
    it "should print stuff"
  end

  describe "#files_to_remove" do
    it "should get the last n files (where n is total number - keep)" do
      subject.stub(:files).and_return(%w(a b c d e f g))
      subject.files_to_remove.should == ["a", "b", "c", "d", "e"]
    end
  end

  describe "#upload_file" do
    it "should create a file"
    it "should raise exception if no s3 object is created"
  end
end
