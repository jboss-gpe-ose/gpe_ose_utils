# as per:  https://access.redhat.com/solutions/666053
#
# NOTE:  ensure admin.opentlc.com is running !
#
# scp install_fuse.sh root@fuse0.ose.opentlc.com:/tmp
# ssh root@fuse0.ose.opentlc.com 'chmod 755 /tmp/install_fuse.sh; /tmp/install_fuse.sh'

oo-admin-cartridge --action erase -o fusesource -n fuse --version 1.0.0 --cartridge_version 0.0.1

yum install -y rubygem-openshift-origin-frontend-haproxy-sni-proxy.noarch

rpm -ivh /opt/downloads/openshift-origin-cartridge-fuse-6.1.0.redhat.396-1.el6op.noarch.rpm

restorecon -R /var/lib/openshift/.cartridge_repository
/etc/init.d/ruby193-mcollective restart
oo-admin-cartridge --action list
