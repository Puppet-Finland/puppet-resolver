# frozen_string_literal: true

require 'spec_helper'

describe 'resolver' do
  default_params = { 'servers' => ['8.8.8.8', '8.8.4.4'],
                     'domains' => ['example.org', 'example.com'] }

  xenial          = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['16.04'] }] }
  # bionic          = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['18.04'] }] }
  # focal           = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['20.04'] }] }
  # jammy           = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['22.04'] }] }
  systemd_ubuntus = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['18.04', '20.04', '22.04'] }] }
  centos          = { supported_os: [{ 'operatingsystem' => 'CentOS', 'operatingsystemmajrelease' => ['7', '8'] }] }
  rocky           = { supported_os: [{ 'operatingsystem' => 'Rocky', 'operatingsystemmajrelease' => ['7', '8'] }] }
  rhel            = { supported_os: [{ 'operatingsystem' => 'RedHat', 'operatingsystemmajrelease' => ['7', '8'] }] }
  redhat_distros  = {}
  redhat_distros.merge(**centos, **rocky, **rhel)

  on_supported_os.each do |os, os_facts|
    context "compiles on #{os}" do
      extra_facts = {}
      extra_facts = { os: { distro: { codename: 'RedHat' } } } if os_facts[:osfamily] == 'RedHat'
      let(:facts) { os_facts.merge(extra_facts) }
      let(:params) { default_params }

      it { is_expected.to compile }
    end
  end

  on_supported_os(redhat_distros).each do |os, os_facts|
    context "default resolver settings on #{os}" do
      extra_facts = {}
      extra_facts = { os: { distro: { codename: 'RedHat' } } } if os_facts[:osfamily] == 'RedHat'
      let(:facts) { os_facts.merge(extra_facts) }
      let(:params) { default_params }

      it { is_expected.to compile }
    end
  end

  on_supported_os(xenial).each do |os, os_facts|
    context "default resolver settings on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params }

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

  on_supported_os(systemd_ubuntus).each do |os, os_facts|
    context "default resolver settings on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params }

      it { is_expected.to contain_class('resolver::systemd_resolved') }
      it { is_expected.to contain_file('/etc/systemd/resolved.conf.d') }
      it {
        is_expected.to contain_file('/etc/systemd/resolved.conf.d/50_puppet_resolver.conf').with('notify' => 'Exec[restart-systemd-resolved]',
                                                                                                    'require' => 'File[/etc/systemd/resolved.conf.d]')
      }
      it {
        is_expected.to contain_exec('restart-systemd-resolved').with('command' => 'systemctl restart systemd-resolved',
                                                                        'refreshonly' => true)
      }
    end
  end
end
