<#
    .SYNOPSIS
        Combs through SCCM looking for Applications and Packages with missing content folders, saves them to a log.

    .DESCRIPTION
        Combs through SCCM looking for Applications and Packages with missing content folders, saves them to a log.

    .PARAMETER path
        Optional. Define path to save log file.

    .EXAMPLE
        Invoke-CMFolderAudit.ps1

    .EXAMPLE
        Invoke-CMFolderAudit.ps1 -path C:\Users\ninja\

    .NOTES
        File Name: Invoke-CMFolderAudit.ps1
        Author: keyboardcrunch
        Date Created: 28/02/18
        Updated: 20/03/18
#>

param (
    [string]$path
)

# Load ConfigMan modules and CD to site path
Import-Module ($env:SMS_ADMIN_UI_PATH.Substring(0,$env:SMS_ADMIN_UI_PATH.Length – 5) + '\ConfigurationManager.psd1')
Set-Location WPS:


$LogName = "CMPathAudit.log"
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


# Grab the list of Packages
Write-Host "Starting package audit... Please wait." -ForegroundColor Green
"----------------------------  Packages missing source content ------------------------------" + "`r`n" | Out-File $LogFile -append
Foreach ($Package in Get-CMPackage) {
    $PackageName = $Package.Name
    $PackagePath = $Package.PkgSourcePath
    If ($PackagePath) { # Make sure value isn't empty
        If (-not(Test-Path $PackagePath)) {
            Write-Host "$PackageName missing source content."
            "$PackageName - $PackagePath`r`n" | Out-File $LogFile -append
        }
    }
}
"-------------------------------------------------------------------------------------------" + "`r`n" | Out-File $LogFile -append


# Grab the list of Applications
Write-Host "Starting application audit... Please wait." -ForegroundColor Green
"--------------------------  Applications missing source content ----------------------------" + "`r`n" | Out-File $LogFile -append
Foreach ($Application in Get-CMApplication) {
    $AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
    $AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title

    foreach ($DeploymentType in $AppMgmt.DeploymentType) {
        $AppData = @{ 
            AppName = $AppName
            Location = $DeploymentType.Installer.Contents.Content.Location
        }
        $ApplicationPath = $AppData.Location
        $ApplicationName = $AppData.AppName
        If ( $ApplicationPath ) { # Make sure value isn't empty
            If (-not(Test-Path $ApplicationPath)) {
                Write-Host "$ApplicationName missing source content."
                "$ApplicationName - $ApplicationPath`r`n" | Out-File $LogFile -append
            }
        }
    }
}
"-------------------------------------------------------------------------------------------" + "`r`n" | Out-File $LogFile -append

# Audit finished
$date = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
"---------------------  Script finished at $date (DD-MM-YYYY hh:mm:ss) ---------------------" + "`r`n" | Out-File $LogFile -append