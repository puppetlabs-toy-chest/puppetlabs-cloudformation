#
#
# [*install_modules*] List of modules to install from forge. Modules must be of the 
#   form <module_owner_namespact>/<module_name>
# [*puppet_agents*] - List of resources names of agents to create in the stack.
#   these agents also accept a hash of param classes to be set.
#
define cloudformation::pe(
  $puppet_agents = {},
  $install_modules = []
) {
  file { $name:
    content => template('cloudformation/pe.erb')
  }
}
