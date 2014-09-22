#!/bin/bash

# JA Bride

# NOTE:  this utility must reside on an OSE 2.1 broker


main() {
    if [ ! -f /etc/openshift/broker.conf ]; then
        echo -en "\n/etc/openshift/broker.conf does not exist.  Please ensure this utility resides on a OSE 2.1 broker\n"
        exit 1;
    fi

    mongoUser=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_USER='`
    mongoUser=${mongoUser#*=}
    mongoUser=${mongoUser//\"}

    mongoPasswd=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_PASSWORD='`
    mongoPasswd=${mongoPasswd#*=}
    mongoPasswd=${mongoPasswd//\"}

    mongoDb=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_DB='`
    mongoDb=${mongoDb#*=}
    mongoDb=${mongoDb//\"}

    echo -en "\n mongoUser = $mongoUser : mongoPasswd = $mongoPasswd : mongoDb = $mongoDb\n"

    
    # findGearByAccountName
    countApps
}

findGearByAccountName() {
    #mongo --quiet --username $mongoUser --password $mongoPasswd $mongoDb --eval 'printjson(db.applications.find( { members: { $elemMatch: { n: "althomas-redhat.com" } } }, { gears: 1 } ) )'
    mongo --username $mongoUser --password $mongoPasswd $mongoDb findGearsByAccountName.js
}

countApps() {
    mongo --username $mongoUser --password $mongoPasswd $mongoDb --eval "db.applications.count()"
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
    if [ "x$command" = "x" ]; then
        echo -en "\n** need to specify a value for: command\n"
        help
        exit 1
    fi
}

help() {
    echo -en "\n\ngpe_student_mgmt\n"
    echo -en "\nSYNOPSIS\n\texecute:  gpe_student_mgmt -userId=[userId] -command=[command]\n"
    echo -en "\n\t Commands:"
    echo -en "\n\t\t countApps                  :   returns # of total apps managed by this OSE environment"
    echo -en "\n\t\t findGearByAccountName      :   returns gear details given an OPENTLC-SSO id"
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
        -command=*)
            command=`echo $var | cut -f2 -d\=`
            ;;
*)  echo "unknown command line parameter: $var .  Execute --help for details of valid parameters. "; exit 1;
    esac
done
main

