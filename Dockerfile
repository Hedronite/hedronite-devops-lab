# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ARG TARGETARCH

ARG TFENV_VERSION=v3.0.0
ARG TF_VERSIONS="1.9.8 1.10.5"
ARG TF_DEFAULT=1.10.5
ARG KUBECTL_VERSION=v1.31.4
ARG HELM_VERSION=v3.16.4
ARG KREW_VERSION=v0.4.4
ARG K9S_VERSION=v0.32.7
ARG GO_VERSION=1.23.5
ARG UV_VERSION=0.5.24
ARG RUST_TOOLCHAIN=1.84.0
ARG RAILS_VERSION=7.2.2
ARG GH_VERSION=2.65.0
ARG YQ_VERSION=v4.44.6
ARG PROMETHEUS_VERSION=2.55.1
ARG GRAFANA_VERSION=11.4.0

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LAB_CONTAINER=1

# --- apt packages ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        dnsutils \
        git \
        gnupg \
        iputils-ping \
        jq \
        less \
        libffi-dev \
        libssl-dev \
        libyaml-dev \
        libzmq3-dev \
        locales \
        netcat-openbsd \
        neovim \
        openssh-client \
        pkg-config \
        python3 \
        r-base \
        r-base-dev \
        r-cran-tidyverse \
        ruby-full \
        ruby-dev \
        tmux \
        unzip \
        vim \
        wget \
        zip \
        zlib1g-dev \
        zsh \
    && rm -rf /var/lib/apt/lists/* \
    && git --version && jq --version && ruby --version && R --version && zsh --version

# --- standalone binaries ---
RUN curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client

RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
        | tar -xz -C /tmp \
    && mv "/tmp/linux-${TARGETARCH}/helm" /usr/local/bin/helm \
    && rm -rf "/tmp/linux-${TARGETARCH}" \
    && helm version

RUN curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${TARGETARCH}.tar.gz" \
        | tar -xz -C /usr/local/bin k9s \
    && k9s version

RUN curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz" \
        | tar -xz -C /tmp \
    && mv "/tmp/gh_${GH_VERSION}_linux_${TARGETARCH}/bin/gh" /usr/local/bin/gh \
    && rm -rf "/tmp/gh_${GH_VERSION}_linux_${TARGETARCH}" \
    && gh --version

RUN curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH}" \
    && chmod +x /usr/local/bin/yq \
    && yq --version

RUN curl -fsSL "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${TARGETARCH}.tar.gz" \
        | tar -xz -C /opt \
    && mv "/opt/prometheus-${PROMETHEUS_VERSION}.linux-${TARGETARCH}" /opt/prometheus \
    && ln -s /opt/prometheus/prometheus /usr/local/bin/prometheus \
    && ln -s /opt/prometheus/promtool /usr/local/bin/promtool \
    && prometheus --version

RUN curl -fsSL "https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-${TARGETARCH}.tar.gz" \
        | tar -xz -C /opt \
    && mv "/opt/grafana-v${GRAFANA_VERSION}" /opt/grafana \
    && ln -s /opt/grafana/bin/grafana /usr/local/bin/grafana \
    && ln -s /opt/grafana/bin/grafana-server /usr/local/bin/grafana-server \
    && grafana --version

# --- language toolchains ---
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
        | tar -xz -C /usr/local \
    && /usr/local/go/bin/go version

RUN curl -fsSL https://sh.rustup.rs \
        | sh -s -- -y --default-toolchain "${RUST_TOOLCHAIN}" --profile minimal \
    && /root/.cargo/bin/rustc --version && /root/.cargo/bin/cargo --version

RUN curl -fsSL "https://astral.sh/uv/${UV_VERSION}/install.sh" | sh \
    && /root/.local/bin/uv --version

RUN git clone --depth 1 --branch "${TFENV_VERSION}" https://github.com/tfutils/tfenv.git /root/.tfenv \
    && for v in ${TF_VERSIONS}; do /root/.tfenv/bin/tfenv install "$v"; done \
    && /root/.tfenv/bin/tfenv use "${TF_DEFAULT}" \
    && /root/.tfenv/bin/terraform version

ENV PATH="/root/.tfenv/bin:/usr/local/go/bin:/root/go/bin:/root/.krew/bin:/root/.cargo/bin:/root/.local/bin:${PATH}"

# --- app-level installs ---
RUN tmpdir="$(mktemp -d)" && cd "$tmpdir" \
    && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_${TARGETARCH}.tar.gz" \
    && tar -xzf "krew-linux_${TARGETARCH}.tar.gz" \
    && "./krew-linux_${TARGETARCH}" install krew \
    && cd / && rm -rf "$tmpdir" \
    && kubectl krew version

RUN gem install rails -v "${RAILS_VERSION}" --no-document \
    && rails --version

RUN Rscript -e 'install.packages("IRkernel", repos = "https://cloud.r-project.org")' \
    && Rscript -e 'library(IRkernel); library(tidyverse); cat("R stack ok\n")'

# --- shell setup ---
COPY shell/lab.zsh /etc/lab/lab.zsh
COPY shell/motd /etc/motd
RUN chsh -s /usr/bin/zsh root \
    && printf 'source /etc/lab/lab.zsh\n' > /root/.zshrc \
    && zsh -ic 'echo shell ok'

WORKDIR /workspace
CMD ["zsh"]
