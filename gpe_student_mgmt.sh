#!/bin/bash

# JA Bride
# Purpose of this script is manage student accounts in GPE's Ravello lab environment

# NOTE:  this utility must reside on an OSE 2.1 broker


main() {
    if [ ! -f /etc/openshift/broker.conf ]; then
        echo -en "\n/etc/openshift/broker.conf does not exist.  Please ensure this utility resides on a OSE 2.1 broker\n"
        exit 1;
    fi
    validGearSizes=`cat /etc/openshift/broker.conf | egrep -i 'VALID_GEAR_SIZES='`
    validGearSizes=${validGearSizes#*=}
    validGearSizes=${validGearSizes//\"}

    checkparams
    # checkUserExists
    if [ "$disenroll" = "disenroll" ]; then
        disenroll
    else
        enroll
    fi
}

disenroll() {
    echo -en "\ndisenroll(): disenrolling the following student from all courses: $userId\n"

    arr=`oo-admin-ctl-domain -l $userId | egrep -i '^name:'`
    for app in $arr;
    do
        if [ "$app" != "name:" ]; then
            oo-admin-ctl-app -l $userId -a $app -c stop
            oo-admin-ctl-app -l $userId -a $app -c destroy -b
        fi
    done

    arr=`oo-admin-ctl-user -l jbride-redhat.com | egrep -i '   gear sizes: '`
    for gearSize in $arr;
    do
        gearSize=${gearSize//,} 
        gearSize=${gearSize//\ } 
        if [ "$gearSize" != "nomansland" ] && [ "$gearSize" != "gear" ] && [ $gearSize != "sizes:"  ]; then
            oo-admin-ctl-user -l $userId --removegearsize $gearSize
        fi
    done
}

enroll() {
    echo -en "\nenroll():  enrolling the following student: $userId in course with gearSize = $gearSize\n"
    oo-admin-ctl-user -l $userId --addgearsize $gearSize
}

checkUserExists() {
    oo-admin-ctl-user -l $userId
    if [ $? -ne 0 ]; then
        exit 1
    else
        echo -ne "\ncheckUserExists() .... good to go\n"
    fi
}

checkparams() {
    if [ "$help" = "help" ]; then
        help
        exit 0
    fi
    if [ "x$userId" = "x" ]; then
        echo -en "\n** need to specify a value for: userId\n"
        help
        exit 1
    fi
    if [ "$disenroll" = "disenroll" ]; then
        return 0
    elif [ "x$gearSize" != "x" ]; then
        checkgearSizes
    else
        echo -en "\n** need to specify either:  -enroll=<gearSize>   or  -disenroll"
        help
        exit 1
    fi
}

checkgearSizes() {

    arr=$(echo $validGearSizes | tr "," "\n")
    for validGearSize in $arr; do
        # echo -en "\n$validGearSize"
        if [ "$validGearSize" = $gearSize ]; then
            echo -en "\ncheckgearSize(): $userId cleared hot to enroll in course with gearSize = $gearSize" 
            return 0
        fi
    done

    echo -en "\ncheckgearSizes(): $gearSize is not in the list of validGearSizes: $validGearSizes\n\n" 
    exit 1
}

help() {
    echo -en "\n\ngpe_student_mgmt\n"
    echo -en "\nSYNOPSIS\n\texecute:  gpe_student_mgmt -userId=[userId] [OPTIONS]\n"
    echo -en "\n\nOPTIONS:"
    echo -en "\n\t-enroll=<gearSize>    :   enroll student in one of the following courses: $validGearSizes"
    echo -en "\n\t-disenroll            :   disenroll a student from all courses"
    echo -en "\n\nEXAMPLES:"
    echo -en "\n\t/root/gpe_student_mgmt.sh -userId=jbride-redhat.com -disenroll             :   disenroll jbride-redhat.com by destroying all apps and stripping all gear sizes"
    echo -en "\n\t/root/gpe_student_mgmt.sh -userId=jbride-redhat.com -enroll=fsw_medium     :   enrolls jbride-redhat.com by registering fsw_medium gear size with that userId"

    echo -en "\n"
}

for var in $@
do
    case $var in
        *help*)
            help=help
            ;;
        -userId=*)
            userId=`echo $var | cut -f2 -d\=`
            ;;
        -enroll=*)
            gearSize=`echo $var | cut -f2 -d\=`
            ;;
        -disenroll*)
            disenroll=disenroll
            ;;
*)  echo "unknown command line parameter: $var .  Execute --help for details of valid parameters. "; exit 1;
    esac
done
main

