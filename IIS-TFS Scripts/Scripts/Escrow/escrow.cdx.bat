

rd Xceligent\CDX
mkdir Xceligent\CDX

7z a Xceligent\CDX\CDX.zip C:\TFS\Common\Shared.References -r 
7z u Xceligent\CDX\CDX.zip C:\TFS\Product\CDX\Development\Development-Main\Xceligent.CDX -r 
7z u Xceligent\CDX\CDX.zip C:\TFS\Product\CDX\Development\Development-Main\Xceligent.CDX.Library -r 
7z l -r Xceligent\CDX\CDX.zip > Xceligent\CDX\escrow.CDX.manifest

fciv Xceligent\CDX\CDX.zip -wp -xml Xceligent\CDX\MD5.xml 

fciv.exe -v -bp Xceligent\CDX -XML Xceligent\CDX\MD5.xml 