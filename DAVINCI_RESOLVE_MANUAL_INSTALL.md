Installing DaVinci Resolve on Debian 13
You can install DaVinci Resolve on Debian 13 (trixie) using the official installer or by converting it into a .deb package for easier integration. Here’s a step-by-step guide.

1. Prerequisites
Debian 13 (trixie) or later.

NVIDIA GPU (recommended for CUDA/OpenCL acceleration) with drivers installed.

At least 16 GB RAM (32 GB+ for 4K editing).

Free .zip installer from Blackmagic Design for Linux.

2. Install NVIDIA Drivers
DaVinci Resolve requires accelerated graphics. Install NVIDIA drivers from their repository:

curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb -o nvidia-keyring.deb
sudo dpkg -i nvidia-keyring.deb
echo "deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/ /" | sudo tee /etc/apt/sources.list.d/nvidia-drivers.list
sudo apt update
sudo apt install -y linux-headers-amd64 nvidia-driver nvidia-opencl-icd libcuda1
Also install OpenCL/CUDA tools:

sudo apt install -y ocl-icd-opencl-dev nvidia-cuda-toolkit libnvidia-encode1
Add your user to video and render groups:

sudo usermod -aG video,render $USER
crystallabs.io+1

3. Install Required Multimedia & Graphics Libraries
sudo apt install -y libgl1-mesa-dri libglib2.0-0 libxext6 libxrender1 libxi6 libsm6 libfontconfig1 libx11-6 libasound2 libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libav
These help with media import/export and GUI stability Position Is Everything.

4. Download and Prepare the Installer
Download the Linux .zip from Blackmagic.
Unzip:

cd ~/Downloads && unzip DaVinci_Resolve_XX.Y.Z_Linux.zip
You’ll have DaVinci_Resolve_XX.Y.Z_Linux.run.

5. Convert to Debian Package (Optional)
If you prefer a .deb:

Download the makeresolvedeb script from danieltufvesson.com matching your Resolve version.
Unpack and run:

tar -xvf makeresolvedeb_*.tar.gz
./makeresolvedeb_*.sh DaVinci_Resolve_XX.Y.Z_Linux.run
sudo dpkg -i davinci-resolve_XX.Y.Z-X_amd64.deb
sudo apt --fix-broken install -y
This avoids some dependency warnings Github+1.

6. Run DaVinci Resolve
From terminal:

/opt/resolve/bin/resolve
Or search for it in your applications menu.

7. High DPI Fix (if needed)
If UI elements are too small:

QT_AUTO_SCREEN_SCALE_FACTOR=1 QT_FONT_DPI=192 /opt/resolve/bin/resolve
crystallabs.io

8. Media Import/Export Notes
Free version doesn’t support .mp4 or AAC audio on Linux.

Convert media to supported formats (e.g., .mov, .mkv) before importing Github.

Tip: For Studio edition, you can install extras via the “Extras” menu, but some download links may fail on Debian crystallabs.io.

By following these steps, you’ll have DaVinci Resolve running smoothly on Debian 13 with GPU acceleration and proper media support.