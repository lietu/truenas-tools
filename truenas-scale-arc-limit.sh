#!/usr/bin/env bash
#
# Changes the ZFS ARC memory limit for TrueNAS Scale, defaults to 1/4 to 1/2 of system RAM depending on amount
#
# Use from TrueNAS Shell like:
#   wget https://raw.githubusercontent.com/lietu/truenas-tools/main/truenas-scale-arc-limit.sh
#   chmod +x truenas-scale-arc-limit.sh
#   ./truenas-scale-arc-limit.sh [limitGB]
#


ARC_SIZE_GB="$1"

if [[ "$ARC_SIZE_GB" == "" ]]; then
	# Try 1/4 of available RAM, if that's < 7GiB then 1/2 of available RAM

	SYS_RAM_KB=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')
	SYS_RAM_GB=$(($SYS_RAM_KB / 1024 / 1024))

	ARC_SIZE_GB=$(($SYS_RAM_GB / 4))
	if [[ "$ARC_SIZE_GB" -lt "7" ]]; then
		SYS_RAM_HALF=$(($SYS_RAM_GB / 2))
		ARC_SIZE_GB="$SYS_RAM_HALF"
	fi

	echo "Auto-detected ARC memory limit to ${ARC_SIZE_GB} GiB"
else
	echo "Configuring ARC memory limit to ${ARC_SIZE_GB} GiB"
fi

ARC_SIZE_B=$(($ARC_SIZE_GB * 1024 * 1024 * 1024))

# Update runtime
echo "$ARC_SIZE_B" > /sys/module/zfs/parameters/zfs_arc_max

# Update boot options
echo "Updating boot options"
midclt call system.advanced.update "{ \"kernel_extra_options\": \"zfs.zfs_arc_max=${ARC_SIZE_B}\" }"

# Clear current caches
echo "New ARC memory limit set, purging caches."
echo "This will probably take a while."

echo 3 > /proc/sys/vm/drop_caches

echo "Please keep in mind you might have to redo this after a system update."
