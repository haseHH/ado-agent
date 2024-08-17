FROM ubuntu:24.04

# setup apt and related essentials
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes
RUN apt update \
 && apt-get install apt-utils \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
RUN apt upgrade

# setup Microsoft azure-cli repo
RUN mkdir -p /etc/apt/keyrings
RUN curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null
RUN chmod go+r /etc/apt/keyrings/microsoft.gpg
RUN echo "Types: deb" > /etc/apt/sources.list.d/azure-cli.sources
RUN echo "URIs: https://packages.microsoft.com/repos/azure-cli/" >> /etc/apt/sources.list.d/azure-cli.sources
RUN echo "Suites: $(lsb_release -cs)" >> /etc/apt/sources.list.d/azure-cli.sources
RUN echo "Components: main" >> /etc/apt/sources.list.d/azure-cli.sources
RUN echo "Architectures: $(dpkg --print-architecture)" >> /etc/apt/sources.list.d/azure-cli.sources
RUN echo "Signed-by: /etc/apt/keyrings/microsoft.gpg" >> /etc/apt/sources.list.d/azure-cli.sources

# install dependencies
RUN apt update \
 && apt install --no-install-recommends \
        git \
        wget \
        unzip \
        zip \
        jq \
        python3 \
        python-is-python3 \
        pipx \
        gcc-arm-linux-gnueabihf \
        libc6 \
        libgcc-s1 \
        libgssapi-krb5-2 \
        libicu74 \
        liblttng-ust1* \
        libssl3* \
        libstdc++6 \
        libunwind8 \
        zlib1g \
        azure-cli
RUN pipx install yq
RUN PSVERSION=`curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq -rM .tag_name`; \
    case `uname -m` in \
      x86_64) \
        wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/${PSVERSION}/powershell-${PSVERSION#v}-linux-x64.tar.gz \
        ;; \
      aarch64) \
        wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/${PSVERSION}/powershell-${PSVERSION#v}-linux-arm64.tar.gz \
        ;; \
    esac
RUN mkdir -p /opt/microsoft/powershell/7
RUN tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
RUN rm -f /tmp/powershell.tar.gz
RUN chmod +x /opt/microsoft/powershell/7/pwsh
RUN ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

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
