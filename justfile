image := "agent-sandbox"
network := "agent-restricted"
proxy_name := "ai-proxy"
runtime := env("RUNSC_PATH", "$HOME/.local/bin/runsc")

default:
    @just --list

build:
    podman build -t {{ image }} .

# Create the internal network and start the squid proxy
proxy-up:
    -podman network create --internal {{ network }}
    -podman rm -f {{ proxy_name }}
    podman run -d --name {{ proxy_name }} \
      --network podman,{{ network }} \
      --dns 1.1.1.1 \
      -v ./squid.conf:/etc/squid/squid.conf:ro,Z \
      docker.io/ubuntu/squid:latest

proxy-down:
    -podman rm -f {{ proxy_name }}

# Run the sandbox in the current directory (default: with gVisor)
run: (_run-sandbox "")

# Run the sandbox mounting a specific project directory
run-in dir: (_run-sandbox dir)

# Run the sandbox without gVisor (standard runc, for debugging)
run-no-gvisor: (_run-no-gvisor "")

# Run without gVisor in a specific project directory
run-no-gvisor-in dir: (_run-no-gvisor dir)

setup: build proxy-up run

status:
    @echo "=== Proxy ==="
    @podman ps -a --filter name={{ proxy_name }} --format "table {{"{{"}}.Names{{"}}"}}\t{{"{{"}}.Status{{"}}"}}\t{{"{{"}}.Ports{{"}}"}}" 2>/dev/null || echo "Not found"
    @echo ""
    @echo "=== Network ==="
    @podman network inspect {{ network }} --format "{{"{{"}}.Name{{"}}"}}: internal={{"{{"}}.Internal{{"}}"}}" 2>/dev/null || echo "Not found"

clean:
    -podman rm -f {{ proxy_name }}
    -podman rmi {{ image }}
    -podman network rm {{ network }}

install-gvisor:
    curl -fSL -o /tmp/runsc https://storage.googleapis.com/gvisor/releases/release/latest/x86_64/runsc
    install -m 755 /tmp/runsc ~/.local/bin/runsc
    rm /tmp/runsc

_mounts := `awk '!/^#/ && NF==3 {printf "--mount type=bind,src=%s,dst=%s,%s ", $1, $2, $3}' mounts.conf`

[private]
_run-sandbox dir:
    podman run -it --rm \
      --runtime={{ runtime }} \
      --runtime-flag=ignore-cgroups \
      --userns=keep-id \
      --network {{ network }} \
      -e HTTP_PROXY="http://{{ proxy_name }}:3128" \
      -e HTTPS_PROXY="http://{{ proxy_name }}:3128" \
      -e NO_PROXY="localhost,127.0.0.1" \
      -e NODE_OPTIONS="--use-env-proxy" \
      {{ _mounts }} \
      -v {{ if dir == "" { "." } else { dir } }}:/workspace:rw \
      --security-opt label=disable \
      {{ image }}

[private]
_run-no-gvisor dir:
    podman run -it --rm \
      --userns=keep-id \
      --network {{ network }} \
      -e HTTP_PROXY="http://{{ proxy_name }}:3128" \
      -e HTTPS_PROXY="http://{{ proxy_name }}:3128" \
      -e NO_PROXY="localhost,127.0.0.1" \
      -e NODE_OPTIONS="--use-env-proxy" \
      {{ _mounts }} \
      -v {{ if dir == "" { "." } else { dir } }}:/workspace:rw \
      --security-opt label=disable \
      {{ image }}
