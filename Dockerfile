FROM ubuntu:24.04

# setup apt, including Microsoft repo
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes
RUN apt update \
 && apt-get install apt-utils \
        apt-transport-https
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
        python-is-python3 \
        pipx \
        libc6 \
        libgcc-s1 \
        libgssapi-krb5-2 \
        libicu74 \
        liblttng-ust1 \
        libssl3 \
        libstdc++6 \
        libunwind8 \
        zlib1g
RUN pipx install \
        azure-cli \
        yq
RUN PSVERSION=`curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq -rM .tag_name`; \
    case `uname -m` in \
      x86_64) \
        wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/${PSVERSION}/powershell-${PSVERSION#v}-linux-x64.tar.gz \
        ;; \
      aarch64) \
        wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/${PSVERSION}/powershell-${PSVERSION#v}-linux-arm64.tar.gz \
        ;; \
      armv7l) \
        wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/${PSVERSION}/powershell-${PSVERSION#v}-linux-arm32.tar.gz \
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
