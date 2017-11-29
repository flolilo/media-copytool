## What is Media-Coypytool?
It's my attempt to create a reliable, fast, feature-rich, granular, and secure way to transfer files from A to B (and even C) with built-in tools from Microsoft Windows - like XCopy, Robocopy, and (obviously) PowerShell.

## Why should I care? / Is it the right tool for me?
Have you ever thought that importing with Lightroom takes forever? Have you ever copied a bunch of files with Windows Explorer, only to find out that it silently aborted? Do you want to not always format your card after each import? Ever got a corrupted file after copying that you found too late?

If you answered one (or more) of these with "yes", then Media-Copytool might be just the tool you are looking for. Just read on...

## Features:
- Three different ways of starting and controlling the program: a **GUI**, an interactive CLI, and a way to start the script right away.
- Copy files from A to B as fast as possible using Robocopy or Xcopy.
  - Copy files to C, as well! (Even as 7z-archive!)
- Verify your files after copying them by getting their hashes; if something went wrong, the script will re-cop the file.
- Choose the files you want to copy by their extensions (e.g. only JPEGs & RAWs).
- Decide where and how your file will be saved with presets for subfolders and naming-schemes!
- Don't want to check which files you already copied the last time? Media-Copytool can save a history-file for you to check that.
  - Or, if you don't want that, you can also let it check if files with the same properties are already in the destination path!
- Won't overwrite existing files - ever! _(Though an option for that is in evaluation...)_
- You need change your presets for some jobs? Don't worry, you can save and load them on-the-fly!
- You have to copy a few TB over night and don't want to change your computer's power settings? No worry, Media-Copytool will prevent your computer from going into standby!

### And the best of all:
- As much of the above as possible is multithreaded, and
- all of the above is optional and can be chaned to fit your demands from within the GUI!


## Limitations:
- Does not work with MTP-devices (such as Android smartphones). Workaround: Copy the files from your MTP-device to your computer and then run media-copytool.
- Safely removing devices does not work with all external drives. *This is on my list, though it seems complicated.*
- While there are many failsaves built-in, one can break things if one wants to. **Note: Even then, no data-loss should occur**.
- No support for non-Windows-OSs, *though I plan to achieve that someday*.
- Covfefe. **No, really.**
