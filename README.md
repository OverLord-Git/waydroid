# Mega Waydroid Installer Supreme

[![GitHub Stars](https://img.shields.io/github/stars/yourusername/mega-waydroid-installer)](https://github.com/yourusername/mega-waydroid-installer/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/yourusername/mega-waydroid-installer)](https://github.com/yourusername/mega-waydroid-installer/issues)
[![GitHub License](https://img.shields.io/github/license/yourusername/mega-waydroid-installer)](https://github.com/yourusername/mega-waydroid-installer/blob/main/LICENSE)
[![Bash Version](https://img.shields.io/badge/bash-5+-brightgreen)](https://www.gnu.org/software/bash/)
[![Downloads](https://img.shields.io/github/downloads/yourusername/mega-waydroid-installer/total)](https://github.com/yourusername/mega-waydroid-installer/releases)

A comprehensive Bash script for installing Waydroid (Android in Linux containers) across multiple distributions. It automates kernel configuration, dependency installation, and advanced features like Android TV support, making Android emulation seamless and customizable.

## Motivation

Waydroid brings Android apps to Linux desktops and servers, but installation varies by distribution and often requires manual tweaks. This script unifies the process, handling edge cases like minimalistic distros (e.g., Alpine, KISS) and specialized setups (e.g., Steam Deck, ChromeOS). It's built with best practices: modular code, error handling, logging, and user-friendly prompts.

## Features

- **Multi-Distribution Support**: Covers 15+ distros with tailored installation methods.
- **Android TV Mode**: Optimized images with VA-API hardware acceleration and Widevine DRM for streaming.
- **Modern Container Options**: Distrobox + Podman for rootless, GPU-accelerated setups.
- **Legacy Alternative**: Anbox for older systems or compatibility.
- **musl libc Compatibility**: Automatic gcompat for Alpine to handle glibc-dependent apps.
- **Kernel Verification**: Checks and installs DKMS modules for binder/ashmem.
- **Post-Installation Tools**: scrcpy for remote control, backups, ARM translation, GPU tweaks.
- **Fallbacks**: Flatpak/Snap if native packages fail; X11 fallback for display issues.
- **Logging & README**: Detailed logs and dynamic README for easy troubleshooting.
- **Cleanup**: Optional removal of temporary files after installation.

## Supported Distributions

| Distribution | Method | Key Features |
|--------------|--------|--------------|
| Ubuntu/Debian | Official repo + curl | Virtualisation, Flatpak fallback |
| Arch Linux | iEscapedVim installer | AUR integration |
| SteamOS (Deck) | ryanrudolfoba script | Game Mode support |
| WSL2 | Custom kernel build | .wslconfig + vhdx modules |
| openSUSE | Runa-Chin repo | AppArmor tweaks |
| NixOS | Declarative config | Official module |
| Gentoo | Emerge portage | Kernel config check |
| ChromeOS (Crostini/Flex) | supechicken kernel + LXD | Crosh automation |
| Void Linux | XBPS packages | runit/OpenRC support |
| KISS Linux | Source compile | Kiss build system |
| Fedora (Silverblue) | rpm-ostree + DNF | Immutable system support |
| Alpine Linux | APK + source compile | musl libc + gcompat |
| Distrobox | Podman OCI containers | Rootless, GPU passthrough |
| Anbox (Legacy) | DKMS modules | Alternative for old hardware |
| Universal Fallback | n1lby73 installer | For unsupported distros |

## Prerequisites

- Bash 5+ (check with `bash --version`).
- Root access (sudo).
- Internet connection for downloads/clones.
- 10GB+ free disk space.
- Kernel with CONFIG_ASHMEM and CONFIG_ANDROID_BINDERFS (script checks and installs DKMS if possible).
- For musl-based distros (e.g., Alpine): gcompat is automatically installed.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mega-waydroid-installer.git
   cd mega-waydroid-installer
   ```

2. Make the script executable:
   ```bash
   chmod +x mega_waydroid_installer_supreme.sh
   ```

3. Run the script:
   ```bash
   sudo ./mega_waydroid_installer_supreme.sh
   ```

The script detects your distro and suggests the best option. Select from the menu or use the fallback.

## Usage Example

After installation:
- Start Waydroid: `waydroid session start`
- Show full UI: `waydroid show-full-ui`
- Install APK: `waydroid app install path/to/app.apk`
- Remote control: `scrcpy` (if installed via post-menu)
- Backup: `./waybak backup /var/lib/waydroid`

For Distrobox mode:
- Enter container: `distrobox enter --root waydroid-box`
- Start session: `waydroid session start`

Logs are in `/var/log/waydroid_install.log`. A custom README is generated at `~/waydroid_setup_readme.md`.

## Screenshots

![Waydroid Running on Ubuntu](https://placehold.co/600x400?text=Waydroid+on+Ubuntu&font=roboto)  
*Waydroid full UI on Ubuntu with Android TV mode.*

![Distrobox Integration](https://placehold.co/600x400?text=Distrobox+Setup&font=roboto)  
*Distrobox container with exported apps.*

(Replace placeholders with actual screenshots from your tests.)

## Contributing

Contributions welcome! Follow these steps:
1. Fork the repo.
2. Create a branch (`git checkout -b feature/awesome-addition`).
3. Commit changes (`git commit -am "Add awesome feature"`).
4. Push (`git push origin feature/awesome-addition`).
5. Open a Pull Request.

Please adhere to Bash best practices: Use `set -euo pipefail`, comment code blocks, and test on multiple distros.

## License

[MIT License](LICENSE) - Feel free to use, modify, and distribute.

## Acknowledgments

- Waydroid Team for the core project.
- supechicken for Android TV builds and ChromeOS tools.
- n1lby73 for universal fallback.
- ublue-os for Distrobox images.
- Anbox Team for legacy support.

Star the repo if it helped! Questions? Open an issue.
