import json
import requests
import os
from urllib.request import urlopen
from urllib.parse import urlencode

class AssistedInstaller:
    def __init__(self):
        self.offline_token=os.environ['OFFLINE_TOKEN']
        self.base_url = "https://api.openshift.com/api/assisted-install/v1/"
        self.cluster_name = "test9"

    # Get access token
    def get_access_token(self):
        url = 'https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token'
        data = {"client_id": "cloud-services", "grant_type": "refresh_token", "refresh_token": self.offline_token}
        data = urlencode(data).encode("ascii")
        result = urlopen(url, data=data).read()
        page = result.decode("utf8")
        self.access_token = json.loads(page)['access_token']

    def get_cluster_id(self):
        # Get clusters list
        headers = {"Authorization": "Bearer " + self.access_token}
        cluster_id = ""
        response = requests.get(self.base_url+"/clusters", headers=headers)
        resp_data = json.loads(response.text)
        for cluster in resp_data:
            if (cluster["name"] == self.cluster_name):
                cluster_id = cluster['id']

        return cluster_id

ai = AssistedInstaller()
ai.get_access_token()
if(not ai.access_token):
    print("We can't find cluster {}".format(ai.cluster_name))
    exit(1)

cl_id = ai.get_cluster_id()
print("We found cluster " + cl_id)


