require 'spec_helper'

describe BackupJenkins::AWS do
  let(:config) { stub }
  let(:s3_mocks) { stub(buckets: stub(:[] => stub(exists?: true), create: true)) }

  before do
    BackupJenkins::Config.stub(:new).and_return(config)

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
    it "should get the objects from backup_files and sort them" do
      a = mock(key: 1)
      b = mock(key: 2)
      c = mock(key: 3)

      subject.should_receive(:backup_files).and_return([b, c, a])
      subject.populate_files.should == [a, b, c]
      subject.instance_variable_get(:"@files").should == [a, b, c]
    end
  end

  describe "#backup_files" do
    it "should return the right files" do
      config.should_receive(:base_file_name).and_return("base_file_name")
      objects = mock
      objects.should_receive(:with_prefix).with("base_file_name").and_return([1, 2, 3])
      subject.should_receive(:s3_files).and_return(objects)

      subject.backup_files.should == [1, 2, 3]
    end
  end

  describe "#remove_old_files" do
    before do
      config.stub(:verbose).and_return(false)
    end

    it "should populate_files" do
      subject.should_receive(:populate_files)
      subject.should_receive(:do_remove_old_files)
      subject.remove_old_files
    end

    it "should print stuff if verbose" do
      config.should_receive(:verbose).twice.and_return(true)
      subject.stub(:populate_files)
      subject.stub(:do_remove_old_files)

      STDOUT.should_receive(:puts).with("Looking for old files...")
      STDOUT.should_receive(:puts).with("Done.")

      subject.remove_old_files
    end
  end

  describe "#do_remove_old_files" do
    it "should iterate over files_to_remove and call delete on each one" do
      config.stub(:verbose).and_return(false)

      file_1 = mock
      file_2 = mock

      file_1.should_receive(:delete)
      file_2.should_receive(:delete)

      subject.should_receive(:files_to_remove).and_return([file_1, file_2])
      subject.do_remove_old_files
    end

    it "should output that's removing a file if verbose" do
      file_1 = mock(key: "filename", delete: true)

      config.should_receive(:verbose).and_return(true)
      subject.should_receive(:files_to_remove).and_return([file_1])
      STDOUT.should_receive(:puts).with("Removing filename...")

      subject.do_remove_old_files
    end
  end

  describe "#files_to_remove" do
    it "should get the last n files (where n is total number - keep)" do
      subject.stub(:files).and_return(%w(a b c d e f g))
      subject.files_to_remove.should == ["a", "b", "c", "d", "e"]
    end
  end

  describe "#upload_file" do
    it "should create a file" do
      config.stub(:verbose).and_return(false)
      objects = mock
      objects.should_receive(:create).with("filename", "file").and_return(
        mock(class: AWS::S3::S3Object)
      )
      subject.should_receive(:s3_files).and_return(objects)

      subject.upload_file("filename", "file")
    end

    it "should print stuff in verbose" do
      config.should_receive(:verbose).twice.and_return(true)

      objects = mock
      objects.stub(:create).with("filename", "file").and_return(mock(class: AWS::S3::S3Object))
      subject.stub(:s3_files).and_return(objects)

      STDOUT.should_receive(:puts).with("About to upload filename...")
      STDOUT.should_receive(:puts).with("Done")

      subject.upload_file("filename", "file")
    end

    it "should raise exception if no s3 object is created" do
      config.stub(:verbose).and_return(false)

      objects = mock
      objects.stub(:create).with("filename", "file").and_return(mock)
      subject.stub(:s3_files).and_return(objects)

      expect{ subject.upload_file("filename", "file")}.to raise_error \
        ::BackupJenkins::AWS::UploadFileError
    end
  end

  describe "#s3_files" do
    after { subject.send(:s3_files) }
    it { subject.should_receive(:bucket).and_return(mock(objects: mock)) }
  end
end
