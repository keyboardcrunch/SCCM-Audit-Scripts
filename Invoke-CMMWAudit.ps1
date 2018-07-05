<#
    .SYNOPSIS
        Combs through SCCM looking for collections with maintenance windows, saves them to a log.

    .DESCRIPTION
        Combs through SCCM looking for collections with maintenance windows, saves them to a log.

    .PARAMETER path
        Optional. Define path to save log file.

    .EXAMPLE
        Invoke-CMAuditMaintWindows.ps1

    .EXAMPLE
        Invoke-CMAuditMaintWindows.ps1 -path C:\Users\ninja\

    .NOTES
        File Name: Invoke-CMAuditMaintWindows.ps1
        Author: keyboardcrunch
        Date Created: 28/02/18
#>

param (
    [string]$path
)

# Load ConfigMan modules and CD to site path
Import-Module ($env:SMS_ADMIN_UI_PATH.Substring(0,$env:SMS_ADMIN_UI_PATH.Length – 5) + '\ConfigurationManager.psd1')
Set-Location WPS:

$LogName = "CMCollectionAudit.log"
If ($path) { # Log path defined by user
    If (Test-Path $path) { # Test path exists
        $LogPath = $path
    } Else { # Path doesn't exist, using script directory
        $LogPath = Split-Path $script:MyInvocation.MyCommand.Path
    }
} Else { # No log path defined, using script directory
    $LogPath = Split-Path $script:MyInvocation.MyCommand.Path
}
$LogFile = "$LogPath\$LogName"

# diddle a lot start entry w/ timestamp
$date = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
"---------------------  Script started at $date (DD-MM-YYYY hh:mm:ss) ----------------------" + "`r`n" | Out-File $LogFile -append

Write-Host "Getting list of collections. Please Wait." -ForegroundColor Green
$CollectionIDs = Get-CMCollection | Select CollectionID
$ColCount = $CollectionIDs.Count
Write-Host "$ColCount collections to analyze.`n" -ForegroundColor Green
$prog = 0

foreach ($CollectionID in $CollectionIDs) {
    $Collection = $CollectionID.CollectionID
    $MaintWind = Get-CMMaintenanceWindow -CollectionID $Collection
    # If $MaintWind is set then log it
    if ($MaintWind) {
        $CollectionName = Get-CMCollection -CollectionID $Collection
        $Name = $CollectionName.Name
        Write-Host "$Collection - $Name" -ForegroundColor Yellow
        "$Collection - $Name`r`n" | Out-File $LogFile -Append
    }
    Write-Progress -Activity "Auditing Collections" -Status "Progress:" -PercentComplete ($prog/$ColCount*100)
    $prog = $prog + 1
}

Write-Host "$ColCount collections analyzed."
$date = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
"---------------------  Script finished at $date (DD-MM-YYYY hh:mm:ss) ---------------------" + "`r`n" | Out-File $LogFile -append