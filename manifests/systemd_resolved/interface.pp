#
# @summary
#   manage per-interface resolver settings for systemd-resolved
#
# @param servers
# @param domains
# @param interface
#
define resolver::systemd_resolved::interface (
  Array[String, 1, 2] $servers,
  Array[String]       $domains = [],
  Optional[String]    $interface = undef,
) {
  # Update DNS settings if they're out of sync with the current desired state
  if (($facts['systemd_resolved_status'][$interface]['dns_servers'] != $servers) or ($facts['systemd_resolved_status'][$interface]['dns_domain'] != $domains)) { # lint:ignore:140chars
    $server_map = $servers.map |$server| {
      "--set-dns=${server}"
    }

    $set_dns_params = $server_map.join(' ')

    $domain_map = $domains.map |$domain| {
      "--set-domain=${domain}"
    }

    $set_domain_params = $domain_map.join(' ')

    exec { "systemd-resolved-update-${interface}":
      command => "systemd-resolve -i ${interface} ${set_dns_params} ${set_domain_params}; systemctl restart systemd-resolved", # lint:ignore:140chars

      path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    }
  }
}
