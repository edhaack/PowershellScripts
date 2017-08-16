# REST Helpers
[string] $restContentType = "application/json"
function SslCertificateCheckDisable() {
	add-type @"
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
	[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
function GetRestHeaders($userName, $userPassword) {
	$pair = "{0}:{1}" -f $userName, $userPassword
	$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
	$base64 = [System.Convert]::ToBase64String($bytes)
	$basicAuthValue = "Basic $base64"
	$headers = @{"Authorization"=$basicAuthValue;"Accept"=$restContentType}
	return $headers
}
function ExecuteGetRequest($method) {
	SslCertificateCheckDisable
	$headers = GetRestHeaders $testRailUserName $testRailApiKey
	$apiUri = "{0}{1}" -f $testRailApiUrl, $method
	try {
		$response = Invoke-RestMethod -Headers $headers -ContentType $restContentType -Uri $apiUri -Method Get
	}
	catch {
		Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    	Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
	}
	return $response
}
function ExecutePostRequest($method, $body) {
	SslCertificateCheckDisable
	$headers = GetRestHeaders $testRailUserName $testRailApiKey
	$apiUri = "{0}{1}" -f $testRailApiUrl, $method
	if($body) {
		$response = Invoke-RestMethod -Headers $headers -ContentType $restContentType -Uri $apiUri -Method Post -Body $body
	} else {
		$response = Invoke-RestMethod -Headers $headers -ContentType $restContentType -Uri $apiUri -Method Post
	}
	return $response
}
# REST Helpers