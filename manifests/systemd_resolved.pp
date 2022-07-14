#
# @summary Manage resolver settings for systemd-resolved
#
# @param servers
# @param domains
# @param interface
# @param service_restart
# @param service_restart_command
#
class resolver::systemd_resolved (
  Array[String, 1, 2]        $servers,
  Boolean                    $service_restart,
  Optional[String]           $interface = undef,
  Optional[Array[String, 1]] $domains = undef,
  Optional[String]           $service_restart_command = undef,
) {
  if $interface {
    resolver::systemd_resolved::interface { $interface:
      servers   => $servers,
      domains   => $domains,
      interface => $interface,
    }
  } else {
    class { 'resolver::systemd_resolved::global':
      servers                 => $servers,
      domains                 => $domains,
      service_restart         => $service_restart,
      service_restart_command => $service_restart_command,
    }
  }
}
