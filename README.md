# dome-ai

Minimal local AI stack for Dome built around Ollama, Open WebUI, Qdrant, and SearXNG.

## Stack

- `ollama`: local model runtime with NVIDIA GPU access
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

- General chat: `qwen2.5:32b`
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
