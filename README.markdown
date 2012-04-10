## Background
This project is based on the Amazon Cloud Formation framework. It adds a Puppet Face
to enable simple creation of a fully operational Puppet Enterprise stack utilizing
module content from the Puppet Forge.

This project contains an aws cloud formation template that is capable of deploying
a cluster of nodes with puppet enterprise installed.
http://aws.amazon.com/cloudformation/

The general goal is that you can specify your desired stack in a simple yaml document
and use a single command to create an entirely functional puppet environment from that
configuration document.

One config file, one command and you're done!


## Prerequisites

AWS Credentials
---------------
You need an active AWS account with EC2 access.  
You'll also need a key pair in the region you wish to use. us-west-1 is recommended.  
Your AWS account needs full administrator rights at this time.  

Environment & Puppet
--------------------
This software requires Puppet >= 2.7.6 (or PE >= 2.0).  
This software also requires Java be installed.  
Export your chosen EC2 region in your environment. ex: `export EC2_REGION=us-west-1`  


## Installation

Static releases can be found on the Puppet Forge: http://forge.puppetlabs.com/puppetlabs/cloudformation
The latest code is always available on Github: https://github.com/puppetlabs/puppetlabs-cloudformation

The amazon Cloud Formation client tools and the Puppet Face can be installed and
configured easily using the cloudformation Puppet class.

The following example manifest can be found at examples/install.pp

  class { 'cloudformation':
    aws_access_key => '< your key here >',
    aws_secret_key => '< your secret key here >',
    # java_home => '< your java_home >',
  }

It may also be necessary to fill in the java home attribute so that it points to
where java has been installed. It currently defaults to the location of Java on a
Mac(/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home).

Add your aws credentials to the class declaration, ensure the cloudformation module
is in your module path, and use puppet to apply the installation manifest:

  `puppet apply examples/install.pp`

This will install the client tools and create the file: bashrc_cfn

Configure your cfn client tools by sourcing this file:

  `source bashrc_cfn`

After you source this file, verify that your cfn tools work:

  `cfn-describe-stacks`

The command should return 'No Stacks found'.


## Stack Configuration

The config file used to specify how to build the stack is build in yaml format and takes the
following configuration options:

* install_modules - list of modules that should be installed on the master from the Puppet Forge

  install_modules
   - puppetlabs-stdlib
   - puppetlabs-ntp

The above example would create the directories ntp and stdlib in /etc/puppetlabs/puppet/modules
on the puppet master.

* puppet_agents - hash of ec2 instances that should be created and have puppet agents installed on
them. The structure of the hash is described below:

for parameterized classes:

puppet_agents:
  resource_id:
    classes:
      class_name1:
        class_param1: value

for non_parameterized classes:

puppet_agents:
  resource_id:
    classes:
      - class_name1
    parameters:
      class_param1: value

resource_id is an arbitrary name and must be unique.

* dashboard_groups - Define arbitrary groupings of classes that can be applied together on nodes.

dashboard_groups:
  group_name:
    classes: class_name1 class_name2 etc..

Once groups are defined, they are applied under your puppet_agents: section like the following.

puppet_agents:
  resource_id:
    groups: group_name

* security groups - If you need aws security groups provided for an agent, you can like so.

puppet_agents:
  resource_id:
    ports:
      - 80
      - 443

## Cloud Formation Puppet Face

After you have sourced the bashrc file, you should be able to use the Cloud Formation Puppet Face.

To get details of how to use the face, you can run:

  `puppet help cloudformation deploy`

The Cloud Formation Face accepts a configuration file as specified above and then
deploys a full application stack using Puppet Enterprise.

It creates all of the required AWS resources, including: security groups, IAM users, an
ec2 instance with the puppet master and modules installed, and a configurable number of
puppet agents with their classification information specified.

The following invocation will deploy one of the example stacks:

  `puppet cloudformation deploy --keyname your_key_name --config config/pedemo.config --stack-name your_stack_name --disable-rollback`

--disable-rollback prevents EC2 from destroying your instances if the stack failed to build properly.

## Logging into the Puppet Master

Once your stack is built, cfn-describe-stacks will return CREATE_COMPLETE and the public hostname for your Puppet Master.

To visit the Puppet Enterprise Console, open your web browser and visit https://public_hostname_here and login with username: ec2_user@example.com and password: ec2_password

To learn more about Puppet Enterprise, see http://docs.puppetlabs.com/pe/index.html.
