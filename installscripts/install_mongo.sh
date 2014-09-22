# as per:  https://access.redhat.com/solutions/666053
#
# NOTE:  ensure admin.opentlc.com is running !
#
# scp install_mongo.sh root@fuse0.ose.opentlc.com:/tmp
# ssh root@fuse0.ose.opentlc.com 'chmod 755 /tmp/install_mongo.sh; /tmp/install_mongo.sh'

yum install mongodb-server mongodb -y

cd /var/tmp/; git clone https://github.com/openshift/origin-server.git
chmod 755 /var/tmp/origin-server/cartridges/openshift-origin-cartridge-mongodb/bin/*
oo-admin-cartridge --action install --source /var/tmp/origin-server/cartridges/openshift-origin-cartridge-mongodb
restorecon -R /var/lib/openshift/.cartridge_repository
/etc/init.d/ruby193-mcollective restart
oo-admin-cartridge --action list
