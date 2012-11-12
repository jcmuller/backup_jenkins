require 'spec_helper'

describe BackupJenkins::AWS do
  let(:config) { stub(:aws => aws, :backup => backup) }
  let(:s3_mocks) {
    stub(:buckets => stub(:[] => stub(:exists? => true), :create => true))
  }
  let(:aws) {
    stub(
      :access_key => "some_key",
      :secret => "some_secret",
      :bucket_name => "some_bucket"
    )
  }
  let(:backup) {
    stub(:backups_to_keep => stub(:remote => 2), :file_name_base => "jenkins")
  }

  before do
    BackupJenkins::Config.stub(:new).and_return(config)
    ::AWS::S3.stub(:new).and_return(s3_mocks)
  end

  describe "#setup_aws" do
    after { subject }

    it { ::AWS::S3.should_receive(:new).and_return(s3_mocks) }

    it "shuld create bucket" do
      s3_mocks.buckets.should_receive(:[]).and_return(mock(:exists? => false))
      s3_mocks.buckets.should_receive(:create).and_return(mock(:exists? => true))
    end
  end

  describe "#files" do
    it "should get the objects from backup_files_for_this_host and sort them" do
      a = mock(:key => 1)
      b = mock(:key => 2)
      c = mock(:key => 3)

      subject.should_receive(:backup_files_for_this_host).and_return([b, c, a])
      subject.send(:files).should == [a, b, c]
      subject.instance_variable_get(:"@files").should == [a, b, c]
    end
  end

  describe "#backup_files_for_this_host" do
    it "should return the right files" do
      config.should_receive(:base_file_name).and_return("base_file_name")
      objects = mock
      objects.should_receive(:with_prefix).with("base_file_name").and_return([1, 2, 3])
      subject.should_receive(:s3_files).and_return(objects)

      subject.send(:backup_files_for_this_host).should == [1, 2, 3]
    end
  end

  describe "#backup_files_for_all_hosts" do
    it "should return the right files" do
      config.should_receive(:backup).and_return(mock(:file_name_base => "base_file_name"))
      objects = mock
      objects.should_receive(:with_prefix).with("base_file_name").and_return([1, 2, 3])
      subject.should_receive(:s3_files).and_return(objects)

      subject.send(:backup_files_for_all_hosts).should == [1, 2, 3]
    end
  end

  describe "#list_backup_files" do
    it "should call the right methods" do
      subject.should_receive(:s3_object_to_hash).twice.and_return(:blah)
      subject.should_receive(:backup_files_for_all_hosts).and_return([mock, mock])
      subject.should_receive(:format_backup_file_data).with([:blah, :blah])

      subject.list_backup_files
    end
  end

  describe "#remove_old_files" do
    before do
      config.stub(:verbose).and_return(false)
    end

    it "should call do_remove_old_files" do
      subject.should_receive(:do_remove_old_files)
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
      subject.send(:do_remove_old_files)
    end
  end

  describe "#files_to_remove" do
    it "should get the last n files (where n is total number - keep)" do
      subject.stub(:files).and_return(%w(a b c d e f g))
      subject.send(:files_to_remove).should == ["a", "b", "c", "d", "e"]
    end
  end

  describe "#upload_file" do
    it "should create a file" do
      config.stub(:verbose).and_return(false)
      objects = mock
      objects.should_receive(:create).with("filename", "file").and_return(
        mock(:class => AWS::S3::S3Object)
      )
      subject.should_receive(:s3_files).and_return(objects)

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

  describe "#download_file" do
    it "should locate a file" do
      chunk = mock
      io = mock
      name = mock
      remote_file = mock
      remote_files = mock

      subject.stub(:bucket).and_return(remote_files)
      remote_files.should_receive(:objects).and_return({ name => remote_file })
      remote_file.should_receive(:read).and_yield(chunk)

      File.should_receive(:open).with(name, 'w').and_yield(io)
      io.should_receive(:write).with(chunk)

      STDOUT.should_receive(:print).with(".")
      STDOUT.should_receive(:puts).with(".")

      subject.download_file(name)
    end
  end

  describe "#s3_files" do
    after { subject.send(:s3_files) }
    it { subject.should_receive(:bucket).and_return(mock(:objects => mock)) }
  end

  describe "#s3_object_to_hash" do
    it "should return a hash from s3 object" do
      s3_object = mock(
        :key => "key",
        :content_length => "length",
        :metadata => "this is so meta",
        :another_key => "Which will be ignored"
      )
      subject.send(:s3_object_to_hash, s3_object).should == {
        :content_length => "length",
        :key => "key",
        :metadata => "this is so meta"
      }
    end
  end
end
