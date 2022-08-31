#!/bin/sh
# certbot renew auth-hook script for namecheap dns wildcard domains.
# AJ Slater <aj@slater.net>
# adapted from: https://github.com/scribe777/letsencrypt-namecheap-dns-auth

####### !!!!!!!!!!!!!  W A R N I N G !!!!!!!!!!!!! ############################
#
# NameCheap only has an API for setting all host DNS records
# i.e., we can't simply update one TXT row
#
# If you develop off this script TAKE A SCREENSHOT OF YOUR NAMECHEAP
# RECORDS before running this. Replacing all hosts can go wrong.
#
# ALSO, NameCheap recommends creating a sandbox account and
# testing there. I would suggest doing this.
#
# -------  certbot will pass us these variables -------
#
# CERTBOT_DOMAIN: The domain being authenticated
# CERTBOT_VALIDATION: The validation string
# CERTBOT_TOKEN: Resource name part of the HTTP-01 challenge (HTTP-01 only)
# CERTBOT_REMAINING_CHALLENGES: Number of challenges remaining after the current challenge
# CERTBOT_ALL_DOMAINS: A comma-separated list of all domains challenged for the current
###############################################################################

################
# INSTALL DEPS #
################
# Alpine only. Meant for the certbot docker image.
if [ ! -x "$(which curl)" ]; then
    apk add --no-cache curl
fi
if [ ! -x "$(which host)" ]; then
    apk add --no-cache bind-tools
fi

######################
# REQUIRED ARGUMENTS #
######################
# Your whitelisted client IP address, namecheap user id & namecheap API key
CLIENT_IP=$AUTH_HOOK_CLIENT_IP
NC_USER=$AUTH_HOOK_NC_USER
NC_API_KEY=$AUTH_HOOK_NC_API_KEY

#############
# CONSTANTS #
#############
# Namecheap API url
NC_SERVICE_URL="https://api.namecheap.com/xml.response"
# Wait time between checks for dns record propagation
WAIT_SECONDS=15
# Maximum time to wait for dns record to propagate
MAX_WAIT=360
# tmp dir for caching data
TMP_DIR=/tmp/namecheap-dns-auth
mkdir -p "$TMP_DIR"
# Common params
AUTH_PARAMS="ClientIp=${CLIENT_IP}&ApiUser=${NC_USER}&ApiKey=${NC_API_KEY}&UserName=${NC_USER}"
TLD=$(echo "$CERTBOT_DOMAIN" | rev | cut -d. -f1 | rev)
SLD=$(echo "$CERTBOT_DOMAIN" | rev | cut -d. -f2 | rev)
API_COMMAND_DOMAIN_PARAMS="SLD=${SLD}&TLD=${TLD}"

# shellcheck disable=SC2154
if [ "$http_proxy" != "" ] || [ "$https_proxy" != "" ]; then
    echo "*** USING PROXY ***"
    echo "http_proxy=$http_proxy"
    echo "https_proxy=$https_proxy"
fi

#############
# GET HOSTS #
#############
API_COMMAND="Command=namecheap.domains.dns.getHosts&$API_COMMAND_DOMAIN_PARAMS"
POST_DATA="${AUTH_PARAMS}&${API_COMMAND}"
XML_HOSTS_PATH=$TMP_DIR/domainHosts.xml
RESULT=$(curl -s --data "$POST_DATA" "$NC_SERVICE_URL")
XML_HOSTS=$(echo "$RESULT" | grep "<host ")
if [ "$XML_HOSTS" = "" ]; then
    echo No xml hosts found.
    echo "$RESULT"
    exit 1
fi
echo "$XML_HOSTS" >"$XML_HOSTS_PATH"
echo "Got $(echo "$XML_HOSTS" | wc -l) xml hosts"

##########################
# PREPARE SET HOSTS DATA #
##########################
# include domain tails before the 2nd level domain in the challenge host.
DOMAIN_TAIL=$(echo "$CERTBOT_DOMAIN" | awk 'NF{NF-=2}1' FS='.' OFS='.')
if [ "$DOMAIN_TAIL" != "" ]; then
    DOMAIN_TAIL=.$DOMAIN_TAIL
fi
CHALLENGE_HOST_NAME=_acme-challenge$DOMAIN_TAIL
API_COMMAND="Command=namecheap.domains.dns.setHosts&$API_COMMAND_DOMAIN_PARAMS"
POST_DATA="${AUTH_PARAMS}&${API_COMMAND}"

ENTRY_NUM=1
while IFS= read -r line; do
    # Parse xml with sed :/
    NAME=$(echo "$line" | sed 's/^.* Name="\([^"]*\)".*$/\1/g')
    TYPE=$(echo "$line" | sed 's/^.* Type="\([^"]*\)".*$/\1/g')
    ADDRESS=$(echo "$line" | sed 's/^.* Address="\([^"]*\)".*$/\1/g')
    MX_PREF=$(echo "$line" | sed 's/^.* MXPref="\([^"]*\)".*$/\1/g')
    TTL=$(echo "$line" | sed 's/^.* TTL="\([^"]*\)".*$/\1/g')

    # apparently 1799 is "auto"
    # if we specify what we received in getHosts, we don't preserve 'auto'
    # so we are specifying auto here
    TTL=1799

    if [ "$NAME" != "$CHALLENGE_HOST_NAME" ]; then
        # skip the _acme-challenge entry as we recreate it next.
        POST_DATA="$POST_DATA&HostName${ENTRY_NUM}=${NAME}&RecordType${ENTRY_NUM}=${TYPE}&Address${ENTRY_NUM}=${ADDRESS}&MXPref${ENTRY_NUM}=${MX_PREF}&TTL${ENTRY_NUM}=${TTL}"
        # sc is wrong about how to do arithmetic here SC2004
        # shellcheck disable=SC2004
        ENTRY_NUM=$((ENTRY_NUM + 1))
    fi
done <"$XML_HOSTS_PATH"

POST_DATA="$POST_DATA&HostName${ENTRY_NUM}=${CHALLENGE_HOST_NAME}&RecordType${ENTRY_NUM}=TXT&Address${ENTRY_NUM}=${CERTBOT_VALIDATION}&TTL${ENTRY_NUM}=60"

#########################
# REPLACE ALL HOST DATA #
#########################
RESULT=$(curl -s --data-raw "$POST_DATA" "$NC_SERVICE_URL")
echo "$RESULT"
SUCCESS=$(echo "$RESULT" | grep 'IsSuccess="true"')
if [ "$SUCCESS" = "" ]; then
    echo setHosts command failed.
    exit 1
fi

############################
# WAIT FOR DNS PROPAGATION #
############################
TXT_DOMAIN="_acme-challenge.${CERTBOT_DOMAIN}"
FOUND=false
# shellcheck disable=SC2004
END_SECONDS=$(($(date +%s) + MAX_WAIT))
while [ "$FOUND" != "true" ] && [ "$(date +%s)" -lt "$END_SECONDS" ]; do
    echo "Sleeping for ${WAIT_SECONDS} seconds..."
    sleep "$WAIT_SECONDS"
    CURRENT_ACME_VALIDATION=$(host -t TXT "$TXT_DOMAIN" | grep "^$TXT_DOMAIN" | cut -d ' ' -f 4 | sed 's/"//g')
    if [ "$CERTBOT_VALIDATION" = "$CURRENT_ACME_VALIDATION" ]; then
        FOUND=true
        echo "Certbot validation matches dns txt record :)"
    else
        echo "dns record not doesn't match... yet?"
    fi
done

if [ "$(date +%s)" -gt "$END_SECONDS" ]; then
    echo "Validation check timed out!"
    exit 1
fi

###########
# CLEANUP #
###########
rm -rf "$TMP_DIR"
