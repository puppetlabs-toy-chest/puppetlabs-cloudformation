#!/bin/bash
curl -o AWSCloudFormation-cli.zip https://s3.amazonaws.com/cloudformation-cli/AWSCloudFormation-cli.zip
unzip AWSCloudFormation-cli.zip
cat > bashrc_cfn <<-EOT
export AWS_CLOUDFORMATION_HOME=`pwd`/AWSCloudFormation-1.0.9
export PATH=\$AWS_CLOUDFORMATION_HOME/bin:\$PATH
export AWS_CREDENTIAL_FILE=\$AWS_CLOUDFORMATION_HOME/credential-file-path.template
# detects JAVA_HOME on macs
export JAVA_HOME=`/usr/libexec/java_home`
EOT
