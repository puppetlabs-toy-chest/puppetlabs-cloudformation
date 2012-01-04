class { 'cloudformation':
  aws_access_key => '< your access key here >',
  aws_secret_key => '< your secret key here >',
  # java_home    => '/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0/jre',
}
  # you will probably have to set the java home
  # above is an example of where it may be on RHEL5
  # It defaults to /System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home
