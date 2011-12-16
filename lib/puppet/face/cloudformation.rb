require 'puppet/face'
require 'puppet'
require 'yaml'
require 'tempfile'
require 'puppet/cloudformation'
Puppet::Face.define(:cloudformation, '0.0.1') do

  option '--config=' do
    summary 'Config file used to customize PE cloudformation template'
    description <<-EOT
      Config file that is used to specify information about how to bootstrap
      the PE environment that will be created.
      This file is represented as a hash in YAML with the following keys:
      install_modules: modules that should be downloaded from the forge.
      dashboard_groups: groups that should be created in the Dashboard.
      puppet_agents: resources names of ec2 instances that should be provisioned along with their classification information.
    EOT
    required
  end

  action 'deploy' do
    summary 'Deploys a full PE stack into EC2'
    description 'Deploys a PE stack'
    option '--stack-name=' do
      summary 'Name of cloudformation stack to create'
      required
    end
    option '--keyname=' do
      summary 'The AWS SSH key name as shown in the AWS console.'
      description <<-EOT
        This options expects the name of the SSH key pair as listed in the
        Amazon AWS console.  CloudFormation will use this information to tell Amazon
        to install the public SSH key into the authorized_keys file of the new EC2
        instance.
      EOT
      required
    end
    ['master','agent'].each do |instance|
      option "--#{instance}-type=" do
        summary "Type of #{instance} instance."
        description <<-EOT
          Type of #{instance} instance to be launched. Type specifies characteristics that
          the #{instance} will have such as architecture, memory, processing power, storage
          and IO performance. The type selected will determine the cost of a machine instance.
          Supported types are: 'm1.small','m1.large','m1.xlarge','t1.micro','m2.xlarge',
          'm2.2xlarge','x2.4xlarge','c1.medium','c1.xlarge','cc1.4xlarge'.
        EOT
        before_action do |action, args, options|
          supported_types = ['m1.small','m1.large','m1.xlarge','t1.micro','m2.xlarge','m2.2xlarge','x2.4xlarge','c1.medium','c1.xlarge','cc1.4xlarge']
          unless supported_types.include?(options["#{instance}_type".to_sym])
            raise ArgumentError, "Invalid type #{instance}: Platform must be one of the following: #{supported_types.join(', ')}"
          end
        end
      end
    end
    option '--region=' do
      summary "The geographic region of the instance. Defaults to us-east-1."
      description <<-'EOT'
        The instance may run in any region EC2 operates within.  The regions at the
        time of this documentation are: US East (Northern Virginia), US West (Northern
        California, Oregon), EU (Ireland), Asia Pacific (Singapore), and Asia Pacific (Tokyo).

        The region names for this command are: eu-west-1, us-east-1,
        ap-northeast-1, us-west-1, us-west-2, ap-southeast-1

        Region can also be specified using the EC2_REGION environment variable.

        Note: to use another region, you will need to copy your keypair.
      EOT
      default_to do
        ENV['EC2_REGION'] || 'us-east-1'
      end
    end
    option '--disable-rollback' do
      summary 'Disables the default cloudformation behavior that terminates failed stacks.'
    end

    when_invoked do |options|

      disable_rollback = options[:disable_rollback] ? ' --disable-rollback' : ''
      master_type = options[:master_type] ? ";MasterInstanceType=#{options[:master_type]}" : ""
      agent_type = options[:agent_type] ? ";AgentInstanceType=#{options[:agent_type]}" : ""

      # set the local vairables install_modules and puppet_agents from our config file
      config = YAML.load_file(options[:config])
      Puppet::CloudFormation.validate_config(config)
      allowed_ports = Puppet::CloudFormation.get_ports(config)
      dashboard_groups = {}
      install_modules = []
      puppet_agents = {}
      if config.is_a?(Hash)
        install_modules = config['install_modules'].to_a if config['install_modules']
        puppet_agents = config['puppet_agents'] if config['puppet_agents']
        dashboard_groups = config['dashboard_groups'] if config['dashboard_groups']
      end

      erb_template_file = Puppet::CloudFormation.get_pe_cfn_template
      cfn_template_contents = ERB.new(File.read(erb_template_file), 0, '-').result(binding)
      Puppet.debug(cfn_template_contents)
      temp_cfn_template = Puppet::CloudFormation.get_pe_cfn_tempfile
      temp_cfn_template.write(cfn_template_contents)
      temp_cfn_template.close

      command = "cfn-create-stack #{options[:stack_name]} --template-file #{temp_cfn_template.path} --parameters='KeyName=#{options[:keyname]}#{master_type}#{agent_type}' --region #{options[:region]} --capabilities CAPABILITY_IAM#{disable_rollback}"
      Puppet::CloudFormation.execute(command)
    end
  end
end
