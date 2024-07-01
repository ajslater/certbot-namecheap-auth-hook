# hadolint ignore=DL3006
FROM tianon/true:multiarch
LABEL maintainer="AJ Slater <aj@slater.net>"
LABEL version=$VERSION

COPY /auth-hook /auth-hook
WORKDIR /auth-hook
