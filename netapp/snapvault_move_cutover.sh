#!/bin/bash

# SnapVault destination volume cutover v1.01
# by Frank Felhoffer <frank@esxi.ca>

# Host name of the filer
filer=


#####################################################################
#####################################################################

if [ -z $filer]; then

	echo "Please setup the filer parameter inside the script!";
	exit 1;
fi

if [ -z $1 ]; then

        echo "Usage: $0 original_volume_name";
        exit 1;
fi


original_vol=$1
target_vol=$original_vol"_SM"


#
#  1. Final sync of the volume
#

echo -n "1. Starting final sync ... ";

cmd_status=`rsh $filer snapmirror update -S $original_vol $target_vol | head -n 1`;

if [ "$cmd_status" == "Transfer started." ]; then

        echo "OK!"
else

        echo "$cmd_status"
        exit 1;
fi

sleep 5
status=`rsh $filer snapmirror status $target_vol | awk '{print $5}' | tail -n 1`;

while [ "$status" != "Idle" ]; do

        echo "$status"

        sleep 5
        status=`rsh $filer snapmirror status $target_vol | awk '{print $5}' | tail -n 1`;
done

echo "$status"
echo "==="

#echo "Hit ENTER to continue ..."
#read


#
#  2. Breaking the SnapMirror relationship
#

echo "2. Breaking the SnapMirror ...";

rsh $filer snapmirror break $target_vol

destination=`rsh $filer snapmirror destinations | grep $target_vol`;
rsh $filer snapmirror release $destination


#
#  3. Rename and offline the old volume
#

echo "3. Removing the old volume";

rsh $filer vol rename $original_vol $original_vol"_old"
rsh $filer vol offline $original_vol"_old"


#
#  4. Set the final name of the volume
#

echo "4. Renaming the new volume ...";

rsh $filer vol rename $target_vol $original_vol


#
#  5. Start a SnapVault resync
#

echo -n "5. Starting a SnapVault resync ... ";

sv_params=`rsh $filer snapvault status | grep $original_vol | awk '{print $1" "$2}'`;
cmd_status=`rsh $filer snapvault start -r -S $sv_params | head -n 1`;

if [ "$cmd_status" == "Transfer started." ]; then

        echo "OK!";
else

        echo "$cmd_status";
        exit 1
fi


echo "Done!"

