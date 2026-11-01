/* Check configured destinations before the master creates or writes anything. */
version 19
capture program drop victimasrd_validate_storage
program define victimasrd_validate_storage
    version 19
    // shortcut: lexical checks cannot resolve junctions/8.3 aliases; qualify canonical non-linked roots on each machine.
    local roots project_root data_root raw_root working_root coded_root ///
        pipeline_working_root intermediate_root staging_root qa_data_root ///
        external_derived_root analysis_data_root external_raw_root ///
        legacy_working_root legacy_coded_root build_root output_root ///
        figures_root tables_root metadata_root logs_root
    foreach root of local roots {
        local path = lower(subinstr("${`root'}", "\", "/", .))
        local unc = substr("`path'", 1, 2) == "//"
        local body = cond(`unc', substr("`path'", 3, .), "`path'")
        while strpos("`body'", "//") {
            local body = subinstr("`body'", "//", "/", .)
        }
        local path = cond(`unc', "//`body'", "`body'")
        while substr("`path'", -1, 1) == "/" & strlen("`path'") > 1 {
            local path = substr("`path'", 1, strlen("`path'") - 1)
        }
        if !regexm("`path'", "^[a-z]:/") & substr("`path'", 1, 2) != "//" {
            display as error "`root' must be an absolute filesystem path."
            exit 198
        }
        if regexm("`path'/", "/[.][.]?/") {
            display as error "`root' cannot contain dot or parent-directory components."
            exit 198
        }
        if regexm("`path'", "[. ](/|$)") {
            display as error "`root' cannot contain Windows dot/space-suffixed components."
            exit 198
        }
        local `root'_path "`path'"
    }

    // Equality and either direction of containment are unsafe across custodians.
    if "`data_root_path'" == "`project_root_path'" | ///
        strpos("`data_root_path'", "`project_root_path'/") == 1 | ///
        strpos("`project_root_path'", "`data_root_path'/") == 1 {
        display as error "Git and Dropbox data_root must be disjoint."
        exit 198
    }
    local data_roots raw_root working_root coded_root
    foreach root of local data_roots {
        if strpos("``root'_path'", "`data_root_path'/") != 1 {
            display as error "`root' must be strictly inside data_root."
            exit 198
        }
        if "``root'_path'" == "`project_root_path'" | ///
            strpos("``root'_path'", "`project_root_path'/") == 1 | ///
            strpos("`project_root_path'", "``root'_path'/") == 1 {
            display as error "Git and Dropbox data roots must be disjoint."
            exit 198
        }
        foreach other of local data_roots {
            if "`root'" != "`other'" & ///
                ("``root'_path'" == "``other'_path'" | ///
                strpos("``root'_path'", "``other'_path'/") == 1) {
                display as error "Raw, Working, and Coded must be disjoint."
                exit 198
            }
        }
    }
    foreach root in build_root output_root {
        if strpos("``root'_path'", "`project_root_path'/") != 1 {
            display as error "`root' must be strictly inside project_root."
            exit 198
        }
    }
    local children pipeline_working_root intermediate_root staging_root ///
        qa_data_root external_derived_root analysis_data_root external_raw_root ///
        legacy_working_root legacy_coded_root figures_root tables_root ///
        metadata_root logs_root
    local parents working_root pipeline_working_root pipeline_working_root ///
        pipeline_working_root pipeline_working_root coded_root raw_root ///
        working_root coded_root output_root output_root project_root project_root
    forvalues index = 1/13 {
        local child : word `index' of `children'
        local parent : word `index' of `parents'
        if strpos("``child'_path'", "``parent'_path'/") != 1 {
            display as error "`child' must be strictly inside `parent'."
            exit 198
        }
    }
    foreach current in pipeline_working_root analysis_data_root {
        foreach archive in legacy_working_root legacy_coded_root {
            if "``current'_path'" == "``archive'_path'" | ///
                strpos("``current'_path'", "``archive'_path'/") == 1 | ///
                strpos("``archive'_path'", "``current'_path'/") == 1 {
                display as error "Current destinations and dated archives must be disjoint."
                exit 198
            }
        }
    }
end
