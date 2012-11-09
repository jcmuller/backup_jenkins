require 'spec_helper'

describe BackupJenkins::Backup do
  let(:config) { mock }

  before do
    BackupJenkins::Config.stub(:new).and_return(config)
  end

  describe "#initialize" do
    it "should assign @config" do
      subject.instance_variable_get(:"@config").should == config
    end
  end

  describe "#backup_files" do
    it "should get a listing for all the files in backup directory" do
      file = "dir/base_1234"
      config.stub(:backup).and_return("dir_base" => "dir")
      config.stub(:base_file_name).and_return("base")

      File.should_receive(:size).with(file).and_return("size")
      Dir.should_receive(:[]).and_return([file])
      subject.send(:backup_files).should == [
        {
          :key => "base_1234",
          :content_length => "size"
        }
      ]
    end
  end

  describe "#backup_directory" do
    let(:backup) { { "dir_base" => "/path/to/some/dir_base" } }

    it "should return the dir base + the base file name + time stamp" do
      config.should_receive(:backup).and_return(backup)
      config.should_receive(:base_file_name).and_return("filename")
      subject.should_receive(:timestamp).and_return("timestamp")

      subject.backup_directory.should == "/path/to/some/dir_base/filename_timestamp"
    end

    it "should get data only once" do
      config.should_receive(:backup).once.and_return(backup)
      config.should_receive(:base_file_name).once.and_return("filename")
      subject.should_receive(:timestamp).once.and_return("timestamp")

      subject.backup_directory
      subject.backup_directory
      subject.backup_directory
    end
  end

  describe "#copy_files" do
    before do
      subject.stub(:plugin_files).and_return("plugin_files")
      subject.stub(:user_content_files).and_return("user_content_files")
      subject.stub(:jobs_files).and_return("jobs_files")

      subject.stub(:create_dir_and_copy)
    end

    after { subject.copy_files }

    it { subject.should_receive(:create_dir_and_copy).with("plugin_files") }
    it { subject.should_receive(:create_dir_and_copy).with("user_content_files") }
    it { subject.should_receive(:create_dir_and_copy).with("jobs_files") }
  end

  describe "#create_dir_and_copy" do
    it "should iterate over filenames and call create_dir_and_copy_impl with them" do
      subject.should_receive(:create_dir_and_copy_impl).with("a")
      subject.should_receive(:create_dir_and_copy_impl).with("b")
      subject.should_receive(:create_dir_and_copy_impl).with("c")

      subject.create_dir_and_copy(%w(a b c))
    end
  end

  describe "#list_local_files" do
    before do
      config.stub(:backup).and_return("dir_base" => "base")
      config.stub(:base_file_name).and_return("base_file_name")
    end

    it "should call the right methods" do
      subject.should_receive(:backup_files)
      subject.should_receive(:format_backup_file_data)
      subject.list_local_files
    end
  end

  describe "#clean_up" do
    it "should clean up" do
      subject.stub(:tarball_filename).and_return("tarball")
      subject.stub(:backup_directory).and_return("directory")

      STDOUT.should_receive(:puts).twice
      subject.should_receive(:remove_temporary_files)
      FileUtils.should_receive(:rm_rf).with("tarball")

      subject.clean_up
    end

    it "should recover from file not found" do
      subject.stub(:backup_directory).and_return("directory")
      subject.should_receive(:remove_temporary_files).and_raise(Errno::ENOENT)
      STDOUT.should_receive(:puts).twice
      subject.clean_up
    end
  end

  describe "#create_dir_and_copy_impl" do
    before do
      FileTest.stub(:file?).and_return(true)
      FileUtils.stub(:mkdir_p)
      FileUtils.stub(:cp)
      config.stub(:verbose).and_return(false)
      subject.stub(:new_file_path).and_return("/this/is/a/new/path/to_file")
    end

    it "should get the new file path of the file" do
      subject.should_receive(:new_file_path)
      subject.create_dir_and_copy_impl("filename")
    end

    it "should create directory new_directory" do
      FileUtils.should_receive(:mkdir_p).with("/this/is/a/new/path", :verbose => false)
      subject.create_dir_and_copy_impl("filename")
    end

    it "should copy old file to new file" do
      FileUtils.should_receive(:cp).with("filename", "/this/is/a/new/path/to_file", :verbose => false)
      subject.create_dir_and_copy_impl("filename")
    end

    it "should raise error if file to copy from doesn't exist" do
      FileTest.should_receive(:file?).and_return(false)
      expect{ subject.create_dir_and_copy_impl("filename") }.to raise_error
    end
  end

  describe "#create_tarball" do
    before do
      Dir.stub(:chdir)
      FileTest.stub(:file?).and_return(true)

      config.stub(:verbose).and_return(false)

      subject.stub(:`)
      subject.stub(:backup_directory).and_return("directory")
      subject.stub(:tar_options).and_return("options")
    end

    context do
      after { subject.create_tarball }
      it { Dir.should_receive(:chdir).with("directory") }
      it { subject.should_receive(:`).with("tar options directory.tar.bz2 .") }
    end

    it "should raise error if file doesn't exist" do
      FileTest.should_receive(:file?).and_return(false)
      expect{ subject.create_tarball }.to raise_error
    end
  end

  describe "#do_backup" do
    before do
      FileTest.stub(:directory?).and_return(false)
      subject.stub(:backup_directory).and_return("backup_directory")
      subject.stub(:copy_files)
      subject.stub(:create_tarball)
      subject.stub(:remove_temporary_files)
    end

    it "should raise error if backup directory exists already" do
      FileTest.should_receive(:directory?).and_return(true)
      expect{ subject.do_backup }.to raise_error
    end

    context do
      after { subject.do_backup }

      it { subject.should_receive(:copy_files) }
      it { subject.should_receive(:create_tarball) }
      it { subject.should_receive(:remove_temporary_files) }
    end

    it "should clean up if Interrupt" do
      subject.should_receive(:copy_files).and_raise(Interrupt)
      subject.should_receive(:clean_up)
      STDOUT.should_receive(:puts)
      subject.do_backup
    end
  end

  describe "#jobs_files" do
    before { config.stub(:jenkins).and_return({ "home" => "home" }) }

    it "should return the config.xml and nextBuildNumber files in job directories" do
      subject.should_receive(:`).
        with("find home/jobs -maxdepth 3 -name config.xml -or -name nextBuildNumber").
        and_return("file1\nfile2\nfile3")
      subject.jobs_files.should == %w(file1 file2 file3)
    end
  end

  describe "#new_file_path" do
    it "should return backup_directory/something" do
      subject.should_receive(:backup_directory).and_return("backup_directory")
      config.should_receive(:jenkins).and_return({ "home" => "some_nice_house"})

      subject.new_file_path("some_nice_house/and/then/a/room").should == "backup_directory/and/then/a/room"
    end
  end

  describe "#plugin_files" do
    before { config.stub(:jenkins).and_return({ "home" => "home" }) }

    it "returns a collection of directories including all the files that have .jpi" do
      Dir.should_receive(:[]).with("home/plugins/*.jpi").and_return(["jpi"])
      Dir.should_receive(:[]).with("home/plugins/*.jpi.pinned").and_return(["pinned"])
      Dir.should_receive(:[]).with("home/plugins/*.jpi.disabled").and_return(["disabled"])

      subject.plugin_files.should == %w(jpi pinned disabled)
    end
  end

  describe "#remove_temporary_files" do
    before do
      subject.should_receive(:backup_directory).and_return("backup_directory")
      config.stub(:verbose).and_return(false)
    end

    after { subject.remove_temporary_files }
    it { FileUtils.should_receive(:rm_rf).with("backup_directory", :verbose => false) }
  end

  describe "#tar_options" do
    it "should be jcf" do
      config.should_receive(:verbose).and_return(false)
      subject.tar_options == "jcf"
    end

    it "should be vjcf" do
      config.should_receive(:verbose).and_return(true)
      subject.tar_options == "vjcf"
    end
  end

  describe "#tarball_filename" do
    before { subject.should_receive(:backup_directory).and_return("backup_directory") }
    it { subject.tarball_filename.should == "backup_directory.tar.bz2"}
  end

  describe "#timestamp" do
    it "should return the current time with the desired timestamp from the config" do
      config.stub(:backup).and_return("timestamp" => "%Y%m%d_%H%M")
      Time.stub(:now).and_return(Time.parse("2013/01/01 12:34PM"))
      subject.send(:timestamp).should == "20130101_1234"
    end
  end

  describe "#user_content_files" do
    before { config.stub(:jenkins).and_return({ "home" => "home" }) }

    it "should return files inside the userContent directory" do
      Dir.should_receive(:[]).with("home/userContent/*").and_return(["my_file"])
      subject.user_content_files.should == %w(my_file)
    end
  end
end
