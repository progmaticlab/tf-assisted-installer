#!/bin/bash -e

set -x

export WORKSPACE=$(pwd)
export OPENSHIFT_REPO=${OPENSHIFT_REPO:-"${WORKSPACE}/tf-openshift"}
AI_CLUSTER_NAME=${AI_CLUSTER_NAME:-"test9"}

sso_url="https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token"
api_base="https://api.openshift.com/api/assisted-install/v1/"
cluster_name="test9"

if [[ -z "${OFFLINE_TOKEN}" ]]; then
    echo "ERROR: Set offline token before call openshift API"
    exit 1
fi

function get_access_token(){
    local res=$(curl -s -X POST -d "client_id=cloud-services&grant_type=refresh_token&refresh_token=${OFFLINE_TOKEN}" $sso_url | jq -r '.access_token')
    echo "$res"
}

function get_clusters(){
    local token=$1
    local res=$(curl -s -H 'Accept: application/json' -H "Authorization: Bearer ${token}" ${api_base}/clusters)
    echo $res
}

function post_manifests_folder_to_ai(){
    local clister_id=$1
    local token=$2
    local folder=$3

    # Itarate over all manifests
    for file in $(ls $OPENSHIFT_REPO/deploy/${folder}); do
        local content=$(cat $OPENSHIFT_REPO/deploy/${folder}/${file} | base64)
        local url="${api_base}clusters/${cluster_id}/manifests"
        curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -H "Authorization: Bearer ${token}" -d "{\"folder\":\"${folder}\",\"file_name\":\"${file}\",\"content\":\"${content}\"}" ${url}
    done
}

function post_manifests_to_ai(){
    local clister_id=$1
    local token=$2
    post_manifests_folder_to_ai ${cluster_id} ${token} "openshift"
    post_manifests_folder_to_ai ${cluster_id} ${token} "manifests"
}

function post_generate_iso(){
    local cluster_id=$1
    local token=$2

    ​POST /clusters​/${cluster_id}​/downloads​/image

    Params:
    {
    "ssh_public_key": "$(cat ~/.ssh/id_rsa.pub)",
    "image_type": "full-iso"
    }
}

function get_cluster_iso(){
    local cluster_id=$1
    local token=$2

    GET /clusters/${cluster_id}/downloads/image
}

# Prepare openshift manifests
if [[ ! -d $OPENSHIFT_REPO ]]; then
    git clone https://github.com/tungstenfabric/tf-openshift.git $OPENSHIFT_REPO
fi

# Get auth token
access_token=$(get_access_token)
clusters=$(get_clusters "${access_token}")

# Find cluster
clusters_len=$(echo "${clusters}" | jq length)
for i in  $(seq 1 $clusters_len); do
    echo No $i
    cn=$(echo "${clusters}" | jq -r ".[$((i-1))].name")
    if [[ "$cn" == "$cluster_name" ]]; then
        echo "INFO: We have found cluster $cn"
        cluster_id=$(echo "${clusters}" | jq -r ".[$((i-1))].id")
    fi
done

if [[ -z ${cluster_id} ]]; then
    echo "ERROR: unable to find cluster"
    exit 1
fi

# Upload tf-openshift manifests to assisted installer
post_manifests_to_ai $cluster_id $access_token

# Generate and download ISO from assisted installer
post_generate_iso $cluster_id $access_token
get_cluster_iso $cluster_id $access_token > ${WORKSPACE}/cluster.iso

# Run machines
#for i in $(seq 0 2); do
#  sudo virt-install --name oc-master${i} --network network=default,model=virtio  --memory 16384 --vcpus 4 --disk size=120 --cdrom /home/ubuntu/assisted_installer/discovery_image_test9.iso --os-variant rhel7 &
#done
