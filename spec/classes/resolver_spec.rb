# frozen_string_literal: true

require 'spec_helper'

describe 'resolver' do
  default_params = { 'servers' => ['8.8.8.8', '8.8.4.4'],
                     'domains' => ['example.org', 'example.com'] }

  # xenial          = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['16.04'] }] }
  # bionic          = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['18.04'] }] }
  # focal           = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['20.04'] }] }
  # jammy           = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['22.04'] }] }
  systemd_ubuntus = { supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['18.04', '20.04', '22.04'] }] }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      extra_facts = {}
      extra_facts = { os: { distro: { codename: 'RedHat' } } } if os_facts[:osfamily] == 'RedHat'
      let(:facts) { os_facts.merge(extra_facts) }
      let(:params) { default_params }

      it { is_expected.to compile }
    end
  end

  on_supported_os(systemd_ubuntus).each do |os, os_facts|
    context "default resolver on #{os}" do
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
