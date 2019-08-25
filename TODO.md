# To Do - AnTu photo project
 
 * fix corrupted .dop filenames
 	- find files that don't match yyyymmdd-hhmmss.ext.dop
	- from their content extract Sidecar.Source.Items.Name as filename
	- rename as filename .dop
	
* Check to have at least one EDIT file per ORIGINAL
	- if not create one using e.g. DxO

* Have new Directory IMG for unedited images (was former EDIT) and create new EDIT for manually edited ones.

* Check for exif entry `Software                        : DxO OpticsPro .*` and put them to EDIT

* Check usage of unique IDs, e.g. `uuidgen` or ExifTool `NewGUID`
	