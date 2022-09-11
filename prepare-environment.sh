#!/usr/bin/env bash
set -euo pipefail

# Set up GitHub's Environment

# shellcheck disable=2129
# Chaining the echos seems more readable.
echo "GIT_AUTHOR_NAME=github-actions[bot]" >> "$GITHUB_ENV"
echo "GIT_AUTHOR_EMAIL=<github-actions[bot]@users.noreply.github.com>" >> "$GITHUB_ENV"
echo "GIT_COMMITTER_NAME=github-actions[bot]" >> "$GITHUB_ENV"
echo "GIT_COMMITTER_EMAIL=<github-actions[bot]@users.noreply.github.com>" >> "$GITHUB_ENV"
