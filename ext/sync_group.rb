#!/opt/puppet/bin/ruby
require 'puppet'
require 'puppet/face'
$LOAD_PATH.push('/etc/puppetlabs/puppet/modules/puppetlabs-dashboard/site_lib')
# it needs three arguments
group_meta_data=PSON.parse(File.read('/var/lib/cfn-init/data/metadata.json'))
if group_meta_data.is_a?(Hash) and group_meta_data['Dashboard'].is_a?(Hash)
  group_data = group_meta_data['Dashboard']['Groups']
  (group_data || {}).each do |k,v|
    Puppet::Face[:dashboard, :current].create_group(
      :enc_server => 'localhost',
      :enc_port => 443,
      :enc_auth_passwd => 'cfn_password',
      :enc_auth_user => 'cfn_user',
      :enc_ssl => true,
      :classes => v['classes'],
      :parent_groups => v['parent_groups'],
      :parameters => v['parameters'],
      :name => k
    )
  end
end
