# frozen_string_literal: true

require 'spec_helper'

describe 'resolver::systemd_resolved::interface' do
  default_params = { 'servers': ['8.8.8.8', '8.8.4.4'],
                     'interface': 'eth0',
                     'domains': ['example.org', 'example.com'] }

  extra_facts = { systemd_resolve_status:
    {
      'global': {
      },
      'eth0': {
        'dns_domain': [
          'example.org',
        ],
        'dns_servers': [
          '10.10.10.1',
          '10.10.10.2',
        ]
      },
      'eth1': {
        'dns_domain': [
          'example.com',
        ],
        'dns_servers': [
          '10.20.20.1',
        ]
      },
      'eth2': {
        'dns_servers': [
          '192.168.248.1',
        ]
      },
      'eth3': {
      }
    } }

  on_supported_os.each do |os, os_facts|
    context "per-link systemd-resolved compiles on #{os}" do
      let(:title) { 'eth0' }
      let(:params) { default_params }
      let(:facts) { os_facts.merge(extra_facts) }

      it { is_expected.to compile }
    end
  end

  on_supported_os.each do |os, os_facts|
    context "per-link systemd-resolved with two servers and domains on #{os}" do
      let(:title) { 'eth0' }
      let(:params) { default_params }
      let(:facts) { os_facts.merge(extra_facts) }

      it {
        is_expected.to contain_exec('systemd-resolved-update-eth0').with('command' => 'systemd-resolve -i eth0 --set-dns=8.8.8.8 --set-dns=8.8.4.4 --set-domain=example.org --set-domain=example.com; systemctl restart systemd-resolved') # rubocop:disable Layout/LineLength
      }
    end
  end

  on_supported_os.each do |os, os_facts|
    context "per-link systemd-resolved with one server and one domain on #{os}" do
      let(:title) { 'eth0' }
      let(:params) do
        { 'servers': ['8.8.8.8'],
                       'interface': 'eth0',
                       'domains': ['example.org'] }
      end
      let(:facts) { os_facts.merge(extra_facts) }

      it {
        is_expected.to contain_exec('systemd-resolved-update-eth0').with('command' => 'systemd-resolve -i eth0 --set-dns=8.8.8.8 --set-domain=example.org; systemctl restart systemd-resolved')
      }
    end
  end

  on_supported_os.each do |os, os_facts|
    context "per-link systemd-resolved with one server and no domain on #{os}" do
      let(:title) { 'eth0' }
      let(:params) do
        { 'servers': ['8.8.8.8'],
                       'interface': 'eth0' }
      end
      let(:facts) { os_facts.merge(extra_facts) }

      it {
        is_expected.to contain_exec('systemd-resolved-update-eth0').with(
        'command' => 'systemd-resolve -i eth0 --set-dns=8.8.8.8 ; systemctl restart systemd-resolved',
      )
      }
    end
  end
end
