# rz-build-scripts
Build scripts for rz projects

This repo holds build scripts that download, assemble and build rz projects.

## JQuerry

This script uses jqerry open source project to manage off tree patching (https://jqlang.github.io/jq/).

## Patching

The general idea is to avoid patches and keep things within the repositories.
In some cases release builds need specific tweaks to work with the infrastructure or environement.
In some cases we have to patch a third party repository.
In such rare cases, patches are held here and applied during build.

## Patch Management Feature

The build script includes functionality to detect and apply new patches as they are added. This allows the script to adapt to evolving project needs without manual intervention for each build. This feature is designed to ensure that any necessary fixes or updates are automatically integrated, keeping the build process efficient and up to date.

## Hierarchy

```
├── README.md
└── rz-sbc
    ├── git_patch.json
    ├── jq-linux-amd64
    ├── patches
    │   ├── meta-summit-radio
    │   │   └── 0001-rzsbc-summit-radio-pre-3.4-support-eSDK-build.patch
    │   └── poky
    │       └── 0001-meta-classes-esdk-explicitly-address-the-location-of.patch
    ├── README.md
    ├── rzsbc_yocto.sh
    └── site.conf

4 directories, 8 files
```

