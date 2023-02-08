ARG VARIANT=7.2
FROM mcr.microsoft.com/azure-functions/powershell:4-powershell${VARIANT}-core-tools

# some people add github functionality here but I found it to be super slow
# to compile for the first time so I moved adding what I wanted here
RUN set -ex; \
    apt-get update ; \
    apt-get install -y --no-install-recommends \
    ca-certificates curl powershell-lts git; \
    rm -rf /var/lib/apt/lists/*