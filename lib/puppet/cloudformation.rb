require 'tempfile'
require 'puppet'
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
    # this method exists to make it easier to stub this call
    # so that we can capture the path of the generated template
    # for testing
    def get_pe_cfn_tempfile
      Tempfile.new(['cfn-template', '.erb'])
    end

    # validate the config used to drive the bootstrapping process
    def validate_config(config)
      top_level_rules = {
        'install_modules'  => [Array, String],
        'dashboard_groups' => [Hash],
        'puppet_agents'    => [Hash]
      }
      group_rules = {
        'classes'       => [Array,String],
        'parameters'    => [Hash],
        'parent_groups' => [Array,String]
      }
      agent_rules = {
        'classes'    => [Array, Hash, String],
        'parameters' => [Hash],
        'groups'     => [Array, String],
        'ports'      => [Array]
      }
      if ! config || config == ''
        config = {}
      end
      validate_config_helper(top_level_rules, config, 'config')
      (config['dashboard_groups'] || {}).each do |group_name, group_config|
        validate_config_helper(group_rules, group_config, "Dashboard Group #{group_name}")
      end
      (config['puppet_agents'] || {}).each do |agent_name, agent_config|
        validate_config_helper(agent_rules, agent_config, "Puppet agent #{agent_name}")
      end
      return true
    end

    def validate_config_helper(rules, config_element, type)
      config_element ||= {}
      unless config_element.is_a?(Hash)
        raise(Puppet::Error, "#{type} expects a Hash")
      end
      invalid_keys = config_element.keys - rules.keys
      unless invalid_keys == []
        raise(Puppet::Error, "Invalid #{type} keys found: #{invalid_keys.inspect}")
      end
      rules.each do |k, v|
        if config_element[k]
          unless v.include?(config_element[k].class)
            raise(Puppet::Error, "#{k} is of invalid type:#{config_element[k].class}")
          end
        end
      end
    end

    # find all of the ports from the config
    # and create security groups for them
    # right now it assumes that all ports are tcp ports
    def get_ports(config)
      config ||= {}
      (config['puppet_agents'] || {}).collect do |agent_name, agent_values|
        agent_values ||= {}
        ports = agent_values['ports'] || []
        if ports.is_a?(Array)
          ports = ports
        elsif ports.is_a?(Fixnum) or ports.is_a?(String)
          ports = ports.to_s.to_a
        end
        ports
      end.flatten.uniq
    end
  end
end
