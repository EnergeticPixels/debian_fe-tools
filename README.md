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
- `VIDEO_EDITOR=none|openshot|davinci` to choose a video editor path

Behavior details:
- Installers are non-interactive and `.env` driven
- `VIDEO_EDITOR=openshot` installs `openshot-qt` from apt
- `VIDEO_EDITOR=davinci` attempts DaVinci Resolve installation from available community apt package sources
- If no DaVinci package source is available, the installer logs a clear skip message and continues
- Lowercase compatibility keys (`inkscape_enable`, `gimp_enable`, `blender_enable`, `audacity_enable`, `video_editor`) are accepted

Run front-end creative app setup only:

```bash
sudo bash scripts/frontend_apps_install.sh
```
