#
# @summary add DNS servers to dhclient.conf
#
class resolver::dhclient (
  Array[String]    $servers,
  Optional[String] $config_file = undef,
  Optional[String] $service_restart_command = undef,
) {
  $servers_string = join($servers, ',')

  file { $config_file:
    ensure => 'file',
  }

  file_line { 'resolver_config':
    path    => $config_file,
    line    => "supersede domain-name-servers ${servers_string};",
    match   => '^supersede\ domain-name-servers',
    require => File[$config_file],
  }

  case $facts['os']['name'] {
    'FreeBSD': {
      $l_service_restart_command = "${service_restart_command} ${facts['networking']['primary']}"
    }
    'RedHat': {
      $l_service_restart_command = '/bin/systemctl restart NetworkManager'
      file { '/etc/NetworkManager/conf.d/dns-dhclient.conf':
        ensure  => 'file',
        content => template('resolver/dns-dhclient.conf.erb'),
        notify  => Exec['restart networking service'],
        require => File_line['resolver_config'],
      }
    }
    default: {
      $l_service_restart_command = $service_restart_command
    }
  }

  exec { 'restart networking service':
    command     => $l_service_restart_command,
    subscribe   => File_line['resolver_config'],
    require     => File_line['resolver_config'],
    refreshonly => true,
  }
}
