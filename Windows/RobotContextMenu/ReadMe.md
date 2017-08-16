Plan:
- Create a context menu driven means for running all Robot Framework tests in the given directory, 
- Report the results to TestRail and finally 
- Open the report for the user.

Use TeamCity's build runner. Most of this work is already in place for that...

TODO Items:

Prep Work:
- Installer for context menu (run powershell script)
- Read variables from dot-sourced file

Nice to have:
- Encrypt passwords and ids (TestRail)
- Decrypt passwords and ids for use in main script

Main:
- Walk thru script to remove any TeamCity specific items
- Verify using variables...

