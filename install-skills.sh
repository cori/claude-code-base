#!/bin/bash
# Copy claude-skills/ to ~/.claude/skills/
mkdir -p ~/.claude/skills
cp -v "$(dirname "$0")/claude-skills/"* ~/.claude/skills/
echo "Skills installed."

