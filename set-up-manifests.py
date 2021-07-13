import json
import requests
import sys
from urllib.request import urlopen
from urllib.parse import urlencode

OFFLINE_TOKEN=sys.environ['OFFLINE_TOKEN']
BASE_URL = "https://api.openshift.com/api/assisted-install/v1/"
CLUSTER_NAME = "test9"
# Get access token
def get_access_token(offlinetoken):
    url = 'https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token'
    data = {"client_id": "cloud-services", "grant_type": "refresh_token", "refresh_token": offlinetoken}
    data = urlencode(data).encode("ascii")
    result = urlopen(url, data=data).read()
    page = result.decode("utf8")
    token = json.loads(page)['access_token']
    return token

access_token = get_access_token(OFFLINE_TOKEN)
headers = {"Authorization": "Bearer "+access_token}

# Get clusters list
cluster_id = ""
response = requests.get(BASE_URL+"/clusters", headers=headers)
resp_data = json.loads(response.text)
for cluster in resp_data:
    if (cluster["name"] == CLUSTER_NAME):
        cluster_id = cluster['id']

if(not cluster_id):
    print("We can't find cluster")
    exit(1)


# print(resp_data)


