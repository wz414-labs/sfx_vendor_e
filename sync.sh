#!/bin/bash

# Copyright (c) 2017 Julian Xhokaxhiu
# Copyright (C) 2017-2018 Nicola Corna <nicola@corna.info>
# Copyright (C) 2020 eCorp Romain HUNAULT <romain.hunaul@e.email>, steadfasterX <steadfasterX@binbash.rocks>
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

echo -e '\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo      '********                /e/ - RESET & SYNC                  ********'
echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'

repo_log="$LOGS_DIR/repo-$(date +%Y%m%d).log"

# cd to working directory
cd "$ANDROIDTOP"

sync_successful=true

if [ "$LOCAL_MIRROR" = true ]; then

  cd "$MIRROR_DIR"

  if [ ! -d .repo ]; then
    echo ">> [$(date)] Initializing mirror repository" | tee -a "$repo_log"
    yes | repo init -u "$MIRROR" --mirror --no-clone-bundle -p linux &>> "$repo_log"
  fi

  # Copy local manifests to the appropriate folder in order take them into consideration
  echo ">> [$(date)] Copying '$LMANIFEST_DIR/*.xml' to '.repo/local_manifests/'"
  mkdir -p .repo/local_manifests
  rsync -a --delete --include '*.xml' --exclude '*' "$LMANIFEST_DIR/" .repo/local_manifests/

  rm -f .repo/local_manifests/proprietary.xml
  if [ "$INCLUDE_PROPRIETARY" = true ]; then
    wget -q -O .repo/local_manifests/proprietary.xml "https://raw.githubusercontent.com/TheMuppets/manifests/mirror/default.xml"
  fi

  echo ">> [$(date)] Syncing mirror repository" | tee -a "$repo_log"
  repo sync --force-sync --no-clone-bundle &>> "$repo_log"

  if [ $? != 0 ]; then
    sync_successful=false
  fi
fi

  if [ -n "$BRANCH_NAME" ] && [ -n "$EOS_DEVICE" ]; then

    cd "$ANDROIDTOP"

    echo ">> [$(date)] Branch:  $BRANCH_NAME"
    echo ">> [$(date)] Devices: $EOS_DEVICE"

    # Remove previous changes of vendor/cm, vendor/lineage and frameworks/base (if they exist)
    for path in "vendor/cm" "vendor/lineage" "frameworks/base"; do
      if [ -d "$path" ]; then
        cd "$path"
        git reset -q --hard
        git clean -q -fd
        cd "$ANDROIDTOP"
      fi
    done

    echo ">> [$(date)] (Re)initializing branch repository" | tee -a "$repo_log"
    if [ "$LOCAL_MIRROR" = true ]; then
      yes | repo init -u "$REPO" --reference "$MIRROR_DIR" -b "$BRANCH_NAME" &>> "$repo_log"
    else
      TAG_PREFIX=""
      curl https://gitlab.e.foundation/api/v4/projects/659/repository/tags | grep "\"name\":\"$BRANCH_NAME\""
      if [ $? == 0 ]
      then
        echo "Branch name $BRANCH_NAME is a tag on e/os/releases, prefix with refs/tags/ for 'repo init'"
        TAG_PREFIX="refs/tags/"
      fi

      yes | repo init -u "$REPO" -b "${TAG_PREFIX}$BRANCH_NAME" &>> "$repo_log"
    fi

    rm -f .repo/local_manifests/proprietary.xml
    if [ "$INCLUDE_PROPRIETARY" = true ]; then
      wget -q -O .repo/local_manifests/proprietary.xml "https://raw.githubusercontent.com/TheMuppets/manifests/$themuppets_branch/muppets.xml"
      ${ROOT_DIR}/build_manifest.py --remote "https://gitlab.com" --remotename "gitlab_https" "https://gitlab.com/the-muppets/manifest/raw/$themuppets_branch/muppets.xml" .repo/local_manifests/proprietary_gitlab.xml
    fi

    echo ">> [$(date)] Syncing branch repository" | tee -a "$repo_log"
    repo sync -c --force-sync &>> "$repo_log"

    if [ $? != 0 ]; then
      export sync_successful=false
      export build_device=false
    fi
  fi
