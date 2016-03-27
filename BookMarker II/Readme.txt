This latest powershell script version of bookmarker loads the csv file exported directly from IIS.

If the site is stopped, the bookmark file will not be created.

Be sure to have a directory on your desktop named "sites" for the link files to be sent to.


1. Open up a Powershell..
2. Change directory to this location (.ps1 script)
3. Export the IIS 6 Sites to a CSV file, save it in the same directory as this script, name it: 'sites.csv'
4. Create a new directory on your desktop for the link files... e.g. "sites"
4. run the script: ./BookMarker.ps1 -desktopDir "sites"
	-desktopDir is the name of the directory on your desktop
	
What will be displayed is html that you can copy for later... but once run, go to that new desktop directory and find your link file
