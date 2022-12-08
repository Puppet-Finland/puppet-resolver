# puppet-resolver

Manage DNS resolver configurations on Linux and Windows systems. The module
supports several different methods of DNS resolver configuration:

* dhclient
* sysconfig
* systemd-resolved
* windows

Other methods can be added relatively easily.

Sane defaults for the DNS resolver method have been provided for all [supported
operating systems](metadata.json):

* Ubuntu 16.04 (dhclient)
* Ubuntu 18.04, 20.04, 22.04 (systemd-resolved)
* CentOS/Red Hat 7 (sysconfig)
* CentOS/Rocky/Red Hat 8 (sysconfig)
* Windows (windows)

However, should the defaults fail the method can be selected manually.

# General usage

In most cases you should be able to just use the defaults:

    class { 'resolver':
      servers => ['10.10.10.1', '10.10.10.2'],
      domains => ['example.org', 'example.com'],
    }

Note that some methods do not supports the *domains* parameter at all, or may
only support it partially.

Note that method defaults only works for the officially supported operating
systems, that is, those that have proper module-level Hiera data.  On
unsupported operating systems catalog configuration will fail unless you
explicitly define the *method* parameter.

Also note that the default methods may not be correct in all cases. For example
some Cloud images may be configured to use different method out of box than
what this module expects.

# Methods

## dhclient

Example usage:

    class { 'resolver':
      method  => 'dhclient',
      servers => ['10.10.10.1', '10.10.10.2'],
    }

Notes:
* The *domains* parameter is not supported

## netplan

The netplan method is somewhat dangerous as it touches network interface
settings instead of just DNS settings. Therefore it has to enabled explicitly
using the *resolver::netplan::interface* define and does not have a
convenience wrapper in the main class. It takes the exact same parameters as
*resolver::systemd_resolved::interface*. Using the netplan method is the only
way to properly customize DNS servers on Ubuntu 20.04 in Amazon EC2, for
example.

## sysconfig

The sysconfig method depends on *ifup* being available. Older versions of
Rocky Linux 8 had that installed out of the box, but newer ones don't. For
the newer ones you need to install *NetworkManager-initscripts-updown*
package to get *ifup*.

Example usage:

    class { 'resolver':
      method    => 'sysconfig',
      servers   => ['10.10.10.1', '10.10.10.2'],
      domains   => ['example.org'],
      interface => 'eth0',
    }

Notes:
* The *domains* parameter is optional
* If *interface* is not defined, Puppet defaults to using the primary network interface ($facts['networking']['primary'])
* If more than one domain is defined, only the first one is used

## systemd-resolved

To configure *global* settings:

    class { 'resolver':
      method    => 'systemd-resolved',
      servers   => ['10.10.10.1', '10.10.10.2'],
      domains   => ['example.org', 'example.com'],
    }

Note that *global* settings may not have the intended effect as per-link
settings may take precedence over them.

To configure settings for an interface (this is a wrapper for
*resolver::systemd_resolved::interface*):

    class { 'resolver':
      method    => 'systemd-resolved',
      servers   => ['10.10.10.1', '10.10.10.2'],
      domains   => ['example.org', 'example.com'],
      interface => 'eth0',
    }

If you need to configure resolvers for more than one interface you can use the
*resolver::systemd_resolved::interface* define:

    resolver::systemd_resolved::interface { 'eth0':
      servers   => ['10.10.10.1', '10.10.10.2'],
      domains   => ['example.org', 'example.com'],
      interface => 'eth0',
    }
    
    resolver::systemd_resolved::interface { 'eth1':
      servers   => ['10.20.20.1', '10.20.20.2'],
      domains   => ['foo.org', 'bar.com'],
      interface => 'eth1',
    }

Notes:
* The domains parameter is optional
* Multiple domains are supported
* If systemd-resolved has already obtained domain information from elsewhere it does not get overwritten (yet). This can cause unexpected behavior and/or flickering on Puppet runs.

## windows

Example usage:

    class { 'resolver':
      method  => 'windows,
      servers => ['10.10.10.1', '10.10.10.2'],
    }

Notes:
* The *domains* parameter is not supported

# Custom facts

## systemd_resolve_status

If systemd-resolved is running this fact should contain a hash with DNS
settings for each interface. For example:

```
{
  Global => {
  }
  eth0 => {
    dns_domain => [
      "example.org"
    ],
    dns_servers => [
      "10.10.10.1",
      "10.10.10.2"
    ]
  },
  eth1 => {
    dns_domain => [
      "example.com"
    ],
    dns_servers => [
      "10.20.20.1",
      "10.20.20.2"
    ]
  },
  eth2 => {
    dns_servers => [
      "10.30.30.1",
      "10.30.30.2"
    ]
  },
  eth3 => {
  }
}
```

## systemd_resolved_active

This fact returns true if "systemctl is-active systemd-resolve" returns 0 and
false otherwise.
