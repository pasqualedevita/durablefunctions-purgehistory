FROM ubuntu:18.04

WORKDIR /usr/src/app

# common
RUN apt-get update \
    && apt-get install -y apt-transport-https bash wget curl

# azure cli
RUN apt-get update \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# dotnet-sdk-3.1
RUN wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-3.1

# azure-functions-core-tools-3
RUN apt-get install -y azure-functions-core-tools-3

ENV DRY_RUN='False'

COPY entrypoint.sh /entrypoint.sh

RUN chmod 700 /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
