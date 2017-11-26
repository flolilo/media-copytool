# media-copytool
:de: [Hier geht es zur deutschen Readme-Datei](https://github.com/flolilo/media-copytool/blob/master/README_GER.md). :de:

Media-Copytool is my attempt to create a tool to easily (and switfly) copies files from my DSLR's memory-cards to my computer. Its feature-set now beats most (if not all) professional RAW-converters (except of course in converting RAWs ;-) ). And the fun doesn't end here - there are even more features to come! And best of all: it not only works with your camera, but with all files that you have! (Also, it's free.)


**Bug-reports, questions, and feature-requests would be very much appreciated!**

## Features
- Copying files with robust methods and then checking the files with SHA1-hashes, so there is no possibility anything gets compromised on the way
- Allowing to copy files to 2 different locations for a fast backup-option
- By keeping a history-file with all already copied files, it can avoid copying files again. That's great if you don't like to format your memory card every time.
- Offering both a GUI and command line parameters
- Using multi-threaded hash-calculations and copy-streams for fast operation (usually 2-8 times faster than `for`-loops - see [the statoistics on this matter!](https://github.com/flolilo/media-copytool/blob/master/Stats/Stats.md))
- By using built-in tools and cmdlets like Robocopy and Get-FileHash for all operations, very few prerequisites are needed
- Allowing you to choose a variety of subfolder-styles
- Built-in fail-saves should tell you when and if problems occur
- Automatically preventing your computer from going to standby while the script is running
- Preset for copying the most common media-files; option to add customized search-parameters (such as `*.rtf`)
- Option to remember all settings for future executions

## Prerequisites
- Windows >= XP (Robocopy and Xcopy are used)
    - For XP, you need the [Windows Server 2003 Resource Kit Tools](https://www.microsoft.com/en-us/download/details.aspx?id=17657) to get Robocopy. From Vista onwards, Robocopy should be included.
    - I am not sure if PowerShell Version >= 3 is supported on WinXP. If you cannot figure out a way to get it up and running on WinXP, then I fear that you won't be able to run the script.
- [PowerShell >= Version 3](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- For the GUI: [.NET Framework >= 4.6](https://www.microsoft.com/en-us/download/details.aspx?id=55170)
- Since v0.6: [PoshRSJob](https://github.com/proxb/PoshRSJob); as of now, it's only used for replacing preventsleep.ps1, but in future releases, it will also speed up Hash-operations.
    - You can still use the old version - it's in the [ST-branch](https://github.com/flolilo/media-copytool/archive/0.5---without-RSJob.zip) and will get important bugfixes as long as the code has any similiarity with the master-branch. (No promise, just an estimate!)
    - To install PoshRSJob, open PowerShell as administrator and run `Install-Module -Name PoshRSJob`.
- To use `-ZipMirror` (to create an .zip-archive in the additional output-path), [7-Zip](http://www.7-zip.org/) is needed. The script will look for `7z.exe` in its own path, but also in the usual installation folders of 7-Zip (both 32bit and 64bit). So a regular installation of 7-Zip will do.

## Installing
- [Download the zip](https://github.com/flolilo/media-copytool/archive/master.zip)
- Extract all files to a folder
- Start the `media_copytool.ps1`-script.

## How to use media-copytool
- Opening PowerShell and typing `Get-Help .\media_copytool.ps1 -detailed` should tell you everything you need.

## Troubleshooting
#### If you cannot start the script:
- Don't launch the script directly, but open a PowerShell-Console, `cd` (or `Set-Location`) to the script's folder and then start it by calling it - this way, it can't close before you can read the error message.
- Check if PowerShell's `Set-ExecutionPolicy` [is set correctly](https://superuser.com/a/106363/703240),
    - Run PowerShell as administrator, type `Set-ExecutionPolicy RemoteSigned`.
- Check if prerequisites are met.
- Perhaps don't place the script on the root of `C:\` ;-)
- Unfortunately, it is still recommended to avoid brackets `[ ]` in all file names and directories for the script to run. It should check for brackets and throw an error if it encounters some.

#### If the script takes very long to finish:
- Check your task manager: is the CPU / drive bottlenecking? If it is the drive: buy a faster one ;-)
    - If it's your CPU (and it is a bit younger than an [8086](https://en.wikipedia.org/wiki/8086)), please tell me what file(s) you tried to copy (size, file count and fomrmat(s)) and where exactly it started to slow down.
- Large history-files tend to slow down the duplicate-check. You can delete (manually or via the "overwrite"-option) it every time after formatting/emptying your sd-card (if you tend to use the script for importing photos as I do).
- Try `-ThreadCount 2` or `-ThreadCount 24` - it can have an impact, especially on slow drives.

#### If the script aborts or throws weird errors:
- Please note as much as you can about your settings: parameters, paths and when it occured. Also copy the error message (it will always be shown in English, so one can look it up more easily). Open a ticket and/or contact me!
    - Run the script with `-debug 2` if you have trouble to determine when things got weird.
- Have you used brackets `[ ]` in paths or files? They seem to work now (since 0.6.3), but I can't still rule out problems with them with full confidence.

#### If the script just starts running, but you want the GUI to appear:
- Run the script with `-GUI_CLI_direct "GUI"` - if you want that to be the standard setting, activate "Remember settings" in the GUI.

#### If you want to copy from/to a network-path (such as `\\192.168.0.2\pictures`):
- Either map the path to a drive letter via Windows Explorer (or PowerShell)...
- ...or just type it into the correlating text-field.

## Limitations
- Does not work with MTP-devices (such as Android smartphones). Workaround: Copy the files from your MTP-device to your computer and then run media-copytool.
- Safely removing devices does not work with all external drives. *This is on my list, though it seems complicated.*
- While there are many failsaves built-in, one can break things if one wants to. Though even then, no data-loss should occur.
- Although multi-threading works, the thread-count is a tricky thing: setting it too high will slow the script down, even. That's why there's a slider for that.
- No support for non-Windows-OSs, *though I plan to achieve that someday*.

## To do
- [ ] Evaluate option for overwriting existing files
- [ ] Creating a Pester-script (high priority)
- [x] Making all `for`-loops multithreaded (where possible)
- [x] Evaluating the usefulness of Posh-RSJob (**Cuntributions are welcome!**)
- [x] GUI with tabs instead of dropdowns
- [x] Option to deactivate copy-verification, thus enabling fast copying.
- [x] Option to just Robocopy files over in their original subfolders (so like `robocopy InputPath OutputPath /MIR`)
- [x] More subfolder-styles
- [x] Reaming files by date
- [x] Checking if the volume exists if output-path(s) are not found (instead of looking for the parent directory)
- [x] Multithreading Get-FileHash operations
- [x] Allowing special characters like brackets in Paths
- [x] Option to create a zip-archive for mirror-copying
- [x] Option to unmount USB drives after finishing (first) copy (done with limitations)
- [x] Option to avoid copying a file that exists more than once in the input more than one time. (E.g. .\DCIM\File_1.jpeg & .\DCIM\Sub\File_1.jpeg -> .\Out\File_1.jpeg) (Low priority)
- [x] Making the output look nice(r) and especially make errors more transparent to users (Low priority)
- [x] Multithreading the GUI
- [x] ~~Creating a second JSON-file for~~ Include looked up files in output-path into history-file.
- [x] Only one JSON-Parameter-file, but with preset-arrays (high priority)
- [ ] :de: Deutsche Übersetzung (sinnvollerweise erst mit Message-Variablen, daher in weiter Ferne)
