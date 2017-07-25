# media-copytool
PowerShell-based, GUI-including script that not only copies your files, but also verifies them afterwards.

## ENGLISH - DEUTSCHE VERSION UNTERHALB

### FEATURES:
#### Basic explanation:
* First things first: It has a GUI. ;-)
* ...But you can also do everything from the PowerShell - See "PARAMETERS". Comes in handy if you can't install .NET Framework (so it should work on PS 6, even on Linux*/OSX*! [ * ... Not tested yet, though. Possibly the paths could be a problem, xcopy most certainly will be a problem...in good time, I will check ;-) ])
* User-Decision of file-formats to search for in the input-path (and all of its subfolders) - some are pre-specified, but you can also manually add formats (see "PARAMETERS", -CustomFormatsEnable & -CustomFormats)
* User-Decision of Subfolder-Style (None vs. some date-formatted styles, see  "PARAMETERS", -OutputSubfolderStyle))
* Ability to "remember" already (successfully) copied files by maintaining a JSON-Sheet, thus preventing duplicates
* User-Decision if this history-file should be used, ignored, resetted (see "PARAMETERS", -HistoryFile & -WriteHist)
* Additionally, the output-path (and all of its subfolders) can be checked for already copied files, effetively preventing duplicates even if other copying-methods are used regularly/sometimes/simultaneously. (see "PARAMETERS", -CheckOutputDupli).
* Copies files without caching the files in RAM - when it's done, it's done.
* If file with the same name and path is already there, it will rename the new file to "copyXYZ" (where XYZ is the first free number >= 1)
* Verifies the files afterwards by generating SHA1-hashes and comparing them.
* If verification fails, a second attempt to copy the malcopied files can be started.
* If verification succeeds, all gathered file-attributes are added to the JSON.
* If verification fails (twice), the malcopied files can be found as "filename.ext_broken", thus making it easier to find them.
* Ability to remember all settings.
* No files are deleted in the input-path (and all of its subfolders), only "filename.ext_broken"-files will be deleted on first attempt in the output-folder (and all of its subfolders)
* This means that it is impossible* to lose files with this script. ( * ... I tried my hardest to get it to delete anything and couldn't achieve it - if you can, you're either very clever or extremely stupid ;-) )
* Comes with a handy standby-preventing script named "preventsleep.ps1" - even if you copy 128 TB of files, you won't need to change the idle-time of your computer.

#### Step-by-step:
* 1-999) Open the .ps1-script and see for yourself - especially watch for the "DEFINITION"-tags.

### STARTING:
* Open Powershell (<Win>+<R> -> powershell or via Start-menu).
* Either navigate to the folder containing the script via Set-Location (e.g. Set-Location "D:\script_folder") and then start it via .\scriptname 
* Or specify all at the same time: "D:\script_folder\script_name.ps1" (quotes only neccessary if path contains spaces)
* If you want help, try Get-Help "D:\script_folder\script_name.ps1" -detailed or "D:\script_folder\script_name.ps1" -showparams 1
If it won't work: most likely you need to adjust the execution-policy for PowerShell:
* see https://superuser.com/a/106363/703240
* Go to Start-Menu, search for PowerShell, right-click it -> "Run as Administrator"
* Type set-executionpolicy remotesigned - done!

If you would like to start the script by double-clicking, there's a script named "powershell_doubleclick-behavior.ps1" in the package. Start it and gasp. ;-)


### PARAMETERS:
Parameters are easily-changeable values. Media-Copytool will take them via CLI or via GUI and can even remember them (if wanted) for the next run. This is a handy feature if you often use it for the same things (e.g. copying RAW-images from a SD-Card in "J:\" to "D:\My_Images".)

Explanation of parameters (CLI - the GUI has tooltips ;-) ):
-showparams		:	Show the parameters as the script has saved them.
-GUI_CLI_Direct	:	"GUI"		= Start Graphical User Interface
				"CLI"		= Start Interactive selection of options
				"Direct"	= Start with values as set in parameters.
-InputPath		:	Input-path
-OutputPath		:	Output-path
-MirrorEnable		:	Value of 1 enables additional output-path
-MirrorPath		:	Additional output-path
-PresetFormats	:	Formats to search for.
				Can = *.cr2,
				Nik = *.nrw & *.nef,
				Son = *.arw,
				Jpg = *.jpg & *.jpeg,
				Mov = *.mov & *.mp4,
				Aud = *.wav & *.mp3 & *.m4a
-CustomFormatsEnable:	Enable / disable custom formats to search for.  1 enables, 0 				disables.
-CustomFormats	:	Specify custom formats, separated by commata.
				"*" will search and copy ALL files,
				"*.ext1","*.ext2" will search and copy all files with 					specified formats,
				"media*" will copy all files starting with "media", regardless 				their format.
-OutputSubfolderStyle:	"none" = No Subfolder(s)
				"yyyy-mm-dd"	= e.g. 2017-01-31
				"yyyy_mm_dd"	= e.g. 2017_01_31
				"yy-mm-dd"	= e.g. 17-01-31
				"yy_mm_dd"	= e.g. 17_01_31
-HistoryFile		:	"use"		: Check history-file for already imported files.
				"delete"	: Delete/overwrite the file.
				"ignore"	: Ignore it for checking.
-WriteHist		:	Enable / disable writing stats of newly copied file to history-				file. 1 enables, 0 disables.
-InputSubfolderSearch:	Enable / disable searching in subfolders in the input-path.
				1 enables, 0 disables.
-DupliCompareHashes	:	Enable / disable comparing all hashes for duplicate-					verification. This will take up more time, especially with many 				files. 1 enables, 0 disables.
-CheckOutputDupli	:	Enable / Disable additional duplicate-verification by searching 				for similar files in the output-path. 1 enables, 0 disables 					feature.
-PreventStandby	:   	Prevent standby by starting additional script 						preventsleep.ps1. 1 enables, 0 disables.
-RememberInPath	:	Remember input-path. 1 enables, 0 disables feature.
-RememberOutPath	:	Remember output-path. 1 enables, 0 disables feature.
-RememberMirrorPath	:	Remember additional out-path. 1 enables, 0 disables feature.
-RememberSettings	:	Remember parameters (excl. Remember-Parameters).
				1 enables, 0 disables feature.
-debug			:	1 Shows additional verbose, 2 enables pausing after each 				step of the script. Default is 0.

You don't have to specify all parameters all the time: if you don't specify them, they will fall back to their remembered setting (-showparams 1 will show them to you). A few examples:

Copy Canon-RAWs, JPEGs, Movies and XMLs from F:\ to D:\ -- Delete the history-file -- Don't check the output-folder for duplicates -- Copy all items to yyyy-mm-dd - subfolders -- Show GUI -- Remember output-path and settings, but don't remember input-path:

.\media_copytool_v0-5.ps1 -InputPath "F:\" -OutputPath "D:\" -PresetFormats "Can","Jpg","Mov" -CustomFormatsEnable 1 -CustomFormats "*.xml" -CheckOutputDupli 0 -HistoryFile 1 -OutputSubfolderStyle 1 -GUI_CLI_Direct "GUI" -RememberInPath 0 -RememberOutPath 1 -RememberSettings 1

Coming from that, doing the exact same operation but with G:\ as input-path and without the GUI (and without remembering anything):

.\media_copytool_v0-5.ps1 -InputPath "G:\" -GUI_CLI_Direct "direct"

Hint: If .\media_copytool_v0-5.ps1 won't bring up the GUI, just try:
.\media_copytool_v0-5.ps1 -GUI_CLI_Direct "GUI" -RememberSettings = 1

### NOTES:
⦁	To function properly, this script will need write-access to the directory it is located in - so it's not wise to use C:\ for it. ;-)
⦁	This script will search for all needed files in its own path (e.g. D:\script folder\).+
⦁	You can rename the script itself (media_copytool_v0-4.ps1) to any name you like - but to function properly, preventsleep.ps1, media_copytool_README_v0-5.rtf, and media_copytool_fileshistory.json must not be renamed.
⦁	You can move the script any time you want - but again, please also copy all other needed files to the new directory.
⦁	If the script won't work any more (weird errors,...), please check if the path contains any spaces (spaces are the devil's work!). If the spaces prevent it from working, please send the error-message plus your script's path to me for mending it.
⦁	Please don't use brackets [ ] in paths or any text - they will most likely screw up everything. Parentheses ( ) will work without any problem. (It's on the fix-list!)



## DEUTSCH - ENGLISH VERSION ABOVE

### FEATURES:
#### Einfach erklärt:
* Zu allererst: es gibt eine GUI (also graphische Benutzeroberfläche). ;-)
* ...Es kann aber auch alles via PowerShell selbst eingestellt werden - Siehe "PARAMETER". Gut, falls man .NET Framework nicht installieren kann (theoretisch funktioniert es so auch mit PS 6, auch auf Linux*/OSX*! [ * ... Ist aber nicht getestet. Vermutlich sind die Pfade ein Problem, xcopy dürfte auch hapern...wenn mal Zeit ist werde ich mir das ansehen. ;-) ])
* Benutzer-Entscheidung bez. der zu suchenden Datei-Formate im Quellverzeichnis (und allen seinen Unterordnern) - es gibt ein paar voreingestellte Varianten, es können aber auch manuell Formate hinzugefügt werden (siehe "PARAMETER", -CustomFormatsEnable & -CustomFormats)
* Benutzer-Entscheidung bez. Unterordner-Stil (Keine Unterordner oder einige Datums-basierte Vorlagen, siehe "PARAMETER", -OutputSubfolderStyle)
* Fähigkeit, sich bereits (erfolgreich) kopierte Dateien durch die Pflege einer JSON-Tabelle zu "merken", somit Verhinderung von Duplikaten.
* Benutzer-Entscheidung bez. dieser History-Datei: benutzen, ignorieren, löschen (siehe "PARAMETER", -HistoryFile & -WriteHist)
* Zusätzlich kann der Zielpfad (und seine Unterordner) auf bereits früher kopierte Dateien untersucht werden, um Duplikate selbst dann zu vermeiden, wenn andere Kopier-Techniken eingesetzt werden/wurden (siehe "PARAMETER", -CheckOutputDupli).
* Kopiert die Dateien ohne System-Cache - das Programm ist wirklich fertig, wenn es fertig ist.
* Falls bereits eine Datei mit gleichem Namen vorhanden ist, wird an die neue Datei "copyXYZ" angehängt (XYZ entspricht der ersten freien Zahl >= 1).
* Verifiziert die kopierten Dateien nach dem Kopieren mit SHA1-Hashes und vergleicht diese.
* Falls die Verifikation scheitert kann ein zweiter Versuch gestartet werden.
* Falls die Verifikation gelingt werden alle gesammelten Datei-Attribute in die History-Datei geschrieben.
* Falls die Verifikation (nochmals) scheitert werden die fehlerhaften Dateien in "dateiname.ext_broken" umbenannt - so sind sie leicht auffindbar.
* Fähigkeit, alle Einstellungen für künftige Durchläufe zu speichern.
* Es werden keine Dateien im Quellverzeichnis (und seinen Unterordnern) gelöscht, während im Zielverzeichnis (samt Unterordnern) nur "dateiname.ext_broken"-Dateien vor dem zweiten Kopier-Versuch gelöscht werden.
* Somit ist es unmöglich*, durch dieses Programm Dateien zu verlieren. ( * ... Ich habe mein Bestes gegeben, dieses Programm zum Löschen der Dateien zu bringen - und bin gescheitert. Falls ihr es schafft seid ihr entweder genial - oder sehr dumm. ;-) )
* Das "beigelegte" Skript "preventsleep.ps1" verhindert einne Standby während der Ausführung - somit braucht man die Energieeinstellungen des Rechners nicht mal dann überprüfen, wenn man 128TB an Dateien kopieren möchte.

Schritt für Schritt:
* 1-999) Einfach selbst ins .ps1-Skript schauen - vor allem die "DEFINITION"-Tags dürften interessant sein.

STARTEN:
* Powershell öffnen (<Win>+<R> -> powershell oder  via Start-Menü).
* Entweder zum das Skript enthaltenden Pfad via Set-Location (e.g. Set-Location "D:\skript_ordner") navigieren und dann via .\skriptname starten...
* ...oder gleich den ganzen Pfad angeben: "D:\skript_ordner\skript name.ps1" (Anführungszeichen nur notwendig, falls Pfad Leerzeichen beinhaltet)

Falls das nicht funktioniert muss vermutlich erst noch die execution-policy in PowerShell eingestellt werden:
* siehe https://superuser.com/a/106363/703240
* Im Start-Menü die PowerShell suchen, Rechtsklick -> "Als Administrator ausführen"
* set-executionpolicy remotesigned eingeben - fertig!

Es ist auch möglich, das Skript via Doppelklick zu öffnen - dazu das beigelegte Skript "powershell_doubleclick-behavior.ps1" öffnen. Starten und Staunen! ;-)


### PARAMETER:
Parameter sind leicht zu ändernde Werte. Das Media-Copytool kann diese via Kommandozeile oder graphischem Benutzerinterface aufnehmen und sie (falls gewünscht) auch für die Zukunft speichern. Letzteres ist besonders dann nützlich, wenn man oft/immer dieselben Pfade und/oder Optionen benötigt (z.B. RAW-Bilder von einer SD-Karte in "J:\" nach "D:\Meine_Bilder" kopieren.)

Erklärung der Parameter (CLI - die GUI hat Tooltips ;-) ):

-showparams		:	Zeigt die Parameter an, wie sie im Skript gespeichert sind. 1 				aktiviert, 0 deaktiviert.
-GUI_CLI_Direct	:	"GUI"		= Graphische Benutzeroberfläche
				"CLI"		= Interktive Kommandozeilen-Eingabe
				"Direct"	= Start mit den (vor)gegebenen Parametern.
-InputPath		:	Quell-Pfad
-OutputPath		:	Ziel-Pfad
-MirrorEnable		:	Wert 1 aktiviert zusätzlichen Ziel-Pfad.
-MirrorPath		:	Zusätzlicher Ziel-Pfad
-PresetFormats	:	Formate, nach denen gesucht werden soll.
				Can = *.cr2,
				Nik = *.nrw & *.nef,
				Son = *.arw,
				Jpg = *.jpg & *.jpeg,
				Mov = *.mov & *.mp4,
				Aud = *.wav & *.mp3 & *.m4a
-CustomFormatsEnable:	(De)aktiviere zusätzliche benutzerdefinierte Formate.  1 					aktiviert, 0 deaktiviert.
-CustomFormats	:	Benutzerdefinierte Formate, mit Kommata getrennt.
				"*" sucht nach ALLEN Dateien,
				"*.ext1","*.ext2" sucht nach Dateien mit den 					entsprechenden Endungen,
				"media*" sucht alle dateien, die mit "media" beginnen, 					unabhängig von ihrem Format und was nach "media" kommt.
-OutputSubfolderStyle:	"none" = Kein(e) Unterordner
				"yyyy-mm-dd"	= z.B. 2017-01-31
				"yyyy_mm_dd"	= z.B. 2017_01_31
				"yy-mm-dd"	= z.B. 17-01-31
				"yy_mm_dd"	= z.B. 17_01_31
-HistoryFile		:	"use"		: History-Datei nach bereits kopierten 							  Dateien durchsuchen.
				"delete"	: History-Datei löschen/überschreiben.
				"ignore"	: History-Datei ignorieren.
-WriteHist		:	(De)aktiviere Schreiben von Eigenschaften der neuen 					Dateien in History-Datei. 1 aktiviert, 0 deaktiviert.
-InputSubfolderSearch:	(De)aktiviere suche nach Dateien in Unterordnern des 					Quellpfads. 1 aktiviert, 0 deaktiviert.
-DupliCompareHashes	:	(De)aktiviere Vergleich von Hashes aller gefundenen 					Dateien - der Vorgang wird hierdurch gerade bei vielen 					Dateien langsamer werden. 1 aktiviert, 0 deaktiviert.
-CheckOutputDupli	:	(De)aktiviere zusätzliche Duplikats-Verifikation (Vergleich mit 				bereits im Zielpfad vorhandenen Dateien). 1 aktiviert, 0 					deaktiviert.
-PreventStandby	:   	Verhindert Standby durch Ausführung des Skripts 					preventsleep.ps1. 1 aktiviert, 0 deaktiviert..
-RememberInPath	:	Quellpfad merken. 1 aktiviert, 0 deaktiviert.
-RememberOutPath	:	Zielpfad merken. 1 aktiviert, 0 deaktiviert.
-RememberMirrorPath	:	Zusätzlichen Zielpfad merken. 1 aktiviert, 0 deaktiviert.
-RememberSettings	:	Einstellungen merken (exkl. Remember-Parameter).
				1 aktiviert, 0 deaktiviert.
-debug			:	1 Zeigt zusätzliche Infos in der Konsole, 2 pausiert nach 					jedem Schritt im Skript. Standard ist 0.

Man muss nicht alle Parameter immer angeben: werden sie nicht spezifiziert, so rufen sie die letzte gespeicherte Einstellung ab (-showparams 1 zeigt diese an). Ein paar Beispiele:

Canon-RAWs, JPEGs, Movies und XMLs von F:\ nach D:\ kopieren -- History-Datei löschen -- Nicht nach Duplikaten suchen im Zielpfad -- Alle Dateien in Unterordner des Schemas jjjj-mm-dd kopieren -- Zeige GUI (in Deutsch) -- Zielverzeichnis und Einstellungen merken, nicht aber das Quellverzeichnis:

.\media_copytool_v0-5.ps1 -InputPath "F:\" -OutputPath "D:\" -PresetFormats "Can","Jpg","Mov" -CustomFormatsEnable 1 -CustomFormats "*.xml" -CheckOutputDupli 0 -HistoryFile 1 -OutputSubfolderStyle 1 -GUI_CLI_Direct "GUI" -RememberInPath 0 -RememberOutPath 1 -RememberSettings 1

Will man nun alles gleich machen, nur den Quellpfad auf G:\ setzen und die GUI deaktivieren, so genügt:

.\media_copytool_v0-5.ps1 -InputPath "G:\" -GUI_CLI_Direct "direct"

Tipp: Falls .\media_copytool_v0-5.ps1 die GUI nicht anzeigt, folgendes versuchen:
.\media_copytool_v0-5.ps1 -GUI_CLI_Direct "GUI" -RememberSettings 1


### SONSTIGES:
* Um korrekt zu funktionieren benötigt das Skript Schreibrechte in seinem Verzeichnis - C:\ sollte daher nicht verwendet werden. ;-)
* Dieses Skript sucht alle für die Funktion benötigten Dateien in seinem eigenen Verzeichnis (z.B. D:\skript ordner\).
* Das Skript selbst (media_copytool_v0-5.ps1) kann man umbenennen - nicht aber preventsleep.ps1, media_copytool_README_v0-5.rtf und media_copytool_fileshistory.json
* Das Skript kann jederzeit in ein anderes Verzeichnis verschoben werden - aber bitte die anderen Dateien mitübersiedeln.
* Falls das Skript nicht (mehr) funktioniert (komische Fehlermeldungen,...), bitte die Pfade auf Leerzeichen überprüfen und diese ggf. mit Unterstrichen ersetzen. (Leerzeichen sind böse!). Falls es dann geht, bitte die Fehlermeldung und den Pfad-Namen (mit Leerzeichen) an mich senden.
* Bitte keine eckigen Klammern [ ] in den Pfaden oder anderem Text verwenden - das Skript kann damit nicht umgehen. Normale Klammern ( ) sind kein Problem.  (Ist auf der Fix-Liste!)
