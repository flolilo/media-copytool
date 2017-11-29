# Media-Copytool

Media-Copytool is my attempt to create a tool to easily (and switfly) copies files from my DSLR's memory-cards to my computer. Its feature-set now beats most (if not all) professional RAW-converters (except of course in converting RAWs ;-) ). And the fun doesn't end here - there are even more features to come! And best of all: it not only works with your camera, but with all files that you have! (Also, it's free.)

**Bug-reports, questions, and feature-requests would be very much appreciated!**

## :uk: [I just created a nice Wiki with all you need to know!](https://github.com/flolilo/media-copytool/wiki) :uk:

## :de: [Hier geht's zur deutschsprachigen Wiki mit allen wichtigen Infos!](https://github.com/flolilo/media-copytool/wiki) :de:


## To do
- [ ] Evaluate if option for overwriting existing files would make sense
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
