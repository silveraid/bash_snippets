#!/bin/bash

# SnapVault destination volume mover
# by Frank Felhoffer <frank@esxi.ca>


# Host name of the filer
filer=

# Target aggregate
target_aggr=


#####################################################################
#####################################################################

if [ -z $filer ] || [ -z $target_aggr ]; then

	echo "Please setup the filer and the target_aggr parameters";
	echo "inside the script!";
	exit 1;
fi

if [ -z $1 ]; then

        echo "Usage: $0 volume_name";
        exit 1;
fi


source_vol=$1
target_vol=$source_vol"_SM"


#
#  1. Get the geometry of the source volume
#

vol_size=`rsh $filer df -x $source_vol | awk '{print $2}' | tail -n 1`;
inode_count=`rsh $filer maxfiles $source_vol | cut -d" " -f9`;

echo "SOURCE: $source_vol   TARGET: $target_vol
echo "SIZE: $vol_size    INODES: $inode_count

echo "Hit ENTER if OK ...";
read


#
#  2. Create the new destination volume
#

rsh $filer vol create $target_vol $target_aggr $vol_size"k"
rsh $filer maxfiles -f $target_vol $inode_count
rsh $filer vol options $target_vol nosnap on
rsh $filer vol options $target_vol guarantee none
rsh $filer vol options $target_vol fractional_reserve 0
rsh $filer snap sched -V $target_vol 0 0 0
rsh $filer snap reserve -V $target_vol 0
rsh $filer vol restrict $target_vol


#
#  3. Start intial transfer
#

rsh $filer snapmirror initialize -S $source_vol $target_vol

