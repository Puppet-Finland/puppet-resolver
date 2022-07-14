# frozen_string_literal: true

require 'spec_helper'

describe 'resolver' do
  default_params = { 'servers' => ['8.8.8.8', '8.8.4.4'],
                     'domains' => ['example.org', 'example.com'] }

  on_supported_os.each do |os, os_facts|
    context "compiles on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params }

      it { is_expected.to compile }
    end
  end

  on_supported_os.each do |os, os_facts|
    context "ubuntu default resolver settings on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params }

      if os_facts[:operatingsystem] == 'Ubuntu' && ['16.04'].include?(os_facts[:operatingsystemmajrelease])
        it { is_expected.to contain_class('resolver::dhclient') }
        it { is_expected.to contain_file('/etc/dhcp/dhclient.conf') }
        it { is_expected.to contain_file_line('resolver_config').with('require' => 'File[/etc/dhcp/dhclient.conf]') }
        it {
          is_expected.to contain_exec('restart networking service').with('require' => 'File_line[resolver_config]',
                                                                         'subscribe'   => 'File_line[resolver_config]',
                                                                         'command'     => '/bin/systemctl restart networking',
                                                                         'refreshonly' => true)
        }
      end
    end

    context "ubuntu default resolver settings on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params }

      if os_facts[:operatingsystem] == 'Ubuntu' && ['18.04', '20.04', '22.04'].include?(os_facts[:operatingsystemmajrelease])
        it { is_expected.to contain_class('resolver::systemd_resolved::global') }
        it { is_expected.to contain_file('/etc/systemd/resolved.conf.d') }
        it {
          is_expected.to contain_file('/etc/systemd/resolved.conf.d/50_puppet_resolver.conf').with('notify' => 'Exec[restart networking service]',
                                                                                                      'require' => 'File[/etc/systemd/resolved.conf.d]')
        }
        it {
          is_expected.to contain_exec('restart networking service').with('command' => 'systemctl restart systemd-resolved',
                                                                          'refreshonly' => true)
        }
      end
    end

    context "redhat default resolver settings on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params.merge({ 'interface': 'eth0' }) }

      if os_facts[:operatingsystem] =~ %r{RedHat|CentOS|Rocky} && ['7', '8'].include?(os_facts[:operatingsystemmajrelease])
        it { is_expected.to contain_class('resolver::sysconfig') }
        it {
          is_expected.to contain_file_line('PEERDNS').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'PEERDNS=no',
                                                                'notify' => 'Exec[restart networking service]')
        }
        it {
          is_expected.to contain_file_line('DNS1').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'DNS1=8.8.8.8',
                                                                'notify' => 'Exec[restart networking service]')
        }
        it {
          is_expected.to contain_file_line('DNS2').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'DNS2=8.8.4.4',
                                                                'notify' => 'Exec[restart networking service]')
        }
        it {
          is_expected.to contain_file_line('DOMAIN').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'DOMAIN=example.org',
                                                                'notify' => 'Exec[restart networking service]')
        }

        it {
          is_expected.to contain_exec('restart networking service').with('command' => '/sbin/ifup eth0')
        }
      end
    end

    context "redhat single DNS server on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        { 'servers' => ['8.8.8.8'],
                       'domains' => ['example.org'] }
      end

      if os_facts[:operatingsystem] =~ %r{RedHat|CentOS|Rocky} && ['7', '8'].include?(os_facts[:operatingsystemmajrelease])
        it { is_expected.to contain_class('resolver::sysconfig') }
        it {
          is_expected.to contain_file_line('PEERDNS').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'PEERDNS=no')
        }
        it {
          is_expected.to contain_file_line('DNS1').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'DNS1=8.8.8.8')
        }

        it { is_expected.not_to contain_file_line('DNS2') }

        it {
          is_expected.to contain_file_line('DOMAIN').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'DOMAIN=example.org')
        }
      end
    end

    context "redhat no domain on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { 'servers' => ['8.8.8.8', '8.8.4.4'] } }

      if os_facts[:operatingsystem] =~ %r{RedHat|CentOS|Rocky} && ['7', '8'].include?(os_facts[:operatingsystemmajrelease])
        it { is_expected.to contain_class('resolver::sysconfig') }
        it {
          is_expected.to contain_file_line('PEERDNS').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'PEERDNS=no')
        }
        it {
          is_expected.to contain_file_line('DNS1').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'DNS1=8.8.8.8')
        }
        it {
          is_expected.to contain_file_line('DNS2').with('ensure' => 'present',
                                                                'path'   => '/etc/sysconfig/network-scripts/ifcfg-eth0',
                                                                'line'   => 'DNS2=8.8.4.4')
        }
        it {
          is_expected.not_to contain_file_line('DOMAIN')
        }
      end
    end

    context "redhat custom service restart #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params.merge({ 'interface': 'eth0', 'service_restart_command': 'nmcli connection reload' }) }

      if os_facts[:operatingsystem] =~ %r{RedHat|CentOS|Rocky} && ['7', '8'].include?(os_facts[:operatingsystemmajrelease])
        it { is_expected.to contain_class('resolver::sysconfig') }

        it {
          is_expected.to contain_exec('restart networking service').with('command' => 'nmcli connection reload')
        }
      end
    end

    context "generic sysconfig method on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params.merge({ 'interface': 'eth0', 'method': 'sysconfig' }) }

      it { is_expected.to contain_class('resolver::sysconfig') }
    end

    context "generic sysconfig method with no service restart on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params.merge({ 'interface': 'eth0', 'method': 'sysconfig', 'service_restart': false }) }

      it { is_expected.to contain_class('resolver::sysconfig') }
      it { is_expected.to contain_file_line('DNS1').without_notify }
      it { is_expected.not_to contain_exec('restart networking service') }
    end

    context "generic systemd-resolved method on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params.merge({ 'method': 'systemd-resolved' }) }

      it { is_expected.to contain_class('resolver::systemd_resolved::global') }
    end

    context "generic systemd-resolved method with no service restart on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params.merge({ 'method': 'systemd-resolved', 'service_restart': false }) }

      it { is_expected.not_to contain_exec('restart networking service') }
    end
  end
end
