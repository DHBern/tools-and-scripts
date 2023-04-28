<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:local="local"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="local map xs xd"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Sep 7, 2022; edited Apr 24, 2023</xd:p>
      <xd:p><xd:b>Author:</xd:b> pd</xd:p>
      <xd:p>Split the bodies of maildir messages into text files.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <!-- How to (Digital Medievalist list):
    - download https://listserv.uleth.ca/hyperkitty/list/dm-l@uleth.ca/export/dm-l@uleth.ca-2023-04.mbox.gz?start=2002-01-27&end=2023-04-28, e.g. "wget -O dm.mbox https://listserv.uleth.ca/hyperkitty/list/dm-l@uleth.ca/export/dm-l@uleth.ca-2023-04.mbox.gz?start=2002-01-27&end=2023-04-28" 
    - convert to maildir format using mb2md (the -s flag (source) requires an absolute path); install with "sudo apt install mb2md"; e.g. "mb2md -s /data/WORK/DH-unibe/pipermail/dm-l.mbox -d /data/WORK/DH-unibe/pipermail/Maildir"
    - point this transformation to the maildir directory and run it (using the $maildir parameter on L27, if desired also set other parameters)
  -->
  
  <!-- ====================================================== 
                         CONTROL SECTION
       ====================================================== -->
  
  <xd:doc>
    <xd:desc>Relative path to maildir directory.</xd:desc>
  </xd:doc>
  <xsl:param name="maildir" as="xs:string" select="'Maildir'"/>
  
  <xd:doc>
    <xd:desc>Prepend subject of the message to the message file (on the first line).</xd:desc>
  </xd:doc>
  <xsl:param name="includeSubject" static="true" as="xs:boolean" select="true()"/>
  
  <xd:doc>
    <xd:desc>Cleanse the message (content type, transfer encoding, phishing warning, e-mail addresses).</xd:desc>
    <xs:desc>NB: cleansing slows down the transformation, esp. calling replace(); deactivate for debugging/extending other areas of the script.</xd:desc>
  </xd:doc>
  <xsl:param name="cleanse" static="true" as="xs:boolean" select="true()"/>
  
  <!-- ====================================================== 
                      CONTROL SECTION (end)
       ====================================================== -->
  
  
  <xsl:output method="text" encoding="UTF-8"/>
  
  <xsl:mode on-no-match="shallow-skip"/>
  
  <xd:doc>
    <xd:desc>Collect file URIs and initiate action.</xd:desc>
  </xd:doc>
  <xsl:template name="xsl:initial-template">
    <xsl:for-each select="uri-collection($maildir||'/cur/?select=*.mbox*')">
      <xsl:try>
        <xsl:call-template name="extract">
          <xsl:with-param name="uri" select="."/>
          <!-- RFC 822
          "Everything after first null line is message body"
          https://datatracker.ietf.org/doc/html/rfc822#section-4.1
          -->
          <!-- RFC 5322 (applies to mbox)
          "The body is simply a sequence of
          characters that follows the header section and is separated from the
          header section by an empty line (i.e., a line with nothing preceding
          the CRLF)."
          https://datatracker.ietf.org/doc/html/rfc5322#section-2.1
          https://datatracker.ietf.org/doc/html/rfc5322#section-3.5 (formalised)
          -->
          <xsl:with-param name="header" as="item()" select="tokenize(unparsed-text(.),'\n\n') => head()"/>
          <xsl:with-param name="body" as="item()*" select="tokenize(unparsed-text(.),'\n\n') => tail()"/>
          <xsl:with-param name="subject" as="item()" select="unparsed-text-lines(.)[matches(.,'^Subject:')][1]" use-when="$includeSubject"/>
        </xsl:call-template>
        <xsl:catch>
          <xsl:message expand-text="true">{.} not processed.</xsl:message>
        </xsl:catch>
      </xsl:try>
    </xsl:for-each>
  </xsl:template>

  <xd:doc>
    <xd:desc>Save files.</xd:desc>
    <xd:param name="uri">File name of the input file.</xd:param>
    <xd:param name="header">Header section of the input file.</xd:param>
    <xd:param name="body">Body section of the input file as a sequence of paragraphs.</xd:param>
    <xd:param name="subject">Subject of the message (applies only when $includeSubject is set to "true()").</xd:param>
  </xd:doc>
  <xsl:template name="extract">
    <xsl:param name="uri"/>
    <xsl:param name="header"/>
    <xsl:param name="body"/>
    <xsl:param name="subject" select="()"/>
    <xsl:result-document href="{local:href($uri)}">
      <xsl:value-of select="$subject,local:cleanse($body)" separator="&#xD;&#xD;"/>
    </xsl:result-document>
    <xsl:result-document href="{local:href($uri) => replace('/out/','/out/headers/')}">
      <xsl:sequence select="$header"/>
    </xsl:result-document>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Define file naming pattern.</xd:desc>
    <xd:param name="uri">File name of the input file.</xd:param>
  </xd:doc>
  <xsl:function name="local:href" as="xs:string">
    <xsl:param name="uri"/>
    <xsl:variable name="months" as="map(xs:string,xs:string)" select="map{'Jan':'01','Feb':'02','Mar':'03','Apr':'04','May':'05','Jun':'06','Jul':'07','Aug':'08','Sep':'09','Oct':'10','Nov':'11','Dec':'12'}"/>
    <xsl:variable name="date" as="xs:string" select="unparsed-text-lines($uri)[matches(.,'^Date:')][1]"/>
    <xsl:variable name="date" as="xs:string" select="replace($date,'Date:(?:\s+[A-Z][a-z]{2},)?\s+(\d+)\s([A-Z][a-z]{2})\s+(\d{2,4})','$3-$2-$1-')"/>
    <xsl:variable name="date" as="xs:string" select="tokenize($date,'-')[1]=>number()=>format-number('0000')||'-'||map:get($months,tokenize($date,'-')[2])||'-'||tokenize($date,'-')[3]=>number()=>format-number('00')"/>
    <xsl:sequence select="$maildir||'/out/'||$date||'_'||($uri => tokenize('/'))[last()] => replace('\.mbox.+','.txt')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Cleanse body.</xd:desc>
    <xd:param name="body">Text body of the message as a sequence of paragraphs.</xd:param>
  </xd:doc>
  <xsl:function name="local:cleanse" as="xs:string*">
    <xsl:param name="body"/>
    <xsl:sequence use-when="$cleanse" select="$body[not(matches(.,'(^Caution: This email was sent from someone outside of)|(^--===============)'))] ! replace(.,'.+(\(a\)|@)','_redacted_$1')"/>
    <xsl:sequence use-when="not($cleanse)" select="$body"/>
  </xsl:function>

</xsl:stylesheet>
