require File.join(File.dirname(__FILE__), 'myconfig')

=begin
  LoadConfig.thor - command line interface to config parser class

  Usage:
    thor load_config:load filename [--overrides]
      filename    -  path to ini file to parse and load
      --overrides -  optional array of setting overrides

  Example:
    thor load_config:load config.ini --overrides=itscript staging ubuntu

  Dependencies:
    ruby 1.9.3-p484
    thor gem

  Author:
    BN
=end

class LoadConfig < Thor
  desc "load FILENAME", "load config file"
  method_option :overrides, :default => [], :type => :array, :desc => "space separated array of settings overrides"
  def load(filename)
    config = MyConfig.load(filename, options[:overrides])


    # returns 2147483648
    puts "config.common.paid_users_size_limit => #{config.common.paid_users_size_limit}"

    # returns “hello there, ftp uploading”
    puts "config.ftp.name => #{config.ftp.name}"

    # returns [“array”, “of”, “values”]
    puts "config.http.params => #{config.http.params}"

    # returns nil
    puts "config.ftp.lastname => #{config.ftp.lastname}"

    # returns false  (permitted bool values are “yes”, “no”, “true”,
    # “false”, 1, 0)
    puts "config.ftp.enabled => #{config.ftp.enabled}"

    # returns “/etc/var/uploads”
    puts "config.ftp[:path] => #{config.ftp[:path]}"

    # returns a symbolized hash: {:name => “http uploading”,
    #                            :path => “/etc/var/uploads”,
    #                            :enabled => false}
    puts "config.ftp => #{config.ftp}"

    puts "config.http.path => #{config.http.path}"
  end
end