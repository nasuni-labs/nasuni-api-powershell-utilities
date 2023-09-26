#Enable Global locking and set mode for the specified paths with a basepath
  
#populate NMC hostname and credentials
$hostname = "host.domain.com"
 
<#Path to the NMC API authentication token file--use GetTokenCredPrompt/GetToken scripts to get a token.
Tokens expire after 8 hours #>
$tokenFile = "c:\nasuni\token.txt"
 
#specify the volume
$volume_guid = "InsertVolumeGuidHere"

#Set the basepath that all specified folders will share
$basepath = "/paths"
 
#Set the path that will be updated within the basepath. The path should start with a "/" and should be separated by a comma
$FolderPaths = @("/folder1", "/folder2", "/folder2")
 
#Set the mode - "optimized, advanced, or asynchronous"
$mode = "optimized"

#end variables
  
# Allow untrusted SSL certs
if ($PSVersionTable.PSEdition -eq 'Core') #PowerShell Core
{
	if ($PSDefaultParameterValues.Contains('Invoke-RestMethod:SkipCertificateCheck')) {}
	else {
		$PSDefaultParameterValues.Add('Invoke-RestMethod:SkipCertificateCheck', $true)
	}
}
else #other versions of PowerShell
{if ("TrustAllCertsPolicy" -as [type]) {} else {		
	
Add-Type -TypeDefinition @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
	public bool CheckValidationResult(
		ServicePoint srvPoint, X509Certificate certificate,
		WebRequest request, int certificateProblem) {
		return true;
	}
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName TrustAllCertsPolicy

#set the correct TLS Type
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
 } }

#build JSON headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Accept", 'application/json')
$headers.Add("Content-Type", 'application/json')
 
#Read the token from a file and add it to the headers for the request
$token = Get-Content $tokenFile
$headers.Add("Authorization","Token " + $token)
 
#Set the URL for the folder update NMC API endpoint
$GFLurl="https://"+$hostname+"/api/v1.1/volumes/" + $volume_guid + "/global-lock-folders/"

#Loop through the array to build the body and set the GFL mode for each path
for ($i=0; $i -lt $FolderPaths.length; $i++) {

$path = $basepath + $FolderPaths[$i]

#build the body for the folder update
$body = @{
    path = $path
    mode = $mode
}
 
#set folder properties
write-output $url
$response=Invoke-RestMethod -Uri $GFLurl -Method Post -Headers $headers -Body (ConvertTo-Json -InputObject $body)
write-output $response | ConvertTo-Json
Start-Sleep -s 1.1
}
