#!/bin/bash
# Fix common linting errors
set -euxo pipefail

################
# Ignore files #
################
bin/sortignore.sh

############################################
##### Javascript, JSON, Markdown, YAML #####
############################################
npm run fix

###################
###### Shell ######
###################
# shellharden --replace ./**/*.sh
# shellharden quotes too much in tempproxy.sh
shellharden --replace auth-hook/auth.sh auth-hook/letsencrypt-namecheap-dns-auth.sh
