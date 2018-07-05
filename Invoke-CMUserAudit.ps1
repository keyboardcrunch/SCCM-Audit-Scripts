<#
    .SYNOPSIS
        Script to list users and administrators configured in SCCM with the ability to detect changes.

    .DESCRIPTION
        Script to list users and administrators configured in SCCM with the ability to detect changes.

    .PARAMETER test
        Optional. Used with -profile to only list existing users but not save to db.

    .PARAMETER verbose
        Optional. Include console output.

    .PARAMETER profile
        Optional. Saves users and administrators currently in SCCM into a json file.

    .PARAMETER email
        Optional. Used for scheduled task alerting to send emails when changes are detected.

    .EXAMPLE
        List all users/administators currently in SCCM.
        Invoke-CMUserAudit.ps1 -profile -test

    .EXAMPLE
        Snapshot user/administrators in SCCM to json file.
        Invoke-CMUserAudit.ps1 -profile

    .EXAMPLE
        Check for changes and send email alert if changes are detected.
        Invoke-CMUserAudit.ps1 -email

    .EXAMPLE
        Check for changes and write to console.
        Invoke-CMUserAudit.ps1 -verbose

    .NOTES
        File Name: Invoke-CMUserAudit.ps1
        Author: keyboardcrunch
        Date Created: 19/03/18
#>

param(
    [switch]$test,
    [switch]$verbose,
    [switch]$profile,
    [switch]$email
)

# Load ConfigMan modules and CD to site path
Import-Module ($env:SMS_ADMIN_UI_PATH.Substring(0,$env:SMS_ADMIN_UI_PATH.Length – 5) + '\ConfigurationManager.psd1')
Set-Location WPS:

$email_from = "SOC@corp.com"
$email_to = "SOC@corp.com"
$email_server = "mail.corp.com"
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

function ProfileAccounts {
    $Admins = Get-CMAdministrativeUser
    $Users  = Get-CMAccount
    [hashtable]$CMAccounts = @{}
    $CMAccounts.Admins = $Admins.LogonName
    $CMAccounts.Users  = $Users.UserName
    If ( $verbose ) {
        $CMAccounts | ConvertTo-Json
    }
    If ($test) {
        $CMAccounts | ConvertTo-Json
    } Else {
        $CMAccounts | ConvertTo-Json | Out-File -FilePath "$ScriptDir\CMAccounts.json"
    }
}

function AuditAccounts {
    $AuditFailed = 0
    If ($verbose) { Write-Host "Loading data for audits..." -ForegroundColor Yellow }
    $DB = Get-Content -Path "$ScriptDir\CMAccounts.json"
    $DB = $DB | ConvertFrom-Json
    $DBAdmins = $DB.Admins
    $DBUsers  = $DB.Users
    $Admins   = Get-CMAdministrativeUser
    $Users    = Get-CMAccount
    $NewAdmins = New-Object System.Collections.Generic.List[System.Object]
    $NewUsers  = New-Object System.Collections.Generic.List[System.Object]

    # RUN THROUGH ADMINISTRATOR ACCOUNTS
    If ($verbose) { Write-Host "Auditing administrator accounts..." -ForegroundColor Yellow }
    ForEach ( $a in $Admins ) {
        If ( -not ( $DBAdmins -contains $a.LogonName ) ) {
            $un = $a.LogonName
            if ($verbose) {
                Write-Host "`tNEW ADMIN: $un" -ForegroundColor Red
            }
            $NewAdmins.Add($un)
            $AuditFailed++
        }
    }

    # RUN THROUGH USER ACCOUNTS
    If ($verbose) { Write-Host "Auditing administrator accounts..." -ForegroundColor Yellow }
    ForEach ( $u in $Users ) {
        If ( -not ( $DBUsers -contains $u.UserName ) ) {
            $un = $u.UserName
            if ($verbose) {
                Write-Host "`tNEW USER: $un" -ForegroundColor  Red
            }
            $NewUsers.Add($un)
            $AuditFailed++
        }
    }

    # THERE ARE AUDIT FINDINGS - LIST OR EMAIL THEM
    If ( $AuditFailed -gt 0 ) {
        If ($verbose) {
            Write-Host "$AuditFailed account changes detected!" -ForegroundColor Red
        }
        If ($email) {
            $Message = "Admin changes `r`n$NewAdmins`r`n`nUser changes`r`n$NewUsers"
            Send-MailMessage -To $email_to -From $email_from -Subject "SCCM Account Audit" -Body $Message -SmtpServer $email_server
        }
    }
}

# SCRIPT ARGUMENT HANDLING
If ($profile) {
    ProfileAccounts
} Else {
    AuditAccounts
}

C: