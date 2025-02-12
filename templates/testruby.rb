$discovered_drives = `blkid -t TYPE=crypto_LUKS -o device`.split(/$/).map(&:strip)
$discovered_drives.pop
$discovered_drives.each do |drv|
  puts drv
end
