# media-copytool
:de: [Hier geht es zur deutschen Readme-Datei](https://github.com/flolilo/media-copytool/blob/master/README_GER.md). :de:

PowerShell-based, GUI-including script that not only copies your files, but also verifies them afterwards. *Now with multithreading for faster processing!*


## Prerequisites
- Windows >= XP (Robocopy and Xcopy are used)
    - For XP, you need the [Windows Server 2003 Resource Kit Tools](https://www.microsoft.com/en-us/download/details.aspx?id=17657) to get Robocopy. From Vista onwards, Robocopy should be included.
    - I am not sure if PowerShell Version >= 3 is supported on WinXP.
- [PowerShell >= Version 3](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- For the GUI: [.NET Framework >= 4.6](https://www.microsoft.com/en-us/download/details.aspx?id=55170)
- Since v0.6: [PoshRSJob](https://github.com/proxb/PoshRSJob); as of now, it's only used for replacing preventsleep.ps1, but in future releases, it will also speed up Hash-operations.
    - You can still use the old version - it's in the [0.5-branch](https://github.com/flolilo/media-copytool/archive/0.5---without-RSJob.zip) and will get important bugfixes as long as the code has any similiarity with the master-branch. (No promise, just an estimate!)
    - To install PoshRSJob, open PowerShell as administrator and run `Install-Module -Name PoshRSJob`.

## Installing
- [Download the zip](https://github.com/flolilo/media-copytool/archive/master.zip)
- Extract all files to a folder
- Start the `media_copytool.ps1`-script.

## How to use media-copytool
- Opening PowerShell and typing `Get-Help .\media_copytool.ps1 -detailed` should tell you everything you need.

## Troubleshooting
If you cannot start the script:
- Check if PowerShell's `Set-ExecutionPolicy` [is set correctly](https://superuser.com/a/106363/703240),
- Check if prerequisites are met.
- Perhaps don't place the script on the root of `C:\` ;-)
- Unfortunately, it is still required to avoid brackets `[ ]` in all file names and directories for the script to run. It should check for brackets and throw an error if it encounters some.

If the script takes very long to finish:
- Check your task manager: is the CPU / drive bottlenecking? If it is the drive: buy a faster one ;-)
    - If it's your CPU (and it is a bit younger than an [8086](https://en.wikipedia.org/wiki/8086)), please tell me what file(s) you tried to copy (size, file count and fomrmat(s)) and where exactly it started to slow down.
- Large history-files tend to slow down the duplicate-check. You can delete (manually or via the "overwrite"-option) it every time after formatting/emptying your sd-card (if you tend to use the script for importing photos as I do).

If the script aborts or throws weird errors:
- Please note as much as you can about your settings: parameters, paths and when it occured. Also copy the error message (it will always be shown in English, so one can look it up more easily). Open a ticket and/or contact me!
    - Run the script with `-debug 2` if you have trouble to determine when things got weird.
- Have you used brackets `[ ]` in paths or files? They seem to work now (since 0.6.3), but I can't still rule out problems with them with full confidence.


## To do
- [ ] Checking if the volume exists if output-path(s) are not found (instead of looking for the parent directory) (High priority)
- [x] Multithreading Get-FileHash operations
- [x] Allowing special characters like brackets in Paths
- [ ] Option to create a 7zip-archive for mirror-copying (Medium priority)
- [ ] Option to unmount USB drives after finishing (first) copy (Medium priority)
- [ ] Option to avoid copying a file that exists more than once in the input more than one time. (E.g. .\DCIM\File_1.jpeg & .\DCIM\Sub\File_1.jpeg -> .\Out\File_1.jpeg) (Low priority)
- [x] Making the output look nice(r) and especially make errors more transparent to users (Low priority)
- [ ] Multithreading the GUI (Low priority)
- [ ] Creating a second JSON-file for looked up files in output-path (eventually)
- [ ] :de: Deutsche Übersetzung (sinnvollerweise erst mit Message-Variablen, daher in weiter Ferne)
