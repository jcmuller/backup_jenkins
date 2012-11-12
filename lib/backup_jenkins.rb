require 'rubygems'
require 'aws'
require 'getoptlong'
require 'hashie'
require 'time'
require 'yaml'

module BackupJenkins
  autoload :AWS,       'backup_jenkins/aws'
  autoload :Backup,    'backup_jenkins/backup'
  autoload :CLI,       'backup_jenkins/cli'
  autoload :Config,    'backup_jenkins/config'
  autoload :Formatter, 'backup_jenkins/formatter'
  autoload :VERSION,   'backup_jenkins/version'
end
