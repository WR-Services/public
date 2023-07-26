[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

Import-Module ActiveDirectory  

# uncomment ME


# Local Active Directory User sync to AAD
# 
# Author Information:
# by: 		Ferit Sari Tomé
# company: 	WR-Services GmbH
# Date:		1 Feb 2023
# All rights reserved
# Version: 1

# ----------------------------------------
#       1. DEFINING MAIN VARIABLES
# ----------------------------------------

# Define Credentials for AAD Admin User
[string]$userName = ''
[string]$userPassword = ''

# Create credential Object
[SecureString]$secureString = $userPassword | ConvertTo-SecureString -AsPlainText -Force 
[PSCredential]$credentialObejct = New-Object System.Management.Automation.PSCredential -ArgumentList $userName, $secureString

#Authenticate against AAD
Connect-MsolService -Credential $credentialObejct

#Set users to be migrated, only select users without value in extensionAttribute10
#also define searchbase
$users = $null  
$users = Get-ADUser -SearchBase "DC=Users,DC=domain,DC=com" -Filter {-not(extensionAttribute10 -like "*") }

#Single User Testcase
#$users = Get-ADUser ftome

ForEach($user in $users)  
{   
	#Build UPN
    $user.Name
	#Set Domainsuffix "domain.com"
    $AAD_UPN = $user.Name + "@domain.com"

    #Fetch guid from AD user
    $guid = $user.ObjectGUID

    #Convert GUID
    $base64 = [system.convert]::ToBase64String(([GUID]$guid).ToByteArray())
    $hexstring = (([GUID]$guid).ToByteArray() | % ToString X2) -join ' '

    #Display Values for debugging
    $base64
    #$guid.ToString()
    #$hexstring

    #Write the converted GUID to the AD Users immutableid
    Get-MsolUser -UserPrincipalName $AAD_UPN | select immutableid
    Set-MsolUser -UserPrincipalName $AAD_UPN -ImmutableId $base64

    #Write the Synchronization flag to the local AD users "extAttrib10" field, to trigger the sync
	#Sync rules have to be defined within the Sync client itself.
    $ThisUser = Get-ADUser -Identity $User -Properties extensionAttribute10
    Set-ADUser –Identity $ThisUser -add @{"extensionattribute10"="AADSyncEnabled"}



    # --------------------------------------------------------------------
    #       DEFINING EMAIL VARIABLES FOR MAILING LOG AND RESULTS
    # --------------------------------------------------------------------
    $usernameReciep = "Your Name"
    $emailSender = "yourname@domain.com"
    $emailRecipient = $AAD_UPN
    $emailCc = ""
    $emailBcc = "yourname@domain.com"
    $emailSubject = "Your Windows user account has been synced with Office365/Azure AD"
    $emailBody = Get-Content "\\yourserver\folder\MailBody.htm"

    $emailServer = "mail.domain.com"
    $file1 = "\\yourserver\folder\file1.pdf"
    $file2 = "\\yourserver\folder\file2.pdf"
    $emailAttachment = new-object System.Net.Mail.Attachment $file1

    # Define Credentials for Mailing
    [string]$userName = ''
    [string]$userPassword = ''

    # Create credential Object
    [SecureString]$secureString = $userPassword | ConvertTo-SecureString -AsPlainText -Force 
    [PSCredential]$mailcredentialObejct = New-Object System.Management.Automation.PSCredential -ArgumentList $userName, $secureString

    # Send an email using local SMTP server with log when done.
    Send-MailMessage -Credential $mailcredentialObejct -From $emailSender -To $emailRecipient -Bcc $emailBcc -Subject $emailSubject -body "$emailBody" -Encoding ([System.Text.Encoding]::UTF8) -BodyAsHtml -SmtpServer $emailServer -Port 587 -Attachments $file1,$file2
}
#>