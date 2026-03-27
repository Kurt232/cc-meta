FROM node:22-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates curl python3 python3-venv \
    && rm -rf /var/lib/apt/lists/*
RUN npm install -g @anthropic-ai/claude-code@latest
RUN useradd -m -s /bin/bash cc-worker
USER cc-worker
ENV CC_IN_CONTAINER=1
WORKDIR /workspace
ENTRYPOINT ["/workspace/start.sh"]
