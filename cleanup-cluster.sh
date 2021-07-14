#!/bin/bash

for i in $(seq 0 2); do 
    sudo virsh destroy oc-master${i}
    sudo virsh undefine oc-master${i}
done
