class cloudformation(
  $aws_access_key,
  $aws_secret_key,
  $base_dir = get_module_path($module_name),
  $aws_credential_file = "${base_dir}/aws_credentials",
  $java_home = '/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home',
  $cfn_version = '1.0.9'
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
