#!/bin/bash

# Publish packages
/usr/bin/rsync -avz /srv/zips/ root@images.eelo.io:/eelo/builds/full/
/usr/bin/rsync -avz /srv/zips/ root@ota.eelo.io:/mnt/docker/ota/builds/full/
