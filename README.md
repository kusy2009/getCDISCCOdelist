# getCDISCCOdelist

# SAS Macro for Fetching CDISC Controlled Terminology (CT) Codelists

This **SAS macro** retrieves and filters **CDISC Controlled Terminology (CT)** codelists for various CDISC standards (SDTM, ADaM, CDASH, etc.). The macro interacts with the **CDISC Terminology API** to fetch the latest terminology version and filters the codelists based on the specified input parameters.

## Features

- **Dynamic Version Fetching**: Automatically fetches the latest version of Controlled Terminology (CT) if not specified.
- **Multiple Standards Support**: Supports multiple CDISC standards including **SDTM**, **ADaM**, **CDASH**, **DEFINE-XML**, **SEND**, and others.
- **Flexible Filtering**: Allows filtering by codelist **ID** or **CodelistCode**.
- **Extensible Data**: Flags if the codelist is extensible (i.e., if it supports additional terms beyond the official list).
- **Error Handling**: Provides detailed error messages if the provided codelist or standard is invalid.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#Setup)
- [How to Use](#how-to-use)
- [Parameters](#parameters)
- [Output](#output)
- [Example Usage](#example-usage)


## Prerequisites
Before you can use this macro, make sure you have the following:
- **SAS**: The macro is written in SAS and requires a working SAS environment.
- **CDISC API Access**: You will need an **API Key** for the CDISC API. If you don’t have one, you can obtain it from [CDISC's website](https://www.cdisc.org/).

## Setup
1. **Download the Macro**: Clone this repository or download the `GetCDISCCodelist.sas` file.
2. **Save to Your Library**: Save the macro code to your desired location in the SAS environment.
3. **Set Up API Key**: Make sure you have access to the **CDISC API Key**. If you don’t have an API key, you can request it from CDISC.
   - Add your API key in the SAS code:
     %let cdiscapikey = your-api-key-here;
    

## How to Use
Once you have called the macro, you can start using it to fetch CDISC Controlled Terminology (CT) codelists for any standard (SDTM, ADaM, etc.) and version.

### Syntax:
%GetCDISCCodelist(
    codelistValue=,  /* The codelist name (e.g., AGEU, PARAMCD) */
    codelistType=ID,  /* Match by ID or CodelistCode */
    standard=SDTM,  /* Default to SDTM */
    version=%str(), /* Version of Controlled Terminology (empty to pull latest) */
    outlib=WORK /* Output Library */
);

## Parameters

### `codelistValue`
- **Required**: Yes
- **Type**: Character
- **Description**: The name of the codelist (e.g., `AGEU`, `PARAMCD`, `DTYPE`).
  
### `codelistType`
- **Required**: No
- **Type**: Character (`ID` or `CodelistCode`)
- **Default**: `ID`
- **Description**: Specify whether to filter by `ID` or `CodelistCode`. By default, the macro will filter by `ID`.

### `standard`
- **Required**: No
- **Type**: Character
- **Default**: `SDTM`
- **Description**: The CDISC standard for which to retrieve the codelist. Valid values include:
  - `SDTM` (default)
  - `ADAM`
  - `CDASH`
  - `DEFINE-XML`
  - `SEND`
  - `DDF`
  - `GLOSSARY`
  - `MRCT`
  - `PROTOCOL`
  - `QRS`
  - `QS-FT`
  - `TMF`
    
### `outlib`
- **Required**: No
- **Type**: Library
- **Default**: `WORK`
- **Description**: The SAS library where the resulting datasets will be saved.

## Output
The macro generates the following outputs:
- **Merged Codelist Dataset**: A dataset containing the **codelist values** and their associated **terms**.
- **Extensibility Flag**: If the codelist is extensible, the output dataset will include a flag indicating so.
- **Filtered Codelists**: The codelist is filtered based on the provided **codelistValue** and **codelistType** parameters.

## Example Usagae
%*Test for SDTM standard;
%GetCDISCCodelist(codelistValue=AGEU);

/* Test for ADaM standard, specific version */
%GetCDISCCodelist(codelistValue=DTYPE, standard=ADAM, version=2023-12-01);

### Conclusion
This macro can be a very useful tool for fetching and working with CDISC Controlled Terminology (CT) codelists in your clinical trial datasets. If you have any questions or suggestions, feel free to reach out or create an issue in the GitHub repository.
