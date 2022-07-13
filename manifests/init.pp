# @summary add DNS servers to dhclient.conf
#
# @param method
#   Method to use to manage resolver configuration
# @param servers
#   A list of DNS servers to use
# @param domains
#   A list of custom DNS domains. Used with systemd-resolved and sysconfig
#   methods. For sysconfig it sets the search domain based on the first
#   entry in the array.
#
#   Prefix a domain with a ~ to make systemd-resolved use the $servers
#   when resolving queries aimed at the domain.
# @param config_file
#   Location of dhclient.conf. Comes from module Hiera.
# @param service_restart_command
#   Command used to restart networking. Comes from module Hiera.
# @param manage
#   Whether to manage dhclient.conf with this module. Defaults to true.
#
class resolver (
  Enum['dhclient', 'sysconfig', 'systemd-resolved', 'windows'] $method,
  Array[String, 1, 2]     $servers,
  Optional[Array[String]] $domains = undef,
  Optional[String]        $interface = undef,
  Optional[String]        $config_file = undef,
  Optional[String]        $service_restart_command = undef,
  Boolean                 $manage = true,
) {

  # Default to using the primary network interface as seen by Puppet.
  # This value is not used by all resolver configuration methods.
  $l_interface = $interface ? {
    undef   => $facts['networking']['primary'],
    default => $interface,
  }

  if $manage {
    case $method {
      'dhclient': {
        class { 'resolver::dhclient':
          servers                 => $servers,
          config_file             => $config_file,
          service_restart_command => $service_restart_command,
        }
      }
      'sysconfig': {
        class { 'resolver::sysconfig':
          servers   => $servers,
          domains   => $domains,
          interface => $l_interface, 
        }
      }
      'systemd-resolved': {
        class { 'resolver::systemd_resolved':
          servers   => $servers,
          domains   => $domains,
          interface => $l_interface,
        }
      }
      'windows': {
        class { 'resolver::windows':
          servers => $servers,
        }
      }
    }
  }
}
