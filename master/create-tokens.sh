#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create the overlay files for the salt tree.  We create these in a separate
# place so that we can blow away the rest of the salt configs on a kube-push and
# re-apply these.

#readonly BASIC_AUTH_FILE="/srv/salt-overlay/salt/kube-apiserver/basic_auth.csv"
readonly BASIC_AUTH_FILE="/srv/kubernetes/basic_auth.csv"
# If file exist don't do anything
if [ ! -e "${BASIC_AUTH_FILE}" ]; then
    mkdir -p /srv/kubernetes

    export KUBE_PASSWORD=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
    echo "${KUBE_PASSWORD},admin,admin" > $BASIC_AUTH_FILE
fi

# Generate and distribute a shared secret (bearer token) to
# apiserver and the nodes so that kubelet and kube-proxy can
# authenticate to apiserver.

kubelet_token=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
kube_proxy_token=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)

# Make a list of tokens and usernames to be pushed to the apiserver
mkdir -p /srv/kubernetes
mkdir -p /srv/kubernetes-env

# Store Environmental Files for later usage
echo "KUBELET_TOKEN=$kubelet_token" > /srv/kubernetes-env/kubelet_token
echo "KUBE_PROXY_TOKEN=$kube_proxy_token" >> /srv/kubernetes-env/kubelet_token
readonly KNOWN_TOKENS_FILE="/srv/kubernetes/known_tokens.csv"

if [ -f ${KNOWN_TOKENS_FILE} ]; then
    exit 0
fi

(umask u=rw,go= ; echo "$kubelet_token,kubelet,kubelet" > $KNOWN_TOKENS_FILE ;
echo "$kube_proxy_token,kube_proxy,kube_proxy" >> $KNOWN_TOKENS_FILE)


# Generate tokens for other "service accounts".  Append to known_tokens.
#
# NB: If this list ever changes, this script actually has to
# change to detect the existence of this file, kill any deleted
# old tokens and add any new tokens (to handle the upgrade case).
service_accounts=("system:scheduler" "system:controller_manager" "system:logging" "system:monitoring" "system:dns")
for account in "${service_accounts[@]}"; do
    token=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
    echo "${token},${account},${account}" >> "${KNOWN_TOKENS_FILE}"
done
