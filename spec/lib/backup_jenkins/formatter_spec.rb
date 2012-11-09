require 'spec_helper'

class SpecFormatterIncluder
  include BackupJenkins::Formatter

  attr_reader :config

  def initialize(config)
    @config = config
  end
end

describe BackupJenkins::Formatter do
  let(:config) { mock(:backup => { "file_name_base" => "jenkins" }) }
  subject { SpecFormatterIncluder.new(config) }

  describe "#format_backup_file_data" do
    let(:files) {
      [
        { :key => "jenkins_berman_20121107_1721.tar.bz2", :content_length => 88762813 },
        { :key => "jenkins_berman_20121107_1745.tar.bz2", :content_length => 88762572 },
        { :key => "jenkins_berman_20121107_1923.tar.bz2", :content_length => 88761816 },
        { :key => "jenkins_berman_20121107_2038.tar.bz2", :content_length => 88752599 },
        { :key => "jenkins_cronus_20121107_2033.tar.bz2", :content_length => 17139234 },
        { :key => "jenkins_perseo_20121107_0035.tar.bz2", :content_length => 52683965 },
        { :key => "jenkins_perseo_20121107_0135.tar.bz2", :content_length => 52684962 }
      ]
    }

    it "should format things nicely" do
      output = subject.send(:format_backup_file_data, files)
      output.should == <<-EOO
Berman:
  - 2012/11/07 17:21 key: jenkins_berman_20121107_1721.tar.bz2 (84.65 MB)
  - 2012/11/07 17:45 key: jenkins_berman_20121107_1745.tar.bz2 (84.65 MB)
  - 2012/11/07 19:23 key: jenkins_berman_20121107_1923.tar.bz2 (84.65 MB)
  - 2012/11/07 20:38 key: jenkins_berman_20121107_2038.tar.bz2 (84.64 MB)

Cronus:
  - 2012/11/07 20:33 key: jenkins_cronus_20121107_2033.tar.bz2 (16.35 MB)

Perseo:
  - 2012/11/07 00:35 key: jenkins_perseo_20121107_0035.tar.bz2 (50.24 MB)
  - 2012/11/07 01:35 key: jenkins_perseo_20121107_0135.tar.bz2 (50.24 MB)

      EOO
    end
  end

  describe "#extract_data_from_filename" do
    it "should obtain important info from filename" do
      filename = "jenkins_berman_20121107_1721.tar.bz2"

      result = subject.send(:extract_data_from_filename, filename)
      result.should == [
        '2012/11/07 17:21',
        'berman',
        'jenkins_berman_20121107_1721.tar.bz2'
      ]
    end
  end
end
