import json
import requests
from urllib.request import urlopen
from urllib.parse import urlencode

OFFLINE_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJhZDUyMjdhMy1iY2ZkLTRjZjAtYTdiNi0zOTk4MzVhMDg1NjYifQ.eyJpYXQiOjE2MjYwNzg5MzcsImp0aSI6IjdiN2ZiODdkLTNmZGMtNGFmYS1iMjYyLWU3OTk0NWVkMzhlZiIsImlzcyI6Imh0dHBzOi8vc3NvLnJlZGhhdC5jb20vYXV0aC9yZWFsbXMvcmVkaGF0LWV4dGVybmFsIiwiYXVkIjoiaHR0cHM6Ly9zc28ucmVkaGF0LmNvbS9hdXRoL3JlYWxtcy9yZWRoYXQtZXh0ZXJuYWwiLCJzdWIiOiJmOjUyOGQ3NmZmLWY3MDgtNDNlZC04Y2Q1LWZlMTZmNGZlMGNlNjphbW9ybGFuZy5yZWRoYXQiLCJ0eXAiOiJPZmZsaW5lIiwiYXpwIjoiY2xvdWQtc2VydmljZXMiLCJub25jZSI6IjQ1OGMyMzM0LWZiYzItNGQ0Ni04ZmJmLWQzMDBlMjg1M2NkMSIsInNlc3Npb25fc3RhdGUiOiJmNDBkNzFhMi1iY2YwLTQ5MjEtYjM2OC1kYzhiODk3ZjAzZDkiLCJzY29wZSI6Im9wZW5pZCBvZmZsaW5lX2FjY2VzcyJ9.SDSFXe44j-DLF8wh0jNZVEXA4DE7s7lZ6TP6qem0Z_Y"
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


