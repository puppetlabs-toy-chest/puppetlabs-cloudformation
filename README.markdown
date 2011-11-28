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
This software requires Puppet >= 2.7.7.
Export your chosen EC2 region in your environment. ex: `export EC2_REGION=us-west-1`


## Installation

The amazon cloud formation client tools can be downloaded
using the cloudformation puppet class.

The following example manifest can be found at examples/install.pp

  class { 'cloudformation':
    aws_access_key => '< your key here >',
    aws_secret_key => '< your secret key here >'
  }

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

After you have sourced the bashrc file, you should be able to use the cloudformation puppet face.

To get details of how to use the face, you can run:

  `puppet help cloudformation deploy`

The cloudformation face accepts a configuration file as specified above and then
deploys a full application stack using Puppet Enterprise.

It creates all of the required AWS resources, including: security groups, IAM users, an
ec2 instance with the puppet master and modules installed, and a configurable number of
puppet agents with their classification information specified.

The following invocation will deploy one of the example stacks:

  `puppet cloudformation deploy --keyname your_key_name --config config/ntp_nodes.config --stack-name your_stack_name --disable-rollback`

--disable-rollback prevents EC2 from destroying your instances if the stack failed to build properly.
