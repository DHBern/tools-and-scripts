import argparse
import requests
import xml.etree.ElementTree as ET
import json
import pprint

from keycloak import KeycloakOpenID

from requests.sessions import session

BASE_URL = "https://transkribus.eu/TrpServer/rest"
COLLECTION_ID = 74823


def get_vol_url(vol_id: int) -> str:
    return BASE_URL + f"/collections/{COLLECTION_ID}/{vol_id}/fulldoc"

def get_page_url(vol_id: int, pagenum: int) -> str:
    return BASE_URL + f"/collections/{COLLECTION_ID}/{vol_id}/{pagenum}/list"

def login(user: str, password: str, sess: requests.Session) -> str:
    keycloak_openid = KeycloakOpenID(
        server_url="https://account.readcoop.eu/auth/",
        client_id="unibe_transkribus_test",
        realm_name="readcoop"
    )

    token = keycloak_openid.token(user, password)

    return token

def main():
    aparse = argparse.ArgumentParser()
    aparse.add_argument("-d", "--debug", action="store_true", required=False)
    aparse.add_argument("-u", "--user", dest="user", required=True)
    aparse.add_argument("-p", "--password", dest="password", required=True)

    args = aparse.parse_args()


    with requests.Session() as session:
        token = login(args.user, args.password, session)
        headers = headers={"Authorization": f"Bearer {token['access_token']}"}
 
        vol_mets_url = get_vol_url(508766)
        data = json.loads(requests.get(vol_mets_url, headers=headers).content) 
        npages = int(data["md"]["nrOfPages"])
        #for pagenum in range(1, npages + 1):
        for pagenum in range(30, 32):
            page_mets_url = get_page_url(514175, pagenum)
            page_xml_url = json.loads(
                requests.get(page_mets_url, headers=headers).content.decode()
            )[1]["url"]

            page_xml_str = requests.get(page_xml_url, headers=headers)\
                .content.decode()

            print(page_xml_str)

if __name__ == "__main__":
    main()