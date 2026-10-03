/*------------------------------------------------------------------------------
Victimas RD: native, fail-closed environment lock. No installation or data writes.
The CSV records file identities, not redistributed software or historical proof.
------------------------------------------------------------------------------*/
version 19

capture program drop _vrd_check_environment
program define _vrd_check_environment
    version 19
    syntax, MANifest(string) ADORoot(string)

    * Reject edited/incomplete locks before trusting any paths or fingerprints.
    quietly checksum "`manifest'"
    if r(checksum) != 598622890 | r(filelen) != 2755021 {
        display as error "Environment manifest differs from the reviewed lock."
        exit 9
    }
    if c(stata_version) != 19 | "`c(born_date)'" != "12 Aug 2026" | ///
        "`c(os)'" != "Windows" | c(bit) != 64 {
        display as error "Stata runtime differs from the audited Windows-64 Stata-19 build."
        exit 9
    }
    local search_path = subinstr(subinstr(subinstr( ///
        c(adopath), char(96), "", .), char(34), "", .), char(39), "", .)
    if "`search_path'" != "BASE;PLUS" {
        display as error "Only official BASE and locked project PLUS may resolve code."
        exit 9
    }

    quietly import delimited using "`manifest'", varnames(1) ///
        stringcols(_all) encoding("utf-8") clear
    assert _N == 13223
    isid root_role relative_path
    assert inlist(root_role, "project_ado", "stata_install", "official_base")
    assert lock_id == "observed-2026-10-03"
    assert !missing(relative_path, sha256, bytes, stata_checksum)
    assert !strpos(relative_path, "..") & !strpos(relative_path, ":") & ///
        substr(relative_path, 1, 1) != "/"

    * Byte lengths plus Stata checksums guard every recorded installation file.
    * A separate read-only Python checker supplies cryptographic SHA-256 checks.
    forvalues i = 1/`=_N' {
        local role = root_role[`i']
        local relative = relative_path[`i']
        local expected_size = real(bytes[`i'])
        local expected_checksum = real(stata_checksum[`i'])
        local root "`adoroot'"
        if "`role'" == "stata_install" local root "`c(sysdir_stata)'"
        if "`role'" == "official_base" local root "`c(sysdir_base)'"
        local target "`root'/`relative'"

        capture quietly checksum "`target'"
        if _rc {
            display as error "Missing/unreadable locked dependency: `role'/`relative'"
            exit 9
        }
        if r(checksum) != `expected_checksum' | r(filelen) != `expected_size' {
            display as error "Changed locked dependency: `role'/`relative'"
            exit 9
        }

        * Verify supporting-code resolution, not merely a file sitting in PLUS.
        if "`role'" == "project_ado" {
            local find_name = resolution_name[`i']
            if substr("`relative'", 1, 6) == "style/" local find_name "`relative'"
            capture quietly findfile "`find_name'"
            if _rc {
                display as error "Locked dependency does not resolve: `find_name'"
                exit 9
            }
            local resolved = lower(subinstr("`r(fn)'", "\", "/", .))
            local expected = lower(subinstr("`target'", "\", "/", .))
            if "`resolved'" != "`expected'" {
                display as error "Another search-path file shadows `find_name'."
                exit 9
            }
        }
        if mod(`i', 3000) == 0 display as text "Checked `i' of 13223 locked files."
    }

    * Detect additions to the executable cache; omission cannot silently expand it.
    local extensions "ado mata mlib mo plugin scheme style"
    local directories : dir "`adoroot'" dirs "*"
    local directories `""." `directories'"'
    local actual_files 0
    foreach directory of local directories {
        if "`directory'" != "." {
            local nested : dir "`adoroot'/`directory'" dirs "*"
            if `"`nested'"' != "" {
                display as error "Nested project-cache directories are not in the lock."
                exit 9
            }
        }
        local files : dir "`adoroot'/`directory'" files "*"
        foreach file of local files {
            foreach extension of local extensions {
                if regexm(lower("`file'"), "[.]`extension'$" ) ///
                    local actual_files = `actual_files' + 1
            }
        }
    }
    if `actual_files' != 267 {
        display as error "The executable project cache contains unlocked additions."
        exit 9
    }
end

capture program drop victimasrd_validate_environment
program define victimasrd_validate_environment, rclass
    version 19
    syntax [, MANifest(string) ADORoot(string)]
    if `"`manifest'"' == "" ///
        local manifest "${project_root}/metadata/stata-dependency-lock-2026-10-03.csv"
    if `"`adoroot'"' == "" local adoroot "${build_root}/ado"

    * A disposable frame keeps the caller's observations, sort order and e() intact,
    * including on failure. The checker never touches a research-data destination.
    tempname lock_frame
    frame create `lock_frame'
    capture noisily frame `lock_frame': _vrd_check_environment, ///
        manifest("`manifest'") adoroot("`adoroot'")
    local check_rc = _rc
    frame drop `lock_frame'
    if `check_rc' exit `check_rc'
    return scalar files = 13223
    return local lock_id "observed-2026-10-03"
    display as result "Victimas RD environment lock passed (13223 file identities)."
end
