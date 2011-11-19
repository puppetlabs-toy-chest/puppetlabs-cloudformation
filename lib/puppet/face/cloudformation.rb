require 'puppet/face'
require 'puppet'
require 'yaml'
require 'tempfile'
require 'puppet/cloudformation'
Puppet::Face.define(:cloudformation, '0.0.1') do

  option '--config=' do
    summary 'Config file used to customize PE cloudformation template'
    description <<-EOT
      config file that is used to specify list of modules to install
      and how to classify the agents. This file should be a hash represented
      as YAML with two keys:
      install_modules: the modules from the forge that should be installed on the master
      puppet_agents: resources names of agent ec2 instances with its classes that should
      be added.
    EOT
    required
  end

  action 'deploy' do
    description 'Deploys a PE stack'
    option '--stack-name=' do
      description <<-EOT
        Name of cloudformation stack to create
      EOT
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
      summary 'by default cloudformation terminates stacks that have failure, this disables that feature'
    end

    when_invoked do |options|

      disable_rollback = options[:disable_rollback] ? ' --disable-rollback' : ''

      # set the local vairables install_modules and puppet_agents from our config file
      config = YAML.load_file(options[:config])
      dashboard_groups = {}
      install_modules = []
      puppet_agents = {}
      if config.is_a?(Hash)
        install_modules = config['install_modules'] if config['install_modules']
        puppet_agents = config['puppet_agents'] if config['puppet_agents']
        dasboard_groups = config['dashboard_groups'] if config['dashboard_groups']
      end

      erb_template_file = Puppet::CloudFormation.get_pe_cfn_template
      cfn_template_contents = ERB.new(File.read(erb_template_file), 0, '-').result(binding)
      Puppet.debug(cfn_template_contents)
      temp_cfn_template = Puppet::CloudFormation.get_pe_cfn_tempfile
      temp_cfn_template.write(cfn_template_contents)
      temp_cfn_template.close

      command = "cfn-create-stack #{options[:stack_name]} --template-file #{temp_cfn_template.path} --parameters='KeyName=#{options[:keyname]}' --region #{options[:region]} --capabilities CAPABILITY_IAM#{disable_rollback}"
      Puppet::CloudFormation.execute(command)
    end
  end
end
