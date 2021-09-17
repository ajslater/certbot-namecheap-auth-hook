FROM tianon/true
LABEL maintainer="AJ Slater <aj@slater.net>"
LABEL version=$VERSION

COPY . /auth-hook
WORKDIR /auth-hook
