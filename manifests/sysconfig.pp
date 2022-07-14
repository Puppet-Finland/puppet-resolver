#
# @summary
#   Add DNS resolver using the generic RedHat sysconfig method. Note that even
#   when this is used with NetworkManager  
#
# @param servers
# @param domains
# @param interface
# @param service_restart
# @param service_restart_command
#
class resolver::sysconfig (
  Array[String, 1, 2]        $servers,
  String                     $interface,
  Boolean                    $service_restart,
  Optional[Array[String, 1]] $domains = undef,
  Optional[String]           $service_restart_command = undef,
) {
  if $service_restart {
    unless $service_restart_command {
      fail('ERROR: service_restart_command must be set when service_restart is set!')
    }
  }

  # Only one search domain is supported
  $dns_domain = $domains ? {
    undef   => undef,
    default => $domains[0],
  }

  $base_settings = {
    'PEERDNS' => 'no',
    'DNS1'    => $servers[0],
  }

  $dns2_settings = $servers.length ? {
    2       => { 'DNS2' => $servers[1] },
    default => {}
  }

  $domain_settings = $dns_domain ? {
    undef   => {},
    default => { 'DOMAIN' => $dns_domain }
  }

  $notify = $service_restart ? {
    false   => undef,
    default => Exec['restart networking service'],
  }

  $settings = $base_settings + $dns2_settings + $domain_settings

  $settings.each |$s| {
    file_line { $s[0]:
      ensure => 'present',
      path   => "/etc/sysconfig/network-scripts/ifcfg-${interface}",
      line   => "${s[0]}=${s[1]}",
      notify => $notify,
    }
  }

  if $service_restart {
    # Replace _INTERFACE_ in the service restart command - if found - with the
    # real interface name
    $l_service_restart_command = regsubst($service_restart_command, '_INTERFACE_', $interface)

    exec { 'restart networking service':
      command     => $l_service_restart_command,
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      refreshonly => true,
    }
  }
}
