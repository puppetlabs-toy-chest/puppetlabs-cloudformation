class { 'cloudformation':
  aws_access_key => '< your access key here >',
  aws_secret_key => '< your secret key here >'
  # you will probably have to set the java home
  # below is an example of where it may be on RHEL5
  # java_home      => '/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0/jre',
}
