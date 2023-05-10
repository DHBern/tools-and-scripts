<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:local="local-functions"
  exclude-result-prefixes="local xd xs"
  expand-text="true"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> May 9, 2023</xd:p>
      <xd:p><xd:b>Author:</xd:b> pd</xd:p>
      <xd:p>Inspect structure of XML file (elements, attributes and their values, counts).</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xd:doc>
    <xd:desc>Debugging mode / production mode.</xd:desc>
  </xd:doc>
  <xsl:param static="true" name="debug" as="xs:boolean" select="false()"/>
  
  <xd:doc>
    <xd:desc>Input specification.</xd:desc>
  </xd:doc>
  <xsl:variable name="data" select="collection('/data/WORK/DH-unibe/parzival/data_parzival/xml/?select=*.xml')" use-when="not($debug)"/>
  <xsl:variable name="data" select="doc('xml/syn528.xml')" use-when="$debug"/>
  
  <xd:doc>
    <xd:desc>Data analysis.</xd:desc>
  </xd:doc>
  <xsl:variable name="xml">
    <array key="elements" xmlns="http://www.w3.org/2005/xpath-functions">
      <xsl:for-each-group select="$data//*" group-by="local:path(.)">
        <xsl:sort select="(tokenize(current-grouping-key(),'/'))[last()]"/>
        <map>
          <string key="element">{(current-grouping-key() => tokenize('/'))[last()]}</string>
          <string key="path">{current-grouping-key()}</string>
          <number key="frequency">{current-group() => count()}</number>
          <xsl:if test="current-group()/@*">
            <array key="attributes">
              <xsl:for-each-group select="current-group()/@*" group-by="local-name()">
                <map>
                  <string key="attribute">{local-name()}</string>
                  <number key="frequency">{current-group() => count()}</number>
                  <array key="values">
                    <xsl:for-each select="current-group() => distinct-values()">
                      <map>
                        <string key="value">{.}</string>
                        <number key="frequency">{current-group()[.=current()] => count()}</number>
                      </map>
                    </xsl:for-each>
                  </array>
                </map>
              </xsl:for-each-group>
            </array>
          </xsl:if>
        </map>
      </xsl:for-each-group>
    </array>
  </xsl:variable>
  
  <xd:doc>
    <xd:desc>Main template, generates outputs.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:result-document href="output/xml-inspection.xml" method="xml" encoding="utf-8" indent="true">
      <xsl:sequence select="$xml"/>
    </xsl:result-document>
    <xsl:result-document href="output/xml-inspection.json" method="text" encoding="utf-8">
      <xsl:value-of select="xml-to-json($xml, map { 'indent' : true()})"/>
    </xsl:result-document>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Build XPath expressions.</xd:desc>
    <xd:param name="node">Input node.</xd:param>
  </xd:doc>
  <xsl:function name="local:path" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="if (exists($node/..)) then local:path($node/..)||'/'||local-name($node) else '/'"/>
  </xsl:function>
  
</xsl:transform>