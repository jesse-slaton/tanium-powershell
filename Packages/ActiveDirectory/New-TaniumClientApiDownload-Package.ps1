function New-TaniumClientApiDownload {
    [cmdletbinding()]
    param (
        [Alias('Name')]
        [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
        [string]$Filename,
        [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
        [string]$Url,
        [int]$Retries=3,
        [int]$SleepinSeconds = 10
    )
    begin {}
    process {
        [xml]$TaniumClientApiSoapRequest = @"
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:TaniumSOAP"> 
    <soapenv:Header/> 
    <soapenv:Body> 
        <urn:tanium_soap_request> 
            <session></session> 
            <command>AddObject</command> 
            <object_list> 
                <download> 
                    <name></name> 
                    <url></url> 
                </download> 
            </object_list> 
        </urn:tanium_soap_request> 
    </soapenv:Body> 
</soapenv:Envelope>
"@

        $TaniumClientApiToken = Get-TaniumClientApiToken
        if ($TaniumClientApiToken) {
            $TaniumClientApiSoapRequest.Envelope.Body.tanium_soap_request.session = $TaniumClientApiToken
            $TaniumClientApiSoapRequest.Envelope.Body.tanium_soap_request.object_list.download.name = $Filename
            $TaniumClientApiSoapRequest.Envelope.Body.tanium_soap_request.object_list.download.url = $Url
        }
        else {
            Write-Warning 'Unable to get Tanium client API token'
            break
        }

        $TaniumClientSoapUrl = "http://localhost:" + (Get-TaniumClientSoapPort)
        $SoapData = Send-TaniumClientSoapRequest -SoapUrl $TaniumClientSoapUrl -TaniumClientApiSoapRequest $TaniumClientApiSoapRequest -Retries $Retries -SleepinSeconds $SleepinSeconds

        if ($SoapData) {
            [xml]$SoapDataXml = ($SoapData).Content
            foreach ($Download in $SoapDataXml.Envelope.Body.return.result_object.download) {
                $TaniumClientApiDownloadProperties = @{
                    Name   = $Download.name
                    Status = $Download.status
                    Url    = $Download.url
                    Path   = $Download.path
                }
                $TaniumClientApiDownload = New-Object -TypeName PSObject -Property $TaniumClientApiDownloadProperties
                $TaniumClientApiDownload
            }
            Write-Verbose "$Url has been requested"
        }
        else {
            Write-Warning "Unable to get Tanium Client API downloads from $TaniumClientSoapUrl"
        }
    }
    end {}
}