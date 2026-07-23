* Victimas RD shared path template.
* Copy this file to config/paths.local.do and edit the copy locally.
* Never commit config/paths.local.do.
* Use forward slashes so paths work consistently in Stata on Windows.

global project_root "C:/Users/USERNAME/Documents/GitHub/VictimasRD"
global dropbox_root "C:/Users/USERNAME/Dropbox (Personal)/VictimasRD"

* Dropbox sources are read-only inputs.
global data_root          "$dropbox_root/2 data"
global raw_root           "$data_root/1 Raw"
global working_input_root "$data_root/2 Working"
global coded_input_root   "$data_root/3 Coded"
global literature_root    "$dropbox_root/0 Literature Review"
global archive_output_root "$dropbox_root/3 output"

* Writable reproducible products belong under the Git project.
* build_root is ignored; output_root is eligible for reviewed Git outputs.
global build_root    "$project_root/build"
global output_root   "$project_root/output"
global figures_root  "$output_root/figures"
global tables_root   "$output_root/tables"
global metadata_root "$project_root/metadata"
global logs_root     "$project_root/logs"
