#!/bin/bash

# JA Bride

# NOTE:  this utility must reside on an OSE 2.1 broker


main() {
    if [ ! -f /etc/openshift/broker.conf ]; then
        echo -en "\n/etc/openshift/broker.conf does not exist.  Please ensure this utility resides on a OSE 2.1 broker\n"
        exit 1;
    fi

    checkparams

    mongoUser=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_USER='`
    mongoUser=${mongoUser#*=}
    mongoUser=${mongoUser//\"}

    mongoPasswd=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_PASSWORD='`
    mongoPasswd=${mongoPasswd#*=}
    mongoPasswd=${mongoPasswd//\"}

    mongoDb=`cat /etc/openshift/broker.conf | egrep -i 'MONGO_DB='`
    mongoDb=${mongoDb#*=}
    mongoDb=${mongoDb//\"}

    # echo -en "\n mongoUser = $mongoUser : mongoPasswd = $mongoPasswd : mongoDb = $mongoDb\n"

    if [ "$command" = "countApps" ]; then
        countApps
    elif [ "$command" = "findGearByAccountName" ]; then
        findGearByAccountName
    elif [ "$command" = "listAllAccountNames" ]; then
        listAllAccountNames
    elif [ "$command" = "findAccountByGearUUID" ]; then
        findAccountByGearUUID
    else
        echo -en "\n** The following is not a valid command:  $command"
        help
        exit 1
    fi
}

countApps() {
    mongo --username $mongoUser --password $mongoPasswd $mongoDb --eval "db.applications.count()"
}

findGearByAccountName() {
    checkssoId
    mongo --username $mongoUser --password $mongoPasswd $mongoDb --eval "printjson(db.applications.find( { members: { \$elemMatch: { n: \"$ssoId\" } } }, { gears: 1 } ).shellPrint() )"
}

findAccountByGearUUID() {
    mongo --username $mongoUser --password $mongoPasswd $mongoDb --eval "printjson(db.applications.find( { _id: ObjectId(\"$gearId\") }, { members: 1 } ).shellPrint() )"
}

listAllAccountNames(){
    mongo --username $mongoUser --password $mongoPasswd $mongoDb --eval 'printjson( db.cloud_users.find( { }, { login: 1 } ).shellPrint() )'
}


checkparams() {
    if [ "$help" = "help" ]; then
        help
        exit 0
    fi
    if [ "x$command" = "x" ]; then
        echo -en "\n** need to specify a value for: -command=\n"
        help
        exit 1
    fi

}
checkssoId() {
    if [ "x$ssoId" = "x" ]; then
        echo -en "\n** need to specify a value for: -ssoId=\n"
        help
        exit 1
    fi
}

help() {
    echo -en "\n\ngpe_student_mgmt\n"
    echo -en "\nSYNOPSIS\n\texecute:  gpe_student_mgmt -command=[command] \n"
    echo -en "\n\t Commands:"
    echo -en "\n\t\t countApps                  :   returns # of total apps managed by this OSE environment"
    echo -en "\n\t\t findGearByAccountName      :   returns gear details given an OPENTLC-SSO id"
    echo -en "\n\t\t                                - requires additional command line parameter of :  -ssoId=[opentlc-sso id]"
    echo -en "\n\t\t listAllAccountNames        :   returns list of OPENTLC-SSO account ids registered with the OSE broker"
    echo -en "\n\t\t                                - requires additional command line parameter of :  -ssoId=[opentlc-sso id]"
    echo -en "\n\t\t findAccountByGearUUID      :   returns OPENTLC-SSO account id of owner of a given gear"
    echo -en "\n\t\t                                - requires additional command line parameter of :  -gearId=[gear uuid]"
    echo -en "\n\n"
}

for var in $@
do
    case $var in
        *help*)
            help=help
            ;;
        -ssoId=*)
            ssoId=`echo $var | cut -f2 -d\=`
            ;;
        -command=*)
            command=`echo $var | cut -f2 -d\=`
            ;;
        -gearId=*)
            gearId=`echo $var | cut -f2 -d\=`
            ;;
*)  echo "unknown command line parameter: $var .  Execute --help for details of valid parameters. "; exit 1;
    esac
done
main
