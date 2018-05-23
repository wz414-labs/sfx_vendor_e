#!/bin/bash

# Get local manifests (especiially for specific devices)
cd /srv/local_manifests
if [ ! -d ".git" ]; then git init && git remote add -f origin ssh://git@gitlab.eelo.io:2222/eelo/local_manifests.git; fi
git checkout master
git pull
