#!/usr/bin/env bash
# exit on error
set -o errexit

# Esta línea instala las herramientas que la gema 'pg' necesita
apt-get update && apt-get install -y libpq-dev

# Estas son las instrucciones que Render ya usaba por defecto
bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
