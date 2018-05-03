# Script written by vlad
# github.com/vlad-tdot
# This script is BSD licensed
# For best results, create a scheduled task with a trigger from an event
# Log: Security
# Source: Microsoft Windows security auditing.
# Event ID: 4776
# 
# Action: powershell -c "C:\script path\script.ps1"
#
# Make sure on the General tab you select "Run whether user is loggen on or not


# Email variables
$fromAddress = 'from@domain.com'
$toAddress   = 'to.domain.com'
$smtpServer  = 'smtp.srv'
$subject     = "$env:COMPUTERNAME Login attempt"



# Create the table ==================
$tabName = "Events"
$table = New-Object system.Data.DataTable “$tabName”

$LogonType = New-Object system.Data.DataColumn "LogonType",([int])
$ImpersonationLevel = New-Object system.Data.DataColumn "ImpersonationLevel",([string])
$SecurityID = New-Object system.Data.DataColumn "SecurityID",([string])
$AccountName = New-Object system.Data.DataColumn "AccountName",([string])
$AccountDomain = New-Object system.Data.DataColumn "AccountDomain",([string])
$LogonID = New-Object system.Data.DataColumn "LogonID",([string])
$LogonGUID = New-Object system.Data.DataColumn "LogonGUID",([string])
$ProcessID = New-Object system.Data.DataColumn "ProcessID",([string])
$ProcessName = New-Object system.Data.DataColumn "ProcessName",([string])
$WorkstationName = New-Object system.Data.DataColumn "WorkstationName",([string])
$SourceNetworkAddress = New-Object system.Data.DataColumn "SourceNetworkAddress",([string])
$SourcePort = New-Object system.Data.DataColumn "SourcePort",([string])
$LogonProcess = New-Object system.Data.DataColumn "LogonProcess",([string])
$AuthenticationPackage = New-Object system.Data.DataColumn "AuthenticationPackage",([string])
$TransitedServices = New-Object system.Data.DataColumn "TransitedServices",([string])
$PackageName = New-Object system.Data.DataColumn "PackageName(NTLMonly)",([string])
$KeyLength = New-Object system.Data.DataColumn "KeyLength",([string])
$TimeCreated = New-Object system.Data.DataColumn "TimeCreated",([System.DateTime])
$Id = New-Object system.Data.DataColumn "Id",([int])

$table.columns.add($TimeCreated)
$table.columns.add($Id)
$table.columns.add($LogonType)
$table.columns.add($ImpersonationLevel)
$table.columns.add($SecurityID)
$table.columns.add($AccountName)
$table.columns.add($AccountDomain)
$table.columns.add($LogonID)
$table.columns.add($LogonGUID)
$table.columns.add($ProcessID)
$table.columns.add($ProcessName)
$table.columns.add($WorkstationName)
$table.columns.add($SourceNetworkAddress)
$table.columns.add($SourcePort)
$table.columns.add($LogonProcess)
$table.columns.add($AuthenticationPackage)
$table.columns.add($TransitedServices)
$table.columns.add($PackageName)
$table.columns.add($KeyLength)
# End creating table ====================



# Read security log, grab last 50 events, pick ones with ID 4624
$logonEvents = (Get-WinEvent @{logname='Security'} -MaxEvents 70 | Where-Object -Property Id -eq 4624| Where-Object Message -match "User32")

# Go through those one by one
foreach ($event in $logonEvents) {
    $row = $table.NewRow()
    
    # Split into lines, remove whutespaces and tabs
    $eventLines = ((($event.Message -split "`r`n") -replace ' ','') -replace '	','') -replace ':\\',';\'
    
    # Event message contains identical lines for "subject" and "new logon" account, this is to remove "subject" info
    $pastSubject = 0
    # For every line of the event
    $eventLines | % { 
        $items = $_.split(':')
        if ($items[0] -match "LogonType") {
            $pastSubject = 1
        }
        # Set anything that's empty to proper $null
        if ($items[1] -like '-') {
                $items[1] = $null
            } 

        # If we've gone past the subject section and variable isn't empty
        if ($items[1] -and $pastSubject) {
            $row.($items[0]) = $items[1] -replace ';\\',':\'
        }
    }             # END going through each line of this message
  
  $row.TimeCreated = $event.TimeCreated
  $row.Id = $event.Id
  # Add row to the table
  $table.Rows.Add($row)
  # Blank out the original message for reasons
  $event.Message = ""

}

# Email Section ===============

$body = ($table | fl TimeCreated, LogonType, AccountName, SourceNetworkAddress) | Out-String
# If body is not empty
if ($body) {
    Send-MailMessage -SmtpServer $smtpServer -From $fromAddress -To $toAddress -Subject $subject -Body $Body
}
