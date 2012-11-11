module BackupJenkins
  module Formatter

    # Assumes that filenames are ordered already.
    #
    # Requires a structure like:
    # [
    #   { :key => "jenkins_berman_20121107_1721.tar.bz2", :content_length => 88762813 },
    #   { :key => "jenkins_berman_20121107_1745.tar.bz2", :content_length => 88762572 }
    # ]
    def format_backup_file_data(file_hashes)
      by_host = build_structure_by_host(file_hashes)
      by_host_to_formatted_output(by_host)
    end

    private

    BYTES_IN_MBYTE = 2.0 ** 20

    class EntryFormatter
      def initialize(entry)
        @entry = entry
      end

      def to_s
        sprintf("  - %s key: %s (%0.2f MB)#{$/}", *entry)
      end

      private

      attr_reader :entry
    end

    class DataFormatter
      def initialize(data)
        @entries = data.map{ |entry| EntryFormatter.new(entry) }
      end

      def to_s
        entries.map(&:to_s).join
      end

      private

      attr_reader :entries
    end

    def build_structure_by_host(file_hashes)
      {}.tap do |by_host|
        file_hashes.each do |file_hash|
          (date, host, key) = extract_data_from_filename(file_hash[:key])
          by_host[host] ||= []
          by_host[host].push([date, key, bytes_to_mb(file_hash[:content_length])])
        end
      end
    end

    def bytes_to_mb(bytes)
      bytes / BYTES_IN_MBYTE
    end

    def extract_data_from_filename(filename)
      sans_base = filename.gsub(/#{config.backup["file_name_base"]}_/, '').gsub(/\.tar\.bz2/, '')
      (hostname, date, time) = sans_base.split("_")
      formatted_date = Time.parse(date << time).strftime("%Y/%m/%d %H:%M")
      [formatted_date, hostname, filename]
    end

    def by_host_to_formatted_output(by_host)
      "".tap do |output|
        by_host.keys.sort.each do |host|
          data = by_host[host]
          output << build_host_entry(host, data)
        end
      end
    end

    def build_host_entry(host, data)
      host.capitalize << ":" << $/ << DataFormatter.new(data).to_s << $/
    end
  end
end
