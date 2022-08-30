#!/bin/sh
# certbot renew auth-hook script for namecheap dns wildcard domains.
# AJ Slater <aj@slater.net>
# adapted from: https://github.com/scribe777/letsencrypt-namecheap-dns-auth
set -x

####### !!!!!!!!!!!!!  W A R N I N G !!!!!!!!!!!!! ####### 
#
#  NameCheap only has an API for setting all host DNS records
#  i.e., we can't simply update one TXT row
#
# That forces the workflow of this script to:
#	first read in all host records,
#	leave out any old _acme-challenge records
#	add our new certbot _acme-challenge record
#	REPLACE ALL HOST DNS RECORDS
#
# This sounds dangerous and probably is!  I took a screenshot
# of my existing NameCheap DNS entries before running this script
# in case it didn't preserve something.
# I personally wouldn't trust my script on a domain which had
# more than 10 records.  This means the update URL gets pretty long
# and AGAIN WANT TO ENCOURAGE YOU TO TAKE A SCREENSHOT OF YOUR DNS
# CONFIGURATION AND CHECK IT AFTER RUNNING THIS SCRIPT
#
# ALSO, NameCheap recommends creating a sandbox account and
# testing there.  I would suggest doing this.
# You can run this script directly, instead of from certbot
# if you fill in a couple extra variables, as mentioned in
# the SANDBOX section below.

# QuickStart: Don't quickstart.  Read everything up to this point first.
#	You'll need the wget and dig commands available
#	Enable API access on your NameCheap Account and obtain your APIKey
#	In NameCheap's API section, whitelist the IP of the server
#		from where you will run this script
#	Configure this script with your NameCheap userID, APIKey, and whitelisted IP address
#
#	TEST THIS SCRIPT BY CONFIGURING IT TO A SANDBOX ACCOUNT YOU'VE SETUP AT:
#	https://ap.www.sandbox.namecheap.com/
#	(see SANDBOX section below)
#
#	provide this script to certbot-2 when renewing, e.g.,
#	certbot-2 renew --manual-auth-hook=/root/letsencrypt-namecheap-dns-auth.sh
#
#	Probably put the above command in a monthly cron job
#
# Best wishes,
#	Troy A. Griffitts <scribe@crosswire.org>
#	https://crosswire.org
#


# -------  certbot will pass us these variables -------
#
# CERTBOT_DOMAIN: The domain being authenticated
# CERTBOT_VALIDATION: The validation string
# CERTBOT_TOKEN: Resource name part of the HTTP-01 challenge (HTTP-01 only)
# CERTBOT_REMAINING_CHALLENGES: Number of challenges remaining after the current challenge
# CERTBOT_ALL_DOMAINS: A comma-separated list of all domains challenged for the current

# -------- required arguments -------------------------
# Your whitelisted client IP address, namecheap user id & namecheap API key
CLIENT_IP=$AUTH_HOOK_CLIENT_IP
NC_USER=$AUTH_HOOK_NC_USER
NC_API_KEY=$AUTH_HOOK_NC_API_KEY

# ------- constants -----------------------------------
# Namecheap API url
NC_SERVICE_URL="https://api.namecheap.com/xml.response"

# Wait time between checks for dns record propagation
WAIT_SECONDS=15
MAX_WAIT=360

# tmp dir for caching data
TMP_DIR=/tmp/namecheap-dns-auth

# Code begins
# shellcheck disable=SC2154
if [ "$http_proxy" != "" ] || [ "$https_proxy" != "" ]; then
  echo "http_proxy=$http_proxy"
  echo "https_proxy=$https_proxy"
fi

if [ ! -x "$(which curl)" ]; then
  apk --no-cache add curl
fi

mkdir -p "$TMP_DIR"

# current dns records
TLD=$(echo "$CERTBOT_DOMAIN" | rev | cut -d. -f1 | rev)
SLD=$(echo "$CERTBOT_DOMAIN" | rev | cut -d. -f2 | rev)
TMP_GET_HOSTS_PATH=$TMP_DIR/getHosts.xml
AUTH_PARAMS="ClientIp=${CLIENT_IP}&ApiUser=${NC_USER}&ApiKey=${NC_API_KEY}&UserName=${NC_USER}"
API_COMMAND_DOMAIN_PARAMS="SLD=${SLD}&TLD=${TLD}"
API_COMMAND="Command=namecheap.domains.dns.getHosts&$API_COMMAND_DOMAIN_PARAMS"
POST_DATA="${AUTH_PARAMS}&${API_COMMAND}"
curl -o "$TMP_GET_HOSTS_PATH" --data "$POST_DATA" "$NC_SERVICE_URL"

# Use temp file instead of non-posix 'here string'
TMP_GET_HOSTS_ONLY_PATH=$TMP_DIR/getHostsOnly.xml
grep "<host " "$TMP_GET_HOSTS_PATH" > "$TMP_GET_HOSTS_ONLY_PATH"

# include domain tails before the 2nd level domain in the challenge host.
DOMAIN_TAIL=$(echo "$CERTBOT_DOMAIN" | awk 'NF{NF-=2}1' FS='.' OFS='.')
if [ "$DOMAIN_TAIL" != "" ];then
  DOMAIN_TAIL=.$DOMAIN_TAIL
fi
CHALLENGE_HOST_NAME=_acme-challenge$DOMAIN_TAIL
API_COMMAND="Command=namecheap.domains.dns.setHosts&$API_COMMAND_DOMAIN_PARAMS"
POST_DATA="${AUTH_PARAMS}&${API_COMMAND}"

ENTRY_NUM=1
while IFS= read -r line; do
  NAME=$(echo "$line"|sed 's/^.* Name="\([^"]*\)".*$/\1/g')
  TYPE=$(echo "$line"|sed 's/^.* Type="\([^"]*\)".*$/\1/g')
  ADDRESS=$(echo "$line"|sed 's/^.* Address="\([^"]*\)".*$/\1/g')
  MX_PREF=$(echo "$line"|sed 's/^.* MXPref="\([^"]*\)".*$/\1/g')
  TTL=$(echo "$line"|sed 's/^.* TTL="\([^"]*\)".*$/\1/g')

  # apparently 1799 is "auto"
  # if we specify what we received in getHosts, we don't preserve 'auto'
  # so we are specifying auto here
  TTL=1799

  if [ "$NAME" != "$CHALLENGE_HOST_NAME" ]; then
    # skip the _acme-challenge entry as we recreate it next.
    POST_DATA="$POST_DATA&HostName${ENTRY_NUM}=${NAME}&RecordType${ENTRY_NUM}=${TYPE}&Address${ENTRY_NUM}=${ADDRESS}&MXPref${ENTRY_NUM}=${MX_PREF}&TTL${ENTRY_NUM}=${TTL}"
    # sc is wrong about how to do arithmetic here SC2004
    # shellcheck disable=SC2004
    ENTRY_NUM=$((${ENTRY_NUM} + 1))
  fi
done < "$TMP_GET_HOSTS_ONLY_PATH"

# OK, now let's add our new acme challenge verification record
POST_DATA="$POST_DATA&HostName${ENTRY_NUM}=${CHALLENGE_HOST_NAME}&RecordType${ENTRY_NUM}=TXT&Address${ENTRY_NUM}=${CERTBOT_VALIDATION}&TTL${ENTRY_NUM}=60"
TMP_UPDATE_RESPONSE_PATH=$TMP_DIR/updateResponse.xml
# Finally, we'll update all host DNS records
curl -o "$TMP_UPDATE_RESPONSE_PATH" --data-raw "$POST_DATA" "$NC_SERVICE_URL"

# Actually, FINALLY, we need to wait for our records to propagate before letting certbot continue.
# Because we "echo" output here, certbot thinks something might have gone wrong.  It doesn't effect
# the successful completion of the domain cert renewal.  I like to see the output.  You might rather like to
# see certbot think everything went perfect and comment out the "echo" lines below.
if [ ! -x "$(which host)" ]; then
  apk add --no-cache bind-tools
fi
TXT_DOMAIN="_acme-challenge.${CERTBOT_DOMAIN}"
FOUND=false
 # shellcheck disable=SC2004
END_SECONDS=$(($(date +%s) + ${MAX_WAIT}))
while [ "$FOUND" != "true" ] && [ "$(date +%s)" -lt "$END_SECONDS" ]; do
  echo "Sleeping for ${WAIT_SECONDS} seconds..."
  sleep "$WAIT_SECONDS"
  CURRENT_ACME_VALIDATION=$(host -t TXT "$TXT_DOMAIN"|grep "^$TXT_DOMAIN"|cut -d ' ' -f 4|sed 's/"//g')
  if [ "$CERTBOT_VALIDATION" = "$CURRENT_ACME_VALIDATION" ]; then
    FOUND=true
    echo "Certbot validation matches dns txt record :)"
  else
    echo "dns record not doesn't match."
  fi
done

if [ "$(date +%s)" -gt "$END_SECONDS" ]; then
  echo "Validation check timed out!"
fi

# cleanup
# comment out these lines if you want to see some output from our commands, above
# rm -rf "$TMP_DIR"
