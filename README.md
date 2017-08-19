# media-copytool
PowerShell-based, GUI-including script that not only copies your files, but also verifies them afterwards.

## Prerequisites
At the moment:
- Windows >= XP (Robocopy and Xcopy are used)
    - For XP, you need the [Windows Server 2003 Resource Kit Tools](https://www.microsoft.com/en-us/download/details.aspx?id=17657) to get Robocopy. From Vista onwards, Robocopy should be included.
    - I am not sure if PowerShell Version >= 3 is supported on WinXP.
- [PowerShell >= Version 3](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- For the GUI: [.NET Framework >= 4.6](https://www.microsoft.com/en-us/download/details.aspx?id=55170)
- Since v0.6: [PoshRSJob](https://github.com/proxb/PoshRSJob); as of now, it's only used for replacing preventsleep.ps1, but in future releases, it will also speed up Hash-operations.
    - You can still use the old version - it's in the [0.5-branch](https://github.com/flolilo/media-copytool/archive/0.5---without-RSJob.zip) and will get important bugfixes as long as the code has any similiarity with the master-branch. (No promise, just an estimate!)
    - To install PoshRSJob, open PowerShell as administrator and run `Install-Module -Name PoshRSJob`

## Installing
* [Download the zip](https://github.com/flolilo/media-copytool/archive/master.zip)
* Extract all files to a folder (you can omit the .md-files and the LICENSE-file if you want)
* Start the `media_copytool.ps1`-script.

### Troubleshooting
If you cannot start the script:
* Check if PowerShell's `Set-ExecutionPolicy` [is set correctly](https://superuser.com/a/106363/703240),
* Check if prerequisites are met.

## Readme
:uk: I recommend using the readme-file `README.rtf` or using `Get-Help .\media_copytool.ps1 -detailed` in PowerShell - as of now, I still have to get used to GitHub's styling (and its limitations for a complete readme). :uk:

:de: Die Readme-Datei hat auch einen deutschsprachigen Teil (anders als der Befehl `Get-Help .\media_copytool.ps1 -detailed`). :de:

## To do
- [ ] Checking if the volume exists if output-path(s) are not found (instead of looking for the parent directory) (High priority)
- [ ] Multithreading Get-FileHash operations (High priority)
- [ ] Allowing special characters like brackets in Paths (High priority, but seemingly complicated)
- [ ] Option to create a 7zip-archive for mirror-copying (Medium priority)
- [ ] Option to unmount USB drives after finishing (first) copy (Medium priority)
- [ ] Option to avoid copying a file that exists more than once in the input more than one time. (E.g. .\DCIM\File_1.jpeg & .\DCIM\Sub\File_1.jpeg -> .\Out\File_1.jpeg) (Low priority)
- [x] Making the output look nice(r) and especially make errors more transparent to users (Low priority)
- [ ] Multithreading the GUI (Low priority)
- [ ] Creating a second JSON-file for looked up files in output-path (eventually)
- [ ] :de: Deutsche Übersetzung (sinnvollerweise erst mit Message-Variablen, daher in weiter Ferne)
