#
# @summary add DNS servers to network-manager
#
# @param servers
# @param domains
# @param interface
# @param service_restart_command
#
class resolver::sysconfig(
  Array[String, 1, 2]        $servers,
  String                     $interface,
  Optional[Array[String, 1]] $domains = undef,
  Optional[String]           $service_restart_command = undef,
) {
  $l_service_restart_command = '/bin/systemctl restart NetworkManager'

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

  $settings = $base_settings + $dns2_settings + $domain_settings

  $settings.each |$s| {
    file_line { $s[0]:
      ensure => 'present',
      path   => "/etc/sysconfig/network-scripts/ifcfg-${interface}",
      line   => "${s[0]}=${s[1]}",
    }
  }

  #exec { 'restart networking service':
  #  command     => $l_service_restart_command,
  #  subscribe   => File['/etc/NetworkManager/conf.d/dns-dhclient.conf'],
  #  refreshonly => true,
  #}
}
