module BackupJenkins
  module Formatter

    # Assumes that filenames are ordered already
    # Requires a structure like:
    # [
    #   { :key => "jenkins_berman_20121107_1721.tar.bz2", :content_length => 88762813 },
    #   { :key => "jenkins_berman_20121107_1745.tar.bz2", :content_length => 88762572 }
    # ]
    def format_backup_file_data(file_hashes)
      by_host = {}
      file_hashes.each do |file_hash|
        (date, host, key) = extract_data_from_filename(file_hash[:key])
        by_host[host] ||= []
        by_host[host].push([date, key, file_hash[:content_length] / 2.0**20])
      end

      "".tap do |output|
        by_host.each do |host, data|
          output << host.capitalize << ":" << $/
          data.each do |datum|
            output << sprintf("  - %s key: %s (%0.2f MB)#{$/}", *datum)
          end
          output << $/
        end
      end
    end

    def extract_data_from_filename(filename)
      sans_base = filename.gsub(/#{config.backup["file_name_base"]}_/, '').gsub(/\.tar\.bz2/, '')
      (hostname, date, time) = sans_base.split("_")
      formatted_date = Time.parse(date << time).strftime("%Y/%m/%d %H:%M")
      [formatted_date, hostname, filename]
    end

  end
end
