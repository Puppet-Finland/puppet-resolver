#
# @summary Manage DNS settings for Windows primary network interface
#
class resolver::windows
(
    Array[String] $servers
)
{
    $alias = $facts['networking']['primary']
    dsc_xdnsserveraddress { $alias:
        dsc_interfacealias => $alias,
        dsc_addressfamily  => 'IPv4',
        dsc_address        => $servers,
    }
}
