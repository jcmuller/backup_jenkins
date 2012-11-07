require 'rubygems'
require 'yaml'
require 'aws'

module BackupJenkins
  autoload :AWS,      'backup_jenkins/aws'
  autoload :Backup,   'backup_jenkins/backup'
  autoload :CLI,      'backup_jenkins/cli'
  autoload :Config,   'backup_jenkins/config'
  autoload :Version,  'backup_jenkins/version'
end
