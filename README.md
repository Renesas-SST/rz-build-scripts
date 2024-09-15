# rz-build-scripts
Build scripts for rz projects

This repo holds build scripts that download, assemble and build rz projects.

## JQuerry

This script uses jqerry open source project to manage off tree patching (https://jqlang.github.io/jq/).

## Patching

The general idea is to avoid patches and keep things within the repositories.
In some cases release builds need specific tweaks to work with the infrastructure or environement.
In some cases we have to patch a third party repository.
In such rare caes, patches are held here and applied during build.

## Hierarchy

```
.
├── README.md
└── rz-sbc
    ├── git_patch.json
    ├── jq-linux-amd64
    ├── patches
    │   ├── 0001-meta-classes-esdk-explicitly-address-the-location-of.patch
    │   └── 0001-rzsbc-summit-radio-pre-3.4-support-eSDK-build.patch
    ├── rzsbc_yocto.sh
    └── site.conf

3 directories, 7 files

```

