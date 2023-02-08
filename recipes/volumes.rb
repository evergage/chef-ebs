node[:ebs][:volumes].each do |mount_point, options|
  
  # skip volumes that already exist
  next if File.read('/etc/mtab').split("\n").any?{|line| line.match(" #{mount_point} ")}
  
  # create ebs volume
  if !options[:device] && options[:size]
    if node[:ebs][:creds][:encrypted]
      credentials = Chef::EncryptedDataBagItem.load(node[:ebs][:creds][:databag], node[:ebs][:creds][:item])
    else
      credentials = data_bag_item node[:ebs][:creds][:databag], node[:ebs][:creds][:item]
    end

    devices = Dir.glob('/dev/xvd?')
    devices = ['/dev/xvdf'] if devices.empty?
    devid = devices.sort.last[-1,1].succ
    device = "/dev/sd#{devid}"

    volume_type = if options[:volume_type]
                    options[:volume_type]
                  else
                    node[:ebs][:volume_type]
                  end

    vol = aws_ebs_volume device do
      # aws_access_key credentials[node.ebs.creds.aki]
      # aws_secret_access_key credentials[node.ebs.creds.sak]
      size options[:size]
      device device
      availability_zone node[:ec2][:placement_availability_zone]
      volume_type volume_type
      if node[:ebs][:encrypted]
        encrypted true
        kms_key_id node[:ebs][:kms_key_id]
      end
      if options.has_key?(:delete_on_termination)
        delete_on_termination options[:delete_on_termination]
      end
      piops options[:piops]
      throughput options[:throughput]
      action :nothing
    end
    vol.run_action(:create)
    vol.run_action(:attach)
    if File.exist?("/dev/xvd#{devid}")
      node.normal[:ebs][:volumes][mount_point][:device] = "/dev/xvd#{devid}"
    else
      node.normal[:ebs][:volumes][mount_point][:device] = "/dev/sd#{devid}"
    end
    node.save unless Chef::Config[:solo]
  end

  # mount volume

  # Use the provided device name, or the name of the mounted device if a device was not provided
  device = options[:device] || node[:ebs][:volumes][mount_point][:device]

  execute 'mkfs' do
    only_if { device and options.has_key?(:fstype) }
    command "mkfs -t #{options[:fstype]} #{device}"
    not_if do
      BlockDevice.wait_for(device)
      system("blkid -s TYPE -o value #{device}")
    end
  end

  directory mount_point do
    recursive true
    action :create
    mode 0755
  end

  mount mount_point do
    fstype options[:fstype]
    device device
    options 'noatime,nofail'
    action [:mount, :enable]
  end

end
