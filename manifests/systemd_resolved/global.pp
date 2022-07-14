#
# @summary
#   Manage global resolver settings for systemd-resolved
#
# @param servers
# @param domains
# @param service_restart
# @param service_restart_command
#
class resolver::systemd_resolved::global (
  Array[String, 1, 2]        $servers,
  Boolean                    $service_restart,
  Optional[Array[String, 1]] $domains = undef,
  Optional[String]           $service_restart_command = undef,
) {
  if $service_restart {
    unless $service_restart_command {
      fail('ERROR: service_restart_command must be set when service_restart is set!')
    }
  }

  $resolved_conf_d = '/etc/systemd/resolved.conf.d'
  $servers_string = join($servers, ' ')

  $notify = $service_restart ? {
    false   => undef,
    default => Exec['restart networking service'],
  }

  if $domains {
    # Prefer the defined DNS servers as resolvers for the given domains
    $prefixed_domains = prefix($domains, '~')
    $domains_string = join($prefixed_domains, ' ')
  } else {
    $domains_string = ''
  }

  file { $resolved_conf_d:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${resolved_conf_d}/50_puppet_resolver.conf":
    ensure  => 'file',
    content => template('resolver/50_puppet_resolver.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File[$resolved_conf_d],
    notify  => $notify,
  }

  if $service_restart {
    $l_service_restart_command = $service_restart_command

    exec { 'restart networking service':
      command     => $l_service_restart_command,
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      refreshonly => true,
    }
  }
}
