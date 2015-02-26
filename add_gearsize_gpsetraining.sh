#!/bin/bash

for i in {1..52}
do
oo-admin-ctl-user -l gpsetraining$i --addgearsize pds_medium
done
