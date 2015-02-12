#!/bin/bash

for i in {1..50}
do
uuids="$(./gpe_mongo_utils.sh -command=findGearByAccountName -ssoId=gpsetraining$i | grep -Po '"uuid" : .*?[^\\]"'|awk '{print $3;}'|sed 's/\"//g' |tr '\n' '#')"
names="$(./gpe_mongo_utils.sh -command=findGearByAccountName -ssoId=gpsetraining$i | grep -Po '"name" : .*?[^\\]"'|awk '{print $3;}'|sed 's/\"//g' |tr '\n' '#')"

IFS='#' read -a luuid <<< "$uuids"
IFS='#' read -a lnames <<< "$names"

for((a = 0 ; a <= ${#luuid[@]} ; a++)) do 
if [[ -n ${luuid[$a]} ]]; then
    for ((b = $a ; b <= ${#lnames[@]} ; b++)) do
        if [[ -n ${lnames[$b]} ]]; then

        echo "Bouncing gpsetraining$i with UUID: ${luuid[$a]} and Name: ${lnames[$b]}"
        oo-admin-ctl-app --command destroy -b -l gpsetraining$i -a ${lnames[$b]} --gear_uuid ${luuid[$a]}
        break 
        fi
    done
fi
done
done
