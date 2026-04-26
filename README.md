# dome-ai

Minimal local AI stack for Dome built around Ollama, Open WebUI, Qdrant, and SearXNG.

## Setup

I confirmed your current dome-ai compose asks Docker for the `nvidia` device driver, so this is a runtime/toolkit registration issue on the LXC host rather than an Ollama image problem. 


Plan to fix this quickly:
1. Confirm Docker can see an NVIDIA runtime.
2. Install/configure NVIDIA Container Toolkit inside the LXC.
3. Validate GPU access with a one-off CUDA container.
4. Start `ollama` again.
5. If it still fails, apply the LXC host-side GPU passthrough checks.

Most likely root cause: Docker in the LXC does not have the `nvidia` runtime registered, even though `nvidia-smi` works in the container OS. Your compose in docker-compose.yml requests `driver: nvidia`, so Docker must know that runtime.

Run these on `ai.dome` (inside the LXC):

```bash
# 1) Check current docker runtimes
docker info --format '{{json .Runtimes}}'
docker info | grep -i -E 'runtime|nvidia|rootless'
```

If `nvidia` is missing, install toolkit:

```bash
# 2) Install NVIDIA Container Toolkit (Ubuntu 24.04)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

Configure Docker runtime and restart:

```bash
# 3) Register nvidia runtime with docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# verify nvidia runtime appears
docker info --format '{{json .Runtimes}}'
```

Test GPU from Docker directly (before compose):

```bash
# 4) Smoke test GPU in docker
docker run --rm --gpus all nvidia/cuda:12.6.3-base-ubuntu24.04 nvidia-smi
```

If this works, retry your service:

```bash
docker compose up -d ollama
docker logs --tail=100 ollama
```

If it still fails, check these LXC prerequisites on the Proxmox host (not inside LXC):
- Container is `privileged` (recommended for GPU passthrough) or properly configured unprivileged mapping.
- `nesting=1` enabled.
- NVIDIA device nodes are bind-mounted into the CT (`/dev/nvidia0`, `/dev/nvidiactl`, `/dev/nvidia-uvm`, `/dev/nvidia-uvm-tools`).
- cgroup device allow rules include NVIDIA device majors.

Quick temporary workaround (CPU only) while fixing runtime:
- Remove/comment GPU reservation block in docker-compose.yml for `ollama`, then start it without GPU.

If you paste the output of these two commands, I can pinpoint the exact next step:
```bash
docker info --format '{{json .Runtimes}}'
cat /etc/docker/daemon.json
```

## Stack

- `portainer-agent`: local Portainer instance for container management
- `dozzle`: local dozzle agent for container log viewing
- `ollama`: local model runtime with NVIDIA GPU access
- `ollama-exporter`: Prometheus exporter for Ollama metrics
- `open-webui`: local chat UI and model interaction layer
- `qdrant`: vector database for later RAG and retrieval workflows
- `searxng`: private local metasearch instance
- `valkey`: required internal dependency for SearXNG

## Files

- `docker/docker-compose.yml`: primary minimal stack
- `docker/.env_sample`: environment template for ports, tags, and paths
- `docker/searxng/settings.yml`: local SearXNG settings
- `setup/02-setup-environment.sh`: prepares the required runtime directories

## First Run

1. Copy `docker/.env_sample` to `docker/.env` and change the secrets.
2. Run `setup/02-setup-environment.sh` on the target host to create directories.
3. Start the stack from `dome-ai/docker` with `docker compose up -d`.
4. Open Open WebUI on `http://localhost:3000` by default.
5. Confirm SearXNG on `http://localhost:8081` and Qdrant on `http://localhost:6333/dashboard`.

## Starter Models

Recommended starting set for a single RTX 5090:

- General chat: `qwen3.6:27b`
- Coding: `qwen2.5-coder:32b`
- Reasoning: `deepseek-r1:32b`

Pull them after the stack is up:

```bash
docker exec -it ollama ollama pull qwen2.5:32b
docker exec -it ollama ollama pull qwen2.5-coder:32b
docker exec -it ollama ollama pull deepseek-r1:32b
```

## Model Management

Use Open WebUI to interact with models and pull new ones, but use the Ollama CLI for exact model lifecycle operations in this containerized setup.

```bash
# Pull a model
docker exec -it ollama ollama pull qwen2.5:32b

# List installed models
docker exec -it ollama ollama list

# Remove a model
docker exec -it ollama ollama rm qwen2.5:32b
```

## Notes

- This version intentionally uses direct local ports only.
- Traefik, OAuth, remote exposure, vision models, and image generation are out of scope for this stack.
- SearXNG is included as a future local search backend for agent and retrieval workflows; its internal Valkey dependency is required even though it is not a user-facing service.
