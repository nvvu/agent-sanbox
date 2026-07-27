FROM registry.fedoraproject.org/fedora:44

RUN dnf install -y \
    golang \
    nodejs \
    npm \
    helix \
    fish \
    git \
    make \
    gcc-c++ \
    curl \
    wget \
    jq \
    ripgrep \
    fd-find \
    fzf \
    tree \
    unzip \
    tar \
    procps-ng \
    file \
    which \
    less \
    diffutils \
    patch \
    && dnf clean all

RUN  dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo \
    && dnf install -y gh

ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$PATH
ENV GOTOOLCHAIN=auto
ENV GOSUMDB=sum.golang.org
ENV NODE_OPTIONS=--use-env-proxy

RUN mkdir -p /go/bin /go/src /workspace

RUN go install golang.org/x/tools/gopls@latest

RUN npm install -g --prefer-online --network-concurrency 1 --ignore-scripts @anthropic-ai/claude-code \
    && node /usr/local/lib/node_modules/@anthropic-ai/claude-code/install.cjs

RUN curl -fsSL "https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-x64.tar.gz" \
       -o /tmp/opencode.tar.gz \
    && tar -xzf /tmp/opencode.tar.gz -C /usr/local/bin opencode \
    && chmod 755 /usr/local/bin/opencode \
    && rm /tmp/opencode.tar.gz

RUN useradd -m -s /usr/bin/fish developer \
    && mkdir -p /home/developer/.config/opencode \
                /home/developer/.local/share/opencode \
                /home/developer/.claude \
    && chown -R developer:developer /go /workspace /home/developer
USER developer
WORKDIR /workspace

CMD ["fish"]
