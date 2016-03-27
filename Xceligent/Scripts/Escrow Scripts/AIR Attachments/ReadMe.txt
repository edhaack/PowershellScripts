2014.03.26 - E.Haack
Purpose of this Powershell Script is to pull down a list of attachment file (relative paths w/ filenames) specifically for A.I.R. needs.

This script will:

1. Create all directories needed for copying.
2. Execute a SQL Script to get three types of files:
	- Attachment
	- Attachment Thumbnail
	- Attachment Report
	(Not each attachment record will have all three of these files.)
3. Loop through each record from the result
	- Check for the existence of the file
	- Copy to the designated destination directory
	- Display which attachment the copy is on
	NOTE: This process takes approximately 15 hours to complete: 
		14 hours 46 minutes to copy: 1,361,364 files (110Gb) in 2000 directories - between 2 USB 3.0 drives
4. When complete, will display duration of script run-time.


Modifications may be necessary for Source and Destination directories, based on the location of the files, this script and other unknown factors (at this time).

