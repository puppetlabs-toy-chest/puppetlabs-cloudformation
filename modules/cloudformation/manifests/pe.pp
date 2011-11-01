class cloudformation::pe(
  $file_name,
  $puppet_agents
) {
  file { $file_name:
    content => template('cloudformation/pe.erb')
  }
}
