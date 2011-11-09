  $puppet_agents
#
#
# [*install_modules*] List of modules to install from forge. Modules must be of the 
#   form <module_owner_namespact>/<module_name>
define cloudformation::pe(
  $install_modules = []
) {
  file { $name:
    content => template('cloudformation/pe.erb')
  }
}
