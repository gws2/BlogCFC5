<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : Index
	Author       : Raymond Camden 
	Created      : February 10, 2003
	Last Updated : May 18, 2007
	History      : Reset history for version 5.0
				 : Link for more entries fixed (rkc 6/25/06)
				 : Gravatar support (rkc 7/8/06)
				 : Cleanup of area shown when no entries exist (rkc 7/15/06)
				 : Use of rb(), use of icons, other small mods (rkc 8/20/06)
				 : Change how categories are handled (rkc 9/17/06)
				 : Big change to cut down on whitespace (rkc 11/30/06)
				 : comment mod support (rkc 12/7/06)
				 : gravatar fix, thanks Pete F (rkc 12/26/06)
				 : use app.maxentries, digg link (rkc 2/28/07)
				 : fix bug where 11 items showed up, not 10 (rkc 5/18/07)
	Purpose		 : Blog home page
--->

<!--- Handle URL variables to figure out how we will get betting stuff. --->
<cfmodule template="tags/getmode.cfm" r_params="params"/>

<!--- only cache on home page --->
<cfset disabled = false>
<cfif url.mode is not "" or len(cgi.query_string) or not structIsEmpty(form)>
	<cfset disabled = true>
</cfif> 

<cfmodule template="tags/scopecache.cfm" cachename="#application.applicationname#" scope="application" disabled="#disabled#" timeout="#application.timeout#">

<!--- Try to get the articles. --->
<cftry>
	<cfset articleData = application.blog.getEntries(params)>
	<cfset articles = articleData.entries>
	<!--- if using alias, switch mode to entry --->
	<cfif url.mode is "alias">
		<cfset url.mode = "entry">
		<cfset url.entry = articles.id>
	</cfif>
	<cfcatch>
		<cfset articleData = structNew()>
		<cfset articleData.totalEntries = 0>
		<cfset articles = queryNew("id")>
	</cfcatch>
</cftry>

<!--- Call layout custom tag. --->
<cfset data = structNew()>
<!--- 
I already know what I'm doing - I got it from getMode, so let me bypass the work done normally for by Entry, it is the most
popular view
--->
<cfif url.mode is "entry" and articleData.totalEntries is 1>
	<cfset data.title = articles.title[1]>
	<cfset data.entrymode = true>
	<cfset data.entryid = articles.id[1]>
	<cfif not structKeyExists(session.viewedpages, url.entry)>
		<cfset session.viewedpages[url.entry] = 1>
		<cfset application.blog.logView(url.entry)>
	</cfif>
</cfif>

<cfmodule template="tags/layout.cfm" attributecollection="#data#">

	<!--- load up swfobject --->
	<cfoutput>
	<script src="#application.rooturl#/includes/swfobject_modified.js" type="text/javascript"></script>
	</cfoutput>
	
	<cfset lastDate = "">
	<cfloop query="articles">
	
		<cfoutput><div class="entry<cfif articles.currentRow EQ articles.recordCount>Last</cfif>"></cfoutput>
		
		<cfif application.trackbacksallowed>
			<!--- output this rdf for auto discovery of trackback links --->
			<cfoutput>
			<!-- 
			<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
	             xmlns:dc="http://purl.org/dc/elements/1.1/"
	             xmlns:trackback="http://madskills.com/public/xml/rss/module/trackback/">
		    <rdf:Description
		        rdf:about="#application.blog.makeLink(id)#"
		        dc:identifier="#application.blog.makeLink(id)#"
		        dc:title="#title#"
		        trackback:ping="#application.rooturl#/trackback.cfm?#id#" />
		    </rdf:RDF>
			-->
			</cfoutput>		
		</cfif>

		<cfoutput>
		<h1><a href="#application.blog.makeLink(id)#">#title#</a></h1>
		
		<div class="byline">#rb("postedat")# : #application.localeUtils.dateLocaleFormat(posted)# #application.localeUtils.timeLocaleFormat(posted)# 
		<cfif len(name)>| #rb("postedby")# : <a href="#application.blog.makeUserLink(name)#">#name#</a></cfif><br />
		#rb("relatedcategories")#:
		</cfoutput>
		<cfset lastid = listLast(structKeyList(categories))>
		<cfloop item="catid" collection="#categories#">
			<cfoutput><a href="#application.blog.makeCategoryLink(catid)#">#categories[currentRow][catid]#</a><cfif catid is not lastid>, </cfif></cfoutput>
		</cfloop>
		<cfoutput>
		</div>
		</cfoutput>

		<cfoutput>		
		<div class="body">
		#application.blog.renderEntry(body,false,enclosure)#

		<!--- STICK IN THE MP3 PLAYER --->
		<cfif enclosure contains "mp3">
			<cfset alternative=replace(getFileFromPath(enclosure),".mp3","") />
			<div class="audioPlayerParent">
				<div id="#alternative#" class="audioPlayer">
				</div>
			</div>
			<script type="text/javascript">
			// <![CDATA[
				var flashvars = {};
				// unique ID
				flashvars.playerID = "#alternative#";
				// load the file
				flashvars.soundFile= "#application.rooturl#/enclosures/#getFileFromPath(enclosure)#";
				// Load width and Height again to fix IE bug
				flashvars.width = "470";
				flashvars.height = "24";
				// Add custom variables
				var params = {};
				params.allowScriptAccess = "sameDomain";
				params.quality = "high";
				params.allowfullscreen = "true";
				params.wmode = "transparent";
				var attributes = false;
				swfobject.embedSWF("#application.rooturl#/includes/audio-player/player.swf", "#alternative#", "470", "24", "8.0.0","/includes/audio-player/expressinstall.swf", flashvars, params, attributes);
			// ]]>
			</script>
		</cfif>
		
		<cfif len(morebody) and url.mode is not "entry">
		<p align="right">
		<a href="#application.blog.makeLink(id)###more">[#rb("more")#]</a>
		</p>
		<cfelseif len(morebody)>
		<span id="more"></span>
		#application.blog.renderEntry(morebody)#
		</cfif>
		</div>
		</cfoutput>

		<cfoutput>
		<div class="byline">
		</cfoutput>

		<cfif allowcomments or commentCount neq ""><cfoutput><img src="#application.rooturl#/images/comment.gif" align="middle" title="#rb("comments")#" alt="#rb("comments")#" height="16" width="16" /> <a href="#application.blog.makeLink(id)###comments">#rb("comments")# (<cfif commentCount is "">0<cfelse>#commentCount#</cfif>)</a> | </cfoutput></cfif>
		<cfif application.trackbacksallowed><cfoutput><a href="#application.blog.makeLink(id)###trackbacks">Trackbacks (<cfif trackbackCount is "">0<cfelse>#trackbackCount#</cfif>)</a> | </cfoutput></cfif>
		<cfif application.isColdFusionMX7><cfoutput><img src="#application.rooturl#/images/printer.gif" align="middle" title="#rb("print")#" alt="#rb("print")#" height="16" width="16" /> <a href="#application.rooturl#/print.cfm?id=#id#" rel="nofollow">#rb("print")#</a> | </cfoutput></cfif>
		<cfoutput><img src="#application.rooturl#/images/email.gif" align="middle" title="#rb("send")#" alt="#rb("send")#" height="16" width="16" /> <a href="#application.rooturl#/send.cfm?id=#id#" rel="nofollow">#rb("send")#</a> | </cfoutput>
		<cfif len(enclosure)><cfoutput><img src="#application.rooturl#/images/disk.png" align="middle" title="#rb("download")#" alt="#rb("download")#" height="16" width="16" /> <a href="#application.rooturl#/enclosures/#urlEncodedFormat(getFileFromPath(enclosure))#">#rb("download")#</a> | </cfoutput></cfif>
		<cfoutput>
    	#views# #rb("views")# |  
		<!-- AddThis Button BEGIN -->
		<a href="http://www.addthis.com/bookmark.php?v=250" onmouseover="return addthis_open(this, '', '#URLEncodedFormat(application.blog.makeLink(id))#', '#URLEncodedFormat(application.blog.getProperty('blogTitle'))#')" onmouseout="addthis_close()" onclick="return addthis_sendto()"><img src="http://s7.addthis.com/static/btn/lg-share-en.gif" width="125" height="16" alt="Bookmark and Share" style="border:0"/></a><script type="text/javascript" src="http://s7.addthis.com/js/250/addthis_widget.js?pub=xa-4a20091556eefead"></script>
		<!-- AddThis Button END -->
		</div>
		</cfoutput>

		<!--- Things to do if showing one entry --->						
		<cfif articles.recordCount is 1>
		
			<cfset qRelatedBlogEntries = application.blog.getRelatedBlogEntries(entryId=id,bDislayFutureLinks=true) />	

			<cfif qRelatedBlogEntries.recordCount>
				<cfoutput>
				<div id="relatedentries">
				<p>
				<div class="relatedentriesHeader">#rb("relatedblogentries")#</div>
				</p>
			
  				<ul id="relatedEntriesList">
				<cfloop query="qRelatedBlogEntries">
				<li><a href="#application.blog.makeLink(entryId=qRelatedBlogEntries.id)#">#qRelatedBlogEntries.title#</a> (#application.localeUtils.dateLocaleFormat(posted)#)</li>
				</cfloop>			
		  		</ul>
		  		</div>
		  		</cfoutput>
			</cfif>

			<cfif application.trackbacksallowed>
				<cfset trackbacks = application.blog.getTrackBacks(id)>	
				<cfoutput>	
				<div id="trackbacks">
				<div class="trackbackHeader">TrackBacks</div>
				</cfoutput>
				
				<cfif trackbacks.recordCount>
		
					<cfoutput>		
					<div class="trackbackBody addTrackbackLink">
					[<a href="javaScript:launchTrackback('#id#')">#application.resourceBundle.getResource("addtrackback")#</a>]
					</div>				
					</cfoutput>
					
					<cfoutput query="trackbacks">
						<div class="trackback<cfif currentRow mod 2>Alt</cfif>">
						<div class="trackbackBody">
						<a href="#postURL#" target="_new" rel="nofollow" class="tbLink">#title#</a><br />
						#paragraphFormat2(excerpt)#
						</div>
						<div class="trackbackByLine">#application.resourceBundle.getResource("trackedby")# #blogname# | #application.resourceBundle.getResource("trackedon")# #application.localeUtils.dateLocaleFormat(created,"short")# #application.localeUtils.timeLocaleFormat(created)#</div>
						</div>
					</cfoutput>			
				<cfelse>
					<cfoutput><div class="body">#application.resourceBundle.getResource("notrackbacks")#</div></cfoutput>
				</cfif>
				
				<cfoutput>
				<p>
				<div class="body">
				#application.resourceBundle.getResource("trackbackurl")#<br />
				#application.rooturl#/trackback.cfm?#id#
				</div>
				</p>
				<div class="trackbackBody addTrackbackLink">
					[<a href="javaScript:launchTrackback('#id#')">#application.resourceBundle.getResource("addtrackback")#</a>]
				</div>
				</div>
				</cfoutput>				
			</cfif>

			<cfif application.usetweetbacks>

				<cfoutput>	
				<div id="tweetbacks">
				<div class="tweetbackHeader">TweetBacks</div>
				<div id="tbContent">
				</cfoutput>

				<cfoutput>
				</div>
				</div>
				</cfoutput>				

			</cfif>

			<cfoutput>
			<div id="comments">
			<div class="commentHeader">#rb("comments")# <cfif application.commentmoderation>(#rb("moderation")#)</cfif></div>
			</cfoutput>
			<cfset comments = application.blog.getComments(id)>

			<cfif comments.recordCount>

				<cfif allowComments>
					<cfoutput>
					<div class="trackbackBody addCommentLink">
					[<a href="javaScript:launchComment('#id#')">#rb("addcomment")#</a>]
					[<a href="javaScript:launchCommentSub('#id#')">#rb("addsub")#</a>]

					</div>
					</cfoutput>
				</cfif>
				
				<cfset entryid = id>
				<cfoutput query="comments">
				<div id="c#id#" class="comment<cfif currentRow mod 2>Alt</cfif>">
					<div class="commentBody">
					<cfif application.gravatarsAllowed><img src="http://www.gravatar.com/avatar/#lcase(hash(email))#?s=40&amp;r=pg&amp;d=#application.rooturl#/images/gravatar.gif" alt="#name#'s Gravatar" border="0" /></cfif>
					#paragraphFormat2(replaceLinks(comment))#
					</div>
					<div class="commentByLine">
					<a href="#application.blog.makeLink(entryid)###c#id#">##</a> #rb("postedby")# <cfif len(comments.website)><a href="#comments.website#" rel="nofollow">#name#</a><cfelse>#name#</cfif> 
					| #application.localeUtils.dateLocaleFormat(posted,"short")# #application.localeUtils.timeLocaleFormat(posted)#
					</div>
				</div>
				</cfoutput>

				<cfif allowComments>
					<cfoutput>
					<div class="trackbackBody addCommentLink">
					[<a href="javaScript:launchComment('#id#')">#rb("addcomment")#</a>]
					</div>
					</cfoutput>
				</cfif>
								
			<cfelseif not allowcomments>
				<cfoutput><div class="body">#rb("commentsnotallowed")#</div></cfoutput>
			<cfelse>
				<cfoutput>
				<div class="trackbackBody addCommentLink">
				<p style="text-align:left">#rb("nocomments")#</p>				
				[<a href="javaScript:launchComment('#id#')">#rb("addcomment")#</a>]
				[<a href="javaScript:launchCommentSub('#id#')">#rb("addsub")#</a>]				
				</div>
				</cfoutput>
			</cfif>

			<cfoutput>
			</div>
			</cfoutput>

		</cfif>

		<!--- this div ends the entry div --->
		<cfoutput>
		</div>
		</cfoutput>
		
	</cfloop>
	
	<cfif articles.recordCount is 0>
	
		<cfoutput><div class="body">#rb("sorry")#</div></cfoutput>
		<cfoutput>
		<div class="body">
		<cfif url.mode is "">
			#rb("noentries")#
		<cfelse>
			#rb("noentriesforcriteria")#
		</cfif>
		</div>
		</cfoutput>
	
	</cfif>

	<!--- Used for pagination. --->
	<cfif (url.startRow gt 1) or (articleData.totalEntries gte url.startRow + application.maxEntries)>
	
		<!--- get path if not /index.cfm --->
		<cfset path = rereplace(cgi.path_info, "(.*?)/index.cfm", "")>
		
		<!--- clean out startrow from query string --->
		<cfset qs = cgi.query_string>
		<!--- handle: http://www.coldfusionjedi.com/forums/messages.cfm?threadid=4DF1ED1F-19B9-E658-9D12DBFBCA680CC6 --->
		<cfset qs = reReplace(qs, "<.*?>", "", "all")>
		<cfset qs = reReplace(qs, "[\<\>]", "", "all")>
	
		<cfset qs = reReplaceNoCase(qs, "&*startrow=[\-0-9]+", "")>
		<cfif isDefined("form.search") and len(trim(form.search)) and not structKeyExists(url, "search")>
			<cfset qs = qs & "&amp;search=#htmlEditFormat(form.search)#">
		</cfif>

		<cfoutput>
		<p align="right">
		</cfoutput>
		
		<cfif url.startRow gt 1>

			<cfset prevqs = qs & "&amp;startRow=" & (url.startRow - application.maxEntries)>
	
			<cfoutput>
			<a href="#application.rooturl#/index.cfm#path#?#prevqs#">#rb("preventries")#</a>
			</cfoutput>

		</cfif>
		
		<cfif (url.startRow gt 1) and (articleData.totalEntries gte url.startRow + application.maxEntries)>
			<cfoutput> / </cfoutput>
		</cfif>
		
		<cfif articleData.totalEntries gte url.startRow + application.maxEntries>
			
			<cfset nextqs = qs & "&amp;startRow=" & (url.startRow + application.maxEntries)>
	
			<cfoutput>
			<a href="#application.rooturl#/index.cfm#path#?#nextqs#">#rb("moreentries")#</a>
			</cfoutput>

		</cfif>

		<cfoutput>
		</p>
		</cfoutput>
		
	</cfif>		

</cfmodule>
</cfmodule>

<cfsetting enablecfoutputonly=false>	
