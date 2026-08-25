#!/bin/bash
#  Run docker compose build and up in the docker compose directory of the app
docker compose build --no-cache
docker compose up -d
