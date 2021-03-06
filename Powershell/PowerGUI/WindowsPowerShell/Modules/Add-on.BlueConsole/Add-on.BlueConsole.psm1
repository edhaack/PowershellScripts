#######################################################################################################################
# File:             Add-on.BlueConsole.psm1                                                                           #
# Author:           Kirk Munro                                                                                        #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2011 Quest Software, Inc. All rights reserved.                                                  #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.BlueConsole module.                                                           #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.BlueConsole                                                        #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

Set-StrictMode -Version 2

#region Define the Win32WindowClass

if (-not ('PowerShellTypeExtensions.Win32Window' -as [System.Type])) {
	$cSharpCode = @'
using System;

namespace PowerShellTypeExtensions {
	public class Win32Window : System.Windows.Forms.IWin32Window
	{
		public static Win32Window CurrentWindow {
			get {
				return new Win32Window(System.Diagnostics.Process.GetCurrentProcess().MainWindowHandle);
			}
		}
	
		public Win32Window(IntPtr handle) {
			_hwnd = handle;
		}

		public IntPtr Handle {
			get {
				return _hwnd;
			}
		}

		private IntPtr _hwnd;
	}
}
'@

	Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition $cSharpCode
}

#endregion

#region Initialize the Script Editor Add-on.

$minimumPowerGUIVersion = [System.Version]'2.4.0.1659'

if ($Host.Name –ne 'PowerGUIScriptEditorHost') {
	return
}

if ($Host.Version -lt $minimumPowerGUIVersion) {
	[System.Windows.Forms.MessageBox]::Show([PowerShellTypeExtensions.Win32Window]::CurrentWindow,"The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version $minimumPowerGUIVersion or later of the Script Editor. The current Script Editor version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to version $minimumPowerGUIVersion and try again.","Version $minimumPowerGUIVersion or later is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

#endregion

#region Apply the native blue PowerShell Console theme.

#region Store the current theme colors.

$oldColors = @{
	       'BackgroundColor' = $pgse.Configuration.Colors.Console.BackgroundColor
	       'ForegroundColor' = $pgse.Configuration.Colors.Console.ForegroundColor
	'WarningBackgroundColor' = $pgse.Configuration.Colors.Console.WarningBackgroundColor
	'WarningForegroundColor' = $pgse.Configuration.Colors.Console.WarningForegroundColor
	  'ErrorBackgroundColor' = $pgse.Configuration.Colors.Console.ErrorBackgroundColor
	  'ErrorForegroundColor' = $pgse.Configuration.Colors.Console.ErrorForegroundColor
	'VerboseBackgroundColor' = $pgse.Configuration.Colors.Console.VerboseBackgroundColor
	'VerboseForegroundColor' = $pgse.Configuration.Colors.Console.VerboseForegroundColor
	  'DebugBackgroundColor' = $pgse.Configuration.Colors.Console.DebugBackgroundColor
	  'DebugForegroundColor' = $pgse.Configuration.Colors.Console.DebugForegroundColor
}

#endregion

#region Set the new theme colors.

$pgse.Configuration.Colors.Console.BackgroundColor        = [System.Drawing.Color]::FromArgb(1,36,86)
$pgse.Configuration.Colors.Console.ForegroundColor        = [System.Drawing.Color]::FromArgb(238,237,240)
$pgse.Configuration.Colors.Console.WarningBackgroundColor = [System.Drawing.Color]::Black
$pgse.Configuration.Colors.Console.WarningForegroundColor = [System.Drawing.Color]::Yellow
$pgse.Configuration.Colors.Console.ErrorBackgroundColor   = [System.Drawing.Color]::Black
$pgse.Configuration.Colors.Console.ErrorForegroundColor   = [System.Drawing.Color]::Red
$pgse.Configuration.Colors.Console.VerboseBackgroundColor = [System.Drawing.Color]::Black
$pgse.Configuration.Colors.Console.VerboseForegroundColor = [System.Drawing.Color]::Yellow
$pgse.Configuration.Colors.Console.DebugBackgroundColor   = [System.Drawing.Color]::Black
$pgse.Configuration.Colors.Console.DebugForegroundColor   = [System.Drawing.Color]::Yellow

#endregion

#region Clear the host.

# This is required in order to properly refresh the colors in the console. It is also required
# when changing the font.

Clear-Host

#endregion

#region Update the font if the control is found.

if (($embeddedConsoleWindow = $pgse.ToolWindows['PowerShellConsole']) -and
    ($richTextBox = $embeddedConsoleWindow.Control.Controls.Find('RichTextBox1',$true) | Select-Object -First 1)) {
	#region Store the old font.

	$oldFont = $embeddedConsoleWindow.Control.Font

	#endregion

	#region Now update the font.

	$embeddedConsoleWindow.Control.Font = "Lucida Console,$($oldFont.Size)"
	$richTextBox.Font = "Lucida Console,$($oldFont.Size)"

	#endregion
}

#endregion

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

	#region Revert to the previous theme for the embedded PowerShell Console.

	#region Reset the old theme colors.

	$pgse.Configuration.Colors.Console.BackgroundColor        = $oldColors.BackgroundColor
	$pgse.Configuration.Colors.Console.ForegroundColor        = $oldColors.ForegroundColor
	$pgse.Configuration.Colors.Console.WarningBackgroundColor = $oldColors.WarningBackgroundColor
	$pgse.Configuration.Colors.Console.WarningForegroundColor = $oldColors.WarningForegroundColor
	$pgse.Configuration.Colors.Console.ErrorBackgroundColor   = $oldColors.ErrorBackgroundColor
	$pgse.Configuration.Colors.Console.ErrorForegroundColor   = $oldColors.ErrorForegroundColor
	$pgse.Configuration.Colors.Console.VerboseBackgroundColor = $oldColors.VerboseBackgroundColor
	$pgse.Configuration.Colors.Console.VerboseForegroundColor = $oldColors.VerboseForegroundColor
	$pgse.Configuration.Colors.Console.DebugBackgroundColor   = $oldColors.DebugBackgroundColor
	$pgse.Configuration.Colors.Console.DebugForegroundColor   = $oldColors.DebugForegroundColor

	#endregion

	#region Clear the host.

	# This is required in order to properly refresh the colors in the console. It is also required
	# when changing the font.

	Clear-Host

	#endregion

	#region Reset the font.

	if (($embeddedConsoleWindow = $pgse.ToolWindows['PowerShellConsole']) -and
		($richTextBox = $embeddedConsoleWindow.Control.Controls.Find('RichTextBox1',$true) | Select-Object -First 1)) {
		$embeddedConsoleWindow.Control.Font = $oldFont
		$richTextBox.Font = $oldFont
	}

	#endregion

	#endregion
}

#endregion

# SIG # Begin signature block
# MIIdfwYJKoZIhvcNAQcCoIIdcDCCHWwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAX20qwhNm02va4ZOyOQidjfp
# y1mgghi8MIIDdTCCAl2gAwIBAgILBAAAAAABFUtaw5QwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw05ODA5
# MDExMjAwMDBaFw0yODAxMjgxMjAwMDBaMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJH
# bG9iYWxTaWduIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDaDuaZjc6j40+Kfvvxi4Mla+pIH/EqsLmVEQS98GPR4mdmzxzdzxtIK+6NiY6a
# rymAZavpxy0Sy6scTHAHoT0KMM0VjU/43dSMUBUc71DuxC73/OlS8pF94G3VNTCO
# XkNz8kHp1Wrjsok6Vjk4bwY8iGlbKk3Fp1S4bInMm/k8yuX9ifUSPJJ4ltbcdG6T
# RGHRjcdGsnUOhugZitVtbNV4FpWi6cgKOOvyJBNPc1STE4U6G7weNLWLBYy5d4ux
# 2x8gkasJU26Qzns3dLlwR5EiUWMWea6xrkEmCMgZK9FGqkjWZCrXgzT/LCrBbBlD
# SgeF59N89iFo7+ryUp9/k5DPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
# HRMBAf8EBTADAQH/MB0GA1UdDgQWBBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkq
# hkiG9w0BAQUFAAOCAQEA1nPnfE920I2/7LqivjTFKDK1fPxsnCwrvQmeU79rXqoR
# SLblCKOzyj1hTdNGCbM+w6DjY1Ub8rrvrTnhQ7k4o+YviiY776BQVvnGCv04zcQL
# cFGUl5gE38NflNUVyRRBnMRddWQVDf9VMOyGj/8N7yy5Y0b2qvzfvGn9LhJIZJrg
# lfCm7ymPAbEVtQwdpf5pLGkkeB6zpxxxYu7KyJesF12KwvhHhm4qxFYxldBniYUr
# +WymXUadDKqC5JlR3XC321Y9YeRq4VzW9v493kHMB65jUr9TU/Qr6cf9tveCX4XS
# QRjbgbMEHMUfpIBvFSDJ3gyICh3WZlXi/EjJKSZp4DCCBAcwggLvoAMCAQICCwEA
# AAAAAR5GQJ02MA0GCSqGSIb3DQEBBQUAMGMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRYwFAYDVQQLEw1PYmplY3RTaWduIENBMSEwHwYD
# VQQDExhHbG9iYWxTaWduIE9iamVjdFNpZ24gQ0EwHhcNMDgxMjE3MTc0ODAyWhcN
# MTExMjE3MTc0ODAyWjBhMQswCQYDVQQGEwJVUzEXMBUGA1UEChMOUXVlc3QgU29m
# dHdhcmUxFzAVBgNVBAMTDlF1ZXN0IFNvZnR3YXJlMSAwHgYJKoZIhvcNAQkBFhFz
# dXBwb3J0QHF1ZXN0LmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA1mza
# 2hKiiqZnaF1sHhuFRS7MEGq9tYhF7AFbJRvTvhCZk9sxK92thKBFyDSOzJauB7Zt
# j+1HwQzpqbbU94EsR09JOf8vB+xQKLCxaBP5YjwhjJzVy+1d6frVWYN1oVxPXRBM
# G7BnFgfRkOdtsg/Qn1Uqn1ENSozyjTuh5iduUy0CAwEAAaOCAUAwggE8MB8GA1Ud
# IwQYMBaAFNJb80smS6Ww5139Vn/28S44TlOgME4GCCsGAQUFBwEBBEIwQDA+Bggr
# BgEFBQcwAoYyaHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLm5ldC9jYWNlcnQvT2Jq
# ZWN0U2lnbi5jcnQwOQYDVR0fBDIwMDAuoCygKoYoaHR0cDovL2NybC5nbG9iYWxz
# aWduLm5ldC9PYmplY3RTaWduLmNybDAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzBLBgNVHSAERDBCMEAGCSsGAQQBoDIBMjAz
# MDEGCCsGAQUFBwIBFiVodHRwOi8vd3d3Lmdsb2JhbHNpZ24ubmV0L3JlcG9zaXRv
# cnkvMBEGCWCGSAGG+EIBAQQEAwIEEDANBgkqhkiG9w0BAQUFAAOCAQEAG9hUuQek
# ddDJ/pzfqo9p4hzKBkeKcVsunEeTUMNg90XzgdOYRFJPCD7T+gXXrTs6Y2xFmLJN
# G/2lQsjQ/32cBBN9zZdbX+ExhFfEV9/w0gbw3H/PfYkCRvp9VZlTafIt4MJCt/Zp
# guPQgggpWadScg7jQNyeHEg6H6c3WHO8PMiKcKJp9LuM1PKX9Bjy6F2k8rbdEAyJ
# u0mIiAcnEAc/KwoKBZVT1gnT3rkwgTgNlXw2hqT/Zcf8Jy4IDzbKzL+gYmDCNaju
# wAzhzaA05oZTLwhFV1sdc5MSJVJnMJVLpNO1jrhi5g6Oo6EmezM/kE8nzoXbmTlP
# JjOApuATvUdFlzCCBA0wggL1oAMCAQICCwQAAAAAASOeD6yzMA0GCSqGSIb3DQEB
# BQUAMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAw
# DgYDVQQLEwdSb290IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcN
# OTkwMTI4MTMwMDAwWhcNMTcwMTI3MTIwMDAwWjCBgTELMAkGA1UEBhMCQkUxGTAX
# BgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExJTAjBgNVBAsTHFByaW1hcnkgT2JqZWN0
# IFB1Ymxpc2hpbmcgQ0ExMDAuBgNVBAMTJ0dsb2JhbFNpZ24gUHJpbWFyeSBPYmpl
# Y3QgUHVibGlzaGluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AKKbdSqnE7oJcSQY36EGYikSntyedXPo31ZXaZYTVk/yyLwBWO0mhnILYPUZxVUD
# V5u5EMmh1HRA/2wA6OZTN/632nk+uFI46YEsnw4zUqbNcM5KXWL00WdevJdKB8q8
# 3Y1Hsc3xZVuFAbBLa97Nji71UOijnJ0mmGs2Y0EDcETwX+IldXlQfV+hBqJGDFWV
# RxTTkUaGaJnnJ/SU7JpBUfeW1HqM4USXaHED2FhvvbQQQu4NZnVGi0SW0jAAEgdj
# 90SbAXDKVm+cWJcqJxeLLnFSbUarpysPfxZIZMhS+gYXAAd010WzDPV4lXPoCu7E
# 4HKMHhGqHrtezvm0AO5zvc0CAwEAAaOBrjCBqzAOBgNVHQ8BAf8EBAMCAQYwDwYD
# VR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUFVF5GnwMWfnazdjEOhOayXgtf00wMwYD
# VR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nbG9iYWxzaWduLm5ldC9Sb290LmNy
# bDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAWgBRge2YaRQ2XyolQL30E
# zTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEAtXimonwEt3/Jf31qvHH6KTBgwvRi
# Hv5/Qx6bbuKyH3MLhXZbffVOSQYv1Pq3kUDv7W+NjhODVMUqAj0KpNyZC3q9dy/M
# QMGP88SMTnK6EHzm/2Qrx85sp/zXmnyORo0Bg01CO9ucP58yYVfXF7CzNmbws/1E
# b4E3sZROp1YlifWK1m0RYmJ5XEKQAhjTnCP8COhkRbktfoBbTq/DiimSg3gfkUE0
# r4XF/QeZTixc/sf9F7slJTFNcrW1KUtImjdvE8cRTkpFHn4vMZyr6FKv1meXNIhf
# DidqZlLRWsesMCwgON0r/zrrzhBFgqJ7G6Egc1abKpPmBFEGbBvcL4mUkzCCBBow
# ggMCoAMCAQICCwQAAAAAASAZwZBmMA0GCSqGSIb3DQEBBQUAMFcxCzAJBgNVBAYT
# AkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENB
# MRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcNMDkwMzE4MTEwMDAwWhcN
# MjgwMTI4MTIwMDAwWjBUMRgwFgYDVQQLEw9UaW1lc3RhbXBpbmcgQ0ExEzARBgNV
# BAoTCkdsb2JhbFNpZ24xIzAhBgNVBAMTGkdsb2JhbFNpZ24gVGltZXN0YW1waW5n
# IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwwy3Eg1NaIoz3jYF
# 8Dy69drNDlN7Rp+C8mIT18F3rbuBN35PHpOBwQYi2h1QhMaXlZKpk7Y9q4Z5GVR9
# DhYETMSIlyzGoahfFTrSZCvMPgx66KRWsR67z4TOjTU6NJxsLcB3tTCpH2fmOglE
# OkNyQaKRw0aaH7a5pw+vHHUbZCXnCGwUR/VHGt6O6qJjlX31qK1VomSbcm+5AnM/
# OYo5XMT+j/sRnL0QGUlj0EMii9arkpl0FM8wB75Pvf2Kj55a3208zFqZUJC5rcKX
# Q8Jf7c0zPYfMwaBbqWI7eH1ko6xNHyvXAxFscVSKsKuxHNZ9I9tABzcm21CvOD2m
# B3VvlwIDAQABo4HpMIHmMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdDgQWBBTowvHEMtwzNTe8ZXb1nBcuF0Us/jBLBgNVHSAERDBCMEAG
# CSsGAQQBoDIBHjAzMDEGCCsGAQUFBwIBFiVodHRwOi8vd3d3Lmdsb2JhbHNpZ24u
# bmV0L3JlcG9zaXRvcnkvMDMGA1UdHwQsMCowKKAmoCSGImh0dHA6Ly9jcmwuZ2xv
# YmFsc2lnbi5uZXQvcm9vdC5jcmwwHwYDVR0jBBgwFoAUYHtmGkUNl8qJUC99BM00
# qP/8/UswDQYJKoZIhvcNAQEFBQADggEBAF32yysNAUCEn4V6Q3Bq4MXnqgYA12cT
# yQiRMWVPFKipBdw4nmqgMAq9jceAKO5CRcqU895YRamAMgT1WVxqcAA5J5RN9bRG
# NOgcUzGys1QW6cxCq9XZWTAc+0YnJbiHI7HodYgkgx7Idjd7AUlFSKTt4l3SfJyi
# 3C26EFoSYmWrrgDHEDQ7y3K9FCQM3MN2J7Sn/uFYKfIOFp+ROR2JpuYPHIeM4lis
# kn4kPqrsFOc6MzSLxjusg6sPFGJ6uhotTUsbxTDwC5J5fTx44Pjm0hWWWZk5KzBh
# 6Lj4wKHpIhQReH3E3Im+wLuU4XKu67VAQE/vFx5YXtCoiZaskijpur8wggQuMIID
# FqADAgECAgsBAAAAAAElsLTMATANBgkqhkiG9w0BAQUFADBUMRgwFgYDVQQLEw9U
# aW1lc3RhbXBpbmcgQ0ExEzARBgNVBAoTCkdsb2JhbFNpZ24xIzAhBgNVBAMTGkds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBMB4XDTA5MTIyMTA5MzI1NloXDTIwMTIy
# MjA5MzI1NlowUjELMAkGA1UEBhMCQkUxFjAUBgNVBAoTDUdsb2JhbFNpZ24gTlYx
# KzApBgNVBAMTIkdsb2JhbFNpZ24gVGltZSBTdGFtcGluZyBBdXRob3JpdHkwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDNwj1ddyLQwn04MsMVgx9CajtT
# Zt1qNkQNac9ojYlFn34v7kI6M3w+ANOXatha1cNNkgpfBlD9v2zEA6KCYNjtUi4T
# dN6XxkUhe1X26rFkA/x0a7Jfx2xsQxSKJBA3SZWB0kgSpaJ2SVAhf8qFcwo8XbUu
# rZCqXk0yyxeT2X+WwMCJZVbZxbE/mBsn+knuHRvLBowwHDvFp3BbqKsYWv7I9o6/
# AV2PYZg0D1hR/98y6lRlHBQrbPwMkBln7ZvZ2mOb1loko3SOCCMAoZK1HgvRCKBm
# f5Ibo+2AZAJJj7aE79FVjl6pl1rFCAKIlFa/kusqLQY1krU3NjHsw/56O8KFAgMB
# AAGjggEBMIH+MB8GA1UdIwQYMBaAFOjC8cQy3DM1N7xldvWcFy4XRSz+MDwGA1Ud
# HwQ1MDMwMaAvoC2GK2h0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5uZXQvVGltZXN0YW1w
# aW5nMS5jcmwwHQYDVR0OBBYEFKqqporvpGRz1pXieciP6s+lYCnKMAkGA1UdEwQC
# MAAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMEsGA1Ud
# IAREMEIwQAYJKwYBBAGgMgEeMDMwMQYIKwYBBQUHAgEWJWh0dHA6Ly93d3cuZ2xv
# YmFsc2lnbi5uZXQvcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQEFBQADggEBALyJ7P7m
# NlWTXHnUEXqGgI8XtpOybZuRoVYYEcZV6vYI7a2bnvUrgci73WB7G0eZHm1APh2A
# whPVjgQFL9vnrlKeaIRyoeVKYDz4m9UvRtjDsreTU6ybbEMkJNHx/OlWLjQRWBhD
# 6u//NHRsoMBsf60DGWmIHpVgyru9DLt278cksIHGODHPNq0MOLiQIISbLo8ouZ/2
# ypQnzaw5YVfg45VanHaSMPXeppc9chwqYDKoM02GNTOKXPOk/fcGLOFrSzD1y9ND
# YvhBud59IMsFjI4s9l81/TONQollCDYso4n0WoWLsLl722zLofjSDhu7l3zRJ3m+
# nXw75qdWNNjJkakwggTTMIIDu6ADAgECAgsEAAAAAAEjng+vJDANBgkqhkiG9w0B
# AQUFADCBgTELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# JTAjBgNVBAsTHFByaW1hcnkgT2JqZWN0IFB1Ymxpc2hpbmcgQ0ExMDAuBgNVBAMT
# J0dsb2JhbFNpZ24gUHJpbWFyeSBPYmplY3QgUHVibGlzaGluZyBDQTAeFw0wNDAx
# MjIxMDAwMDBaFw0xNzAxMjcxMDAwMDBaMGMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRYwFAYDVQQLEw1PYmplY3RTaWduIENBMSEwHwYD
# VQQDExhHbG9iYWxTaWduIE9iamVjdFNpZ24gQ0EwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCwsfKAAHDO7MOMtJftxgmMJm+J32dZgc/eFBNMwrFF4lN1
# QfoHNm+6EXAolHxtcr0HFSVlOgn/hdz6e143hzjkx0sIgJieis1YCQLAwwFJlliI
# iSZZ9W3GucH7GCXt2GJOygpsXXDvztObKQsJxvbuthbUPFSOzF3gr9vdIwkyezKB
# FmIKBst6zzQhtm82trHOy5opNUA+nVh8/62CmPq41YnKNd3LzVcGy5vkv5SogJhf
# d5bwtuerdHlAIaZj6dAHkb2FOLSulqyh/xRz2qVFuE2Gzio879TfKA51qaiIE8Lk
# fGCT8iXMA4SX5k62ny3WtYs0PKvVODrIPcSx+ZTNAgMBAAGjggFnMIIBYzAOBgNV
# HQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU0lvzSyZL
# pbDnXf1Wf/bxLjhOU6AwSgYDVR0gBEMwQTA/BgkrBgEEAaAyATIwMjAwBggrBgEF
# BQcCARYkaHR0cDovL3d3dy5nbG9iYWxzaWduLm5ldC9yZXBvc2l0b3J5MDkGA1Ud
# HwQyMDAwLqAsoCqGKGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5uZXQvcHJpbW9iamVj
# dC5jcmwwTgYIKwYBBQUHAQEEQjBAMD4GCCsGAQUFBzAChjJodHRwOi8vc2VjdXJl
# Lmdsb2JhbHNpZ24ubmV0L2NhY2VydC9QcmltT2JqZWN0LmNydDARBglghkgBhvhC
# AQEEBAMCAAEwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHwYDVR0jBBgwFoAUFVF5GnwM
# WfnazdjEOhOayXgtf00wDQYJKoZIhvcNAQEFBQADggEBAB5q8230jqki/nAIZS6h
# XaszMN1sePpL6q3FjewQemrFWJc5a5LzkeIMpygc0V12josHfBNvrcQ2Q7PBvDFZ
# zxg42KM7zv/KZ1i/4PGsYT6iOx68AltBrERr9Sbz7V6oZfbKZaY/yvV366WGKlgp
# Vvi+FhBA6dL8VyxjYTdmJTkgLgcDoDYDJZS9fOt+06PCxXYWdTCSuf92QTUhaNEO
# XlyOwwNg5oBA/MBdolRubpJnp4ESh6KjK9u3Tf/k1cflBebV8a78zWYYIfM+R8nl
# lUJhLJ0mgLIPqD0Oyad43250jCxG9nLpPGRrKFXES2Qzy3hUEzjw1XEG1D4NCjUO
# 4LMxggQtMIIEKQIBATByMGMxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxT
# aWduIG52LXNhMRYwFAYDVQQLEw1PYmplY3RTaWduIENBMSEwHwYDVQQDExhHbG9i
# YWxTaWduIE9iamVjdFNpZ24gQ0ECCwEAAAAAAR5GQJ02MAkGBSsOAwIaBQCgeDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEW
# BBR/mephCHFEwS7NK364cWz8iYDm6DANBgkqhkiG9w0BAQEFAASBgJSWWzJxDr/5
# K1znLMQWhBD5tFDBPjFL6bkYPBtwTFJgQwKTEbZ7fJPWtMEXP6eUZ1/h6GCGTACg
# ShHR5bnmDpka/Hpu1IZc2QwPd4J369DJD9uh0moFgsbCuuwWaKhw8XvVNDnNhd7m
# ykg6fO3nUZygc/BBEAbWKL3DObp0b6+WoYIClzCCApMGCSqGSIb3DQEJBjGCAoQw
# ggKAAgEBMGMwVDEYMBYGA1UECxMPVGltZXN0YW1waW5nIENBMRMwEQYDVQQKEwpH
# bG9iYWxTaWduMSMwIQYDVQQDExpHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQQIL
# AQAAAAABJbC0zAEwCQYFKw4DAhoFAKCB9zAYBgkqhkiG9w0BCQMxCwYJKoZIhvcN
# AQcBMBwGCSqGSIb3DQEJBTEPFw0xMTAyMjcyMjIwMTRaMCMGCSqGSIb3DQEJBDEW
# BBRZ2IseIOQ6iJ8X2w+SffhEgDozcTCBlwYLKoZIhvcNAQkQAgwxgYcwgYQwgYEw
# fwQUrt9992u6JBDWfbrxj1uhW0F+SWwwZzBYpFYwVDEYMBYGA1UECxMPVGltZXN0
# YW1waW5nIENBMRMwEQYDVQQKEwpHbG9iYWxTaWduMSMwIQYDVQQDExpHbG9iYWxT
# aWduIFRpbWVzdGFtcGluZyBDQQILAQAAAAABJbC0zAEwDQYJKoZIhvcNAQEBBQAE
# ggEAUcMDZiuHsMPWNbUwoY1zJD1QQukn+YR1RMNQISE0nY8+OJAEqP1M7e0SD/hT
# CaQ5ZjPoa4vrpYtjJUxRjYsfXGS1F6qQ/jdxMLeJ97ftcBp7C4wo79eJl39wQdsU
# q6GSQ3hXWgIqR/DUQsiUpnRvM9OagxIaQBam9II55WjBUGcz0+JwrMrypzNx3CIX
# eM1TXDBSccJJ9bZt0ZDkz07IGroek+QxTlfJP4a188AIuOH9hGEnSHS+WFBA1Vsn
# Jm9qlPEeWLI1dtLjS4+ZFm2UYi8zCNI5zzzdp/f+H9VCeo1rkVkApxu348kdXVvn
# xpSNb24HVxFnACq/8E9A2fGagQ==
# SIG # End signature block
