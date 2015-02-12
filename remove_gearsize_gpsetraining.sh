#!/bin/bash

for i in {1..50}
do
oo-admin-ctl-user -l gpsetraining$i --removegearsize pds_medium
done
