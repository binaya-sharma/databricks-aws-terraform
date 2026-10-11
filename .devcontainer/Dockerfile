FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Common tooling plus Java for local Spark/Databricks development.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        jq \
        less \
        lsb-release \
        make \
        openjdk-17-jdk \
        shellcheck \
        unzip \
        zip \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI v2 supports both Intel/AMD and Apple Silicon dev-container hosts.
RUN case "${TARGETARCH}" in \
        amd64) aws_arch="x86_64" ;; \
        arm64) aws_arch="aarch64" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl --fail --location --retry 3 \
        "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" \
        --output /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

# Terraform from HashiCorp's signed apt repository.
RUN curl --fail --silent --show-error --location \
        https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor --output /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends terraform \
    && rm -rf /var/lib/apt/lists/*

# Install the current Databricks CLI using Databricks' official installer.
RUN curl --fail --silent --show-error --location \
        https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh \
        | sh

# Keep developer-owned tools and their caches under the non-root user's home.
USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}"

RUN curl --fail --silent --show-error --location https://astral.sh/uv/install.sh | sh \
    && uv --version

RUN curl --fail --silent --show-error --location https://chatgpt.com/codex/install.sh | sh \
    && codex --version

WORKDIR /workspaces/databricks-aws-terraform
