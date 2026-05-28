#!/bin/bash
set -e
# Copy claude-skills/ to ~/.claude/skills/
mkdir -p ~/.claude/skills
cp -rv "$(dirname "$0")/claude-skills/"* ~/.claude/skills/
echo "Skills installed."
