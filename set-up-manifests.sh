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

# Prepare openshift manifests
if [[ ! -d $OPENSHIFT_REPO ]]; then
    git clone https://github.com/tungstenfabric/tf-openshift.git $OPENSHIFT_REPO
fi

# Upload manifests
access_token=$(get_access_token)
clusters=$(get_clusters "${access_token}")

clusters_len=$(echo "${clusters}" | jq length)
for i in  $(seq 1 $clusters_len); do
    echo No $i
    cn=$(echo "${clusters}" | jq -r ".[$((i-1))].name")
    if [[ "$cn" == "$cluster_name" ]]; then
        echo "INFO: We have found cluster $cn"
        cluster_id=$(echo "${clusters}" | jq -r ".[$((i-1))].id")
        post_manifests_to_ai $cluster_id $access_token
    fi
done



# Push manifest example:
# curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICItNGVsY19WZE5fV3NPVVlmMkc0UXhyOEdjd0l4X0t0WFVDaXRhdExLbEx3In0.eyJleHAiOjE2MjYyNjkzNDYsImlhdCI6MTYyNjI2ODQ0NiwiYXV0aF90aW1lIjoxNjI2MDc2MTczLCJqdGkiOiI1ZjNlMmJjNS0xZmEyLTQzZWMtOTZjYS1jZGFhNThmZGZhODMiLCJpc3MiOiJodHRwczovL3Nzby5yZWRoYXQuY29tL2F1dGgvcmVhbG1zL3JlZGhhdC1leHRlcm5hbCIsImF1ZCI6ImNsb3VkLXNlcnZpY2VzIiwic3ViIjoiZjo1MjhkNzZmZi1mNzA4LTQzZWQtOGNkNS1mZTE2ZjRmZTBjZTY6YW1vcmxhbmcucmVkaGF0IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiY2xvdWQtc2VydmljZXMiLCJub25jZSI6IjQ1OGMyMzM0LWZiYzItNGQ0Ni04ZmJmLWQzMDBlMjg1M2NkMSIsInNlc3Npb25fc3RhdGUiOiJmNDBkNzFhMi1iY2YwLTQ5MjEtYjM2OC1kYzhiODk3ZjAzZDkiLCJhY3IiOiIwIiwiYWxsb3dlZC1vcmlnaW5zIjpbImh0dHBzOi8vcHJvZC5mb28ucmVkaGF0LmNvbToxMzM3IiwiaHR0cHM6Ly9xYXByb2RhdXRoLmNvbnNvbGUucmVkaGF0LmNvbSIsImh0dHBzOi8vcWFwcm9kYXV0aC5mb28ucmVkaGF0LmNvbSIsImh0dHBzOi8vYXBpLmNsb3VkLnJlZGhhdC5jb20iLCJodHRwczovL3FhcHJvZGF1dGguY2xvdWQucmVkaGF0LmNvbSIsImh0dHBzOi8vY2xvdWQub3BlbnNoaWZ0LmNvbSIsImh0dHBzOi8vcHJvZC5mb28ucmVkaGF0LmNvbSIsImh0dHBzOi8vY2xvdWQucmVkaGF0LmNvbSIsImh0dHBzOi8vY29uc29sZS5yZWRoYXQuY29tIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJhdXRoZW50aWNhdGVkIiwiY2FuZGxlcGluX3N5c3RlbV9hY2Nlc3Nfdmlld19lZGl0X3BlcnNvbmFsIiwib2ZmbGluZV9hY2Nlc3MiLCJwb3J0YWxfbWFuYWdlX2Nhc2VzIiwicG9ydGFsX3N5c3RlbV9tYW5hZ2VtZW50IiwicG9ydGFsX2Rvd25sb2FkIl19LCJzY29wZSI6Im9wZW5pZCBvZmZsaW5lX2FjY2VzcyIsImFjY291bnRfbnVtYmVyIjoiNTMwMTA0MCIsImlzX2ludGVybmFsIjpmYWxzZSwiaXNfYWN0aXZlIjp0cnVlLCJsYXN0X25hbWUiOiJNb3JsYW5nIiwicHJlZmVycmVkX3VzZXJuYW1lIjoiYW1vcmxhbmcucmVkaGF0IiwidHlwZSI6IlVzZXIiLCJsb2NhbGUiOiJlbl9VUyIsImlzX29yZ19hZG1pbiI6ZmFsc2UsImFjY291bnRfaWQiOiI1MTI2MDkzNiIsIm9yZ19pZCI6IjY5NjMyMzgiLCJmaXJzdF9uYW1lIjoiQWxleGV5IiwiZW1haWwiOiJhbW9ybGFuZ0BqdW5pcGVyLm5ldCIsInVzZXJuYW1lIjoiYW1vcmxhbmcucmVkaGF0In0.IvFUlNeg1_0Cw55EQDxA-ofOkcOu9zwHIWfL7kZm00j1Visg13VZsN3uRjbYBBK2z3sjcaAs14VW4eIE08HtQK_e_Q_kQhe1BdQWXwAbHh-qwrmp_z4Py6ufFrDwdV_tGIS4HlYFpbNHWdcQzfwA9O30Bg7Vlg_eJ4rKqhoCXV0iMrUzJypcKqIJ0oabvJRM1dtZxP-KRWOIIGqXHqT_Y4RPmFEP3Yjz_zibWJber1hVB-tiNng3uhheFqJ3iI1how9fBn1OU7UNpYuHkJ2LWmfi_03kY_b28zus9SIm2RhaX4uFPZToW9HZPhf8EMDaCgChqsjFPFq08Vg9IZYQHqH3OQDo8w6iMeNjHDGp0eBh2qtFW-_1E1CW27Wjx5bQJOihcuV8EH0rADOP3_A9A-8riR7_eI0ZRU2AauhGG7SrAwAsxiG1CcpcBTpBiaYn2L3fuGBha71aNrZgKIyDKmUoO6_4OQrGMA41m91nYIdqq9Lkq6nSltvR8A5xld_mscgNYWZvrN3hua6ev5uyHqq00spApgaoKECI06ejBJIVvoslrQnXsPwe4BLGMNp5RzESNt_63YdcQ7syz8cbMa1kE1NMmUeYJCDE9iSbiuK-_t3DEzfTlPFPBvJWTUb8EjohQrdyePgMoihGT2kxooFSP_JSbBwIEuUI_TWiuxU" -d '{"folder":"openshift","file_name":"99_master-kernel-modules-overlay.yaml","content":"YXBpVmVyc2lvbjogbWFjaGluZWNvbmZpZ3VyYXRpb24ub3BlbnNoaWZ0LmlvL3YxCmtpbmQ6IE1hY2hpbmVDb25maWcKbWV0YWRhdGE6CiAgbGFiZWxzOgogICAgbWFjaGluZWNvbmZpZ3VyYXRpb24ub3BlbnNoaWZ0LmlvL3JvbGU6IG1hc3RlcgogIG5hbWU6IDAyLW1hc3Rlci1tb2R1bGVzCnNwZWM6CiAgY29uZmlnOgogICAgaWduaXRpb246CiAgICAgIHZlcnNpb246IDIuMi4wCiAgICBzdG9yYWdlOgogICAgICBkaXJlY3RvcmllczoKICAgICAgICAtIGZpbGVzeXN0ZW06ICJyb290IgogICAgICAgICAgcGF0aDogIi9vcHQvbW9kdWxlcyIKICAgICAgICAgIG1vZGU6IDA3NTUKICAgICAgICAtIGZpbGVzeXN0ZW06ICJyb290IgogICAgICAgICAgcGF0aDogIi9vcHQvbW9kdWxlcy53ZCIKICAgICAgICAgIG1vZGU6IDA3NTUKICAgICAgICAtIGZpbGVzeXN0ZW06ICJyb290IgogICAgICAgICAgcGF0aDogIi9vcHQvdXNyYmluIgogICAgICAgICAgbW9kZTogMDc1NQogICAgICAgIC0gZmlsZXN5c3RlbTogInJvb3QiCiAgICAgICAgICBwYXRoOiAiL29wdC91c3JiaW4ud2QiCiAgICAgICAgICBtb2RlOiAwNzU1CiAgICBzeXN0ZW1kOgogICAgICB1bml0czoKICAgICAgICAtIG5hbWU6IHVzci1saWItbW9kdWxlcy5tb3VudAogICAgICAgICAgZW5hYmxlZDogdHJ1ZQogICAgICAgICAgY29udGVudHM6IHwKICAgICAgICAgICAgW1VuaXRdCiAgICAgICAgICAgIERlc2NyaXB0aW9uPWNvbnRyYWlsIG1vdW50IGZvciBrZXJuZWwgbW9kdWxlCiAgICAgICAgICAgIFdhbnRzPW5ldHdvcmstb25saW5lLnRhcmdldAogICAgICAgICAgICBBZnRlcj1uZXR3b3JrLW9ubGluZS50YXJnZXQgbWFjaGluZS1jb25maWctZGFlbW9uLXB1bGwuc2VydmljZQogICAgICAgICAgICBbTW91bnRdCiAgICAgICAgICAgIFdoZXJlPS91c3IvbGliL21vZHVsZXMKICAgICAgICAgICAgV2hhdD1vdmVybGF5CiAgICAgICAgICAgIFR5cGU9b3ZlcmxheQogICAgICAgICAgICBPcHRpb25zPWxvd2VyZGlyPS91c3IvbGliL21vZHVsZXMsdXBwZXJkaXI9L29wdC9tb2R1bGVzLHdvcmtkaXI9L29wdC9tb2R1bGVzLndkCiAgICAgICAgICAgIFtJbnN0YWxsXQogICAgICAgICAgICBXYW50ZWRCeT1tdWx0aS11c2VyLnRhcmdldAogICAgICAgIC0gbmFtZTogdXNyLWJpbi5tb3VudAogICAgICAgICAgZW5hYmxlZDogdHJ1ZQogICAgICAgICAgY29udGVudHM6IHwKICAgICAgICAgICAgW1VuaXRdCiAgICAgICAgICAgIERlc2NyaXB0aW9uPWNvbnRyYWlsIG1vdW50IGZvciBzY3JpcHRzCiAgICAgICAgICAgIFdhbnRzPW5ldHdvcmstb25saW5lLnRhcmdldAogICAgICAgICAgICBBZnRlcj1uZXR3b3JrLW9ubGluZS50YXJnZXQgbWFjaGluZS1jb25maWctZGFlbW9uLXB1bGwuc2VydmljZQogICAgICAgICAgICBbTW91bnRdCiAgICAgICAgICAgIFdoZXJlPS91c3IvYmluCiAgICAgICAgICAgIFdoYXQ9b3ZlcmxheQogICAgICAgICAgICBUeXBlPW92ZXJsYXkKICAgICAgICAgICAgT3B0aW9ucz1sb3dlcmRpcj0vdXNyL2Jpbix1cHBlcmRpcj0vb3B0L3VzcmJpbix3b3JrZGlyPS9vcHQvdXNyYmluLndkCiAgICAgICAgICAgIFtJbnN0YWxsXQogICAgICAgICAgICBXYW50ZWRCeT1tdWx0aS11c2VyLnRhcmdldAoK"}' https://api.openshift.com/api/assisted-install/v1/clusters/b8064a19-07fa-432f-954c-c1e4c70b8f5d/manifests