#!/bin/bash

# JA Bride
# Purpose of this script is manage student accounts in GPE's Ravello lab environment

# NOTE:  this utility must reside on an OSE 2.1 broker

bold="\033[1m"
normal="\033[0m"

main() {
    if [ "$op" = "disenroll" ]; then
        checkparams
        checkUserExists
        disenroll
    elif [ "$op" = "batchDisenrollFromAllByGears" ]; then
        batchdisenrollbygears
    elif [ "$op" = "batchDisenrollFromAllByAccounts" ]; then
        batchDisenrollFromAllByAccounts
    elif [ "$op" = "enroll" ]; then
        checkparams
        if [ ! -f /etc/openshift/broker.conf ]; then
            echo -en "\n/etc/openshift/broker.conf does not exist.  Please ensure this utility resides on a OSE 2.1 broker\n"
            exit 1
        fi
        enroll
    fi
}

check() {
    echo -en "\ncheck(): checking for $userId in $gearSize\n"
    arr=`/usr/sbin/oo-admin-ctl-user -l $userId | egrep -i '  gear sizes:'|sed -e "s/.*:\s//"|sed -e "s/,//g"`
    if [ -n "$arr" ]; then
        for gs in $arr;
        do
           if [ "$gs" == "$gearSize" ]; then
            echo "ERROR: User $userId is already a member of $gearSize"
            exit 111
           fi
        done
    fi
}

destroyApp() {
    echo -en "\ndestroyApp() userId = $1 appId = $2 \n"
    /usr/sbin/oo-admin-ctl-app -l $userId -a $app -c stop
    /usr/sbin/oo-admin-ctl-app -l $userId -a $app -c destroy -b
}


checkUserExists() {
    /usr/sbin/oo-admin-ctl-user -l $userId >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error, user $userId does not exist.  Exiting."
        exit 1
    fi
}

checkparams() {
    if [ -n "$op" ]; then
        if [ -z "$userId" ]; then
          echo -en "\n** need to specify a value for: userId\n"
          help
          exit 1
        fi
    fi
    if [ "$op" = "disenroll" ]; then
        return 0
    fi
    if [ "$op" = "enroll" ]; then
      if [ -n "$gearSize" ]; then
         checkgearSizes
      else
        echo -e "\n** need to specify -enroll=<gearSize>"
        help
        exit 1
      fi
    fi
}

getgearSizes() {
    validGearSizes=`/bin/cat /etc/openshift/broker.conf | egrep -i 'VALID_GEAR_SIZES='`
    validGearSizes=${validGearSizes#*=}
    validGearSizes=${validGearSizes//\"}
}

checkgearSizes() {
    getgearSizes
    arr=$(echo $validGearSizes | tr "," "\n")
    for validGearSize in $arr; do
        # echo -en "\n$validGearSize"
        if [ "$validGearSize" = "$gearSize" ]; then
            #echo -e "\ncheckgearSize(): $userId cleared hot to enroll in course with gearSize = $gearSize" 
            return 0
        fi
    done

    echo -en "\ncheckgearSizes(): $gearSize is not in the list of validGearSizes: $validGearSizes\n\n" 
    exit 1
}

help() {
    echo -e "Usage: $0 -userId=[userId] [OPTIONS]"
    echo -e "\nOPTIONS:"
    echo -e "\t-enroll=<gearSize> - enroll student in one of the following courses: "
    getgearSizes
    echo -e " $bold$validGearSizes$normal"
    echo -e "\t-disenrollFromAll         - destroys all OSE apps and removes all gear sizes associated to that account(with the exception of pds_medium"
    echo -e "\t-batch_disenroll_all_by_gears   - disenroll students corresponding to a list of gear UUIDs found in a file called:  gears.txt"
    echo -e "\t-batch_disenroll_all_by_accounts   - disenroll students found in a file called:  accounts.txt"
    echo -e "\nEXAMPLES:"
    echo -e " Disenroll user$bold jbride-redhat.com$normal by destroying all apps and stripping all gear"
    echo -e "  sizes:"
    echo -e "  $0 -userId=jbride-redhat.com -disenroll"
    echo -e " Enroll user$bold jbride-redhat.com$normal by registering$bold fsw_medium$normal gear size with that"
    echo -e "  userId:"
    echo -e "  $0 -userId=jbride-redhat.com -enroll=fsw_medium"

    echo -e
}

determineMongoInfo() {

    mongoUser=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_USER='`
    mongoUser=${mongoUser#*=}
    mongoUser=${mongoUser//\"}

    mongoPasswd=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_PASSWORD='`
    mongoPasswd=${mongoPasswd#*=}
    mongoPasswd=${mongoPasswd//\"}

    mongoDb=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_DB='`
    mongoDb=${mongoDb#*=}
    mongoDb=${mongoDb//\"}
    echo -en "\ndetermineMongoInfo() mongoUser=$mongoUser mongoPasswd=$mongoPasswd mongoDb=$mongoDb \n "
}


enroll() {
    id $userId > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error, user $userId does not exist in SSO.  Exiting."
        exit 1
    fi
    check
    echo -en "\nenroll():  enrolling $userId to course with gearSize = $gearSize\n"
    /usr/sbin/oo-admin-ctl-user -c -l $userId --addgearsize $gearSize > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo "Adding user failed!"
        exit 1
    fi
}

# Given a userId, destroys all OSE apps and removes all gear sizes (with the exception of pds_medium)
disenrollFromAll() {
    echo -en "\ndisenroll(): disenrolling $userId from all courses\n"
    arr=`/usr/sbin/oo-admin-ctl-domain -l $userId | egrep -i '^name:'`
    if [ -n "$arr" ]; then
        for app in $arr;
        do
         if [ "$app" != "name:" ]; then
            destroyApp $userId $app
         fi
       done
    fi
    arr=`/usr/sbin/oo-admin-ctl-user -l $userId | egrep -i '  gear sizes:'|sed -e "s/.*:\s//"|sed -e "s/,//g"`
    if [ -n "$arr" ]; then
        for gearSize in $arr;
        do
           gearSize=${gearSize//,} 
           gearSize=${gearSize//\ } 
           if [ "$gearSize" != "pds_medium" ]; then
            echo "Removing gear size $gearSize for user $userId"
            /usr/sbin/oo-admin-ctl-user -l $userId --removegearsize $gearSize >/dev/null 2>&1
           fi
        done
    fi
}

batchDisenrollFromAllByAccounts() {
    for userId in $(cat accounts.txt)
    do
        if [[ $userId != \#* ]] ; then
            disenroll
        fi
    done
}

destroyAppGivenGearUUID() {

    determineMongoInfo

    eval appString=\" `mongo --username $mongoUser --password $mongoPasswd $mongoDb --eval "printjson(db.applications.find( { _id: ObjectId(\"$gearId\") }, { canonical_name: 1 } ).shellPrint() )"` \"
    appId=`echo $appString | cut -d':' -f 5 | cut -d' ' -f 2 | cut -d',' -f 1`
    echo $appId

}

batchdisenrollbygears() {

    determineMongoInfo

    for gearId in $(cat gears.txt)
    do
        if [[ $gearId != \#* ]] ; then
            eval userString=\" `mongo --username $mongoUser --password $mongoPasswd $mongoDb --eval "printjson(db.applications.find( { _id: ObjectId(\"$gearId\") }, { members: 1 } ).shellPrint() )"` \"
            userId=`echo $userString | cut -d':' -f 8 | cut -d' ' -f 2 | cut -d',' -f 1`
            echo -en "\n\n*********     $gearId userId=$userId\n"
            disenroll
        fi
    done
}



if [ -z "$1" ]
then
    help
    exit 1
fi

for var in $@
do
    case $var in
        *help*)
            help
            exit 0
            ;;
        -userid=*|-userId=*)
            userId=`/bin/echo $var | cut -f2 -d\=`
            ;;
        -enroll=*)
            gearSize=`/bin/echo $var | cut -f2 -d\=`
            op=enroll
            ;;
        -disenroll*)
            op=disenrollFromAll
            ;;
        -disenrollFromAll*)
            op=disenrollFromAll
            ;;
        -batch_disenroll_all_by_gears*)
            op=batchDisenrollFromAllByGears
            ;;
        -batch_disenroll_all_by_accounts*)
            op=batchDisenrollFromAllByAccounts
            ;;
        *)  echo "unknown command line parameter: $var .  Execute -help for details of valid parameters. "; exit 1;
    esac
done
main

