# rz-sbc build package

This directory holds the automated build scripts that perform the rz yocto repository builds.

## Hierarchy

```
.
├── git_patch.json
├── jq-linux-amd64
├── patches
│   ├── 0001-meta-classes-esdk-explicitly-address-the-location-of.patch
│   └── 0001-rzsbc-summit-radio-pre-3.4-support-eSDK-build.patch
├── rzsbc_yocto.sh
└── site.conf

2 directories, 6 files

``` 

## Organization:

| File           | Description                                            |
|---------------|-------------------------------------|
| git_patch.json | contains json keys and list of patchfiles to apply.|
| jq-linux-amd64 | json querry oss binary to perform reads of git_patch.json from shell script. |
| patches/       | folder containing patches. This should ideally be organized into sub directories named after the json key |
| rzsbc_yocto.sh | main build script that performs setup, configure and build operations. |
| site.conf      | An over-riding site.conf. This file is used as an override and replaces the default site.conf from the meta template. This is to force specific tags or commits in the build.|
