<# 
 .Synopsis

 .Description

 .Parameter 

 .Example
 
#>
#$publicVariable = 'publicValue'

function SendEmail($smtpServer, $emailTo, $emailFrom, $emailSubject, $emailBody) {
	Write-Host "Sending email to: $emailTo"
		
	$emailMessage = New-Object System.Net.Mail.MailMessage( $emailFrom , $emailTo )
	$emailMessage.Subject = "{0}-{1} Failure" -f $scriptPath, $scriptName
	$emailMessage.IsBodyHtml = $false
	$emailMessage.Body = $errorMessage

	$SMTPClient = New-Object System.Net.Mail.SmtpClient( $smtpServer )
	$SMTPClient.Send( $emailMessage )
}

#Export-ModuleMember -Variable $publicVariable
Export-ModuleMember -Function SendEmail