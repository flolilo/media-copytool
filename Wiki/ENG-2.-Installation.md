Media-Copytool is a PowerShell-script. That means that it is perfectly portable and extremely easy to install. However, it also means that you have to meet a few requirements:

## Prerequisites:
- Windows >= XP (Robocopy and Xcopy are used)
    - For XP, you need the [Windows Server 2003 Resource Kit Tools](https://www.microsoft.com/en-us/download/details.aspx?id=17657) to get Robocopy. From Vista onwards, Robocopy should be included.
    - I am not sure if PowerShell Version >= 3 is supported on WinXP. If you cannot figure out a way to get it up and running on WinXP, then I fear that you won't be able to run the script.
- [PowerShell >= Version 3](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- For the GUI: [.NET Framework >= 4.6](https://www.microsoft.com/en-us/download/details.aspx?id=55170)
- Since v0.6: [PoshRSJob](https://github.com/proxb/PoshRSJob); it is used to speed up Hash-operations.
    - You can still use the old version - it's in the [ST-branch](https://github.com/flolilo/media-copytool/archive/0.5---without-RSJob.zip) and will get important bugfixes as long as the code has any similiarity with the master-branch. (No promise, just an estimate!)
    - To install PoshRSJob, open PowerShell as administrator and run `Install-Module -Name PoshRSJob`.
- To use `-ZipMirror` (to create an archive in the additional output-path), [7-Zip](http://www.7-zip.org/) is needed. The script will look for `7z.exe` in its own path, but also in the usual installation folders of 7-Zip (both 32bit and 64bit). So a regular installation of 7-Zip will do.

## Installing the script:
- [Download the zip](https://github.com/flolilo/media-copytool/archive/master.zip)
- Extract all files to a folder
- Start the `media_copytool.ps1`-script.
