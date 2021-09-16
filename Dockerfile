ARG PYTHON_VERSION
FROM python:$PYTHON_VERSION
LABEL maintainer="AJ Slater <aj@slater.net>"
LABEL version=$VERSION

RUN apk add --no-cache gcc musl-dev libffi-dev openssl-dev python3-dev cargo openssh
RUN pip3 install --no-cache-dir -U pip
RUN CRYPTOGRAPHY_DONT_BUILD_RUST=1 pip3 install --no-cache-dir -U poetry

COPY . /auth-hook
WORKDIR /auth-hook

RUN poetry install --no-dev
