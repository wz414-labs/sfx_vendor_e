#!/bin/bash

# Docker init script
# Copyright (c) 2017 Julian Xhokaxhiu
# Copyright (C) 2017-2018 Nicola Corna <nicola@corna.info>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Prepare the environment
echo ">> [$(date)] Preparing build environment"
source $VENDOR_DIR/vendorsetup.sh reset > /dev/null
source build/envsetup.sh > /dev/null

# check required variables
echo ">> [$(date)] DEBUG: ROOT_DIR is set to: >$ROOT_DIR<"
if [ -z "$ROOT_DIR" ]||[ ! -d "$ROOT_DIR" ];then
    echo ">> [$(date)] ERROR: Please set the ROOT_DIR (e.g. ROOT_DIR=./root) variable and ensure it is an existing directory"
    exit 3
fi

# Copy the user scripts
mkdir -p ${ROOT_DIR}/userscripts
cp -r $USERSCRIPTS_DIR/. ${ROOT_DIR}/userscripts

# Initialize CCache if it will be used
if [ "$USE_CCACHE" = 1 ]; then
  ccache -M $CCACHE_SIZE 2>&1
fi

# Initialize Git user information
git config --global user.name $USER_NAME
git config --global user.email $USER_MAIL

if [ "$SIGN_BUILDS" = true ]; then
  if [ -z "$(ls -A "$KEYS_DIR")" ]; then
    echo ">> [$(date)] SIGN_BUILDS = true but empty \$KEYS_DIR, generating new keys"
    for c in releasekey platform shared media; do
      echo ">> [$(date)]  Generating $c..."
      ${VENDOR_DIR}/src/make_key "$KEYS_DIR/$c" "$KEYS_SUBJECT" <<< '' &> /dev/null
    done
  else
    for c in releasekey platform shared media; do
      for e in pk8 x509.pem; do
        if [ ! -f "$KEYS_DIR/$c.$e" ]; then
          echo ">> [$(date)] SIGN_BUILDS = true and not empty \$KEYS_DIR, but \"\$KEYS_DIR/$c.$e\" is missing"
          break 9
        fi
      done
    done
  fi
  for c in cyngn{-priv,}-app testkey; do
    for e in pk8 x509.pem; do
      ln -s releasekey.$e "$KEYS_DIR/$c.$e" 2> /dev/null
      test -L "$KEYS_DIR/$c.$e"
    done
  done
fi
