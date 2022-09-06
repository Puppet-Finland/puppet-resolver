# frozen_string_literal: true

require 'spec_helper'

describe 'resolver::netplan::interface' do
  default_params = { 'servers': ['8.8.8.8', '8.8.4.4'],
                     'interface': 'eth0',
                     'domains': ['example.org', 'example.com'] }

  extra_facts = {}

  on_supported_os.each do |os, os_facts|
    context "netplan compiles on #{os}" do
      let(:title) { 'eth0' }
      let(:params) { default_params }
      let(:facts) { os_facts.merge(extra_facts) }

      if os_facts[:operatingsystem] == 'Ubuntu' && ['20.04'].include?(os_facts[:operatingsystemrelease])
        it { is_expected.to compile }
        it { is_expected.to contain_file('/etc/netplan/99-custom-dns-eth0.yaml').with('owner' => 'root', 'group' => 'root', 'mode' => '0644', 'notify' => 'Exec[netplan-apply-eth0]') }
        it { is_expected.to contain_exec('netplan-apply-eth0').with('command' => 'netplan generate && netplan apply') }
      end
    end
  end
end
