<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>MMS Intersection Detail</title>

	<script type="text/javascript" src="//maps.googleapis.com/maps/api/js?sensor=false"></script>

	<cfif IsDefined('URL.intersection_id')>
		<cfset intersection_id = URL.intersection_id>
	<cfelseif IsDefined('FORM.intersection_id')>
		<cfset intersection_id = FORM.intersection_id>
	<cfelse>
		<cfset intersection_id = 1>
	</cfif>
	<CFQUERY NAME="Intersection_View" DATASOURCE="cms_tad">
	SELECT      Int.INTERSECTION_ID, Int.MAIN_STREET_NAME, Int.MAIN_ROUTE_NUM,
				Int.CROSS1_STREET_NAME, Int.CROSS1_ROUTE_NUM,
				Int.CROSS2_STREET_NAME, Int.CROSS2_ROUTE_NUM,
				Int.MUNICIPALITY, Int.MHD_DISTRICT, Int.Latitude, Int.Longitude, Int.OBLIQUE_IMAGE, Int.DATACOMMON_LINK,
				to_char(round(CAST(MHD.CRASH_RATE_SIGNAL AS NUMERIC),3),'FM990.000') AS MHD_CRASH_RATE_SIGNAL, 
				to_char(round(CAST(MHD.CRASH_RATE_NO_SIGNAL AS NUMERIC),3),'FM990.000') AS MHD_CRASH_RATE_NO_SIGNAL, 
				Int.UNSIG_CONTROL,
				Int.PRINCIPAL_DATA_SOURCE
	FROM        I_INTERSECTION Int, I_MHD_DISTRICT MHD
	WHERE       Int.INTERSECTION_ID = #intersection_id# AND
				Int.MHD_DISTRICT = MHD.MHD_DISTRICT
	</CFQUERY>
	
	<CFQUERY NAME="Qualitative" datasource="cms_tad">
	SELECT		COMMENTS, COMMENTS_PED_SIG, COMMENTS_SIDEWALK, COMMENTS_BIKE_LANE
	FROM		I_QUALITATIVE
	WHERE		INTERSECTION_ID = #intersection_id#
	</CFQUERY>
	
	<CFQUERY NAME="Signal" datasource="cms_tad">
	SELECT		SIGNAL_TYPE, JURISDICTION
	FROM		I_SIGNAL
	WHERE		INTERSECTION_ID = #intersection_id#
	</CFQUERY>
	
	<CFQUERY NAME="Performance" datasource="cms_tad">
	SELECT		INTERSECTION_ID, LOS_AM, LOS_PM, PEAKHOUR_AM, PEAKHOUR_PM, PEAKHR_VOL_AM, PEAKHR_VOL_PM, 
				DELAY_AM, DELAY_PM, VC_HCM_AM, VC_HCM_PM, PEAKHR_PED_AM, PEAKHR_PED_PM,
				PEAKHR_BIKE_AM, PEAKHR_BIKE_PM, to_char(round(CAST(CRASH_RATE AS NUMERIC),3),'FM990.000') "Crash_rate"
	FROM		I_PERFORMANCE
	WHERE		INTERSECTION_ID = #intersection_id#
	</CFQUERY>
	
	<CFQUERY NAME="Approach" datasource="cms_tad">
	SELECT		STREETNAME, COMPASS_DIRECTION, PEAKHOUR_DELAY_AM, PEAKHOUR_DELAY_PM
	FROM		I_APPROACH
	WHERE		INTERSECTION_ID = #intersection_id#
	</CFQUERY>
	
	<CFQUERY NAME="Crash" datasource="cms_tad">
	SELECT		YEARS, ALL_CRASHES, INVOLVE_BICYCLISTS, INVOLVE_PEDESTRIANS,
				PROP_DAMAGE_ONLY, INVOLVE_INJURIES, INVOLVE_FATALITIES
	FROM		I_CRASHES
	WHERE		INTERSECTION_ID = #intersection_id#
	</CFQUERY>

	<CFQUERY NAME="Transit_routes" datasource="cms_tad">
	SELECT		Rte.CARRIER, Rte.ROUTE_NUMBER, Rte.ROUTE_DESCRIPTION, Rte.WEB_SITE
	FROM		I_INT_TRANSIT_JCTN Jctn, I_TRANSIT_ROUTES Rte
	WHERE		Jctn.INTERSECTION_ID = #intersection_id# AND
				Jctn.TRANSIT_ROUTE_ID = Rte.TRANSIT_ROUTE_ID
	</CFQUERY>
	
	<CFQUERY NAME="Report_source" DATASOURCE="cms_tad">
	SELECT		Rep.TITLE, Rep.REPORT_TYPE, Rep.FIRM, Rep.REPORT_YEAR
	FROM		I_REPORT_JCTN Jctn, I_REPORTS Rep
	WHERE		Jctn.INTERSECTION_ID = #intersection_id# AND
				Jctn.REPORT_ID = Rep.REPORT_ID
	</CFQUERY>
	
	<style type="text/css">
		#txtFrame	{	width: 3.9in;
						padding: 0in 0.2in 0in 0in;
						border-right: 1px solid black;	}
		#gfxFrame	{	width: 3.1in;
						padding: 0in 0in 0in 0.1in;	}
		#CommentBlk	{	width: 3.7in;
						margin: 0;
						padding: 0;	}
		#TrafCtlTbl	{	width: 3.7in;	}
		#IntPerfTbl	{	width: 3.7in;	}
		#CrashTbl	{	width: 3.7in;	}
		#TransitTbl	{	width: 3.7in;	}
		#BikePedTbl	{	width: 3.7in;	}
		#ImpTbl		{	width: 3.7in;	}
		#Credits	{	text-align: right;	}
		#map_detail	{	width: 3in; 
						height: 3in; 
						margin: 0in;
						overflow: hidden;	}
		#oblique_image	{	width:3in;
						height:3in;
						margin: 0in;	}
		#definitions	{	width:3in; 
						margin: 0in;	}
		.peakHrCol	{	width: 25%;
						text-align: center;	}
		.peakHrColHdr	{	border-bottom: 1px solid black;	}
		.alignBot	{	vertical-align: bottom;	}
		A			{	text-decoration: none;
						color: #44a9f7; }
		A:hover, A:active	{ color: #bfe3ff; }
		BODY		{	font-family: Arial, Helvetica, sans-serif;
						font-size: 14px; }
					
		H2			{	line-height: normal;
						font-size: 1.5em;
						/*page-break-after: avoid;*/
						margin: 0in;
						padding-left: 0.25in;
						text-indent: -0.25in;	}
		H3			{	line-height: normal;
						margin: 1em 0em 1em 0em;
						/*page-break-after: avoid;*/	}
		IMG			{	margin: 0in;	}
		P			{	/*orphans: 2;
						widows: 2;*/
						margin: 1em 0em 1em 0em;	}
		TABLE		{	border-collapse: collapse;
						/*page-break-inside: auto;
						orphans: 2;
						widows: 3;*/
						border-spacing: 0;	}
		TD			{	vertical-align: top;
						/*page-break-inside: auto;*/	}
		TR			{	/*page-break-inside: auto;*/	}
		UL			{	margin-top: 0;	
						margin-bottom: 1em;	}
	</style>
	
	<script language="JavaScript" type="text/javascript">
	<cfoutput query="Intersection_View">
		var lat = #Latitude#;
		var lng = #Longitude#;
	</cfoutput>
    function load() {
	
	  var myOptions = {
	  	center: new google.maps.LatLng(lat, lng),
		zoom: 17,
		mapTypeId: google.maps.MapTypeId.ROADMAP,
		mapTypeControlOptions: {'style': google.maps.MapTypeControlStyle.DROPDOWN_MENU},
		panControl: false,
		streetViewControl: false,
		zoomControlOptions: {'style': 'SMALL'},
		scaleControl: true,
		overviewMapControl: false
	  };
	  
	  map = new google.maps.Map(document.getElementById("map_detail"), myOptions);
	  
	  markerOpts = {
	    'map': map,
		'visible': true,
		'position': new google.maps.LatLng(lat, lng),
		'shadow': new google.maps.MarkerImage('images/shadow50.png',
											  new google.maps.Size(37,34),
											  new google.maps.Point(0,0),
											  new google.maps.Point(9,33)),
		'icon': 'images/marker_link_blue.png'
	  };
	  new google.maps.Marker(markerOpts);
		
	}
	</script>
</head>

<body onload="load()" onunload="GUnload()" style="background-color:#ffffff;">
<!--<div style="width: 7.5in;background-color:#ffffff;margin-top:0.2in">-->
<table border="0" cellspacing="0" cellpadding="0" style="width:7.5in; margin:0.2in 0in 0in 0.2in;">
<!--<div id="txtFrame">-->
<tr>
<td id="txtFrame">
<b>Mobility Monitoring System<br>
Monitored Intersections in the Boston Region</b><br>
<br>
<cfoutput query="Intersection_View">
<cfset principalDataSource = PRINCIPAL_DATA_SOURCE>
<cfset useParensM = MAIN_ROUTE_NUM IS NOT "" AND MAIN_STREET_NAME IS NOT "">
<cfset useParens1 = CROSS1_ROUTE_NUM IS NOT "" AND CROSS1_STREET_NAME IS NOT "">
<cfset useParens2 = CROSS2_ROUTE_NUM IS NOT "" AND CROSS2_STREET_NAME IS NOT "">
<h2>#MAIN_STREET_NAME#<cfif 
	useParensM> (</cfif>#MAIN_ROUTE_NUM#<cfif useParensM>)</cfif><cfif
	CROSS1_STREET_NAME IS NOT "" OR CROSS1_ROUTE_NUM IS NOT ""> at </cfif>#CROSS1_STREET_NAME#<cfif 
	useParens1> (</cfif>#CROSS1_ROUTE_NUM#<cfif useParens1>)</cfif><cfif 
	CROSS2_STREET_NAME IS NOT "" OR CROSS2_ROUTE_NUM IS NOT ""> and </cfif>#CROSS2_STREET_NAME#<cfif
	useParens2> (</cfif>#CROSS2_ROUTE_NUM#<cfif useParens2>)</cfif></h2>
<h2>#MUNICIPALITY#, MA</h2>
<!--<a href="#DATACOMMON_LINK#" target="_blank">MetroBoston DataCommon Community Snapshot (PDF)</a>-->
</cfoutput>
<br>
<h3>Evaluator Comments and Recommendations</h3>
<div id="CommentBlk"><cfif principalDataSource IS "Speed run">
This site has not been visited by MPO staff. 
<cfelseif Qualitative.RecordCount IS 0>
Evaluation by MPO staff is in progress.
<cfelseif Qualitative.COMMENTS IS "" Or Qualitative.COMMENTS IS "<P>&nbsp;</P>">
Evaluation by MPO staff is in progress.
<cfelse>
	<cfoutput query="Qualitative">#COMMENTS#</cfoutput>
</cfif>
</div>
<h3>Traffic Control</h3>
	<table id="TrafCtlTbl">
		<cfoutput query="Intersection_view">
			<cfif UNSIG_CONTROL IS NOT "" AND UNSIG_CONTROL IS NOT "Not specified">
				<tr><td>Type:</td><td>Unsignalized: #UNSIG_CONTROL#</td></tr>
			</cfif>
		</cfoutput>
		<cfoutput query="Signal">
			<cfif Intersection_view.UNSIG_CONTROL IS "" OR Intersection_view.UNSIG_CONTROL IS "Not specified">
				<tr><td>Type:</td><td>Signalized
					<cfif SIGNAL_TYPE IS NOT "" AND SIGNAL_TYPE IS NOT "Not specified">: #SIGNAL_TYPE#</cfif>
				</td></tr>
			</cfif>
		<tr><td>Jurisdiction:</td><td>#JURISDICTION#</td></tr>
		</cfoutput>
	</table>
<cfif Approach.RecordCount GREATER THAN 0 OR Performance.RecordCount GREATER THAN 0>
	<h3>Intersection Performance</h3>
		<table id="IntPerfTbl">
		<cfif principalDataSource IS NOT "Speed run">
			<tr><th>&nbsp;</th><th colspan="2">Peak Hour</th></tr>
			<tr><th>&nbsp;</th><th class="peakHrColHdr">AM</th><th class="peakHrColHdr">PM</th></tr>
			<cfoutput query="Performance">
			<tr><td width="50%">Peak hour:</td><td class="peakHrCol">#PEAKHOUR_AM#</td><td class="peakHrCol">#PEAKHOUR_PM#</td></tr>
			<tr><td>Vehicle volume:</td><td class="peakHrCol">#PEAKHR_VOL_AM#</td><td class="peakHrCol">#PEAKHR_VOL_PM#</td></tr>
			<tr><td>Pedestrian volume:</td><td class="peakHrCol">#PEAKHR_PED_AM#</td><td class="peakHrCol">#PEAKHR_PED_PM#</td></tr>
			<tr><td>Bicyclist volume:</td><td class="peakHrCol">#PEAKHR_BIKE_AM#</td><td class="peakHrCol">#PEAKHR_BIKE_PM#</td></tr>
			<tr><td>Detailed volume counts:</td>
				<cfset turnPDFBase = ExpandPath("turning_movements/") & INTERSECTION_ID>
				<td class="peakHrCol"><cfif FileExists(turnPDFBase & "a.pdf")><a href="turning_movements/#INTERSECTION_ID#a.pdf" target="_blank">AM</a><cfelse>&nbsp;</cfif></td>
				<td class="peakHrCol"><cfif FileExists(turnPDFBase & "p.pdf")><a href="turning_movements/#INTERSECTION_ID#p.pdf" target="_blank">PM</a><cfelse>&nbsp;</cfif></td></tr>
			<tr><td>Level of service (LOS):</td><td class="peakHrCol">#LOS_AM#</td><td class="peakHrCol">#LOS_PM#</td></tr>
			<tr><td>Intersection delay (in sec.):</td><td class="peakHrCol">#Delay_AM#</td><td class="peakHrCol">#Delay_PM#</td></tr>
			<tr><td>Volume/capacity ratio:</td><td class="peakHrCol">#VC_HCM_AM#</td><td class="peakHrCol">#VC_HCM_PM#</td></tr>
			</cfoutput>
		<cfelseif Approach.RecordCount GREATER THAN 0>
			<tr><th>&nbsp;</th><th colspan="2">Peak Hour Delay</th></tr>
			<tr><th style="text-align:left;">Approach Street (dir. from int.)</th><th class="peakHrColHdr">AM</th><th class="peakHrColHdr">PM</th></tr>
			<cfoutput query="Approach">
			<tr>
				<td width="70%">#STREETNAME# (#COMPASS_DIRECTION#)</td>
				<td width="15%" style="text-align:right;">#PEAKHOUR_DELAY_AM#</td>
				<td width="15%" style="text-align:right;">#PEAKHOUR_DELAY_PM#</td>
			</tr>
			</cfoutput>
		</cfif>
		</table>
</cfif>
<h3><cfoutput query="Crash">Crashes: #YEARS#</cfoutput></h3>
	<table id="CrashTbl">
		<cfoutput query="Crash">
		<tr><td style="width:40%">Total crashes:</td>
			<td style="width:10%"><cfif ALL_CRASHES IS "">0<cfelse>#ALL_CRASHES#</cfif></td>
			<td style="width:40%">Crashes involving bicyclists:</td>
			<td style="width:10%" class="alignBot"><cfif INVOLVE_BICYCLISTS IS "">0<cfelse>#INVOLVE_BICYCLISTS#</cfif></td></tr>
		<tr><td>Crashes involving property damage only:</td>
			<td class="alignBot"><cfif PROP_DAMAGE_ONLY IS "">0<cfelse>#PROP_DAMAGE_ONLY#</cfif></td>
			<td>Crashes involving pedestrians:</td>
			<td class="alignBot"><cfif INVOLVE_PEDESTRIANS IS "">0<cfelse>#INVOLVE_PEDESTRIANS#</cfif></td></tr>
		<tr><td>Crashes involving injuries:</td>
			<td colspan="3" class="alignBot"><cfif INVOLVE_INJURIES IS "">0<cfelse>#INVOLVE_INJURIES#</cfif></td></tr>
		<tr><td>Crashes involving fatalities:</td>
			<td colspan="3" class="alignBot"><cfif INVOLVE_FATALITIES IS "">0<cfelse>#INVOLVE_FATALITIES#</cfif></td></tr>
		</cfoutput>
		<cfoutput query="Performance">
		<tr><td>Crash rate:</td><td colspan="3" class="alignBot">#CRASH_RATE#</td></tr>
		</cfoutput>
		<cfoutput query="Intersection_view">
		<tr>
			<td>Average crash rate for
				<cfif UNSIG_CONTROL IS NOT "" AND UNSIG_CONTROL IS NOT "Not specified">un</cfif>signalized intersections:
			</td>
			<td colspan="3" class="alignBot">
				<cfif UNSIG_CONTROL IS NOT "" AND UNSIG_CONTROL IS NOT "Not specified">#MHD_CRASH_RATE_NO_SIGNAL#
				<cfelse>#MHD_CRASH_RATE_SIGNAL#
				</cfif>(MassHighway District #MHD_DISTRICT#)
			</td></tr>
		</cfoutput>
	</table>
<h3>Transit</h3>
	<table id="TransitTbl">
		<cfif Transit_routes.RecordCount IS 0><tr><td>No transit service crosses this intersection.</td></tr></cfif>
		<cfoutput query="Transit_routes">
		<tr><td>
			<cfif WEB_SITE IS NOT ""><a href="#WEB_SITE#" target="_blank"></cfif>
				#CARRIER# <cfif ROUTE_NUMBER IS NOT "">Bus Route ###ROUTE_NUMBER#: </cfif>#ROUTE_DESCRIPTION#
			<cfif WEB_SITE IS NOT ""></a></cfif>
		</td></tr>
		</cfoutput>
	</table>
<h3>Bicycle and Pedestrian</h3>
	<table id="BikePedTbl">
		<cfif Qualitative.RecordCount IS 0>
		<tr><td width="25%">Pedestrian signals:</td><td>No comments</td></tr>
		<tr><td>Sidewalks:</td><td>No comments</td></tr>
		<tr><td>Bicycle lanes:</td><td>No comments</td></tr>
		<cfelse>
		<cfoutput query="Qualitative">
		<tr><td width="25%">Pedestrian signals:</td><td class="alignBot">#COMMENTS_PED_SIG#</td></tr>
		<tr><td>Sidewalks:</td><td class="alignBot">#COMMENTS_SIDEWALK#</td></tr>
		<tr><td>Bicycle lanes:</td><td class="alignBot">#COMMENTS_BIKE_LANE#</td></tr>
		</cfoutput>
		</cfif>
	</table>
<!--<h3>Implementation</h3>
	<table id="ImpTbl">
		<tr><td width="25%">Status:</td></tr>
	</table>-->
	<div id="Credits">
		<br><b>Data source<cfif Report_source.RecordCount GREATER THAN 1>s</cfif>:</b><br>
		<cfoutput query="Report_source">
		#TITLE# (#REPORT_TYPE#),<br>
		#FIRM#, #REPORT_YEAR#<br>
		</cfoutput>
	</div>
</td>
<td id="gfxFrame" name="gfxFrame"><div id="map_detail"></div>
<div id="oblique_image">
	<cfoutput query="Intersection_View">
		<cfset obliqueImageBase = ExpandPath(OBLIQUE_IMAGE)>
		<cfif OBLIQUE_IMAGE IS "">
			<table style="width:100%;height:100%">
				<tr>
					<td style="text-align:center;height:100%;vertical-align:middle;padding:25%;border:1px solid gray">No 
						oblique aerial image is available for this intersection.</td>
				</tr>
			</table>
		<cfelseif NOT FileExists(obliqueImageBase)>
			<table style="width:100%;height:100%">
				<tr>
					<td style="text-align:center;height:100%;vertical-align:middle;padding:25%;border:1px solid gray">No 
						oblique aerial image is available for this intersection.</td>
				</tr>
			</table>
		<cfelse>
			<img width="100%" height="100%" border="0" 
			 alt="Oblique aerial image of #MAIN_STREET_NAME# at #CROSS1_STREET_NAME# in #MUNICIPALITY#" 
			 src="#OBLIQUE_IMAGE#">
			<div style="position:relative;top:-2.9in;left:0.11in">
				<cfset imageFile = GetFileFromPath(OBLIQUE_IMAGE)>
				<cfset dotIndex = Find(".",imageFile)>
				<cfif dotIndex GREATER THAN 2>
					<cfif IsNumeric(Left(imageFile,dotIndex-2))>
						<cfset oblique_direction = LCase(Mid(imageFile,dotIndex-1,1))>
						<cfswitch expression="#oblique_direction#">
							<cfcase value="n"><img src="images/arrow_north.gif"></cfcase>
							<cfcase value="s"><img src="images/arrow_south.gif"></cfcase>
							<cfcase value="e"><img src="images/arrow_east.gif"></cfcase>
							<cfcase value="w"><img src="images/arrow_west.gif"></cfcase>
							<cfdefaultcase></cfdefaultcase>
						</cfswitch>
					</cfif>
				</cfif>
			</div>
		</cfif>
	</cfoutput>
</div>
<div id="definitions">
	<h3>Definitions</h3>
	<cfif Approach.RecordCount GREATER THAN 0 OR Performance.RecordCount GREATER THAN 0>
		<p><b>Peak hour:</b> The maximum-volume hour during the morning or the evening.</p>
		<cfif principalDataSource IS NOT "Speed run">
			<p><b>Level of service (LOS):</b> A qualitative measure describing operational conditions at an intersection, 
				based on intersection delay (see below). LOS A is best, LOS F is worst.</p>
		</cfif>
		<p><b>Intersection delay:</b> The total additional travel time experienced by a driver 
			as a result of traffic control measures (for example, signals) and interaction with other users 
			of the intersection. </p>
		<cfif principalDataSource IS NOT "Speed run">
			<p><b>Volume/capacity ratio:</b> The ratio of the traffic flow rate to intersection capacity. Capacity is the 
				maximum hourly rate at which vehicles reasonably can be expected to proceed through an intersection under 
				prevailing roadway, traffic, and control conditions. A V/C above 1.0 indicates that the intersection operates 
				beyond its capacity.</p>
		</cfif>
	</cfif>
	<p><b>Crash rate:</b> The number of crashes per million vehicles entering the intersection.</p>
</div>
<!--<div style="clear:both;">

</div>-->
<!--</div>-->
</td>
</tr>
</table>
</body>
</html>
