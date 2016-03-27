<#
===========================================================================
PURPOSE: Resize image, w/ source, target and quality

OVERVIEW:
1)
2)
3)

CREATED:
1.0 4/20/2015 - ESH - Initial release

UPDATED:

FOUND AT: http://benoitpatra.com/2014/09/14/resize-image-and-preserve-ratio-with-powershell/
===========================================================================
#>

Param ( [Parameter(Mandatory=$True)] [ValidateNotNull()] $imageSource,
[Parameter(Mandatory=$True)] [ValidateNotNull()] $imageTarget,
[Parameter(Mandatory=$true)][ValidateNotNull()] $quality )
 
if (!(Test-Path $imageSource)){throw( "Cannot find the source image")}
if(!([System.IO.Path]::IsPathRooted($imageSource))){throw("please enter a full path for your source path")}
if(!([System.IO.Path]::IsPathRooted($imageTarget))){throw("please enter a full path for your target path")}
if ($quality -lt 0 -or $quality -gt 100){throw( "quality must be between 0 and 100.")}
 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$bmp = [System.Drawing.Image]::FromFile($imageSource)
 
#hardcoded canvas size...
$canvasWidth = 194.0
$canvasHeight = 194.0
 
#Encoder parameter for image quality
$myEncoder = [System.Drawing.Imaging.Encoder]::Quality
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($myEncoder, $quality)
# get codec
$myImageCodecInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|where {$_.MimeType -eq 'image/jpeg'}
 
#compute the final ratio to use
$ratioX = $canvasWidth / $bmp.Width;
$ratioY = $canvasHeight / $bmp.Height;
$ratio = $ratioY
if($ratioX -le $ratioY){
$ratio = $ratioX
}
 
#create resized bitmap
$newWidth = [int] ($bmp.Width*$ratio)
$newHeight = [int] ($bmp.Height*$ratio)
$bmpResized = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
$graph = [System.Drawing.Graphics]::FromImage($bmpResized)
 
$graph.Clear([System.Drawing.Color]::White)
$graph.DrawImage($bmp,0,0 , $newWidth, $newHeight)
 
#save to file
$bmpResized.Save($imageTarget,$myImageCodecInfo, $($encoderParams))
$bmpResized.Dispose()
$bmp.Dispose()
