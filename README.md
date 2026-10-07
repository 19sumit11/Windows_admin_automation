# Windows Admin Automation

A PowerShell script that checks the health of a Windows machine and saves the results to a timestamped log file. It helps service desk and system administrators quickly see whether a system is healthy, and find what is slowing it down.

## Project Structure
```
Windows_admin_automation/
├── SystemHealthCheck.ps1   # Main script
├── README.md               # Documentation
└── logs/                   # Reports are created here automatically
```

## How to Run
```powershell
cd D:\SUMIT\Windows_admin_automation
Set-ExecutionPolicy -Scope Process Bypass
.\SystemHealthCheck.ps1
```
Each run creates a new report, for example `logs\health_2026-10-07_10-30-15.log`.

## What the Script Checks

| # | Section | What it checks | Why it matters |
|---|---|---|---|
| 1 | **Header** | Date, computer name and logged-in user | Identifies which machine and when the report was taken |
| 2 | **Uptime** | Time since the last restart | A very long uptime can mean pending updates or slowness; a short one can mean unexpected reboots |
| 3 | **CPU Load** | Average processor usage in % | A consistently high value (above 85–90%) points to a performance problem |
| 4 | **Memory Usage** | Total, used and free RAM in GB, and used % | Low free memory makes the system slow and applications freeze |
| 5 | **Disk Usage** | Size, free space and used % for each drive | A nearly full drive (above 90%) can stop updates, logging and applications |
| 6 | **Top 10 Processes by Memory** | The ten processes using the most RAM | Finds the application causing high memory use |
| 7 | **Top 10 Processes by CPU** | The ten processes that have used the most CPU time | Finds the application causing high CPU use |
| 8 | **Network: IP Configuration** | Adapter name, IPv4 address, default gateway and DNS servers | Confirms the machine has a valid network setup |
| 9 | **Network: Routing Table** | How network traffic is routed | Helps diagnose "no internet" or wrong-gateway issues |
| 10 | **Network: Active Connections** | The first 15 established TCP connections, with remote address, port and process ID | Shows what the machine is talking to and spots unusual connections |
| 11 | **Critical Services** | Status of Print Spooler, Windows Time, DNS Client and Windows Defender | Shows whether key services are running or stopped |

## Sample Output
```
*************** Automated System Health Check Logs ***************
Date: 10/07/2026 10:30:15
Host: LAPTOP01   User: sumit

[UPTIME]
Up 2 days, 4 hours, 12 minutes

[CPU LOAD]
Average CPU load: 18%

[MEMORY USAGE]
Total: 15.7 GB | Used: 9.4 GB | Free: 6.3 GB | Used%: 59.9%

[DISK USAGE]
DeviceID Size(GB) Free(GB) Used%
C:          475.0    210.3  55.7
```

## Troubleshooting With This Report
| Symptom reported by user | Section to check |
|---|---|
| "My laptop is slow" | CPU Load, Memory Usage, Top 10 Processes |
| "Cannot save files / updates fail" | Disk Usage |
| "No internet" | IP Configuration, Routing Table |
| "Cannot print" | Critical Services (Print Spooler) |
| "Time or login problems" | Critical Services (Windows Time) |

## Requirements
- Windows 10 / 11 or Windows Server
- PowerShell 5.1 or later
- Some details may need "Run as administrator"

## Planned Additions
1. `DiskCleanup.ps1`: delete temporary files older than N days
2. `ServiceMonitor.ps1`: restart a service if it has stopped
3. `UserAudit.ps1`: list local users and their last logon
4. Daily scheduled run using Task Scheduler
