#!/bin/bash

# JA Bride
# Purpose of this script is manage student accounts in GPE's Ravello lab environment

# NOTE:  this utility must reside on an OSE 2.1 broker

# TO-DO:  investigate:  http://software.frodo.looijaard.name/getopt/docs/getopt-parse.bash

bold="\033[1m"
normal="\033[0m"

main() {
    checkparams
    if [ "$op" = "disenroll" ]; then
        checkUserExists
        disenroll
    elif [ "$op" = "enroll" ]; then
        if [ ! -f /etc/openshift/broker.conf ]; then
            echo -en "\n/etc/openshift/broker.conf does not exist.  Please ensure this utility resides on a OSE 2.1 broker\n"
         exit 1;
        fi

        enroll
    fi
}

disenroll() {
    echo -en "\ndisenroll(): disenrolling $userId from all courses\n"

    arr=`/usr/sbin/oo-admin-ctl-domain -l $userId | egrep -i '^name:'`
    if [ -n "$arr" ]; then
        for app in $arr;
        do
         if [ "$app" != "name:" ]; then
             /usr/sbin/oo-admin-ctl-app -l $userId -a $app -c stop
             /usr/sbin/oo-admin-ctl-app -l $userId -a $app -c destroy -b
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

enroll() {
    id $userId > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error, user $userId does not exist in SSO.  Exiting."
        exit 1
    fi
    echo -en "\nenroll():  enrolling the $userId to course with gearSize = $gearSize\n"
    /usr/sbin/oo-admin-ctl-user -c -l $userId --addgearsize $gearSize > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo "Adding user failed!"
        exit 1
    fi
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
    echo -e "\t-disenroll         - disenroll a student from all courses"
    echo -e "\nEXAMPLES:"
    echo -e " Disenroll user$bold jbride-redhat.com$normal by destroying all apps and stripping all gear"
    echo -e "  sizes:"
    echo -e "  $0 -userId=jbride-redhat.com -disenroll"
    echo -e " Enroll user$bold jbride-redhat.com$normal by registering$bold fsw_medium$normal gear size with that"
    echo -e "  userId:"
    echo -e "  $0 -userId=jbride-redhat.com -enroll=fsw_medium"

    echo -e
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
            op=disenroll
            ;;
        *)  echo "unknown command line parameter: $var .  Execute -help for details of valid parameters. "; exit 1;
    esac
done
main

