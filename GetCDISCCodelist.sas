/**
@file GetCDISCCodelist.sas

@brief Retrieves a specified CDISC Controlled Terminology codelist via CDISC Library API.

@details 
This macro connects to the CDISC Library API using a valid API key to retrieve a specific codelist and its associated terms for standards such as SDTM, ADaM, and others. It supports both ID and CodelistCode-based lookup and can dynamically determine the latest terminology version if not explicitly provided. The result is output to a SAS dataset for further use in metadata-driven processes or validation tasks.

Syntax:
@code
%GetCDISCCodelist(
    codelistValue=AGEU,
    codelistType=ID,
    standard=SDTM,
    version=,
    outlib=WORK
);
@endcode

Usage:
@code
%GetCDISCCodelist(codelistValue=DTYPE, standard=ADAM);
@endcode

@param codelistValue The name or code of the codelist to retrieve (e.g., AGEU, PARAMCD, DTYPE).
@param codelistType Specifies the type of match: either ID or CODELISTCODE.
@param standard CDISC standard to use (e.g., SDTM, ADAM). Defaults to SDTM.
@param version Controlled Terminology version in YYYY-MM-DD format. If omitted, the latest version is retrieved automatically.
@param outlib Output library where the resulting datasets will be stored. Defaults to WORK.

@return Creates two output datasets in the specified library: one for merged codelists and another for the filtered codelist containing only the requested items.

@version 1.0

@author Saikrishnareddy Yengannagari
*/

%let cdiscapikey=Your_CDISC_API_KEY;
%macro GetCDISCCodelist(
    codelistValue=,  /* The codelist name (e.g., AGEU, PARAMCD) */
    codelistType=ID,  /* Match by ID or CodelistCode */
    standard=SDTM,  /* Default to SDTM */
    version=%str(), /* Version of Controlled Terminology (empty to pull latest) */
    outlib=WORK /* Output Library */
);

    /* Validate input */
    %if %superq(codelistValue)= %then %do;
        %put ERROR: You must specify a codelistValue= (e.g., AGEU for SDTM or DTYPE for ADaM).;
        %return;
    %end;

    /* Ensure correct standard input */
    %let valid_standards = SDTM ADAM CDASH DEFINE-XML SEND DDF GLOSSARY MRCT PROTOCOL QRS QS-FT TMF;
    %if not (%sysfunc(indexw(&valid_standards, %upcase(&standard)))) %then %do;
        %put ERROR: Invalid standard "&standard". Supported values are:;
        %put ERROR: &valid_standards;
        %return;
    %end;

    /* Convert standard to API format */
    %let api_standard = %lowcase(&standard)ct;

    /* Dynamically fetch available versions if not provided */
    %if %superq(version)= %then %do;
        %put NOTE: Version is not specified. Fetching the latest version...;

        filename version TEMP;
        proc http
            url="https://api.library.cdisc.org/api/mdr/products/Terminology"
            method="GET"
            out=version;
            headers
                "api-key"="&cdiscapikey"
                "Accept"="application/json";
        run;

        /* Parse the JSON response to extract available versions */
        libname version JSON fileref=version;
        
        data versions;
            set version._LINKS_PACKAGES;
            /* Extract the standard from href */
            standard_from_href = scan(href, 4, '/'); 
            standard_from_href = substr(standard_from_href, 1, length(standard_from_href)-13);
            if upcase(standard_from_href)=upcase("&standard");
            /* Extract the date from the href field */           
            version_date = substr(href, length(href)-9, 10); /* Last 10 characters (YYYY-MM-DD) */
           keep version_date standard_from_href;
           run;
        
        /* Sort by date to get the latest version */
        proc sort data=versions;
            by descending version_date;
        run;

        /* Get the latest version date */
        data _null_;
            set versions(obs=1);
            call symputx('version', version_date);
        run;

        %put NOTE: Latest &standard CT version is &version;
        
    %end;

    /* Fetch CDISC CT package */
    filename cdiscCT TEMP;
    proc http
        url="https://api.library.cdisc.org/api/mdr/ct/packages/&api_standard.-&version."
        method="GET"
        out=cdiscCT;
        headers
            "api-key"="&cdiscapikey"
            "Accept"="application/json";
    run;

    /* Create JSON library */
    libname cdisc JSON fileref=cdiscCT;

    /* Extract Codelist-level data */
    data _codelist_data;
        retain submissionValue conceptId name extensible ordinal_codelists;
        set cdisc.CODELISTS(keep=conceptId submissionValue extensible name ordinal_codelists);
        rename 
            conceptId       = CodelistCode
            submissionValue = ID;
    run;

    /* Extract Term-level data */
    data _codelist_terms_data;
        retain submissionValue conceptId preferredTerm ordinal_codelists;
        set cdisc.CODELISTS_TERMS(keep=ordinal_codelists conceptId submissionValue preferredTerm);
        rename 
            submissionValue = TERM
            conceptId       = TermCode
            preferredTerm   = DecodedValue;
    run;

    /* Merge codelist and terms */
    proc sql;
        create table &outlib..merged_codelists as
        select 
            a.*,
            b.TermCode,
            b.TERM,
            b.DecodedValue as TermDecodedValue
        from _codelist_data as a
        inner join _codelist_terms_data as b
        on a.ordinal_codelists = b.ordinal_codelists
        order by a.ID, b.TERM;
    quit;

    /* Format Extensible Flag */
    proc format;
        value $extensible_fmt
            "true"  = "Yes"
            "false" = "No";
    run;

    /* Filter specific codelist */
    data &outlib..specific_codelist;
        set &outlib..merged_codelists;
        length ExtensibleYN $3;
        ExtensibleYN = put(Extensible, $extensible_fmt.);

        %if %upcase(&codelistType)=ID %then %do;
            where upcase(ID) = upcase("&codelistValue");
        %end;
        %else %if %upcase(&codelistType)=CODELISTCODE %then %do;
            where upcase(CodelistCode) = upcase("&codelistValue");
        %end;
    run;

    /* Check if codelistValue exists */
    proc sql noprint;
        select count(*) into: check_exists
        from &outlib..specific_codelist;
        select distinct ExtensibleYN into: Extensible
        from &outlib..specific_codelist;
    quit;

    /* If the codelist value does not exist, print a message and exit */
    %if &check_exists = 0 %then %do;
        %put WARNING: The provided Codelist Value "&codelistValue" does not exist in the &standard Controlled Terminology version &version.;
        %put WARNING: Please check if your ID is correct or if it exists in the &standard Codelists.;
        title "Codelist Value Not Found";
        data _null_;
            file print;
            put "------------------------------------------------------------";
            put "WARNING: The specified Codelist Value '&codelistValue' was not found in &standard CT Version &version.";
            put "Please verify your input value.";
            put "------------------------------------------------------------";
        run;
        title;
        %return;
    %end;

    /* Output the results */
    title "Submission Values for &codelistType=&codelistValue (&standard. CT Version=&version, Extensible=&Extensible)";
    proc print data=&outlib..specific_codelist noobs label;
        var TERM;
        label TERM = "Submission Value";
    run;
    title;

%mend GetCDISCCodelist;

%*Test the macro with dynamic version fetch;
%*GetCDISCCodelist(codelistValue=ACN);
%*GetCDISCCodelist(codelistValue=DTYPE, standard=ADAM);
