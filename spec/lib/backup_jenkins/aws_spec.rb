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

  describe "#populate_files"
  describe "#remove_old_files"
  describe "#files_to_remove"
  describe "#upload_file"

end
