# AI Agent Developer Sandbox

A secure, isolated development environment for running autonomous AI coding agents (Claude Code, OpenCode) on Fedora Silverblue. The sandbox ensures agents can help you write code without risking your host system's security, privacy, or stability.

## How the Sandbox Works

Defense-in-depth architecture with four layers of isolation:

1. **gVisor**: Interposes a user-space kernel (the Sentry) between the container and the host kernel. Syscalls from the AI agent never reach your real kernel. File I/O goes through a separate Gofer process, adding another boundary.
2. **Filesystem Boundary**: The AI can only see your project folder (`/workspace`). Home directory, SSH keys, and system files are invisible.
3. **User Namespaces**: The AI operates as an unprivileged user (`--userns=keep-id`). Files it creates in your project are owned by your host user account.
4. **Air-Gapped Network**: The container is on an internal-only network with zero direct internet access. All traffic must go through a Squid proxy that only allows whitelisted domains.

### What's Inside the Container

- **Languages**: Go, Node.js
- **AI agents**: Claude Code, OpenCode
- **Editors**: Helix
- **Shell**: Fish
- **Tools**: gopls, git, make, gcc, curl, jq, ripgrep, fd, fzf, tree, and more

Customize via `Containerfile`

## Prerequisites

- podman, just, runsc(gVisor)

## Setup

### 1. Install gVisor

```bash
just install-gvisor
```

### 2. Build and Run

First time, build the image, start the proxy, and launch the sandbox:

```bash
just setup
```

This runs `just build && just proxy-up && just run` in sequence.

## Usage

### Daily workflow

Navigate to your project directory and launch the sandbox:

```bash
cd ~/my-go-project
just run
# just run-in
```

You'll be dropped into Fish shell. Run `claude`, `opencode`, or use your Go tooling directly. Type `exit` to destroy the sandbox.

## Networks

### Whitelisted Domains

Configured in `squid.conf`. Only these domains are reachable from the sandbox:

| Domain | Purpose |
|---|---|
| `.anthropic.com`, `.claude.ai` | Claude API and auth |
| `.opencode.ai` | OpenCode services |
| `.github.com`, `.githubusercontent.com` | Git repos, release assets |
| `.golang.org`, `.go.dev`, `storage.googleapis.com` | Go modules, proxy, downloads |
| `.npmjs.org`, `.npmjs.com` | npm packages |

Everything else is blocked. Direct connections (bypassing the proxy) fail with "Network is unreachable".

### Testing the Network Isolation

From inside the sandbox:

```bash
# Direct connections should fail
curl -m 5 https://google.com

# Allowed domains via proxy should work
curl -x http://ai-proxy:3128 https://api.anthropic.com

# Blocked domains via proxy should get 403
curl -x http://ai-proxy:3128 https://google.com
```

### Adding Allowed Domains

Edit `squid.conf` and restart the proxy:

```bash
just proxy-down && just proxy-up
```

### Mounted Config

Edit `mounts.conf` and restart the sandbox (`exit` and `just run`)
