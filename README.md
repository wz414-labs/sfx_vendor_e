# Classic / Standard Android build process

## Why *not* simply using "Docker"?

The provided Docker image is the recommended way to build /e/.
Especially for new users who never build Android before it is THE method
which will simply just work. It does not require a Linux setup and has
extreme low barriers for beginners.

If you ask yourself if you should go the recommended way or the classic
one the anywer would be almost always: use Docker instead of this here.

Checkout the [docker guide][docker-guide] for that.

## Who might wanna use this repo?

If you can answer any or all of the following with yes, then this repo
is for you:

 - you have build Android before and are used to the classic way of building
 - you have already a good working build environment
 - you do not like docker :P
 - you want to get the most speed possible
 - you want to learn how Android would be normally build
 - you plan to build other Android ROMs like LOS, AOSiP etc and do not want
   to start everytime from scratch
 - you already have Linux, have good experience with Linux and/or be willing
   to get used to it :)

Some / all of the above matches on you? Well then this is for you!


## Getting started

To get started with Android and/or /e/, you'll need to get
familiar with [Repo](https://source.android.com/source/using-repo.html) and [Version Control with Git](https://source.android.com/source/version-control.html).

To initialize your local repository using the /e/ trees, use either [a tag (you now what you get)][release-tags] or a [branch (the latest code of a branch)][release-branches]:
```
repo init -u https://gitlab.e.foundation/e/os/releases.git -b refs/tags/<tag>
or
repo init -u https://gitlab.e.foundation/e/os/releases.git -b <branch>

e.g:
repo init -u https://gitlab.e.foundation/e/os/releases.git -b refs/tags/v0.9.4-pie
repo init -u https://gitlab.e.foundation/e/os/releases.git -b v1-pie

```
Then create/edit your local manifest in `.repo/local_manifests/eos.xml`:
```
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <!-- F-Droid (optional - see topic "F-Droid")
    #####################################################-->
    <project name="suicide-squirrel/android_vendor_fdroid" path="vendor/fdroid" remote="github" revision="eos" />

    <!-- KERNEL
    #####################################################-->
    <project name="REPLACE WITH YOURS" path="REPLACE WITH YOURS" remote="REPLACE" revision="REPLACE" />

    <!-- DEVICE TREES
    #####################################################-->
    <project name="REPLACE WITH YOURS" path="REPLACE WITH YOURS" remote="REPLACE" revision="REPLACE" />

    <!-- /e/ vendor repo
    #####################################################-->
    <project path="vendor/e" name="steadfasterX/android_vendor_e" remote="e" revision="main" />
<manifest>
```
Finally sync the sources:
```
repo sync -j<processes>
e.g.
repo sync -j8
```


## Setup /e/

### root-less support

One of the major concerns with the docker guide is that everything runs as root - so with full permissions.

Using this approach instead let you use a normal user account when you set the following rule in sudoers. It is not required but will let you auto-change to the correct JAVA version during a build:

`<YOURUSERNAME>      ALL=NOPASSWD: /usr/sbin/update-java-alternatives *`

You can leave even that out if you switch your java version manually, of course. When building for several versions on the same sources it is quite handy though ;)


### vendorsetup.sh (your device tree)

you find that one here: `device/<vendor>/<codename>/vendorsetup.sh`

if it does not exists (might be the case on newer tree's where the lunch combo's have been moved already) just create it.

you need at least to set 1 variable here:

 - `export EOS_DEVICE=<codename>`: your device's codename. that means set it identical to what you have defined for "PRODUCT_DEVICE".
 
 there are more variables you *can* set here (optional), some maybe interesting examples are:

 - `export EOS_USE_CCACHE=1|0 (1 = enable, 0 = disable)`
 - `export EOS_CCACHE_DIR=<directory>`
 - `export EOS_CCACHE_SIZE=<size>G`
 - `export EOS_SIGNATURE_SPOOFING=no|yes|restricted`: add or add not microG, or add it restricted (see topic "Signature spoofing")
 - `export EOS_BRANCH_NAME=v1-pie` the [release branch][release-branches] you want to build on, e.g. "v1-pie"
 - `export EOS_RELEASE_TYPE=UNOFFICIAL`: the [type of your release][release-types], e.g. "UNOFFICIAL"
 - `export EOS_CUSTOM_PACKAGES="....."`: override the list of /e/ apps to be included

Show which EOS variable sets which internal/Android variable by executing this command:

`egrep '^\w+=' vendor/e/vendorsetup.sh |cut -d = -f1-10 | grep -v EXPORTS_`

For their default values look into vendor/e/[vendorsetup.sh][vendorsetup].
Don't do any changes in that file though, just adjust the correct EOS_xxx variable if you don't want to use the default.

Note: Do *not* change variables in vendor/e/vendorsetup.sh! Just find out what the proper variable name is
and set that EOS_xxx variable within your `device/<vendor>/<codename>/vendorsetup.sh`!


### lineage.mk

In order to make use of this vendor repo you have to include it in your `device/<vendor>/<codename>/lineage.mk`


~~~
# inherit vendor e
$(call inherit-product, vendor/e/config/common.mk)
~~~

### Signature spoofing

If you want to make use of [microG][microg] there are 2 options for the required [signature spoofing patch][signature-spoofing]:

 * "Original" [patches][signature-spoofing-patches]
 * Restricted patches

With the "original" patch the FAKE_SIGNATURE permission can be granted to any
user app: while it may seem handy, this is considered dangerous by a great
number of people, as the user could accidentally give this permission to rogue
apps.

A more strict option is the restricted patch, where the FAKE_SIGNATURE
permission can be obtained only by privileged system apps, embedded in the ROM
during the build process.

The signature spoofing patch can be optionally included with:

 * `export EOS_SIGNATURE_SPOOFING=yes` to use the original patch, `restricted` for
    the restricted one, `no` for none of them

If in doubt, use `restricted`: note that packages that requires the
FAKE_SIGNATURE permission must be embedded in the build by adding them in

 * `EOS_CUSTOM_PACKAGES`

Extra packages can be included in the tree by adding the corresponding manifest
XML to the local_manifests volume.

### Proprietary files

Some proprietary files are needed to create a LineageOS build, but they're not
included in the repo for legal reasons. You can obtain these blobs in
four ways:

 * by [pulling them from a running LineageOS][blobs-pull]
 * by [extracting them from a LineageOS ZIP][blobs-extract]
 * by downloading them from [TheMuppets repos][blobs-themuppets] (unofficial)
 * by adding them to a local_manifests definition (e.g. roomservice.xml)

/e/ expects you take care of these blobs (1,2,4 from the above) and so pulling them from TheMuppets is NOT enabled by default; 
if you're OK with that just move on, otherwise set `EOS_INCLUDE_PROPRIETARY` to `true` in `device/<vendor>/<codename>/vendorsetup.sh` to pull them from TheMuppets automatically.

### F-Droid / AuroraStore

Setting up [F-Droid](https://f-droid.org) in your local manifest will allow you to pre-install F-Droid, it's Privileged Extension and also the [AuroraStore][aurora-store].

Here are the things to do/know:

`device/<vendor>/<codename>/<device>.mk`:
- include F-Droid with: `WITH_FDROID := true`
- include additional F-Droid repos with: `FDROID_EXTRA_REPOS := true` - see [additional_repos.xml][fdroid-repos]
- add these to either PRODUCT_PACKAGES in the same mk or add these to `EOS_CUSTOM_PACKAGES` in `device/<vendor>/<codename>/vendorsetup.sh`

Note1: additional repos for F-Droid need to be enabled in F-Droid manually to use them. This ensures that you just have enabled what you need/want.

Note2: enabling the additional repos need either clearing the app data of F-Droid (settings) or a factory reset to make them appear [(background)][fdroid-reset]

Example config which includes F-Droid + privilege ext. + additional repos and AuroraStore:

~~~
WITH_FDROID := true
FDROID_EXTRA_REPOS := true
PRODUCT_PACKAGES += \
    F-Droid \
    FDroidPrivilegedExtension \
    additional_repos.xml \
    AuroraStore
~~~

In short:

 - F-Droid: lesser apps but build from source-code which is public available (open source means trust)
 - Aurora: Google Play client. Only use your account details here when really needed (e.g. paid apps). Better choose the *anonymous* access especially when playing around with advanced features like spoofing etc. Apps here comin directly from Google Play which also means the majority is proprietary / closed source and so cannot be verified (same apply when using google play directly, of course)

### OTA

If you plan to provide updates for your unofficial and/or custom build you can
setup your own [custom OTA server][customOTA]. 

Follow that guide to setup and prepare your device tree to use it.


### Signing

By default, builds are signed with your own keys - created automatically on build.
If you want to sign your builds with the default test-keys (**not recommended**) just
setup your device tree vendorsetup.sh with:

 * `EOS_SIGN_BUILDS`: set to `false` to sign the builds with the *test-keys* instead of your own


## Start building

This repo provides a new build target:

`mka eos`:

    build /e/ ;)

so a complete run would be:

~~~
repo sync -j8
source build/envsetup.sh
breakfast <your-device> (or lunch <your-device_releasetype>)
mka eos
~~~

## Finally

enjoy your new created build and do not forget to share your work at the [e foundation forum][e-forum]


[fdroid-reset]: https://github.com/lineageos4microg/android_prebuilts_prebuiltapks/issues/8#issuecomment-453854227
[aurora-store]: https://gitlab.com/AuroraOSS/AuroraStore
[fdroid-repos]: https://github.com/Suicide-Squirrel/android_vendor_fdroid/blob/eos/extra/additional_repos.xml
[e-forum]: https://community.e.foundation/
[docker-guide]: https://community.e.foundation/t/howto-build-e/
[release-branches]: https://gitlab.e.foundation/e/os/releases/-/branches
[release-tags]: https://gitlab.e.foundation/e/os/releases/-/tags
[release-types]: https://doc.e.foundation/build-status
[customOTA]: https://community.e.foundation/t/howto-create-your-custom-ota-server/19154
[vendorsetup]: vendorsetup.sh
[signature-spoofing]: https://github.com/microg/android_packages_apps_GmsCore/wiki/Signature-Spoofing
[microg]: https://microg.org/
[signature-spoofing-patches]: src/signature_spoofing_patches/
[blobs-pull]: https://wiki.lineageos.org/devices/bacon/build#extract-proprietary-blobs
[blobs-extract]: https://wiki.lineageos.org/extracting_blobs_from_zips.html
[blobs-themuppets]: https://github.com/TheMuppets/manifests
