  $puppet_agents
define cloudformation::pe(
) {
  file { $name:
    content => template('cloudformation/pe.erb')
  }
}
