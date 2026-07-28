* Victimas RD shared path template.
* Copy this file to config/paths.local.do and edit the copy locally.
* Never commit config/paths.local.do.
* Use forward slashes so paths work consistently in Stata on Windows.

global project_root "C:/Users/USERNAME/Documents/GitHub/VictimasRD"
global dropbox_root "C:/Users/USERNAME/Dropbox (Personal)/VictimasRD"
global overleaf_root "C:/Users/USERNAME/Dropbox (Personal)/Apps/Overleaf/Collective Reparations"

* Dropbox data contract.
* Raw sources are immutable. Persistent data products belong in Working or
* Coded; code should prefer Stata tempfiles for scratch data within a run.
global data_root    "$dropbox_root/2 data"
global raw_root     "$data_root/1 Raw"
global working_root "$data_root/2 Working"
global coded_root   "$data_root/3 Coded"

global external_raw_root     "$raw_root/13 External administrative sources"
global legacy_working_root   "$working_root/0 Archive - legacy workflow through 2026-07-27"
global legacy_coded_root     "$coded_root/0 Archive - legacy workflow through 2026-07-27"
global pipeline_working_root "$working_root/1 Current pipeline"
global intermediate_root     "$pipeline_working_root/01 intermediate"
global staging_root          "$pipeline_working_root/02 staging"
global qa_data_root          "$pipeline_working_root/03 qa"
global external_derived_root "$pipeline_working_root/04 external derived"
global analysis_data_root    "$coded_root/1 Current analysis datasets"

global literature_root     "$dropbox_root/0 Literature Review"
global archive_output_root "$dropbox_root/3 output"

* Live Overleaf publication layer. Never use it for data or intermediates.
global manuscript_tex   "$overleaf_root/Working Paper.tex"
global overleaf_images  "$overleaf_root/Images"
global overleaf_tables  "$overleaf_root/Tables"

* Git contains no datasets. build_root is only a local ignored dependency/cache
* area; reviewed non-sensitive tables and figures belong under output_root.
global build_root    "$project_root/build"
global output_root   "$project_root/output"
global figures_root  "$output_root/figures"
global tables_root   "$output_root/tables"
global metadata_root "$project_root/metadata"
global logs_root     "$project_root/logs"
