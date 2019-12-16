#
# @summary Manage resolver settings for systemd-resolved
#
class resolver::systemd_resolved
(
    Array[String]           $servers,
    Optional[Array[String]] $domains = undef,
)
{
    $resolved_conf_d = '/etc/systemd/resolved.conf.d'
    $servers_string = join($servers, ' ')
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
        ensure  => 'present',
        content => template('resolver/50_puppet_resolver.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File[$resolved_conf_d],
        notify  => Exec['restart-systemd-resolved'],
    }

    # We do not want to manage the systemd-resolved service in
    # this module as it may be managed elsewhere
    exec { 'restart-systemd-resolved':
        command     => 'systemctl restart systemd-resolved',
        path        => ['/bin','/sbin','/usr/bin','/usr/sbin'],
        refreshonly => true,
    }

    # On Fedora 30 NetworkManager is responsible for setting up interfaces. But
    # we don't want it to be responsible for DNS, so we forward requests to
    # systemd-resolved instead.
    #
    if $::lsbdistcodename == 'Thirty' {
        $conn = 'System eth0'
        $cmd = 'nmcli connection'

        exec { 'nmcli-use-systemd-resolved':
          command => "${cmd} modify \"${conn}\" ipv4.dns 127.0.0.53 && ${cmd} down \"${conn}\" && ${cmd} up \"${conn}\"",
          unless  => "${cmd} show \"${conn}\"|grep -E \"^ipv4.dns:[[:space:]]*127.0.0.53\$\"",
          path    => ['/bin','/usr/bin'],
        }
    }
}
