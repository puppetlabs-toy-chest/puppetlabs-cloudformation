# Class: cloudformation
#   This class installs the cloudformation client tools and
#   configures the cloudformation face.
#
# Tested Platforms:
#  - Darwin 10.3.2
#
# Requirements:
#  Assumes that Java version 1.5 or higher is installed.
#
# Parameters:
#  [aws_access_key]
#    *Required* AWS account credentials access key.
#  [aws_secret_key]
#    *Required* AWS account secret key.
#  [java_home]
#    *Optional* Location of java tools. Defaults to location for Mac.
#  [cfn_version]
#    *Optional* Version of the cloudformation client tools installed.
#    Defaults to 1.0.9
#  [base_dir]
#    *Optional* Location where all of the generated files and directories will
#    be installed. Defaults to the cloudformation module directory.
#  [aws_credential_file]
#    *Optional* Location where generated aws_credential_file should be saved.
#
# Actions:
#   - installs and unzips cloudformation client tools
#   - creates an example bashrc file that can be used to configure project.
#   - creates a credential file
#
class cloudformation(
  $aws_access_key,
  $aws_secret_key,
  $java_home = '/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home',
  $cfn_version = '1.0.9',
  $base_dir = get_module_path($module_name),
  $aws_credential_file = "${base_dir}/aws_credentials"
) {

  exec { 'download_cloudformation_client':
    command => '/usr/bin/curl -o AWSCloudFormation-cli.zip https://s3.amazonaws.com/cloudformation-cli/AWSCloudFormation-cli.zip',
    cwd => $base_dir,
    creates => "${base_dir}/AWSCloudFormation-cli.zip",
  }~>
  exec { 'unzip_cfn_client':
    command => '/usr/bin/unzip AWSCloudFormation-cli.zip',
    cwd => $base_dir,
    refreshonly => true,
    creates => "${base_dir}/AWSCloudFormation-#{cfn_version}",
  }
  file { $aws_credential_file:
    content => template('cloudformation/credential-file.erb'),
  }
  file { "${base_dir}/bashrc_cfn":
    content => template('cloudformation/bashrc_cfn.erb'),
  }
}
