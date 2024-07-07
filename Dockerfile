ARG UBUNTU_VERSION=22.04
FROM ubuntu:${UBUNTU_VERSION}

# setup apt, including Microsoft repo
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes
RUN apt update \
 && apt-get install apt-utils \
        apt-transport-https \
        software-properties-common
RUN wget -q https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb \
 && dpkg -i packages-microsoft-prod.deb \
 && rm packages-microsoft-prod.deb \
 && apt-get update
RUN apt upgrade

# install dependencies
RUN apt install --no-install-recommends \
        ca-certificates \
        git \
        curl \
        wget \
        unzip \
        zip \
        jq \
        python3 \
        python3-pip \
        python-is-python3 \
        powershell \
        libicu70
RUN pip install --progress-bar off --no-color \
        azure-cli \
        yq

# cleanup apt
RUN rm -rf /var/lib/apt/lists/* \
 && apt-get clean

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

# Create agent user and set up home directory
RUN useradd -m -d /home/agent agent
RUN chown -R agent:agent /azp /home/agent
USER agent

ENTRYPOINT [ "./start.sh" ]
