## Troubleshooting
#### If you cannot start the script:
- Don't launch the script directly, but open a PowerShell-Console, `cd` (or `Set-Location`) to the script's folder and then start it by calling it - this way, it can't close before you can read the error message.
- Check if PowerShell's `Set-ExecutionPolicy` [is set correctly](https://superuser.com/a/106363/703240),
    - Run PowerShell as administrator, type `Set-ExecutionPolicy RemoteSigned`.
- Check if [all prerequisites](https://github.com/flolilo/media-copytool/wiki/ENG-2.-Installation#prerequisites) are met.
- Perhaps don't place the script on the root of `C:\` ;-)
- Unfortunately, it is still recommended to avoid brackets `[ ]`, `$`, and backticks ` `` ` in all file names and directories for the script to run. It should check for brackets and throw an error if it encounters some.

#### If the script takes very long to finish:
- Check your task manager: is the CPU / drive bottlenecking? If it is the drive: buy a faster one ;-)
    - If it's your CPU (and it is a bit younger than an [8086](https://en.wikipedia.org/wiki/8086)), please tell me what file(s) you tried to copy (size, file count and fomrmat(s)) and where exactly it started to slow down.
- Large history-files tend to slow down the duplicate-check. You can delete (manually or via the "overwrite"-option) it every time after formatting/emptying your sd-card (if you tend to use the script for importing photos as I do).

#### If the script aborts or throws weird errors:
- Please note as much as you can about your settings: parameters, paths and when it occured. Also copy the error message (it will always be shown in English, so one can look it up more easily). Open a ticket and/or contact me!
    - Run the script with `-debug 2` if you have trouble to determine when things got weird.
- Have you used brackets `[ ]` in paths or files? They seem to work now (since 0.6.3), but I can't still rule out problems with them with full confidence.

#### If the script just starts running, but you want the GUI to appear:
- Run the script with `-GUI_CLI_direct "GUI"`. If you have to do that every time, open the script in a text editor and search for `Param(`, and there, change it to `$GUI_CLI_direct = "GUI"`.

#### If you want to copy from/to a network-path (such as `\\192.168.0.2\pictures`):
- Either map the path to a drive letter via Windows Explorer (or PowerShell)...
- ...or just type it into the correlating text-field.