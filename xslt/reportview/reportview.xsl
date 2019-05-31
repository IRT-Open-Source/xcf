<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs svrl subcheck" version="2.0"
    xmlns:svrl="http://purl.oclc.org/dsdl/svrl" xmlns:subcheck="http://www.irt.de/subcheck">
    <xsl:strip-space elements="*"/>
    <xsl:param name="constraints_path" select="'constraints.xml'"/>
    <xsl:param name="error_limit">50</xsl:param><!-- 'none' disables the limit -->
    
    <xsl:variable name="constraints" select="document($constraints_path)"/>

    <xsl:template match="/">
        <!-- ensure that the constraints file exists -->
        <xsl:if test="empty($constraints)">
            <xsl:message terminate="yes">
                The constraints file does not exist.
            </xsl:message>
        </xsl:if>
        
        <!-- ensure correct error limit (number or 'none') -->
        <xsl:if test="not(number($error_limit) eq number($error_limit) or $error_limit eq 'none')">
            <xsl:message terminate="yes">
                The parameter 'error_limit' has the invalid value '<xsl:value-of select="$error_limit"/>'.
            </xsl:message>
        </xsl:if>
        
        <!-- determine all specs that are not disabled for being referenced here -->
        <xsl:variable name="enabled_specs" select="$constraints//Specifications/Specification[not(Config/disableSpecRef)]/@ID"/>
        
        <result>
            <xsl:for-each-group select="//svrl:failed-assert" group-by="@see">
                <xsl:sort select="@see"/>

                <!-- get constraint (ID) -->
                <xsl:variable name="constraintId" select="replace(current-grouping-key(), 'http://www.irt.de/subcheck/constraints/', '')"/>
                <xsl:variable name="constraint" select="$constraints//Constraint[@ID = $constraintId]"/>
                
                <!-- determine the referenced normal/global specs that are not disabled -->
                <xsl:variable name="specs_normal" select="$constraint/SpecifiedBy[SpecificationReference = $enabled_specs]"/>
                <xsl:variable name="specs_global" select="$constraint/GlobalSpecifiedBy[@refDerived = $constraints//GlobalSpecReferences/SpecifiedBy[SpecificationReference = $enabled_specs]/@ID]"/>
                
                <!-- output error category if at least one affected spec not disabled -->
                <xsl:if test="exists(($specs_normal, $specs_global))">
                   <errorCategory>
                       <constraintID>
                           <xsl:value-of select="$constraintId"/>
                       </constraintID>
                       <title>
                           <xsl:value-of select="$constraint/ShortName"/>
                       </title>
                       <shortUserDesc>
                           <xsl:value-of select="$constraint/ShortDescriptionUser"/>
                       </shortUserDesc>
                       <longUserDesc>
                           <xsl:value-of select="$constraint/LongDescriptionUser"/>
                       </longUserDesc>
                       <specs>
                           <xsl:apply-templates select="$specs_normal">
                               <xsl:with-param name="main_spec_ref" select="()"/>
                           </xsl:apply-templates>
                           <xsl:apply-templates select="$specs_global"/>
                       </specs>
                       <errors>
                           <!-- due to performance reasons, only return the first X errors -->
                           <xsl:for-each select="
                               if ($error_limit eq 'none')
                               then current-group()
                               else subsequence(current-group(), 1, number($error_limit))
                               ">
                               <error>
                                   <messages>
                                       <xsl:call-template name="messageMain">
                                           <xsl:with-param name="assertion" select="svrl:text"/>
                                           <xsl:with-param name="diagnostics" select="svrl:diagnostic-reference"/>
                                       </xsl:call-template>
                                       <messageAssertion><xsl:value-of select="normalize-space(svrl:text)"/></messageAssertion>
                                       <xsl:if test="svrl:diagnostic-reference">
                                          <messageDiagnosticsAll>
                                              <xsl:call-template name="messageGlue">
                                                  <xsl:with-param name="messages" select="svrl:diagnostic-reference"/>
                                              </xsl:call-template>
                                          </messageDiagnosticsAll>
                                       </xsl:if>
                                   </messages>
                                   <locations>
                                       <location locationType="resolvableXPATH"><xsl:value-of select="@location"/></location>
                                       <location locationType="humanXPATH"><xsl:value-of select="@subcheck:alternativeLocation"/></location>
                                   </locations>
                               </error>
                           </xsl:for-each>
                           
                           <!-- in case the error limit was reached, add a dummy error with remark -->
                           <xsl:variable name="error_count" select="count(current-group())"/>
                           <xsl:if test="($error_limit ne 'none') and ($error_count gt number($error_limit))">
                               <error>
                                   <messages>
                                       <messageMain>
                                           <xsl:choose>
                                               <xsl:when test="number($error_limit) eq 0">
                                                   <xsl:value-of select="concat('In total ', $error_count, ' error(s) has/have been found.')"/>
                                               </xsl:when>
                                               <xsl:otherwise>
                                                   <xsl:value-of select="concat('... and ', $error_count - number($error_limit), ' further error(s). Currently only the first ', number($error_limit), ' errors are shown.')"/>
                                               </xsl:otherwise>
                                           </xsl:choose>
                                       </messageMain>
                                   </messages>
                               </error>
                           </xsl:if>
                       </errors>
                       <xsl:if test="$constraint/Tagref">
                           <tags>
                               <xsl:apply-templates select="$constraint/Tagref"/>
                           </tags>
                       </xsl:if>
                   </errorCategory>
                </xsl:if>
            </xsl:for-each-group>
        </result>
    </xsl:template>

    <!-- template copied 1:1 to xsd_report_output.xsl; should be moved to separate file to which both XSLTs refer -->
    <xsl:template match="SpecifiedBy">
        <xsl:param name="main_spec_ref" as="node()?"/>
        
        <xsl:variable name="main_spec" select="if($main_spec_ref) then $main_spec_ref else ."/>
        <xsl:variable name="spec"
            select="$constraints/SpecificationConstraints/Specifications/Specification[@ID = current()/SpecificationReference]"/>
        <xsl:variable name="specNameVersion" select="concat($spec/Name, ', Version ', $spec/Version)"/>
        <xsl:variable name="specChapterPage" select="string-join((if(Chapter) then concat('Chapter ', Chapter) else (), if(Page) then concat('Page ', Page) else ()), ', ')"/>
        <spec>
            <name>
                <xsl:value-of select="$specNameVersion"/>
            </name>
            <nameAcronym>
                <xsl:value-of select="$spec/Acronym"/>
            </nameAcronym>
            <xsl:if test="SpecText">
                <text>
                    <xsl:value-of select="SpecText"/>
                </text>
            </xsl:if>
            <errorLevel>
                <xsl:value-of select="$main_spec/Error_Level"/>
            </errorLevel>
            <xsl:if test="$specChapterPage">
                <section>
                    <xsl:value-of select="$specChapterPage"/>
                </section>
            </xsl:if>
            <xsl:if test="URI">
                <uri>
                    <xsl:value-of select="URI"/>
                </uri>
            </xsl:if>
        </spec>
    </xsl:template>
    
    <xsl:template match="GlobalSpecifiedBy">
        <xsl:variable name="main_spec_ref" select="../SpecifiedBy[@ID = current()/@refMain]"/>
        <xsl:variable name="global_spec_ref" select="$constraints/SpecificationConstraints/GlobalSpecReferences/SpecifiedBy[@ID = current()/@refDerived]"/>

        <!-- ensure that main spec ref exists -->
        <xsl:if test="not($main_spec_ref)">
            <xsl:message terminate="yes">
                The main spec with ID '<xsl:value-of select="@refMain"/>' does not exist for constraint '<xsl:value-of select="../@ID"/>'!
            </xsl:message>
        </xsl:if>
        
        <!-- ensure that global spec ref exists -->
        <xsl:if test="not($global_spec_ref)">
            <xsl:message terminate="yes">
                The global spec with ID '<xsl:value-of select="@refDerived"/>' does not exist for constraint '<xsl:value-of select="../@ID"/>'!
            </xsl:message>
        </xsl:if>
        
        <!-- apply the general spec ref template -->
        <xsl:apply-templates select="$global_spec_ref">
            <xsl:with-param name="main_spec_ref" select="$main_spec_ref"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="Tagref">
        <xsl:variable name="tag" select="/SpecificationConstraints/Tags/Tag[@ID = current()/@IDREF]"/>
        <tag type="{$tag/@type}">
            <shortDesc><xsl:value-of select="$tag/DisplaynameShort"/></shortDesc>
            <xsl:if test="$tag/DisplaynameLong">
                <longDesc>
                    <xsl:value-of select="$tag/DisplaynameLong"/>
                </longDesc>
            </xsl:if>
            <xsl:if test="$tag/Description">
                <descText>
                    <xsl:value-of select="$tag/Description"/>
                </descText>
            </xsl:if>
        </tag>
    </xsl:template>
    <xsl:template name="messageMain">
        <!-- Creates a pre-combined message text that could be used directly for display. -->        
        <xsl:param name="assertion"/>
        <xsl:param name="diagnostics"/>
        <messageMain>
            Assertion: <xsl:value-of select="normalize-space($assertion)"/>
            <xsl:if test="$diagnostics">
                Error Information:<xsl:text> </xsl:text>
                <xsl:call-template name="messageGlue">
                    <xsl:with-param name="messages" select="$diagnostics"/>
                </xsl:call-template>
            </xsl:if>
        </messageMain>        
    </xsl:template>
    <xsl:template name="messageGlue">
        <!-- "Glues" different messages together. -->
        <xsl:param name="messages"/>
            <xsl:for-each select="$messages">
                <xsl:if test="position() > 1">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
