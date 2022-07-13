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

    context "redhat default resolver settings on #{os}" do
      let(:facts) { os_facts }
      let(:params) { default_params }

      if os_facts[:operatingsystem] =~ %r{RedHat|CentOS|Rocky} && ['7', '8'].include?(os_facts[:operatingsystemmajrelease])
        it { is_expected.to contain_class('resolver::sysconfig') }
        #it {
        #  is_expected.to contain_file('/etc/NetworkManager/conf.d/dns-dhclient.conf').with('ensure' => 'file',
        #                                                                                      'notify' => 'Exec[restart networking service]')
        #}

        #it {
        #  is_expected.to contain_exec('restart networking service').with('require' => 'File_line[resolver_config]',
        #                                                               'subscribe'   => 'File_line[resolver_config]',
        #                                                               'command'     => '/bin/systemctl restart NetworkManager',
        #                                                               'refreshonly' => true)
        #}
      end
    end
  end
end
