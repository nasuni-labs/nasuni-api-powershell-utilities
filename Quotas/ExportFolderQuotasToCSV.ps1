#Export Folder Quotas to CSV

#populate NMC hostname and credentials
$hostname = "insertHostname"
 
<# Path to the NMC API authentication token file--use GetTokenCredPrompt/GetToken scripts to get a token.
Tokens expire after 8 hours #>
$tokenFile = "c:\nasuni\token.txt"

#Path for CSV Export
$reportFile = "c:\export\FolderQuotas.csv"

#Number of folder quotas to return
$limit = 1000

#end variables

#Request token and build connection headers
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

#List Quota Folders NMC API endpoint
$QuotaFoldersUrl="https://"+$hostname+"/api/v1.1/volumes/folder-quotas/?limit=" + $limit + "&offset=0"
$FormatEnumerationLimit=-1
$GetQuotaFolders = Invoke-RestMethod -Uri $QuotaFoldersUrl -Method Get -Headers $headers

#Initialize CSV output file
$csvHeader = "Quota ID, VolumeGuid,FilerSerial,Path,Quota Type,Quota Limit,Quota Usage,Email"
Out-File -FilePath $reportFile -InputObject $csvHeader -Encoding UTF8
write-host ("Exporting Folder Quota information to: " + $reportFile)

foreach($i in 0..($GetQuotaFolders.items.Count-1)){
    $QuotaID = $GetQuotaFolders.items[$i].id
	$VolumeGuid = $GetQuotaFolders.items[$i].volume_guid
	$FilerSerial = $GetQuotaFolders.items[$i].filer_serial_number
	$Path = $GetQuotaFolders.items[$i].path
	$Type = $GetQuotaFolders.items[$i].type
    $Email = $GetQuotaFolders.items[$i].email
    $QuotaLimit = $GetQuotaFolders.items[$i].limit
    $QuotaUsage = $GetQuotaFolders.items[$i].usage
	$datastring = "$QuotaID,$VolumeGuid,$FilerSerial,$Path,$Type,$QuotaLimit,$QuotaUsage,$Email"
	Out-File -FilePath $reportFile -InputObject $datastring -Encoding UTF8 -append
	$i++
} 
