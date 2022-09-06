Facter.add(:systemd_resolved_active) do
  confine kernel: 'Linux'

  setcode do
    systemctl_present = false
    systemd_resolved_active = false

    Open3.popen3('which systemctl') do |_stdin, _stdout, _stderr, thread|
      systemctl_present = thread.value.success?
    end

    if systemctl_present
      Open3.popen3('systemctl is-active systemd-resolved') do |_stdin, _stdout, _stderr, thread|
        systemd_resolved_active = thread.value.success?
      end
    end

    systemd_resolved_active
  end
end
