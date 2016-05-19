<!-- 
* Written by Margaret Vail (https://github.com/mvail) in December 2014 for the Dalhousie University Archives.
* See the accompanying LICENSE file for terms.
* The stylesheet converts EAD exported from the Archivists' Toolkit into EAD that can be successfully imported into AtoM. 
* The stylesheet does NOT ensure all data is successfully imported. Data loss is always a possibility when performing bulk data migrations. Testing is strongly encouraged.

* The stylesheet performs the following functions:
*** Changes EAD Schema to DTD
*** Creates EAD <genreform> statements based on EAD <container> label values
*** Combines various EAD <physdesc> notes and repeating sub-elements into a single EAD <physdesc> statement
*** Combines multiple EAD <container> elements into a single <container> element
*** Uses EAD <container> elements to generate new EAD <unitid> statements

* See accompanying instructions for exporting XML from the Archivists' Toolkit and performing batch transformations in Oxygen XML editor.
-->

<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:s="urn:isbn:1-931666-22-9" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    exclude-result-prefixes="s xsl xsi">
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <!-- add proper doctype -->
    <xsl:template match="/|comment()|processing-instruction()">
        <xsl:text disable-output-escaping="yes">
            &lt;!DOCTYPE ead PUBLIC "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN" "http://lcweb2.loc.gov/xmlcommon/dtds/ead2002/ead.dtd"&gt;
        </xsl:text>
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <!-- keep everything -->
    <xsl:template match="*">
        <xsl:element name="{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- Keep attributes -->
    <xsl:template match="@*">
        <xsl:if test="not(starts-with(local-name(), 'schemaLocation'))">
            <xsl:attribute name="{local-name()}">
                <xsl:value-of select="."/>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>
    
    <!-- Remove head -->
    <xsl:template match="s:head"></xsl:template>
    
    <!--   -->
    <xsl:template match="s:persname | s:corpname">
        <xsl:variable name="value_of_role"><xsl:value-of select="@role"/></xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($value_of_role, 'Donor (dnr)')"></xsl:when>
            <xsl:otherwise>
                <xsl:element name="{local-name()}">
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- call genreform template  -->
    <xsl:template match="s:c[(@level='item') or (@level='file')]/child::*"> 
        <xsl:call-template name="genreform" />
    </xsl:template>
    
    <!-- Create genreform -->
    <xsl:template name="genreform">
        
        <xsl:choose>
            
            <xsl:when test="(following-sibling::s:controlaccess) or (local-name()= 'controlaccess')">
                <xsl:choose>
                    <xsl:when test="local-name()='controlaccess'">
                        <xsl:element name="{local-name()}">
                            <xsl:apply-templates select="@*|node()"/>
                            
                            <xsl:for-each select="../s:did/child::*[name()='container']/@*[name()='label']">
                                <xsl:variable name="genreform_value">
                                    <xsl:call-template name="genreform_value" />
                                </xsl:variable>
                                <genreform source="rad"><xsl:value-of select="$genreform_value" /></genreform>
                            </xsl:for-each>
                        </xsl:element>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:element name="{local-name()}">
                            <xsl:apply-templates select="@*|node()"/>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>                
            </xsl:when>

            <xsl:otherwise>
                
                <xsl:element name="{local-name()}">
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:element>

                <xsl:for-each select="child::*[name()='container']/@*[name()='label']">
                    <xsl:variable name="genreform_value">
                        <xsl:call-template name="genreform_value" />
                    </xsl:variable>
                    <controlaccess>
                        <genreform source="rad"><xsl:value-of select="$genreform_value" /></genreform>
                    </controlaccess>
                </xsl:for-each>
           </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

    <xsl:template name="genreform_value">
              
        <xsl:variable name="genreform_value">
            <xsl:value-of select="." />
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$genreform_value = 'Text'">
                    <genreform source="rad">Textual record</genreform>              
            </xsl:when>
            <xsl:when test="$genreform_value = 'Books'">
                    <genreform source="rad">Textual record</genreform>                
            </xsl:when>
            <xsl:when test="$genreform_value = 'graphic material'">
                    <genreform source="rad">Graphic material</genreform>
            </xsl:when>
            <xsl:when test="$genreform_value = 'Microform'">
                    <genreform source="rad">Textual record (microform)</genreform>
            </xsl:when>
            <xsl:when test="$genreform_value = 'Mixed materials'">
                    <genreform source="rad">Multiple media</genreform>
            </xsl:when>
            <xsl:when test="$genreform_value = 'moving images'">
                    <genreform source="rad">Moving images</genreform>
            </xsl:when>
            <xsl:when test="$genreform_value = 'Realia'">
                    <genreform source="rad">Object</genreform>
            </xsl:when>
            <xsl:when test="$genreform_value = 'sound recording'">
                    <genreform source="rad">Sound recording</genreform>
            </xsl:when>
            
            <xsl:otherwise>
                    <genreform source="rad"><xsl:value-of select="$genreform_value" /></genreform>              
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>


    <!-- Create container and unitid from containers, also call template to combine all containers  -->
    <xsl:template match="s:did/child::*[self::s:container]">                   
        <!-- Is this the first element in a sequence? -->
        <xsl:if test="local-name(preceding-sibling::*[position()=1]) != 'container'">
            <xsl:variable name="value_of_container">
                <xsl:copy>
                    <xsl:apply-templates />
                    <!-- Match the next sibling if it has the same name -->
                    <xsl:apply-templates select="following-sibling::*[1][local-name()='container']" mode="next"/>
                </xsl:copy>
            </xsl:variable>
            <unitid><xsl:value-of select="/s:ead/s:eadheader/s:eadid" /><xsl:text>, </xsl:text><xsl:value-of select="$value_of_container" /></unitid>
            <container><xsl:value-of select="/s:ead/s:eadheader/s:eadid" /><xsl:text>, </xsl:text><xsl:value-of select="$value_of_container" /></container>
        </xsl:if>
        <!-- This removes the display of container 
        <xsl:element name="{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element> -->
    </xsl:template>
    
    <!-- if more than one container combine for unitid and continue -->
    <xsl:template match="s:did/child::*[self::s:container]" mode="next">
        <xsl:text> ; </xsl:text>
        <xsl:apply-templates />
        <xsl:apply-templates select="following-sibling::*[local-name()='container']" mode="next"/>
    </xsl:template>
    
    <!-- call physdesc template if it's the first time only  -->
    <xsl:template match="s:did/child::*[self::s:physdesc]"> 
        
        <xsl:if test="not(preceding-sibling::*[local-name() = 'physdesc'])">
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="physdesc" />
        </xsl:if>
        
    </xsl:template>
    
    <!-- Combine physdesc into one field -->
    <xsl:template name="physdesc">
        <physdesc>
            
            <xsl:for-each select="parent::*/child::*[local-name()='physdesc']">
                <xsl:if test="child::*[local-name()='extent']">
                    <xsl:call-template name="call_extent" />
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="parent::*/child::*[local-name()='physdesc']">
                <xsl:if test="child::*[local-name()='physfacet']">
                    <xsl:call-template name="call_physfacet" />
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="parent::*/child::*[local-name()='physdesc']">
                <xsl:if test="child::*[local-name()='dimensions']">
                    <xsl:call-template name="call_dimensions" />
                </xsl:if>
            </xsl:for-each>
            
            <xsl:if test="parent::*/child::*[local-name()='physdesc' and not(*)]">
                <xsl:call-template name="call_phydesc_no_children" />
            </xsl:if>
            
        </physdesc>
    </xsl:template>
    
    <!-- Combine physdesc with no children into one field -->
    <xsl:template name="call_phydesc_no_children">
        <xsl:value-of select="parent::*/child::*[local-name()='physdesc' and not(*)]" separator=". - "/>
    </xsl:template>
    
    <!-- Combine extent into one field -->
    <xsl:template name='call_extent'>
        <xsl:variable name="value_of_extent"><xsl:value-of select="*"/></xsl:variable>
        <xsl:value-of select="replace($value_of_extent, '\.0 ', ' ')"/>
        <xsl:choose>
            <xsl:when test="count(following-sibling::*[local-name()='physdesc']/child::*[local-name()='extent'])=0">
                <xsl:choose>
                    <xsl:when test="(count(following-sibling::*[local-name()='physdesc'])>0 or count(preceding-sibling::*[local-name()='physdesc'])>0) and (count(following-sibling::*[local-name()='physdesc']/child::*[not(local-name()='extent')])>0 or count(preceding-sibling::*[local-name()='physdesc']/child::*[not(local-name()='extent')])>0)">                      
                        <xsl:text> : </xsl:text>        
                    </xsl:when>
                    <xsl:when test="(count(following-sibling::*[local-name()='physdesc'])>0 or count(preceding-sibling::*[local-name()='physdesc'])>0) and (count(following-sibling::*[local-name()='physdesc' and not(*)])>0 or count(preceding-sibling::*[local-name()='physdesc' and not(*)])>0)">
                        <xsl:text>. - </xsl:text>        
                    </xsl:when>
                    <xsl:otherwise></xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Combine physfacet into one field -->
    <xsl:template name="call_physfacet">
        <xsl:value-of select="*" separator=", "/>
        <xsl:choose>
            <xsl:when test="count(following-sibling::*[local-name()='physdesc']/child::*[local-name()='physfacet'])=0">
                <xsl:choose>
                    <xsl:when test="(count(following-sibling::*[local-name()='physdesc'])>0 or count(preceding-sibling::*[local-name()='physdesc'])>0) and (count(following-sibling::*[local-name()='physdesc']/child::*[not(local-name()='physfacet') and not(local-name()='extent')])>0 or count(preceding-sibling::*[local-name()='physdesc']/child::*[not(local-name()='physfacet') and not(local-name()='extent')])>0)">
                        <xsl:text> ; </xsl:text>        
                    </xsl:when>
                    <xsl:when test="(count(following-sibling::*[local-name()='physdesc'])>0 or count(preceding-sibling::*[local-name()='physdesc'])>0) and (count(following-sibling::*[local-name()='physdesc' and not(*)])>0 or count(preceding-sibling::*[local-name()='physdesc' and not(*)])>0)">
                        <xsl:text>. - </xsl:text>        
                    </xsl:when>
                    <xsl:otherwise></xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>, </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Combine Dimensions into one field -->
    <xsl:template name="call_dimensions">
        <xsl:value-of select="*"  separator=", "/>
        <xsl:choose>
            <xsl:when test="count(following-sibling::*[local-name()='physdesc']/child::*[local-name()='dimensions'])=0">
                <xsl:choose>
                    <xsl:when test="(count(following-sibling::*[local-name()='physdesc'])>0 or count(preceding-sibling::*[local-name()='physdesc'])>0) and (count(following-sibling::*[local-name()='physdesc']/child::*[not(local-name()='dimensions') and not(local-name()='physfacet') and not(local-name()='extent')])>0 or count(preceding-sibling::*[local-name()='physdesc']/child::*[not(local-name()='dimensions') and not(local-name()='physfacet') and not(local-name()='extent')])>0)">
                        <xsl:text> ; </xsl:text>        
                    </xsl:when>
                    <xsl:when test="(count(following-sibling::*[local-name()='physdesc'])>0 or count(preceding-sibling::*[local-name()='physdesc'])>0) and (count(following-sibling::*[local-name()='physdesc' and not(*)])>0 or count(preceding-sibling::*[local-name()='physdesc' and not(*)])>0)">
                        <xsl:text>. - </xsl:text>        
                    </xsl:when>
                    <xsl:otherwise></xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>