#
# @summary
#   Configure DNS settings using netplan
#
# @param servers
# @param domains
# @param interface
#
define resolver::netplan::interface (
  Array[String, 1, 2] $servers,
  Array[String]       $domains = [],
  Optional[String]    $interface = undef
) {
  if $facts['os']['name'] != 'Ubuntu' {
    fail('ERROR: netplan is only supported on Ubuntu!')
  }

  $servers_str = join($servers,',')
  $domains_str = join($domains,',')

  $interface_str = $interface ? {
    undef   => $facts['networking']['primary'],
    default => $interface,
  }

  $netplan_settings = {
    interface_str => $interface_str,
    servers_str   => $servers_str,
    domains_str   => $domains_str,
  }

  file { "/etc/netplan/99-custom-dns-${interface_str}.yaml":
    ensure  => 'file',
    content => epp('resolver/99-custom-dns.yaml.epp', $netplan_settings),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec["netplan-apply-${interface_str}"],
  }

  exec { "netplan-apply-${interface_str}":
    command     => 'netplan generate && netplan apply',
    path        => ['/bin', '/usr/bin', '/sbin','/usr/sbin'],
    refreshonly => true,
  }
}
