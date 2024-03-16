#!/bin/bash

# Update the system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install necessary dependencies
sudo apt-get install -y git build-essential linux-headers-$(uname -r)

# Install hugepages
sudo apt-get install -y libhugetlbfs-dev

# Enable Intel IOMMU
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt"/g' /etc/default/grub
sudo update-grub

# Download DPDK
cd ~
git clone http://dpdk.org/git/dpdk

# Build DPDK
cd dpdk
make config T=x86_64-native-linuxapp-gcc
make

# Setup hugepages
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
mkdir -p /mnt/huge
mount -t hugetlbfs nodev /mnt/huge

# Load DPDK UIO module
modprobe uio
insmod x86_64-native-linuxapp-gcc/kmod/igb_uio.ko

# Load vfio-pci module
modprobe vfio-pci

# Bind Ethernet devices to DPDK
#./usertools/dpdk-devbind.py --bind=vfio-pci eth1

echo "DPDK setup is complete."
