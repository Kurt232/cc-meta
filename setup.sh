#!/bin/bash
# Initialize project-specific files (run once after cloning from meta)
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

[ ! -f TASKS.md ]    && touch TASKS.md    && echo "Created TASKS.md"
cat > TASKS.md << 'EOF'
# Tasks
EOF

[ ! -f PROGRESS.md ] && touch PROGRESS.md && echo "Created PROGRESS.md"
cat > PROGRESS.md << 'EOF'
# Progress Log
EOF

[ ! -f README.md ]   && touch README.md   && echo "Created README.md"
cat > README.md << 'EOF'
# <Project Name>
<Project Description>
## Repo Structure

## Tech Stack

## Architecture

EOF

[ ! -f .gitignore ]  && touch .gitignore  && echo "Created .gitignore"

echo "Setup complete."
