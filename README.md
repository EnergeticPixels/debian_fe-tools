# My Windows 11 WSL/Debian 13

## Used for Front-End Video, Images, etc development

### Constraints
This repo is targeted for Windows 11 host with WSL2 and Debian (Trixie) distribution.
If you are working in a git repo, you will either need to setup git scm yourself or it should have been setup in a previous server side process.
This repo does not include any advanced text editor setup. If you need this ability, either set it up manually or it should be included in a previous server setup process. 

### Pre-Provisioning Steps
Since security is a big thing in modern times, you will need to accomplish the following steps before setting this repo into automatic provisioning a brand new Linux setup.
1. Update/upgrade the system
```bash
sudo apt update
```

### To begin:
1. Download a .zip copy of this repo.
2. Extract the contents of the .zip into a temporary folder in your home directory.
3. Change to that temporary folder.
4. Change the filename of .env.sample to .env
5. Edit the properties to your liking. Then:
```bash
sudo bash begin_here.sh
```
### Provision front-end creative apps
Front-end creative tooling is optional and can be enabled per app during provisioning.

Set these in `.env`:
- `INKSCAPE_ENABLE=true` to install Inkscape
- `GIMP_ENABLE=true` to install GIMP
- `BLENDER_ENABLE=true` to install Blender
- `AUDACITY_ENABLE=true` to install Audacity
- `VIDEO_EDITOR=none|openshot` to choose a video editor

Behavior details:
- Installers are non-interactive and `.env` driven
- `VIDEO_EDITOR=openshot` installs `openshot-qt` from apt
- Lowercase compatibility keys (`inkscape_enable`, `gimp_enable`, `blender_enable`, `audacity_enable`, `video_editor`) are accepted

> **DaVinci Resolve (advanced / manual):** DaVinci Resolve is not included in automated provisioning due to the significant pre-setup required: NVIDIA GPU drivers, a free site registration at [Blackmagic Design](https://www.blackmagicdesign.com/), and a ~3.6 GB Linux installer download. If you want to install it manually, see [DAVINCI_RESOLVE_MANUAL_INSTALL.md](DAVINCI_RESOLVE_MANUAL_INSTALL.md) at the root of this project.

Run front-end creative app setup only:

```bash
sudo bash scripts/frontend_apps_install.sh
```
