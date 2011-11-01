class { 'cloudformation::pe':
  file_name     => '/Users/danbode/dev/pe-cloudformation/pe-8-node.template',
  puppet_agents => ['Agent1', 'Agent2', 'Agent3', 'Agent4', 'Agent5', 'Agent6', 'Agent7', 'Agent8']
}
