# 🧹 Windows Deep Clean

A PowerShell script that automates a complete system cleanup and optimization in a single run — no third-party tools required.

> Made by [@claraaraujodv](https://github.com/claraaraujodv)

---

## 📂 Available Scripts

| File | Description |
|------|-------------|
| `limpeza_profunda_windows10.ps1` | Optimized for PCs with 64GB RAM and SSD |
| `windows_deep_clean_universal.ps1` | **Recommended** — automatically detects your PC specs and adapts |

---

## ⚡ What it does

| Step | Action |
|------|--------|
| 1/8 | Removes 35+ pre-installed bloatware apps |
| 2/8 | Cleans temp files, cache, logs and Windows Update leftovers |
| 3/8 | Disables hibernation and adjusts virtual memory based on your RAM |
| 4/8 | Disables 25+ unnecessary background services |
| 5/8 | Blocks telemetry, Cortana, activity tracking and advertising |
| 6/8 | Applies CPU, animation and Game DVR performance tweaks |
| 7/8 | Cleans obsolete registry entries |
| 8/8 | Sets power plan based on your device (desktop or laptop) |

---

## 🤖 Universal Script — What it detects

The universal version automatically adapts to any PC:

| Detected | Behavior |
|----------|----------|
| **Laptop vs Desktop** | Laptop: keeps hibernation, geolocation and battery savings. Desktop: disables everything |
| **RAM amount** | < 8GB → automatic pagefile. 8GB → 8GB. 16GB → 4GB. 32GB+ → 2GB |
| **SSD vs HDD** | HDD: keeps SysMain active. SSD: disables it |
| **Fingerprint reader** | Keeps biometric service if a device is detected |
| **CPU cores** | Only boosts foreground priority on 4+ core systems |
| **Very low RAM (≤4GB)** | Disables all visual effects for maximum performance |
| **Power plan** | Laptop → Balanced. Desktop → High Performance |

---

## 🗑️ Bloatware removed

- Xbox, Xbox Live, Xbox Game Bar
- Cortana, Bing Weather, Bing News, Bing Finance
- Microsoft Teams, Skype, Your Phone
- OneNote, Mixed Reality, Groove Music
- Solitaire, 3D Viewer, Print 3D
- People, Maps, Feedback Hub, Get Help
- And more...

---

## 🔧 How to use

> ⚠️ **Important:** Windows blocks `.ps1` scripts by default. Follow the steps below to run correctly.

**Step 1 — Allow script execution (run once):**

Open PowerShell as Administrator and run:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Step 2 — Navigate to the script folder:**
```powershell
cd "C:\path\to\your\folder"
```

**Step 3 — Run the script:**
```powershell
.\windows_deep_clean_universal.ps1
```

**Step 4 — Restart your PC when done.**

> 💡 **Tip:** Always run via terminal so you can see the progress and any errors in real time. Do NOT just double-click the file — it will open and close instantly.

---

## 💻 Requirements

- Windows 10 or Windows 11 (64-bit)
- PowerShell 5.0 or higher
- Administrator privileges

---

## ⚠️ Disclaimer

Run at your own risk. It is recommended to **create a System Restore Point** before running any system optimization script.

To create a restore point:
> Control Panel → System → System Protection → Create

---

## 📄 License

MIT License — free to use, modify and share.
