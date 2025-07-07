#!/usr/bin/env bash
# Exit on error
set -o errexit

# Apply database migrations
alembic upgrade head
