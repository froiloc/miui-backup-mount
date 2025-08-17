# MIUI Backup Mount Utility
![Bash Version](https://img.shields.io/badge/Bash-5.x%2B-blue)
![License](https://img.shields.io/badge/License-GPLv3-green)
![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)
![Version](https://img.shields.io/github/v/release/froiloc/miui-backup-mount)

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
sudo curl -LO https://raw.githubusercontent.com/foiloc/miui-backup-utils/main/miui-backup-mount.sh
sudo chmod +x miui-backup-mount.sh
```
### Clone repository via Git
```bash
git clone https://github.com/foiloc/miui-backup-utils.git
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
|  Package     | Debian/Ubuntu | Arch Linux   | Notes       | Purpose
|--------------|---------------|--------------|-------------|-----------------------------
| Core         | util-linux    | util-linux   | Required    | Provides losetup command
| FUSE         | fuse          | fuse2        | Required    |
| archivemount | archivemount  | archivemount | Recommended | For best mounting experience

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
**Q:** Why use this instead of just extracting the .bak file? \
**A:** Saves storage space and allows direct access to large backups without duplication.

**Q:** The script says "Failed to create loop device" - what now? \
**A:** Try:
```bash
sudo modprobe loop  # Load kernel module
losetup -f          # Check available loop devices
```
If issues persist,
[open an issue](https://github.com/froiloc/miui-backup-mount/issues) with your `lsmod` output.

# 🛡 Security
- Runs with minimal sudo privileges (only for losetup)

- Automatic cleanup on script exit

- Filesystem operations are read-only by default

> 🔒 **Security Tip**: Always **unmount** after use to prevent accidental modifications.

# 🤝 Contributing
- Pull requests welcome! Please:
- Follow existing code style
- Add tests for new features
- Update documentation

# 📜 License
GPLv3 - See LICENSE for details.

> 💡  **Pro Tip**: Combine with  ```rclone mount``` for network-accessible backups!

