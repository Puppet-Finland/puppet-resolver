# frozen_string_literal: true

require 'spec_helper'

describe 'resolver' do
  default_params = { 'servers' => ['8.8.8.8', '8.8.4.4'] }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      extra_facts = {}
      extra_facts[:lsbdistcodename] = 'RedHat' if os_facts[:osfamily] == 'RedHat'

      let(:facts) { os_facts.merge(extra_facts) }
      let(:params) { default_params }

      it { is_expected.to compile }
    end
  end
end
