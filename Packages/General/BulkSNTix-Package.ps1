# NOTE: Requires external repo at D:\dev\repos\ServiceNow
# Original repo: https://git.example.com/sydlexius/ServiceNow.git

Clear-Host

$U_EMAIL  = "<user@example.com>"
$USER_SID = "<SNOW_SYS_ID>"        # JDOE
$USER_LOC = "<SNOW_SYS_ID>"        # 100-HQ-CA-Site
$CI       = "<SNOW_SYS_ID>"        # CI
#$ITIL     = "user@example.com"  #

#region Feed File Check
Write ""
Write-Host -ForegroundColor GREEN "Service Now Ticket Generator"
Write ""
Write-Host -ForegroundColor Yellow "     The format of the feed csv file should be comma seperated values..."
Write-Host "          Client Name, Machine Name, UserName, Location"
Write ""
Write-Host -ForegroundColor Yellow  "     For Example:"
Write-Host "          Tanium, CABIDS65243TL, NFuentes, CA100-Site"
Write ""
Write-Host -ForegroundColor RED "  *NOTE*  Service Now Ticket caller is John Doe unless the script is changed manually!!!"
Write ""

$csvfile  = "C:\DesktopSupportTools\ServiceNowTicketFeed.csv"

IF (Test-Path $csvfile) {
    Write-Host -ForegroundColor CYAN "          SUCCESS:  Feed file found, continuing in 5 seconds..."
    Write ""
    Write ""
    Start-Sleep -Seconds 5
} ELSE {
    Write-Host -ForegroundColor RED "          ERROR:  Can't find a feed file!!!"
    Write-Host -ForegroundColor CYAN "          Provide a feed file... $CSVFILE is missing"
    Write ""
    Write ""
    Write-Host "Closing in 10 seconds..."
    Start-Sleep -Seconds 10
    [Environment]::Exit(99)
}
#endregion

#region Service Now Environment Choice
cls
$Title = "Service Now Environment"
$Info  = "Are you creating tickets in a STAGE or PRODUCTION environment?"
Write ""
Write-Host -ForegroundColor GREEN "Service Now Ticket Generator"
Write ""
$options = [System.Management.Automation.Host.ChoiceDescription[]] @("&Stage", "&Production", "&Quit")
[int]$defaultchoice = 2
$opt = $host.UI.PromptForChoice($Title , $Info , $Options,$defaultchoice)
switch($opt) {
    0 {
        Write ""
        Write-Host -ForegroundColor Yellow "     STAGE Selected..."
        $AGROUP   = "<SNOW_SYS_ID>"        # DESKTOP SUPPORT
        $uri = "https://contosodev.service-now.com/api/now/table/incident"
        Write ""
        Write ""
    } 

    1 {
        Write ""
        Write-Host -ForegroundColor Yellow "     PRODUCTION Selected..."
        $AGROUP   = "<SNOW_SYS_ID>"        # TECHNICAL SUPPORT
        $uri = "https://contoso.service-now.com/api/now/table/incident"
        Write ""
        Write ""
    }

    2 {
        Write-Host -ForegroundColor CYAN "     No Selection made... closing script!!!"
        Write ""
        Start-Sleep -Seconds 10
        [Environment]::Exit(98)
    }
}
#endregion

#region CREDS
function New-Credential{
    $counter = 0
    $more = $true
    while($more){
        if($counter -ge 3){
            Write-Warning -Message ('Take a deep breath and perhaps a break.  You have entered your password {0} times incorrectly' -f $counter)
            Write-Warning -Message ('Please wait until {0} to try again to avoid risking locking yourself out.' -f $((Get-Date).AddMinutes(+15).ToShortTimeString()))
            Start-Sleep -Seconds 30
        }

        # Collect the username and password and store in credential object.
        $Script:userName = Read-Host -Prompt 'Please enter your domain\username'
        $Script:password = Read-Host -AsSecureString -Prompt 'Please enter your password'
         
        try{
            $credential = New-Object System.Management.Automation.PSCredential $userName,$password

            # Build the current domain
            $currentDomain = 'LDAP://{0}' -f $credential.GetNetworkCredential().Domain

            # Get the user\password. The GetNetworkCredential only works for the passwrod because the current user
            # is the one who entered it.  Shouldn't be accessible to anything\one else.
            $Script:userName = $credential.GetNetworkCredential().UserName

            $password2 = $credential.GetNetworkCredential().Password

        }
        catch{
            Write-Warning -Message ('There was a problem with what you entered: {0}' -f $_.exception.message)
            continue
        }

        # Do a quick query against the domain to authenticate the user.
        $dom = New-Object System.DirectoryServices.DirectoryEntry($currentDomain,$userName,$password2)
        # If we get a result back with a name property then we're good to go and we can store the credential.
        if($dom.name){
            Write-Output $credential
            $more = $false
            Remove-Variable password2 -Force
        }
        else{
            $counter++

            Write-Warning -Message ('The password you entered for {0} was incorrect.  Attempts {1}. Please try again.' -f $userName,$counter)
        }
    }
}
#endregion

New-Credential

Start-Sleep -Seconds 5

Write ""
Write-Host -ForegroundColor Green "SUCCESS:  Account & password has been validated..."
Write ""
Write ""
Write-Host -ForeGroundColor YELLOW "     Here are your ticket numbers..."
Write ""

Start-Sleep -Seconds 5

# Build auth header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))))))
Remove-Variable Password -Force

$X = import-csv $csvfile -Header Client, Computer, User, Location
Remove-Variable TicketList -ErrorAction SilentlyContinue
[array]$TicketList = @()

TRY {
    Foreach ($item in $X) {
        $snClient = $Item.Client
        $snPC     = $Item.Computer
        $snUser   = $Item.User
        $snLoc    = $Item.Location

        # Set proper headers
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))
        $headers.Add('Accept','application/json')
        $headers.Add('Content-Type','application/json')

        # Specify endpoint uri
        # Set above in environment logic

        # Specify HTTP method
        $method = "post"


        # Specify request body
        $hash= @{
            "short_description"="[Auto]  PC Hygiene - $snClient";
            "description"="Auto generated Service Now Ticket for Client Remediation  -  $snClient  |  $snPC  |  $snUser  |  $snLoc";
            "caller_id"="$USER_SID";                 # JDoe
            "location"="$USER_LOC";                  # 100-HQ-CA-Site
            "u_line_of_business"="NA";
            "category"="Installation";       
            "assignment_group"="$AGROUP";            # TECHNICAL SUPPORT
            "cmdb_ci"="$CI";                         # MISC SOFTWARE
            #"u_itil_watch_list"="$ITIL"
        }

        $body = $hash | ConvertTo-Json

        # Send HTTP request
        $response = Invoke-WebRequest -Headers $headers -Method $method -Uri $uri -Body $body

        # Print response
        $R2J = $response | ConvertFrom-Json
        $snOutput = $R2J.result
        $snOutput.number
        $val = $snOutput.number
        $TicketList += $val + "; "
    }

    $TO   = $username + " " + $U_EMAIL
    $FROM = $username + " " + $U_EMAIL
    $Date = Get-Date
    Send-MailMessage -From $FROM -To $TO -Subject "$SNClient Service Now Tix for $Date" -Body "$TICKETLIST" -SmtpServer smtp.int.mgc.com

    Write ""
    Write ""
    Write-Host -ForegroundColor Yellow "SCRIPT COMPLETE... Closing in 30 seconds."

    Start-Sleep -Seconds 30
} CATCH {
    Write-Host -ForegroundColor RED "ERROR:  Debug REST API Section"
} 

