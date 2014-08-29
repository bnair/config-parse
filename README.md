Configuration Parser
====================

## Generic configuration parser and class in ruby
This is an example project of a class that loads and parses a configuration file in psuedo ini file format and creates an object to query the config data. Configuration values can be scalars, arrays, hashmaps or a combination of these.  The class does not support nested values or structures.  The code takes advantage of ruby's method_missing() method to dynamically create methods in the config class with the name of keys and sub-keys.  The lack of structure support is largely moot since the class supports nested hashmaps.

## To Do
* Separate reading and parsing from creating the object.
* Support alternative data formats (json, yaml, etc)
* Support structures as values
* Activerecord-like query dsl
