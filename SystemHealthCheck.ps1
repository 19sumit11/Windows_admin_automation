<#
.SYNOPSIS
    Windows system health check - PowerShell equivalent of systemhealthcheck.sh.
.DESCRIPTION
    Collects CPU, memory, disk, top processes and network info,
    and saves them to a timestamped log file in .\logs
.EXAMPLE
    .\SystemHealthCheck.ps1
#>

$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$LogFile = Join-Path $LogDir ("health_{0}.log" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))

$report = & {
    "*************** Automated System Health Check Logs ***************"
    "Date: $(Get-Date)"
    "Host: $env:COMPUTERNAME   User: $env:USERNAME"

    "`n[UPTIME]"
    $os = Get-CimInstance Win32_OperatingSystem
    $up = (Get-Date) - $os.LastBootUpTime
    "Up {0} days, {1} hours, {2} minutes" -f $up.Days, $up.Hours, $up.Minutes

    "`n[CPU LOAD]"
    $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
    "Average CPU load: {0}%" -f [math]::Round($cpu.Average, 1)

    "`n[MEMORY USAGE]"
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedGB  = [math]::Round($totalGB - $freeGB, 2)
    "Total: $totalGB GB | Used: $usedGB GB | Free: $freeGB GB | Used%: $([math]::Round($usedGB / $totalGB * 100, 1))%"

    "`n[DISK USAGE]"
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object DeviceID,
            @{n="Size(GB)"; e={[math]::Round($_.Size / 1GB, 1)}},
            @{n="Free(GB)"; e={[math]::Round($_.FreeSpace / 1GB, 1)}},
            @{n="Used%";    e={[math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)}} |
        Format-Table -AutoSize | Out-String

    "`n[TOP 10 PROCESSES USING HIGH MEMORY]"
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Id, ProcessName,
        @{n="Mem(MB)"; e={[math]::Round($_.WorkingSet64 / 1MB, 1)}}, CPU |
        Format-Table -AutoSize | Out-String

    "`n[TOP 10 PROCESSES USING HIGH CPU]"
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Id, ProcessName,
        @{n="Mem(MB)"; e={[math]::Round($_.WorkingSet64 / 1MB, 1)}},
        @{n="CPU(s)";  e={[math]::Round($_.CPU, 1)}} |
        Format-Table -AutoSize | Out-String

    "`n[NETWORK - IP CONFIGURATION]"
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } |
        Select-Object InterfaceAlias,
            @{n="IPv4Address"; e={$_.IPv4Address.IPAddress -join ", "}},
            @{n="Gateway";     e={$_.IPv4DefaultGateway.NextHop -join ", "}},
            @{n="DNS";         e={$_.DNSServer.ServerAddresses -join ", "}} |
        Format-List | Out-String

    "`n[NETWORK - ROUTING TABLE]"
    route print -4

    "`n[NETWORK - ACTIVE CONNECTIONS (ESTABLISHED)]"
    Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
        Select-Object -First 15 LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess |
        Format-Table -AutoSize | Out-String

    "`n[CRITICAL SERVICES]"
    Get-Service -Name Spooler, W32Time, Dnscache, WinDefend -ErrorAction SilentlyContinue |
        Select-Object Name, Status, StartType | Format-Table -AutoSize | Out-String

    "`n***** Report Generated Successfully *****"
}

$report | Out-File -FilePath $LogFile -Encoding utf8
Write-Host "Health report saved successfully at: $LogFile"
