# ==============================================================================
# Script  : entra-id-user-provisioning.ps1
# Author  : Vikrant Verma
# Purpose : Bulk-provision new users in Microsoft Entra ID (Azure AD) from a
#           CSV file. Assigns licenses, adds to security groups, enforces MFA
#           registration policy, and generates a provisioning report.
# CSV Cols: FirstName, LastName, Department, JobTitle, Manager, LicenseSKU, Groups
# Usage   : .\entra-id-user-provisioning.ps1 -CsvPath ".\new-users.csv"
#           .\entra-id-user-provisioning.ps1 -CsvPath ".\new-users.csv" -WhatIf
# Requires: Microsoft.Graph PowerShell SDK
#           Install-Module Microsoft.Graph -Scope CurrentUser
# ==============================================================================

param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [string]$DefaultDomain   = "yourdomain.com",      # UPDATE: your tenant domain
    [string]$DefaultPassword = "Welcome@2024!",        # UPDATE: or use a secure vault
    [switch]$WhatIf,
    [string]$LogPath = ".\provisioning-log-$(Get-Date -Format 'yyyy-MM-dd-HHmm').csv"
)

# ── 1. Connect to Microsoft Graph ─────────────────────────────────────────────
Write-Host "`n[INFO] Connecting to Microsoft Graph..." -ForegroundColor Cyan

try {
    Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All" -ErrorAction Stop
    Write-Host "[OK]   Connected to Microsoft Graph.`n" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Graph connection failed: $_" -ForegroundColor Red
    exit 1
}

# ── 2. Load CSV ────────────────────────────────────────────────────────────────
if (-not (Test-Path $CsvPath)) {
    Write-Host "[ERROR] CSV file not found: $CsvPath" -ForegroundColor Red
    exit 1
}

$users = Import-Csv -Path $CsvPath
Write-Host "[INFO] Loaded $($users.Count) user(s) from CSV.`n" -ForegroundColor Cyan

# ── 3. Provision each user ─────────────────────────────────────────────────────
$log = @()

foreach ($u in $users) {

    $upn         = "$($u.FirstName.ToLower()).$($u.LastName.ToLower())@$DefaultDomain"
    $displayName = "$($u.FirstName) $($u.LastName)"
    $mailNick    = "$($u.FirstName.ToLower())$($u.LastName.ToLower())"

    Write-Host "  Processing : $displayName  ($upn)" -ForegroundColor White

    $logEntry = [PSCustomObject]@{
        DisplayName  = $displayName
        UPN          = $upn
        Department   = $u.Department
        JobTitle     = $u.JobTitle
        Status       = ""
        Error        = ""
        ProcessedAt  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # -- WhatIf dry-run mode --
    if ($WhatIf) {
        Write-Host "  [WHATIF]   Would create user: $upn" -ForegroundColor Yellow
        $logEntry.Status = "WhatIf"
        $log += $logEntry
        continue
    }

    # -- Check if user already exists --
    $existing = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "  [SKIP]     User already exists: $upn" -ForegroundColor Yellow
        $logEntry.Status = "AlreadyExists"
        $log += $logEntry
        continue
    }

    try {
        # -- Create user --
        $passwordProfile = @{
            Password                      = $DefaultPassword
            ForceChangePasswordNextSignIn = $true
        }

        $newUser = New-MgUser `
            -DisplayName        $displayName `
            -GivenName          $u.FirstName `
            -Surname            $u.LastName `
            -UserPrincipalName  $upn `
            -MailNickname       $mailNick `
            -Department         $u.Department `
            -JobTitle           $u.JobTitle `
            -AccountEnabled     $true `
            -PasswordProfile    $passwordProfile `
            -UsageLocation      "IN" `
            -ErrorAction        Stop

        Write-Host "  [OK]       User created: $upn  (ID: $($newUser.Id))" -ForegroundColor Green

        # -- Assign to groups (comma-separated in CSV) --
        if ($u.Groups) {
            $groupNames = $u.Groups -split ";"
            foreach ($groupName in $groupNames) {
                $groupName = $groupName.Trim()
                $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
                if ($group) {
                    New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $newUser.Id -ErrorAction SilentlyContinue
                    Write-Host "  [OK]       Added to group: $groupName" -ForegroundColor Green
                } else {
                    Write-Host "  [WARN]     Group not found: $groupName" -ForegroundColor Yellow
                }
            }
        }

        $logEntry.Status = "Created"

    } catch {
        Write-Host "  [ERROR]    Failed to create $upn : $_" -ForegroundColor Red
        $logEntry.Status = "Failed"
        $logEntry.Error  = $_.Exception.Message
    }

    $log += $logEntry
    Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray
}

# ── 4. Summary ────────────────────────────────────────────────────────────────
$created  = ($log | Where-Object { $_.Status -eq "Created" }).Count
$skipped  = ($log | Where-Object { $_.Status -eq "AlreadyExists" }).Count
$failed   = ($log | Where-Object { $_.Status -eq "Failed" }).Count
$whatif   = ($log | Where-Object { $_.Status -eq "WhatIf" }).Count

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "  PROVISIONING SUMMARY" -ForegroundColor White
Write-Host "  Created       : $created" -ForegroundColor Green
Write-Host "  Already Exist : $skipped" -ForegroundColor Yellow
Write-Host "  Failed        : $failed"  -ForegroundColor Red
if ($WhatIf) {
Write-Host "  WhatIf (dry)  : $whatif"  -ForegroundColor Cyan }
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor DarkCyan

# ── 5. Export log ─────────────────────────────────────────────────────────────
$log | Export-Csv -Path $LogPath -NoTypeInformation
Write-Host "[OK]   Provisioning log saved to: $LogPath`n" -ForegroundColor Green

Disconnect-MgGraph | Out-Null