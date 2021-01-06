# @summary add DNS servers to dhclient.conf
#
# @param servers
#   A list of DNS servers to use. An array of strings.
# @param domains
#   A list of custom DNS domains. Only used with systemd-resolved.
#   Prefix a domain with a ~ to make systemd-resolved use the $servers
#   when resolving queries aimed at the domain.
# @param config_file
#   Location of dhclient.conf. Comes from module Hiera.
# @param service_restart_command
#   Command used to restart networking. Comes from module Hiera.
# @param manage
#   Whether to manage dhclient.conf with this module. Defaults to true.
#
class resolver
(
    Array[String]           $servers,
    Optional[Array[String]] $domains = undef,
    Optional[String]        $config_file = undef,
    Optional[String]        $service_restart_command = undef,
    Boolean                 $manage = true,
)
{

if $manage {

    if $::osfamily == 'windows' {
        class { '::resolver::windows':
            servers => $servers,
        }
    } elsif $::osfamily == 'FreeBSD' {
          class { '::resolver::dhclient':
              servers                 => $servers,
              config_file             => $config_file,
              service_restart_command => $service_restart_command,
          }
    } else {
        if $::lsbdistcodename =~ /(bionic|focal|Thirty)/ {
            class { '::resolver::systemd_resolved':
                servers => $servers,
                domains => $domains,
            }
        } else {
              class { '::resolver::dhclient':
                  servers                 => $servers,
                  config_file             => $config_file,
                  service_restart_command => $service_restart_command,
              }
        }
    }
}
}
