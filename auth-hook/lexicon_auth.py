#!/usr/bin/env python3
"""
Certbot Auth plugin for Namecheap uses the DNS API.

Usually certbot sets two environment variables:
CERTBOT_DOMAIN & CERTBOT_VALIDATION
But these can be overridden as when used in the flask server
"""

import os
import sys
import time

from datetime import datetime
from datetime import timezone
from logging import DEBUG
from logging import basicConfig
from logging import getLogger
from pathlib import Path

from lexicon.client import Client
from lexicon.config import ConfigResolver


DOMAIN_CACHE_PATH = Path("/tmp/domain.cache")
DOMAIN_CACHE_BOUNCE_SECONDS = 180
NAMECHEAP_MIN_TTL = 60
WAIT_SECS = NAMECHEAP_MIN_TTL + 1
CONFIG_PATH = Path(os.getenv("AUTH_HOOK_CONFIG_PATH", default="config/lexicon.yml"))
LOG_FMT = "%(asctime)s %(levelname)s:%(message)s"
LOG_LEVEL = os.getenv("LOGLEVEL", DEBUG)
basicConfig(format=LOG_FMT, level=LOG_LEVEL)
LOG = getLogger(__name__)


def debounce_domains(domain):
    """Prevent two similar domains from interfering.

    *.bullfrog.sl8r.net & bullfrog.sl8r.net validation
    interfere with each other.
    Might be better as a json dict of domains and times.
    """
    if DOMAIN_CACHE_PATH.exists():
        mtime = DOMAIN_CACHE_PATH.stat().st_mtime
        mod_dt = datetime.fromtimestamp(mtime, tz=timezone.utc)
        now = datetime.now(tz=timezone.utc)
        diff_seconds = (now - mod_dt).seconds
        if diff_seconds < DOMAIN_CACHE_BOUNCE_SECONDS:
            LOG.info(f"Checking {domain} for domain bouncing...")
            with DOMAIN_CACHE_PATH.open("r") as cache_file:
                old_domain = cache_file.read()
                if old_domain == domain:
                    LOG.warning("Exiting to avoid domain bouncing")
                    exit(0)

    with DOMAIN_CACHE_PATH.open("w") as cache_file:
        cache_file.write(domain)


def main():
    """Get arguments, host records, write the host records and sleep."""
    LOG.info(f"Started {sys.argv[0]}")
    certbot_domain = os.getenv("CERTBOT_DOMAIN")
    debounce_domains(certbot_domain)
    LOG.info(f"Updating TXT records for {certbot_domain}")
    certbot_validation = os.getenv("CERTBOT_VALIDATION")

    action = {
        "action": "update",
        "domain": certbot_domain,
        "type": "TXT",
        "name": certbot_domain,
        "content": certbot_validation,
    }
    config = ConfigResolver().with_config_file(str(CONFIG_PATH)).with_dict(action)
    Client(config).execute()

    LOG.info(f"Waiting {WAIT_SECS}s for DNS to propagate...")
    time.sleep(WAIT_SECS)
    LOG.info("Done.")


if __name__ == "__main__":
    main()

# For more than 20 domains namecheap reccomends a post body
# validation = os.getenv("CERTBOT_VALIDATION")
# challengeTag = BeautifulSoup(
#    f'<host name="_acme-challenge" type="TXT" address="{validation}"' +
#    ' ttl="60"',
#    "lxml",
# ).body.next
# hosts.append(challengeTag)

# Unused
#
# def get_domain_list():
#    """
#    Return list of <Domain> elements.
#    Currently unpaged, so only works on accounts with up to 20 domains.
#    Currently does not check if domain IsExpired or IsLocked.
#    """
#    url = method_url("namecheap.domains.getList", sandbox=SANDBOX)
#    result = requests.get(url).text
#    soup = BeautifulSoup(result, "lxml")
#    domains = soup.find_all("domain")
#    return domains
