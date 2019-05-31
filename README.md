# XML Checker Framework (XCF)


## Introduction

This repository contains the XML Checker Framework (XCF) which allows to
check XML files according to certain defined constraints/rules.

The constraints are described in a custom XML format that allows to
reuse them for other purposes.

The rules are written using Schematron, to allow the implementation of
sophisticated checks of the related constraints and to detailed 
diagnostic data feedback.


## Related repositories

A sample set of constraints/rules is contained in the
[`xcf_suite_sample` repository](https://github.com/IRT-Open-Source/xcf_suite_sample).

Constraints/rules for TTML subtitles can be found in the
[`xcf_suite_ttml` repository](https://github.com/IRT-Open-Source/xcf_suite_ttml).


## Details for specific files

The files are described in more detail here.

### /xsd/constraints/constraints.xsd
This XSD restricts the constraints XML file of XCF.

### /xsd/reportview/reportview.xsd
This XSD restricts the report XML file that is used by XCF.

### /xsd/rules_config/rules_config.xsd
This XSD restricts the rules configuration XML file that is used by XCF.

### /xslt/reportview/reportview.xsl
This XSLT transforms the SVRL result of XCF into a custom XML
representation which is as "View Model" by other components (e.g. the 
XCF web app).

The result needs to be valid against the `reportview.xsd`.

### /xslt/schematron
This folder contains a customized Schematron-to-XSLT set of XSLT files
that is used to transform the Schematron rules into a more convenient
XSLT file.

Only small parts have been changed (e.g. to bug fix known issues).
Compared to the [original repository](https://github.com/Schematron/schematron), also the files targetting
XSLT1 have been removed, as the fixes have only been implemented for the
XSLT2 version.


## Compiling the Schematron rules to XSLT

The XSLTs in the customized Schematron-to-XSLT folder are used to
stepwise compile the `rules.sch` (not stored in this repo) to an XSLT
version. The required steps are all explained in the `readme.txt` of the
mentioned folder. The process also allows to skip certain steps if
specific features are not used.

For example a `rules.sch` file may have to be transformed only with the
`iso_svrl_for_xslt2.xsl` here in order to get the compiled XSLT rules.


## Acknowledgement
Parts of the XCF were developed in the European collaborative research
project HBB4ALL  (Grant Agreement no 621014). This project has received
funding from the European Union ICT Policy Support Programme (ICT PSP)
under the Competitiveness and Innovation Framework Programme (CIP).
