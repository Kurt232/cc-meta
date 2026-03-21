FROM node:22-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates curl python3 python3-venv \
    && rm -rf /var/lib/apt/lists/*
RUN npm install -g @anthropic-ai/claude-code
RUN useradd -m -s /bin/bash cc-worker
USER cc-worker
ENV CC_IN_CONTAINER=1
RUN git config --global user.name "cc-worker" && git config --global user.email "cc-worker@noreply"
WORKDIR /workspace
ENTRYPOINT ["/workspace/start.sh"]
