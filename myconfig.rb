=begin
  Class MyConfig - DSL for parsing and querying ini files

  Usage:
    config = MyConfig.load("config.ini", ["a", "b", "c"])
    puts config.foo.bar # prints "foobar"

    where config.ini looks like:
    [foo]
    bar="foobar"

  Dependencies:
    ruby 1.9.3-p484

  Author:
    BN
=end

class MyConfig < Hash

  attr_reader :group_name

  def initialize(name)
    @group_name = name
  end

  #######################################################################
  # Override method_missing to support dot notation access of groups
  # and settings. method_missing will be called only once to inject a
  # Proc into the MyConfig class for the group or setting being accessed.
  # Any future calls for the group or setting will call the newly created
  # Proc and skip method_missing (since the method won't be missing)
  #######################################################################
  def method_missing(method, *args, &block)
    if key?(method.to_s) or key?(method)

      self.class.send(:define_method, method) {
        # major hack!
        if (method == :enabled)
          (self[method].nil? ? [method.to_s] : self[method])
        else
          self[method] || self[method.to_s]
        end
      }
      # call proc we just create to return the value the first time
      self.send(method)
    else
      # not defined groups or settings are not errors so don't call super
      # which will just throw an exception.
      nil
    end
  end

  #######################################################################
  # Need to support respond_to? or we will break ruby's
  # method_missing logic.
  #######################################################################
  def respond_to?(method, include_private=false)
    key?(method.to_s) or key?(method) ? true : super
  end

  #######################################################################
  # Class variables and members
  #######################################################################
  @@bool_mapper = {
    "yes" => true, "no" => false, "true" => true, "false" => false, 1 => true, 0 => false
  }

  #######################################################################
  # read the config file line by line and parse each line
  #######################################################################
  def self.load(filename, overrides)
    # strip out symbols - we'll normalize later
    overrides.map! { |o| o.to_s }

    config = MyConfig.new(:main)
    # create a default group just in case we get a config file with
    # settings not in a group.
    config[:default] = current_group = MyConfig.new(:default)

    # read and parse each line in the config file
    IO.foreach(filename) { |line|
      MyConfig::parse(line) { |obj|
        # if parser returns a config object we're starting a new group
        if (obj.instance_of?(MyConfig))
          config[obj.group_name] = current_group = obj;
        # otherwise this is a setting to be added to the current group
        elsif (obj[:override].nil?) || (overrides.include?(obj[:override]))
          current_group[obj[:setting]] = obj[:value]
        end
      }
    }
    # return the parsed config object
    config
  end

  #######################################################################
  # parse a line of config.  We make some assumptions:
  # - ignore empty lines
  # - strip leading and trailing spaces
  # - lines starting with '[' are group definition section
  # - lines starting with ';' are comments - skip these
  # - any line that passes the above tests is a setting
  #######################################################################
  def self.parse(line)
    line.strip!

    unless (line.empty?)
      # new group
      if (line[0] == '[')
        yield MyConfig.new(line.gsub(/[\[\]\n]/, ''))

      # group settings
      else
        # ignore comments
        unless (line[0] == ';')
          setting, value = line.split('=').each {|s| s.strip!}
          
          #
          # clean up value 
          #

          # hack - if it's not quoted and it contains one or more ',' then it's an array
          if ((value[0] != '"') && !(value =~ /,/).nil?)
            value = value.split(',')
          end

          # strip unnecessary quotes
          if (value[0] == '"')
            value.gsub!(/"/, '')
          end

          # strip of trailing comments
          if (value.is_a? String)
            value.sub!(/;.*$/,'')
          end

          # hack: keys called enabled are boolean
          if (setting == 'enabled') && !@@bool_mapper[value].nil?
            value = @@bool_mapper[value]
          end

          # numerics
          if !(value =~ /^[0-9]+$/).nil?
            value = value.to_i
          end

          # make all keys symbols
          settings = {:setting => setting.to_sym, :value => value}

          # parse out conditional expressions
          if (!(setting =~ /<\w+>/).nil?)
            _setting, override_val = setting.split(/</).each {|s| s.sub!(/>/,'')}
            settings[:setting] = _setting.to_sym
            settings[:override] = override_val
          end

          # let the caller decide what to do with the parsed line
          yield settings
        end
      end
    end
  end

end