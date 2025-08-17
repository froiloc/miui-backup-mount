# MIUI Backup Mount Utility
![Bash Version](https://img.shields.io/badge/Bash-5.x%2B-blue)
![License](https://img.shields.io/badge/License-GPLv3-green)
![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)

Mount MIUI `.bak` backup files as virtual filesystems without extraction - perfect for inspecting or recovering data while saving storage space.

## 📦 Features
- **Zero-storage mounting** - Access backup contents without temporary files
- **Smart detection** - Auto-finds tar archive offset in MIUI backup files
- **Dual-mode access**
  - `archivemount` for transparent file access (recommended)
  - Fallback to `tar` for basic operations
- **Safety first**
  - Read-only by default
  - Conflict detection for mounted filesystems
  - Clean resource cleanup

## 🛠  Installation
### Direct Download 
```bash
curl -LO https://raw.githubusercontent.com/<your-username>/miui-backup-utils/main/miui-backup-mount.sh
chmod +x miui-backup-mount.sh
```
### Clone repository via Git
```bash
git clone https://github.com/<your-username>/miui-backup-utils.git
cd miui-backup-utils
```
# 📖 Basic Usage
```bash
# Mount a backup
./miui-backup-mount.sh mount backup.bak [custom_mountpoint]

# Unmount
./miui-backup-mount.sh unmount backup.bak

# Check version
./miui-backup-mount.sh version
```
# 🔧 Dependencies
|  Package     | Debian/Ubuntu | Arch Linux   | Notes
|--------------|---------------|--------------|--------
| Core         | util-linux    | util-linux   | Required
| FUSE         | fuse          | fuse2        | Required
| archivemount | archivemount  | archivemount | Recommended

Install with:

```bash
# Debian/Ubuntu
sudo apt install archivemount util-linux fuse

# Arch Linux
sudo pacman -S archivemount util-linux fuse2
```
# 🌟 Advanced Features
### Environment Variables
```bash
# Adjust header detection (default: 257)
# distance between tar start and tar magic string "ustar"
PREMAGIC_SIZE=300 ./miui-backup-mount.sh mount backup.bak

# Disable colors
NO_COLOR=1 ./miui-backup-mount.sh mount backup.bak

# Debug mode
DEBUG=1 ./miui-backup-mount.sh mount backup.bak
```
# ❓ FAQ
:**Q:** Why use this instead of just extracting the .bak file?
:**A:** Saves storage space and allows direct access to large backups without duplication.

:**Q:** The script says "Failed to create loop device" - what now?
:**A:** Try:
```bash
sudo modprobe loop  # Load kernel module
losetup -f          # Check available loop devices
```

# 🛡  Security
Runs with minimal sudo privileges (only for losetup)

Automatic cleanup on script exit

Filesystem operations are read-only by default

# 🤝 Contributing
- Pull requests welcome! Please:
- Follow existing code style
- Add tests for new features
- Update documentation

# 📜 License
GPLv3 - See LICENSE for details.

> 💡  **Pro Tip**: Combine with  ```rclone mount``` for network-accessible backups!


### How This Renders on GitHub:
![README Preview](https://user-images.githubusercontent.com/158189/199689681-5e8a3b1a-5d9a-4f1e-8f8d-3e5e5f3e3c7a.png)

