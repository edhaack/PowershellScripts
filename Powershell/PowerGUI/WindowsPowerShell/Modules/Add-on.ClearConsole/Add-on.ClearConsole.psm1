#######################################################################################################################
# File:             Add-on.ClearConsole.psm1                                                                          #
# Author:           Kirk Munro                                                                                        #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2010 Quest Software, Inc.. All rights reserved.                                                 #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.ClearConsole module.                                                          #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.ClearConsole                                                       #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

Set-StrictMode -Version 2

#region Initialize the Script Editor Add-on.

if ($Host.Name –ne 'PowerGUIScriptEditorHost') { return }
if ($Host.Version -lt '2.1.0.1200') {
	[System.Windows.Forms.MessageBox]::Show("The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version 2.1.0.1200 or later of the Script Editor. The current Script Editor version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to version 2.1.0.1200 and try again.","Version 2.1.0.1200 or later is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

#endregion

#region Load resources from disk.

$iconLibrary = @{
	ClearConsoleIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ClearPowerShellConsole.ico",16,16
	ClearConsoleIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ClearPowerShellConsole.ico",32,32
}

$imageLibrary = @{
	ClearConsoleImage16 = $iconLibrary['ClearConsoleIcon16'].ToBitmap()
}

#endregion

#region Create the Clear PowerShell Console command.

if (-not ($clearConsoleCommand = $se.Commands['ViewCommand.ClearPowerShellConsole'])) {
	$clearConsoleCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'ViewCommand','ClearPowerShellConsole'
	$clearConsoleCommand.Text = 'Cl&ear PowerShell Console'
	$clearConsoleCommand.Image = $imageLibrary['ClearConsoleImage16']
	$clearConsoleCommand.AddShortcut('Ctrl+R')
	$clearConsoleCommand.ScriptBlock = {
		Clear-Host
	}

	$se.Commands.Add($clearConsoleCommand)
}

#endregion

#region Create the Clear PowerShell Console menu item in the View menu.

if (($viewMenu = $se.Menus['MenuBar.View']) -and
    (-not ($clearConsoleMenuItem = $viewMenu.Items['ViewCommand.ClearPowerShellConsole']))) {
	$viewMenu.Items.Add($clearConsoleCommand)
	if ($clearConsoleMenuItem = $viewMenu.Items['ViewCommand.ClearPowerShellConsole']) {
		$clearConsoleMenuItem.FirstInGroup = $true
	}
}

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

	#region Remove the Clear PowerShell Console menu item from the View menu.

	if (($viewMenu = $se.Menus['MenuBar.View']) -and
	    ($clearConsoleMenuItem = $viewMenu.Items['ViewCommand.ClearPowerShellConsole'])) {
		$viewMenu.Items.Remove($clearConsoleMenuItem) | Out-Null
	}

	#endregion

	#region Remove the Clear PowerShell Console command.

	if ($clearConsoleCommand = $se.Commands['ViewCommand.ClearPowerShellConsole']) {
		$se.Commands.Remove($clearConsoleCommand) | Out-Null
	}

	#endregion
}

#endregion

# SIG # Begin signature block
# MIIPGwYJKoZIhvcNAQcCoIIPDDCCDwgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmUVmd20A396PrtZj0QPR50Dh
# 8bmgggzzMIIEBzCCAu+gAwIBAgILAQAAAAABHkZAnTYwDQYJKoZIhvcNAQEFBQAw
# YzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExFjAUBgNV
# BAsTDU9iamVjdFNpZ24gQ0ExITAfBgNVBAMTGEdsb2JhbFNpZ24gT2JqZWN0U2ln
# biBDQTAeFw0wODEyMTcxNzQ4MDJaFw0xMTEyMTcxNzQ4MDJaMGExCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5RdWVzdCBTb2Z0d2FyZTEXMBUGA1UEAxMOUXVlc3QgU29m
# dHdhcmUxIDAeBgkqhkiG9w0BCQEWEXN1cHBvcnRAcXVlc3QuY29tMIGfMA0GCSqG
# SIb3DQEBAQUAA4GNADCBiQKBgQDWbNraEqKKpmdoXWweG4VFLswQar21iEXsAVsl
# G9O+EJmT2zEr3a2EoEXINI7Mlq4Htm2P7UfBDOmpttT3gSxHT0k5/y8H7FAosLFo
# E/liPCGMnNXL7V3p+tVZg3WhXE9dEEwbsGcWB9GQ522yD9CfVSqfUQ1KjPKNO6Hm
# J25TLQIDAQABo4IBQDCCATwwHwYDVR0jBBgwFoAU0lvzSyZLpbDnXf1Wf/bxLjhO
# U6AwTgYIKwYBBQUHAQEEQjBAMD4GCCsGAQUFBzAChjJodHRwOi8vc2VjdXJlLmds
# b2JhbHNpZ24ubmV0L2NhY2VydC9PYmplY3RTaWduLmNydDA5BgNVHR8EMjAwMC6g
# LKAqhihodHRwOi8vY3JsLmdsb2JhbHNpZ24ubmV0L09iamVjdFNpZ24uY3JsMAkG
# A1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEsG
# A1UdIAREMEIwQAYJKwYBBAGgMgEyMDMwMQYIKwYBBQUHAgEWJWh0dHA6Ly93d3cu
# Z2xvYmFsc2lnbi5uZXQvcmVwb3NpdG9yeS8wEQYJYIZIAYb4QgEBBAQDAgQQMA0G
# CSqGSIb3DQEBBQUAA4IBAQAb2FS5B6R10Mn+nN+qj2niHMoGR4pxWy6cR5NQw2D3
# RfOB05hEUk8IPtP6BdetOzpjbEWYsk0b/aVCyND/fZwEE33Nl1tf4TGEV8RX3/DS
# BvDcf899iQJG+n1VmVNp8i3gwkK39mmC49CCCClZp1JyDuNA3J4cSDofpzdYc7w8
# yIpwomn0u4zU8pf0GPLoXaTytt0QDIm7SYiIBycQBz8rCgoFlVPWCdPeuTCBOA2V
# fDaGpP9lx/wnLggPNsrMv6BiYMI1qO7ADOHNoDTmhlMvCEVXWx1zkxIlUmcwlUuk
# 07WOuGLmDo6joSZ7Mz+QTyfOhduZOU8mM4Cm4BO9R0WXMIIEDTCCAvWgAwIBAgIL
# BAAAAAABI54PrLMwDQYJKoZIhvcNAQEFBQAwVzELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNVBAsTB1Jvb3QgQ0ExGzAZBgNVBAMT
# Ekdsb2JhbFNpZ24gUm9vdCBDQTAeFw05OTAxMjgxMzAwMDBaFw0xNzAxMjcxMjAw
# MDBaMIGBMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEl
# MCMGA1UECxMcUHJpbWFyeSBPYmplY3QgUHVibGlzaGluZyBDQTEwMC4GA1UEAxMn
# R2xvYmFsU2lnbiBQcmltYXJ5IE9iamVjdCBQdWJsaXNoaW5nIENBMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAopt1KqcTuglxJBjfoQZiKRKe3J51c+jf
# VldplhNWT/LIvAFY7SaGcgtg9RnFVQNXm7kQyaHUdED/bADo5lM3/rfaeT64Ujjp
# gSyfDjNSps1wzkpdYvTRZ168l0oHyrzdjUexzfFlW4UBsEtr3s2OLvVQ6KOcnSaY
# azZjQQNwRPBf4iV1eVB9X6EGokYMVZVHFNORRoZomecn9JTsmkFR95bUeozhRJdo
# cQPYWG+9tBBC7g1mdUaLRJbSMAASB2P3RJsBcMpWb5xYlyonF4sucVJtRqunKw9/
# FkhkyFL6BhcAB3TXRbMM9XiVc+gK7sTgcoweEaoeu17O+bQA7nO9zQIDAQABo4Gu
# MIGrMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQV
# UXkafAxZ+drN2MQ6E5rJeC1/TTAzBgNVHR8ELDAqMCigJqAkhiJodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24ubmV0L1Jvb3QuY3JsMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB8G
# A1UdIwQYMBaAFGB7ZhpFDZfKiVAvfQTNNKj//P1LMA0GCSqGSIb3DQEBBQUAA4IB
# AQC1eKaifAS3f8l/fWq8cfopMGDC9GIe/n9DHptu4rIfcwuFdlt99U5JBi/U+reR
# QO/tb42OE4NUxSoCPQqk3JkLer13L8xAwY/zxIxOcroQfOb/ZCvHzmyn/NeafI5G
# jQGDTUI725w/nzJhV9cXsLM2ZvCz/URvgTexlE6nViWJ9YrWbRFiYnlcQpACGNOc
# I/wI6GRFuS1+gFtOr8OKKZKDeB+RQTSvhcX9B5lOLFz+x/0XuyUlMU1ytbUpS0ia
# N28TxxFOSkUefi8xnKvoUq/WZ5c0iF8OJ2pmUtFax6wwLCA43Sv/OuvOEEWConsb
# oSBzVpsqk+YEUQZsG9wviZSTMIIE0zCCA7ugAwIBAgILBAAAAAABI54PryQwDQYJ
# KoZIhvcNAQEFBQAwgYExCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWdu
# IG52LXNhMSUwIwYDVQQLExxQcmltYXJ5IE9iamVjdCBQdWJsaXNoaW5nIENBMTAw
# LgYDVQQDEydHbG9iYWxTaWduIFByaW1hcnkgT2JqZWN0IFB1Ymxpc2hpbmcgQ0Ew
# HhcNMDQwMTIyMTAwMDAwWhcNMTcwMTI3MTAwMDAwWjBjMQswCQYDVQQGEwJCRTEZ
# MBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEWMBQGA1UECxMNT2JqZWN0U2lnbiBD
# QTEhMB8GA1UEAxMYR2xvYmFsU2lnbiBPYmplY3RTaWduIENBMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsLHygABwzuzDjLSX7cYJjCZvid9nWYHP3hQT
# TMKxReJTdUH6BzZvuhFwKJR8bXK9BxUlZToJ/4Xc+nteN4c45MdLCICYnorNWAkC
# wMMBSZZYiIkmWfVtxrnB+xgl7dhiTsoKbF1w787TmykLCcb27rYW1DxUjsxd4K/b
# 3SMJMnsygRZiCgbLes80IbZvNraxzsuaKTVAPp1YfP+tgpj6uNWJyjXdy81XBsub
# 5L+UqICYX3eW8Lbnq3R5QCGmY+nQB5G9hTi0rpasof8Uc9qlRbhNhs4qPO/U3ygO
# damoiBPC5Hxgk/IlzAOEl+ZOtp8t1rWLNDyr1Tg6yD3EsfmUzQIDAQABo4IBZzCC
# AWMwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYE
# FNJb80smS6Ww5139Vn/28S44TlOgMEoGA1UdIARDMEEwPwYJKwYBBAGgMgEyMDIw
# MAYIKwYBBQUHAgEWJGh0dHA6Ly93d3cuZ2xvYmFsc2lnbi5uZXQvcmVwb3NpdG9y
# eTA5BgNVHR8EMjAwMC6gLKAqhihodHRwOi8vY3JsLmdsb2JhbHNpZ24ubmV0L3By
# aW1vYmplY3QuY3JsME4GCCsGAQUFBwEBBEIwQDA+BggrBgEFBQcwAoYyaHR0cDov
# L3NlY3VyZS5nbG9iYWxzaWduLm5ldC9jYWNlcnQvUHJpbU9iamVjdC5jcnQwEQYJ
# YIZIAYb4QgEBBAQDAgABMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB8GA1UdIwQYMBaA
# FBVReRp8DFn52s3YxDoTmsl4LX9NMA0GCSqGSIb3DQEBBQUAA4IBAQAeavNt9I6p
# Iv5wCGUuoV2rMzDdbHj6S+qtxY3sEHpqxViXOWuS85HiDKcoHNFddo6LB3wTb63E
# NkOzwbwxWc8YONijO87/ymdYv+DxrGE+ojsevAJbQaxEa/Um8+1eqGX2ymWmP8r1
# d+ulhipYKVb4vhYQQOnS/FcsY2E3ZiU5IC4HA6A2AyWUvXzrftOjwsV2FnUwkrn/
# dkE1IWjRDl5cjsMDYOaAQPzAXaJUbm6SZ6eBEoeioyvbt03/5NXH5QXm1fGu/M1m
# GCHzPkfJ5ZVCYSydJoCyD6g9DsmneN9udIwsRvZy6TxkayhVxEtkM8t4VBM48NVx
# BtQ+DQo1DuCzMYIBkjCCAY4CAQEwcjBjMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEWMBQGA1UECxMNT2JqZWN0U2lnbiBDQTEhMB8GA1UE
# AxMYR2xvYmFsU2lnbiBPYmplY3RTaWduIENBAgsBAAAAAAEeRkCdNjAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUYPJEK2i8ieOmYmsFt4cinerNZJIwDQYJKoZIhvcNAQEBBQAEgYAW
# wZfli45HeS5CSifrDEXXUHD0x1XfZ6FSGuEraH20htwzvkZeGhwy+TuL7Wp8Sfav
# 7rpCv08ywRGXPwmyPICxp7iFRw6k2K9NNpMQVDhvS1fl6/UlLJOGXLKp60DZV4eZ
# ZWv5XRPzpFDMCnKbNYXQeQXkw/TjnGyoiRxpM21Low==
# SIG # End signature block
