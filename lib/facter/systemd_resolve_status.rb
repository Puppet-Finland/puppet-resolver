Facter.add(:systemd_resolve_status) do
  confine kernel: 'Linux'

  setcode do
    settings = {}
    link = ''

    systemctl_present = false
    systemd_resolved_running = false
    resolvectl_present = false

    Open3.popen3('which systemctl') do |_stdin, _stdout, _stderr, thread|
      systemctl_present = thread.value.success?
    end

    if systemctl_present
      Open3.popen3('systemctl is-active systemd-resolved') do |_stdin, _stdout, _stderr, thread|
        systemd_resolved_running = thread.value.success?
      end
      Open3.popen3('which resolvectl') do |_stdin, _stdout, _stderr, thread|
        resolvectl_present = thread.value.success?
      end
    end

    if systemd_resolved_running
      output = ''
      if resolvectl_present
        output = `resolvectl status`
      else
        output = `systemd-resolve --status`
      end
      output.split("\n").each do |line|
        if line.start_with?('Global')
          link = 'Global'
          settings[link] = {}
        elsif line.start_with?('Link ')
          link = line.match(%r{\((.*)\)})[1]
          settings[link] = {}
        elsif line.start_with?(%r{\s*DNS\sServers:\s})
          dns_servers = line.match(%r{: (.*)$})[1].split(' ')
          settings[link][:dns_servers] = dns_servers
        elsif line.start_with?(%r{\s*DNS\sDomain:\s})
          dns_domain = line.match(%r{: (.*)$})[1].split(' ')
          settings[link][:dns_domain] = dns_domain
        end
      end

      settings
    end
  end
end
