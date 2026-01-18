# Windows Segment Heap Optimizer

🚀 What's New in v1.2.1
🛡️ Compatibility Shield (IFEO Exclusion)
Added a dedicated module to prevent specific applications from using Segment Heap optimization. This is necessary to resolve potential stability issues, performance regressions, or crashes while maintaining system-wide memory efficiency.

Dynamic Table: Instant visual feedback. Newly added or removed applications appear immediately in the console table.

Smart Input Cleaning: Automatic extraction of executable names from paths and removal of quotes to ensure registry integrity.

Dual-Architecture Support: Exclusions are automatically applied to both 64-bit and 32-bit (Wow6432Node) registry hives.

Technical Description: Integrated as "Compatibility shield to fix app bugs or performance drops."

📊 Professional UI Restoration
Full restoration of the high-detail menu including hardware recommendations (e.g., 32GB+ RAM) and specific commit values.

Fixed-width table formatting for professional terminal rendering.

📅 Version History (Changelog)
## What's New in v1.1 (Reference Base)
Ultimate Expert Core: Implementation of the high-performance memory management engine.

4-Tier Optimization:

Ultimate: 32KiB Commit | 32KiB Threshold (32GB+ RAM).

Optimized: 16KiB Commit | 32KiB Threshold (16-32GB RAM).

Standard: 16KiB Commit | 64KiB Threshold (16GB RAM).

Lite: 8KiB Commit | 64KiB Threshold (4-16GB RAM).

Automated Safety: Systematic .reg backup before any modification.

Admin Auto-Elevation: Forced Administrator privileges for registry write access.


🎨 Professional Expert UI
Metrium987 Visual Identity: Implementation of the color-coded console interface (Green/Yellow/Red).

Technical Transparency: Display of exact hex values and hardware recommendations for every profile.

# Windows Segment Heap Optimizer

Developed by **METAPLAYER987**

A powerful PowerShell utility designed to fine-tune the Windows Segment Heap for gamers and power users. This tool helps improve FPS stability, reduce micro-stutters (0.1% lows), and optimize memory management on Windows 10 and 11.

## 🚀 Features

- **Automated Profiles**: 4 pre-configured profiles based on your RAM and CPU power.
- **Expert Mode**: Full manual control over Heap parameters (Commit, Reserve, Thresholds).
- **Safety First**: Every modification prompts for a registry backup (.reg) and final confirmation.
- **Visual Interface**: Clean, color-coded Command Line Interface (CLI).
- **No Dependencies**: Pure PowerShell script, no external installation required.

## 📊 Optimization Profiles

| Profile | Target Hardware | Technical Impact |
| :--- | :--- | :--- |
| **Ultimate** | 32GB+ RAM / High-End CPU | 32KiB Commit / 32KiB Threshold (Extreme) |
| **Optimized Standard** | 16-32GB RAM / Mid-High CPU | 16KiB Commit / 32KiB Threshold (Recommended) |
| **Standard** | 16GB RAM / Mid-Range CPU | 16KiB Commit / 64KiB Threshold (Stable) |
| **Lite** | 4-16GB RAM / Low-End CPU | 8KiB Commit / 64KiB Threshold (Safe) |
| **Factory** | Any System | Restores Windows default values |

## 🛠️ How to Use

1. Download the `HeapOptimizer.ps1` file.
2. Right-click the file and select **"Run with PowerShell"**. 
   *(Win11 users: click "Show more options" to see this. Alternatively, drag and drop the file into an Admin PowerShell window).*
3. The script will automatically ask for Administrator privileges.
4. Follow the on-screen instructions to select your profile or enter Expert Mode.
5. **Reboot your computer** after applying changes to take full effect.

## ⚠️ Disclaimer

This tool modifies system registry settings. While it includes safety backups and has been tested, use it at your own risk. **METAPLAYER987** is not responsible for any system instability or data loss. Always create a backup when prompted.

## 💻 Compatibility

- **OS**: Windows 10 (all versions) & Windows 11.
- **Architecture**: x64 / ARM64.
- *Note: Not compatible with Windows 7 or 8.1.*

---

*Optimized for performance by METAPLAYER987*

