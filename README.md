# media-copytool
PowerShell-based, GUI-including script that not only copies your files, but also verifies them afterwards.

## Prerequisites
At the moment:
- Windows >= XP (Robocopy and Xcopy are used)
    - For XP, you need the [Windows Server 2003 Resource Kit Tools](https://www.microsoft.com/en-us/download/details.aspx?id=17657) to get Robocopy. From Vista onwards, Robocopy should be included.
- [PowerShell >= Version 3](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- For the GUI: [.NET Framework >= 4.6](https://www.microsoft.com/en-us/download/details.aspx?id=55170)

## Installing
* [Download the zip](https://github.com/flolilo/media-copytool/archive/master.zip)
* Extract files to a folder
* Start the script.

### Troubleshooting
If you cannot start the script:
* Check if PowerShell's `Set-ExecutionPolicy` [is set correctly](https://superuser.com/a/106363/703240),
* Check if prerequisites are met.

## Readme
:uk: I recommend using the readme-file `README.rtf` (fill in * according to the version you are using) or using `Get-Help .\media_copytool.ps1 -detailed` in PowerShell - as of now, I still have to get used to GitHub's styling (and its limitations for a complete readme). :uk:

:de: Die Readme-Datei hat auch einen deutschsprachigen Teil (anders als der Befehl `Get-Help .\media_copytool.ps1 -detailed`). :de:

## To do
- [ ] Option to avoid copying a file that exists more than once in the input more than one time. (E.g. .\DCIM\File_1.jpeg & .\DCIM\Sub\File_1.jpeg -> .\Out\File_1.jpeg)
- [ ] Making the output look nice(r)
- [ ] Option to create a 7zip-archive for mirror-copying
- [ ] Option to unmount USB drives after finishing (first) copy
- [ ] Checking if the volume exists if output-path(s) are not found (instead of looking for the parent directory)
- [ ] Multithreading Get-FileHash operations
- [ ] Multithreading the GUI