# Windows Security Audit & Surgical Recovery Tool
> ⚠️ **Project Status & Disclaimer:** This project is actively maintained and updated by the author. However, the software is provided **"AS-IS"** without any warranties. You are running this script entirely at your own risk. The author is not responsible for any system damage or data loss. Always test in a Virtual Machine first!
⚠️ DO NOT copy-paste the raw code lines directly into an open CMD window. Always save the code as a .bat file and run it by double-clicking, otherwise the registry percentage escaping will corrupt your system binary execution logic!
> 
A transparent, open-source Windows batch (`.bat`) script designed for deep system diagnostics, critical registry auditing, and surgical recovery of corrupted or malware-compromised system components.

## Core Features

### 1. Security Audit & Intelligence (Mode 1)
* **System Hijack Detection:** Audits *Image File Execution Options (IFEO)*, *SilentProcessExit*, and *Winlogon* registry branches for unauthorized overrides.
* **Persistence Check:** Maps out startup items (*Run/RunOnce* keys), scheduled jobs, and monitors the integrity of the `hosts` file.
* **Process Mapping:** Searches for suspicious active processes running directly out of temporary folders (`AppData`, `Temp`).
* **Automated Logging:** Saves all diagnostic output cleanly into a `Registry_Audit.txt` report generated on your desktop.

### 2. Surgical Recovery & Resuscitation (Mode 2)
* **Shell Rescue:** Restores default factory configurations for `explorer.exe` and `userinit.exe`.
* **Binary Association Fix:** Resets core low-level file associations (`.exe`, `.com`, `.pif`) ensuring programs can execute properly.
* **Policy & Admin Tool Unlocker:** Reverts malicious registry restrictions, repairs UAC settings, and unlocks administrative tools like *CMD*, *Regedit*, and *Task Manager*.
* **Security & Defender Restoration:** Resets Windows Defender and Windows Firewall policies to default, triggering a forced restart of essential defense services.
* **Boot & Update Repair:** Resuscitates corrupted Windows Update components, clears download caches, and runs an automated boot file repair via `BCDBOOT`.

### 3. Extended Repair Toolbar (Interactive Menu)
* **Network Repair:** Flushes DNS cache, registers DNS records, and completely resets the Winsock stack and IP protocols to resolve connectivity issues.
* **Icon Cache Flusher:** Safely terminates `explorer.exe` to clear and rebuild broken, corrupted, or missing system desktop icons.
* **DLL Registration:** Performs a bulk re-registration of critical system `.dll` libraries via `regsvr32` to fix missing dependency errors.
* **UWP Application Fix:** Re-registers native Windows applications (such as the Start Menu and Settings App) globally using background PowerShell commands.
* **Disk Integrity (Chkdsk):** Schedules a rigorous deep-drive sector integrity check on the next system reboot.

## How to Run

1. Download the `.bat` file directly from this repository.
2. Right-click the file and select **Run as Administrator** (requires highest privileges).
3. Follow the on-screen prompts to select your mode, and let the tool do its work. A system reboot is highly recommended after completion.

---
*This tool is purely native, dependency-free, and open-source for 100% transparency.*
*You can freely modify, ship and use this product.*
