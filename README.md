# BackupJenkins
[![Build Status](https://secure.travis-ci.org/jcmuller/backup_jenkins.png)](http://travis-ci.org/jcmuller/backup_jenkins)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/jcmuller/backup_jenkins)
[![Dependency Status](https://gemnasium.com/jcmuller/backup_jenkins.png)](https://gemnasium.com/jcmuller/backup_jenkins)

This gem provides `backup_jenkins`, which provided with a correctly configured `config.yml`
located on `~/.config/backup_jenkins/` will backup your job configurations, next build number,
global configuration and plugins up to your Amazon AWS S3 account.

### Prerequisites

* Amazon AWS S3 account (you need to provide the user and secret keys)
* Jenkins installation
* Backup volume with lots of space

## Installation

    $ gem install backup_jenkins

## Usage

    $ backup_jenkins

The first time you run `backup_jenkins`, it shows you a sample configuration file which you
should copy into the appropriate location and fill in with your information.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
