## Was ist das Media-Coypytool?
Es ist mein Versuch, ein zuverlässiges, schnelles, Feature-reiches, frei einstellbares und sicheres Tool für Datenübertragungen zwischen A und B (und optional C) zu erschaffen - und zwar mit bereits in Windows eingebauten Tools wie Robocopy, Xcopy und natürlich PowerShell.

## Warum sollte ich das brauchen? / Brauche ich das?
Dauert das Importieren der neuen Fotos mit Lightroom zu lange? Hat der Windows Explorer schon mal die eine oder andere Datei einfach nicht kopiert, ohne was zu sagen? War schon mal eine vormals gute Datei nach dem Kopieren defekt?

Falls deine Antwort auf eine dieser Fragen "ja" war, dann ist das Media-Copytool vielleicht das Tool, nachdem du gesucht hast.

## Features:
- Drei verschiedene Wege, das Programm zu starten und zu steuern: eine **GUI** (graphische Oberfläche), interaktive Konsolen-Eingabe und die Möglichkeit, das Programm direkt und unmittelbar zu starten.
- Dateien schnellstmöglich von A nach B kopieren mit Robocopy und Xcopy.
  - Natürlich auch nach C! (Wenn gewünscht sogar als 7z-Archiv!)
- Die kopierten Dateien werden mittels Hash auf Fehler in der Übertragung überprüft; wenn tatsächlich was schief ging, dann kopiert das Programm die Dateien nochmal.
- Wähle die zu kopierenden Dateien nach Dateiformat aus (z.B. nur JPEGs & RAWs).
- Möglichkeit, Unterordner und Datebenennung nach Datum und Uhrzeit vorzunehmen.
- Du willst nicht jedes mal händisch prüfen, welche Dateien du bereits übertragen hast? Media-Copytool kann dafür eine History-Datei anlegen, die das für dich übernimmt.
  - Falls du das nicht willst, kann es außerdem das Zielverzeichnis nach bereits vorhandenen Dateien durchsuchen!
- Überschreibt niemals Dateien! _(Eine Option dafür überlege ich aber gerade...)_
- Du hast verschiedene Aufgaben für das Media-Copytool und willst nicht immer alles händisch einstellen? Keine Sorge - Presets können schnell und einfach erstellt und geladen werden!
- Du musst ein paar TB an Daten kopieren und willst die Energieeinstellungen deines Computers nicht ändern? Keine Sorge, auch dafür hat Media-Copytool eine Lösung und verhindert einen eventuellen Standby bis alles abgeschlossen ist!

### Und das Beste:
- So viel wie nur möglich wurde gemultithreaded, also durch Verteilung auf die Prozessoren beschleuningt.
- Alle der oben genannten Optionen sind vom Benutzer völlig frei steuerbar!

## Was nicht funktioniert:
- MTP-Geräte (wie Android-Smartphones). Workaround: Dateien zuerst via Explorer vom MTP-Gerät zum Computer kopieren, dann mit media-copytool weitermachen.
- Das sichere Entfernen funktioniert bei manchen Geräten nicht. *Soll behoben werden, ist aber scheinbar schwierig.*
- Auch wenn Fail-Saves eingebaut sind, die grobe Probleme vermeiden sollten: Wenn man es drauf anlegt ist es dennoch möglich, das Skript zu Fehlern zu bewegen. **Datenverlust sollte aber auch dann nicht möglich sein**.
- Kein Support für andere Betriebssysteme als Windows *- Support ist aber irgendwann geplant*.
- Leider noch keine deutsche Übersetzung - das könnte leider auch noch dauern, denn wenn, dann soll das ordentlich gemacht werden...
