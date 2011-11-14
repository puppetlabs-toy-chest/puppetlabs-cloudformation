module Puppet::Parser::Functions
  newfunction(:get_module_path, :type =>:rvalue, :doc => <<-EOT
    Given the name of a module as the argument, returns the path
    of the module for the current environment.
  EOT
  ) do |args|
    raise(Puppet::ParseError, "get_module_name(): Wrong number of arguments, expects one") unless args.size == 1
    if module_path = Puppet::Module.find(args[0], compiler.environment.to_s)
      module_path.path
    else
      raise(Puppet::ParseError, "Could not find module #{args[0]} in environment #{compiler.environment}")
    end
  end
end
