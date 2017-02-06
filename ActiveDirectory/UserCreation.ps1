
<#--------------------------------------
AD\Exchange User Creation Script
Author: Robert Greene
Date: 9-26-2016
Revision: 2.0

.Synopsis
Imports user from excel file and create AD Accounts, Exchange, and G:\ Home drive accounts.

.Description
Imports users from a excel file and does a For Each cyle to create users in AD.
Also creates the users exchange accounts, and G:\ home folder with proper security permissions.
AD Accounts are disabled until acctivated and password is manually entered but recommeneded to be "Changeme!"

Change Log:
1.1
- Added exchange mailbox creation

2.0
- rewrote script to incorporate team managers and use arrays rather then elseif for easier management if the OU's change. 
The information parses easier and is quicker then the original script. 

2.1 
- Added excel function to allow HR to fill out required Excel Document and then pull in info. Tad easier then CSV file (website linked: https://podlisk.wordpress.com/2011/11/20/import-excel-spreadsheet-into-powershell/)

#>

#Function to import Excel Document and convert to be read as CSV
function Import-Excel
{
  param (
    [string]$FileName,
    [string]$WorksheetName,
    [bool]$DisplayProgress = $true
  )

  if ($FileName -eq "") {
    throw "Please provide path to the Excel file"
    Exit
  }

  if (-not (Test-Path $FileName)) {
    throw "Path '$FileName' does not exist."
    exit
  }

  $FileName = Resolve-Path $FileName
  $excel = New-Object -com "Excel.Application"
  $excel.Visible = $false
  $workbook = $excel.workbooks.open($FileName)

  if (-not $WorksheetName) {
    Write-Warning "Defaulting to the first worksheet in workbook."
    $sheet = $workbook.ActiveSheet
  } else {
    $sheet = $workbook.Sheets.Item($WorksheetName)
  }
  
  if (-not $sheet)
  {
    throw "Unable to open worksheet $WorksheetName"
    exit
  }
  
  $sheetName = $sheet.Name
  $columns = $sheet.UsedRange.Columns.Count
  $lines = $sheet.UsedRange.Rows.Count
  
  Write-Warning "Worksheet $sheetName contains $columns columns and $lines lines of data"
  
  $fields = @()
  
  for ($column = 1; $column -le $columns; $column ++) {
    $fieldName = $sheet.Cells.Item.Invoke(1, $column).Value2
    if ($fieldName -eq $null) {
      $fieldName = "Column" + $column.ToString()
    }
    $fields += $fieldName
  }
  
  $line = 2
  
  
  for ($line = 2; $line -le $lines; $line ++) {
    $values = New-Object object[] $columns
    for ($column = 1; $column -le $columns; $column++) {
      $values[$column - 1] = $sheet.Cells.Item.Invoke($line, $column).Value2
    }  
  
    $row = New-Object psobject
    $fields | foreach-object -begin {$i = 0} -process {
      $row | Add-Member -MemberType noteproperty -Name $fields[$i] -Value $values[$i]; $i++
    }
    $row
    $percents = [math]::round((($line/$lines) * 100), 0)
    if ($DisplayProgress) {
      Write-Progress -Activity:"Importing from Excel file $FileName" -Status:"Imported $line of total $lines lines ($percents%)" -PercentComplete:$percents
    }
  }
  $workbook.Close()
  $excel.Quit()
}

#Import Active Directory and Exchange Modules
$Creds = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://EXCHANGE SERVER/PowerShell/ -Authentication Kerberos -Credential $Creds
import-pssession $session
import-module activedirectory

#Static Variables 
#These include DNS, OU's for Departments, and Team Managers/Colors
$Users = Import-Excel C:\NewUser.xlsx
$DNS = (Get-ADDomain).DNSRoot
$OU = @{
        "OU NAME" = "PATH TO OU IN AD (same as Scope)     
}
$Manager = @{
        #Team Colors/Managers
        "Team Name" = "Team Manager Username"                   #Team Managers Name
   
}
#ForEach loop for AD User creation + Enabling Exchange Mailbox
ForEach($User in $Users){
        $First = $User.FirstName
        $Initials = $User.Initials
        $Last = $User.LastName
        $SAM = if ($User.Department -eq "TEAM NAME"){
            ($User.FirstName.substring(0,1) + $User.Initials + $User.Lastname.substring(0,1))}
            Else{
                ($User.FirstName.substring(0,1) + $User.LastName)}
        $UPN = ($SAM + "@" + $DNS)
        $UserInfo = @{
        GivenName = $First
        Initials = $Initials
        Surname = $Last
        Name = ($First + " " + $Last)
        DisplayName = ($First + " " + $Last)
        sAMAccountName = $SAM
        userPrincipalName = $UPN
        Title = ($User.Title + " " + $User.Teamcolor)
        Description = ($User.Title + " " + $User.Teamcolor)
        Office = "OFFICE"
        Department = $User.Department
        Company = "COMPANY NAME"
        HomePage = "WEBSITE"
        homeDirectory = "HOME DIRECTORY"
        StreetAddress = "ADDRESS"
        City = "CITY"
        State = "STATE" 
        PostalCode = "ZIP" 
        Country = "COUNTRY"
        }
    New-ADUser @UserInfo -AccountPassword (Convertto-SecureString -AsPlainText "Changeme!" -force) -Enabled $true -Path $OU[$user.department] -Manager $Manager[$user.Teamcolor]
    Enable-Mailbox -Identity $UPN -Alias $SAM -Database 'MBDB3' -ActiveSyncMailboxPolicy 'ActiveSync--Default User Policy--HIPAA--Encryption--Required'
    Add-ADGroupMember 'GROUP' $SAM
    Add-ADGroupMember 'GROUP' $SAM
}
#Adding Mailbox permissions for calendar viewing

$mb = Get-Mailbox | Where-Object {$_.WhenCreated -ge ((Get-Date).Adddays(-1))} 
$mb | Foreach-Object {Add-MailboxFolderPermission $_":\Calendar" -User calaccess -AccessRights editor}
$mb | Foreach-Object {Add-MailboxFolderPermission $_":\Calendar" -User "all coworkers" -AccessRights reviewer}
