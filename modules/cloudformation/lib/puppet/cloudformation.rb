require 'tempfile'
module Puppet::CloudFormation
  class << self
    # created so that an expectation could be set on the
    # executed command
    def execute(command)
      `#{command}`
    end

    # this method exists so that it can be stubbed to return
    # a different template for testing
    def get_pe_cfn_template
      File.join(File.dirname(__FILE__), 'templates', 'pe.erb')
    end
  end
end
