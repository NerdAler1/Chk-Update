# Simple Powershell script to check any laptop for 16GB of RAM and >65% battery health remaining.
# Created by Jack Thiess

# Check RAM Capacity
$ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory
$totalRAMGB = [math]::Round(($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
Clear-Host

Write-Host "Total Installed RAM: $totalRAMGB GB"
if ($totalRAMGB -lt 16) {
    Write-Host "RAM below 16GB!" -ForegroundColor Red
} elseif ($totalRAMGB -eq 16) {
    Write-Host "RAM is 16GB!" -ForegroundColor Green
} elseif ($totalRAMGB -gt 16) {
    Write-Host "RAM is more than 16GB!" -ForegroundColor Yellow
}

# Generate battery report
$batteryReportPath = "$env:TEMP\battery-report.html"
Write-Host "Generating battery report..."
powercfg /batteryreport /output "$batteryReportPath" | Out-Null
Start-Sleep -Seconds 2

# Check battery report
if (Test-Path $batteryReportPath) {
    try {
        # Read the battery report HTML file
        $content = Get-Content $batteryReportPath -Raw
        
        # Extract Full Charge Capacity
        $fullChargePattern = '<span class="label">FULL CHARGE CAPACITY</span></td><td>([0-9,]+)\s+mWh'
        $fullChargeMatch = [regex]::Match($content, $fullChargePattern)
        
        # Extract Design Capacity
        $designPattern = '<span class="label">DESIGN CAPACITY</span></td><td>([0-9,]+)\s+mWh'
        $designMatch = [regex]::Match($content, $designPattern)
        
        if ($fullChargeMatch.Success -and $designMatch.Success) {
            $fullChargeCapacity = [int]($fullChargeMatch.Groups[1].Value -replace ',', '')
            $designCapacity = [int]($designMatch.Groups[1].Value -replace ',', '')
            
            # Calculate battery health percentage
            $batteryHealth = [math]::Round(($fullChargeCapacity / $designCapacity) * 100, 2)
            
            # Display Battery Health
            if ($batteryHealth -lt 65) {
                Write-Host "Battery health is below 65% - Replace Battery! ($batteryHealth%)" -ForegroundColor Red
            } else {
                Write-Host "Battery health is good! ($batteryHealth%)" -ForegroundColor Green
            }
        } else {
            Write-Warning "Could not extract battery capacity information from report"
        }
    }
    catch {
        Write-Warning "Error reading battery report: $($_.Exception.Message)"
    }
} else {
    Write-Warning "Battery report could not be generated. This may not be a laptop or battery information is unavailable."
}

# Launch Windows Update
Read-Host -Prompt "Press Enter to open Windows Update..."
Start-Process "ms-settings:windowsupdate"