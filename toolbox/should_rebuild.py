#!/usr/bin/python3

# author: Ole Schuett

import re
import sys
import requests
from requests.auth import HTTPBasicAuth
import google.auth.transport.requests
import google.auth
from datetime import datetime, timedelta

#===============================================================================
def main():
    if len(sys.argv) == 1:
        should_rebuild_everything()

    elif sys.argv[1] == "toolchain":
        should_rebuild_toolchain()

    else:
        print("should_rebuild.py [toolchain]")
        sys.exit(255)

#===============================================================================
def should_rebuild_toolchain():
    labels = get_image_labels("img_cp2k-toolchain")

    sha = labels['org.label-schema.vcs-ref']
    r = requests.get("https://api.github.com/repos/cp2k/cp2k/compare/" + sha + "...HEAD")
    for entry in r.json()['files']:
        if entry['filename'].startswith("tools/toolchain"):
            print("Toolchain source files changed.")
            sys.exit(0)

    age = datetime.utcnow() - get_build_date(labels)
    max_age_days = 20
    if age.days > max_age_days:
        print("Toolchain image is older than {} days.".format(max_age_days))
        sys.exit(0)

    print("Toolchain image is ok.")
    sys.exit(1)

#===============================================================================
def should_rebuild_everything():
    sdbg_labels = get_image_labels("img_cp2k-sdbg")
    sdbg_build_date = get_build_date(sdbg_labels)

    toolchain_labels = get_image_labels("img_cp2k-toolchain")
    toolchain_build_date = get_build_date(toolchain_labels)

    if sdbg_build_date < toolchain_build_date:
        print("Toolchain image has changed - rebuild everything.")
        sys.exit(0)

    sdbg_sha = sdbg_labels['org.label-schema.vcs-ref']
    r = requests.get("https://api.github.com/repos/cp2k/cp2k/compare/" + sdbg_sha + "...HEAD")
    for entry in r.json()['files']:
        if entry['filename'].startswith("tools/docker/"):
            print("Source files have changed - rebuild everything.")
            sys.exit(0)

    # check runtime of latest sdbg test
    url = "https://storage.googleapis.com/cp2k-ci/dashboard_sdbg_report.txt"
    length = int(requests.head(url).headers['Content-Length'])
    tail = requests.get(url, headers={"Range":"bytes=%d-"%(length - 500)}).text
    runtime_sec = float(re.search("Regtest took (.*) seconds.", tail).group(1))
    report_date = parse_date(re.search("EndDate: (.*)", tail).group(1))
    used_latest_image = report_date - sdbg_build_date > timedelta(hours=4)
    if used_latest_image and runtime_sec > 15 * 60:
        print("Latest sdbg test run took too long - rebuild everything.")
        sys.exit(0)

    print("Images are ok.")
    sys.exit(1)

#===============================================================================
def get_image_labels(image):
    # https://hackernoon.com/inspecting-docker-images-without-pulling-them-4de53d34a604
    # https://cloud.google.com/container-registry/docs/advanced-authentication

    scopes = ["https://www.googleapis.com/auth/devstorage.read_only"]
    credentials, project = google.auth.default(scopes=scopes)
    auth_request = google.auth.transport.requests.Request()
    credentials.refresh(auth_request)

    auth = HTTPBasicAuth('_token', credentials.token)
    headers = {"Accept": "application/vnd.docker.distribution.manifest.v2+json"}
    base_url = "https://gcr.io/v2/" + project + "/" + image

    url = base_url + "/manifests/latest"
    r = requests.get(url, headers=headers, auth=auth)
    digest = r.json()['config']['digest']

    url = base_url + "/blobs/" + digest
    r = requests.get(url, headers=headers, auth=auth)
    return r.json()['config']['Labels']

#===============================================================================
def get_build_date(labels):
    return parse_date(labels['org.label-schema.build-date'])

#===============================================================================
def parse_date(date_str):
    return datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S+00:00")

#===============================================================================

main()

#EOF