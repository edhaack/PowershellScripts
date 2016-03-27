7z l -r Projects\CDX.zip > Projects\CDX.manifest
7z l -r Projects\CDXDirect.zip > Projects\CDXDirect.manifest
7z l -r Projects\ExternalLibraries.zip > Projects\ExternalLibraries.manifest
7z l -r Projects\ReportGenerationService.zip > Projects\ReportGenerationService.manifest
7z l -r Projects\ReportPortalService.zip > Projects\ReportPortalService.manifest
7z l -r Projects\ServicePortalWeb.zip > Projects\ServicePortalWeb.manifest
7z l -r Projects\xceligentApp.zip > Projects\xceligentApp.manifest

fciv Projects\CDX.zip -wp -xml Projects\CDX.md5 
fciv Projects\CDXDirect.zip -wp -xml Projects\CDXDirect.md5 
fciv Projects\ExternalLibraries.zip -wp -xml Projects\ExternalLibraries.md5 
fciv Projects\ReportGenerationService.zip -wp -xml Projects\ReportGenerationService.md5 
fciv Projects\ReportPortalService.zip -wp -xml Projects\ReportPortalService.md5 
fciv Projects\ServicePortalWeb.zip -wp -xml Projects\ServicePortalWeb.md5 
fciv Projects\xceligentApp.zip -wp -xml Projects\xceligentApp.md5 

fciv.exe -v -bp Projects -XML Projects\CDX.MD5
fciv.exe -v -bp Projects -XML Projects\CDXDirect.MD5
fciv.exe -v -bp Projects -XML Projects\ExternalLibraries.MD5
fciv.exe -v -bp Projects -XML Projects\ReportGenerationService.MD5
fciv.exe -v -bp Projects -XML Projects\ReportPortalService.MD5
fciv.exe -v -bp Projects -XML Projects\ServicePortalWeb.MD5
fciv.exe -v -bp Projects -XML Projects\xceligentApp.MD5
