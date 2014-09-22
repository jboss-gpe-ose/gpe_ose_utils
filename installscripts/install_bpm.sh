# as per:  https://access.redhat.com/solutions/666053
#
# NOTE:  ensure admin.opentlc.com is running !
#
#while read host; do
#  echo $host
#  scp install_bpm.sh root@fuse0.ose.opentlc.com:/tmp
#  ssh root@fuse0.ose.opentlc.com 'chmod 755 /tmp/install_bpm.sh; /tmp/install_bpm.sh'
#done <hosts.txt


oo-admin-cartridge --action erase -n bpms --version 6.0 --cartridge_version 0.0.2

cd /var/tmp/; git clone https://github.com/jboss-gpe-ose/openshift-origin-cartridge-bpms-full.git
chmod 755 /var/tmp/openshift-origin-cartridge-bpms-full/bin/*
oo-admin-cartridge --action install --source /var/tmp/openshift-origin-cartridge-bpms-full
restorecon -R /var/lib/openshift/.cartridge_repository
/etc/init.d/ruby193-mcollective restart
oo-admin-cartridge --action list
