<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title>MMS query results</title>
	
	<!--- On initial execution of page, there is no form data yet. Initialize the form variables for 
	      an unrestricted, all-records query. --->
	<cfif NOT IsDefined("FORM.crashes")>
		<cfset FORM.municipality = 999>
		<cfset FORM.route = "999">
		<cfset FORM.LOS = "999">
		<cfset FORM.crashes = "999">
		<cfset FORM.bikePedCrashes = "999">
		<cfset FORM.minX = -180>
		<cfset FORM.maxX = 0>
		<cfset FORM.minY = 0>
		<cfset FORM.maxY = 90>
		<cfset FORM.retrieveAllMarkersInExtent = 0>
		<cfset FORM.updateExtent = 1>
	</cfif>
	
	<!--- Set up numCriteria and multipleCriteria variables to help in initializing the query criteria
	      drop-down lists appropriately with the "All" and "All meeting other criteria" choices --->
	<cfset numCriteria = 0>
	<cfif FORM.municipality LESS THAN 998><cfset numCriteria = numCriteria + 1></cfif>
	<cfif NOT ("+999+998+" CONTAINS FORM.route)><cfset numCriteria = numCriteria + 1></cfif>
	<cfif NOT ("+999+998+" CONTAINS FORM.LOS)><cfset numCriteria = numCriteria + 1></cfif>
	<cfif NOT ("+999+998+" CONTAINS FORM.crashes)><cfset numCriteria = numCriteria + 1></cfif>
	<cfif NOT ("+999+998+" CONTAINS FORM.bikePedCrashes)><cfset numCriteria = numCriteria + 1></cfif>
	<cfif numCriteria GREATER THAN 1><cfset multipleCriteria = TRUE><cfelse><cfset multipleCriteria = FALSE></cfif>
	<cfset otherCriteriaPhrase = "All">
	
	<!--- The principle query: the INTERSECTION table joined to supporting tables.
	      This query returns all records meeting non-spatial criteria, and is the
		  "result set" for tabular purposes--->
	<cfquery name="meetNonSpatialCriteria" datasource="cms_tad" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
		SELECT  Int.INTERSECTION_ID, Int.MAIN_STREET_NAME, 
		        Int.CROSS1_STREET_NAME, Int.CROSS1_ROUTE_NUM, Int.CROSS2_STREET_NAME, Int.CROSS2_ROUTE_NUM,
				Int.MAIN_ROUTE_NUM,
				Int.MUNICIPALITY, Int.CITY_NUM,
				CASE WHEN Crash.ALL_CRASHES IS NULL THEN '0-4'
					 WHEN Crash.ALL_CRASHES BETWEEN 0 AND 4 THEN '0-4'
					 WHEN Crash.ALL_CRASHES BETWEEN 5 AND 14 THEN '5-14'
					 WHEN Crash.ALL_CRASHES BETWEEN 15 AND 29 THEN '15-29'
					 WHEN Crash.ALL_CRASHES >= 30 THEN '30+' 
				END AS Crashes,
				CASE WHEN Crash.ALL_CRASHES IS NULL THEN 0
					 WHEN Crash.ALL_CRASHES BETWEEN 0 AND 4 THEN 0
					 WHEN Crash.ALL_CRASHES BETWEEN 5 AND 14 THEN 5
					 WHEN Crash.ALL_CRASHES BETWEEN 15 AND 29 THEN 15
					 WHEN Crash.ALL_CRASHES >= 30 THEN 30 
				END AS Crash_List_Order,
				CASE WHEN Crash.INVOLVE_BIKE_PED IS NULL OR Crash.INVOLVE_BIKE_PED = 0 THEN 'None'
					 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 1 AND 2 THEN '1-2'
					 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 3 AND 4 THEN '3-4'
					 WHEN Crash.INVOLVE_BIKE_PED >= 5 THEN '5+' 
				END AS Bike_Ped_Crashes,
				CASE WHEN Crash.INVOLVE_BIKE_PED IS NULL OR Crash.INVOLVE_BIKE_PED = 0 THEN 0
					 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 1 AND 2 THEN 1
					 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 3 AND 4 THEN 3
					 WHEN Crash.INVOLVE_BIKE_PED >= 5 THEN 5 
				END AS Bike_Ped_Crash_List_Order,
				Perf.LOS_AM, Perf.LOS_PM, 
				CASE CHR(GREATEST( ASCII(CASE WHEN Perf.LOS_AM IS NULL THEN ' ' ELSE Perf.LOS_AM END),
							       ASCII(CASE WHEN Perf.LOS_PM IS NULL THEN ' ' ELSE Perf.LOS_PM END)))
					WHEN 'A' THEN 'LOS A-D'
					WHEN 'B' THEN 'LOS A-D'
					WHEN 'C' THEN 'LOS A-D'
					WHEN 'D' THEN 'LOS A-D'
					WHEN 'E' THEN 'LOS E-F'
					WHEN 'F' THEN 'LOS E-F'
					ELSE ''
				END AS LOS,												
				Int.Latitude, Int.Longitude,
				MAIN_STREET_NAME 
				|| CASE WHEN MAIN_ROUTE_NUM IS NOT NULL THEN ' (' || MAIN_ROUTE_NUM || ')' ELSE '' END
				|| CASE WHEN CROSS1_STREET_NAME IS NOT NULL OR CROSS1_ROUTE_NUM IS NOT NULL THEN ' and' ELSE '' END
				|| CASE WHEN CROSS1_STREET_NAME IS NOT NULL THEN ' ' || CROSS1_STREET_NAME ELSE '' END
				|| CASE WHEN CROSS1_ROUTE_NUM IS NOT NULL THEN ' (' || CROSS1_ROUTE_NUM || ')' ELSE '' END
				|| CASE WHEN CROSS2_STREET_NAME IS NOT NULL OR CROSS2_ROUTE_NUM IS NOT NULL THEN ' and' ELSE '' END
				|| CASE WHEN CROSS2_STREET_NAME IS NOT NULL THEN ' ' || CROSS2_STREET_NAME ELSE '' END
				|| CASE WHEN CROSS2_ROUTE_NUM IS NOT NULL THEN ' (' || CROSS2_ROUTE_NUM || ')' ELSE '' END  AS Int_Desc	
		FROM    
				I_INTERSECTION Int
				LEFT OUTER JOIN I_PERFORMANCE AS Perf ON Int.INTERSECTION_ID = Perf.INTERSECTION_ID
				LEFT OUTER JOIN I_CRASHES AS Crash ON Int.INTERSECTION_ID = Crash.INTERSECTION_ID	
				
				<cfif NOT ("+999+998+" CONTAINS FORM.route)>
				LEFT OUTER JOIN I_INT_ROUTE_JCTN AS Rte ON Int.INTERSECTION_ID = Rte.INTERSECTION_ID
				</cfif>
		WHERE   
				Int.MOST_RECENT_REPORT_YEAR >= 2000  AND				
				CAST ( (CASE WHEN Int.Latitude IS NULL THEN 0 ELSE Int.Latitude END) AS NUMERIC ) <> 0 AND 
				CAST ( (CASE WHEN Int.Longitude IS NULL THEN 0 ELSE Int.Longitude END) AS NUMERIC ) <> 0
				
				<cfif FORM.municipality LESS THAN 998>AND Int.CITY_NUM = #FORM.municipality#</cfif>
				<cfif NOT ("+999+998+" CONTAINS FORM.route)>AND 
					(CASE WHEN Rte.ROUTE_SYSTEM = 'I'  THEN 'Interstate'
						  WHEN Rte.ROUTE_SYSTEM = 'US' THEN 'US'
						  WHEN Rte.ROUTE_SYSTEM = 'SR' THEN 'MA'
						  ELSE Rte.ROUTE_SYSTEM
					END) = SUBSTRING('#FORM.route#' FROM 1 FOR (POSITION(' ' IN '#FORM.route#')-1))
					AND 
						<!--- Rte.ROUTE_NUMBER = SUBSTR('#FORM.route#',INSTR('#FORM.route#',' ')+1) --->
						Rte.ROUTE_NUMBER = SUBSTRING('#FORM.route#' FROM (POSITION(' ' IN '#FORM.route#')+1) FOR (CHAR_LENGTH('#FORM.route#') - POSITION(' ' IN '#FORM.route#')))
				</cfif>
				<cfif NOT ("+999+998+" CONTAINS FORM.LOS)>AND 	
					(CASE CHR(GREATEST( ASCII(CASE WHEN Perf.LOS_AM IS NULL THEN ' ' ELSE Perf.LOS_AM END),
							            ASCII(CASE WHEN Perf.LOS_PM IS NULL THEN ' ' ELSE Perf.LOS_PM END)))				
						WHEN 'A' THEN 'LOS A-D'
						WHEN 'B' THEN 'LOS A-D'
						WHEN 'C' THEN 'LOS A-D'
						WHEN 'D' THEN 'LOS A-D'
						WHEN 'E' THEN 'LOS E-F'
						WHEN 'F' THEN 'LOS E-F'
						ELSE ''
					END) = '#FORM.LOS#'								
				</cfif>
				<cfif NOT ("+999+998+" CONTAINS FORM.crashes)>AND 
					(CASE WHEN Crash.ALL_CRASHES IS NULL THEN '0-4'
						  WHEN Crash.ALL_CRASHES BETWEEN 0 AND 4 THEN '0-4'
						  WHEN Crash.ALL_CRASHES BETWEEN 5 AND 14 THEN '5-14'
						  WHEN Crash.ALL_CRASHES BETWEEN 15 AND 29 THEN '15-29'
						  WHEN Crash.ALL_CRASHES >= 30 THEN '30+' 
					END) = '#FORM.crashes#'
				</cfif>
				<cfif NOT ("+999+998+" CONTAINS FORM.bikePedCrashes)>AND 
					(CASE 
						 WHEN Crash.INVOLVE_BIKE_PED IS NULL OR Crash.INVOLVE_BIKE_PED = 0 THEN 'None'
						 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 1 AND 2 THEN '1-2'
						 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 3 AND 4 THEN '3-4'
						 WHEN Crash.INVOLVE_BIKE_PED >= 5 THEN '5+' 
					END) = '#FORM.bikePedCrashes#'
				</cfif>
		ORDER BY Int.CITY_NUM, Int.MAIN_STREET_NAME
	</cfquery>
	<!--- This query is the records meeting the spatial criteria (falling within Google Map display)
		  that do NOT meet the non-spatial criteria. It is used to add non-result set markers to the
		  map display --->
	<cfquery name="othersMeetSpatialCriteria" datasource="cms_tad">
		<cfif FORM.retrieveAllMarkersInExtent IS NOT 0>
		    SELECT  INTERSECTION_ID, MAIN_STREET_NAME, CROSS1_STREET_NAME, CROSS2_STREET_NAME,
			        MAIN_ROUTE_NUM, CROSS1_ROUTE_NUM, CROSS2_ROUTE_NUM, MUNICIPALITY, CITY_NUM,
					Latitude, Longitude,
					MAIN_STREET_NAME 
					|| CASE WHEN MAIN_ROUTE_NUM IS NOT NULL THEN ' (' || MAIN_ROUTE_NUM || ')' ELSE '' END
					|| CASE WHEN CROSS1_STREET_NAME IS NOT NULL OR CROSS1_ROUTE_NUM IS NOT NULL THEN ' and' ELSE '' END
					|| CASE WHEN CROSS1_STREET_NAME IS NOT NULL THEN ' ' || CROSS1_STREET_NAME ELSE '' END
					|| CASE WHEN CROSS1_ROUTE_NUM IS NOT NULL THEN ' (' || CROSS1_ROUTE_NUM || ')' ELSE '' END
					|| CASE WHEN CROSS2_STREET_NAME IS NOT NULL OR CROSS2_ROUTE_NUM IS NOT NULL THEN ' and' ELSE '' END
					|| CASE WHEN CROSS2_STREET_NAME IS NOT NULL THEN ' ' || CROSS2_STREET_NAME ELSE '' END
					|| CASE WHEN CROSS2_ROUTE_NUM IS NOT NULL THEN ' (' || CROSS2_ROUTE_NUM || ')' ELSE '' END "Int_Desc"
			FROM    I_INTERSECTION
			WHERE   MOST_RECENT_REPORT_YEAR >= 2000 AND
					CAST ( (CASE WHEN Latitude IS NULL THEN 0 ELSE Latitude END) AS NUMERIC ) BETWEEN #FORM.minY# AND #FORM.maxY# AND
						CAST ( (CASE  WHEN Longitude IS NULL THEN 0 ELSE Longitude END) AS NUMERIC ) BETWEEN #FORM.minX# AND #FORM.maxX# AND
					INTERSECTION_ID NOT IN
				   (SELECT	Int.INTERSECTION_ID
					FROM    
							I_INTERSECTION Int
							LEFT OUTER JOIN I_PERFORMANCE AS Perf ON Int.INTERSECTION_ID = Perf.INTERSECTION_ID
							LEFT OUTER JOIN I_CRASHES AS Crash ON Int.INTERSECTION_ID = Crash.INTERSECTION_ID
							
							<cfif NOT ("+999+998+" CONTAINS FORM.route)>
							LEFT OUTER JOIN I_INT_ROUTE_JCTN AS Rte ON Int.INTERSECTION_ID = Rte.INTERSECTION_ID 
							</cfif>							
					WHERE   
							Int.MOST_RECENT_REPORT_YEAR >= 2000 AND
							CAST ( (CASE WHEN Int.Latitude IS NULL THEN 0 ELSE Int.Latitude END) AS NUMERIC ) <> 0 AND 
							CAST ( (CASE WHEN Int.Longitude IS NULL THEN 0 ELSE Int.Longitude END) AS NUMERIC ) <> 0
							<cfif FORM.municipality LESS THAN 998>AND Int.CITY_NUM = #FORM.municipality#</cfif>
							<cfif NOT ("+999+998+" CONTAINS FORM.route)>
								AND (CASE WHEN Rte.ROUTE_SYSTEM = 'I'  THEN 'Interstate'
										  WHEN Rte.ROUTE_SYSTEM = 'US' THEN 'US'
										  WHEN Rte.ROUTE_SYSTEM = 'SR' THEN 'MA'
										  ELSE Rte.ROUTE_SYSTEM
									END) = SUBSTRING('#FORM.route#' FROM 1 FOR (POSITION(' ' IN '#FORM.route#')-1))
								AND Rte.ROUTE_NUMBER = SUBSTRING('#FORM.route#' FROM (POSITION(' ' IN '#FORM.route#')+1) FOR (CHAR_LENGTH('#FORM.route#') - POSITION(' ' IN '#FORM.route#')))								
							</cfif>
							<cfif NOT ("+999+998+" CONTAINS FORM.LOS)>AND 							
									(CASE CHR(GREATEST( ASCII(CASE WHEN Perf.LOS_AM IS NULL THEN ' ' ELSE Perf.LOS_AM END),
													    ASCII(CASE WHEN Perf.LOS_PM IS NULL THEN ' ' ELSE Perf.LOS_PM END)))
										WHEN 'A' THEN 'LOS A-D'
										WHEN 'B' THEN 'LOS A-D'
										WHEN 'C' THEN 'LOS A-D'
										WHEN 'D' THEN 'LOS A-D'
										WHEN 'E' THEN 'LOS E-F'
										WHEN 'F' THEN 'LOS E-F'
										ELSE ''
									END) = '#FORM.LOS#'
							</cfif>
							<cfif NOT ("+999+998+" CONTAINS FORM.crashes)>AND 
								(CASE WHEN Crash.ALL_CRASHES IS NULL THEN '0-4'
									  WHEN Crash.ALL_CRASHES BETWEEN 0 AND 4 THEN '0-4'
									  WHEN Crash.ALL_CRASHES BETWEEN 5 AND 14 THEN '5-14'
									  WHEN Crash.ALL_CRASHES BETWEEN 15 AND 29 THEN '15-29'
									  WHEN Crash.ALL_CRASHES >= 30 THEN '30+' 
								END) = '#FORM.crashes#'
							</cfif>
							<cfif NOT ("+999+998+" CONTAINS FORM.bikePedCrashes)>AND 
								(CASE 
									 WHEN Crash.INVOLVE_BIKE_PED IS NULL OR Crash.INVOLVE_BIKE_PED = 0 THEN 'None'
									 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 1 AND 2 THEN '1-2'
									 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 3 AND 4 THEN '3-4'
									 WHEN Crash.INVOLVE_BIKE_PED >= 5 THEN '5+' 
								END) = '#FORM.bikePedCrashes#'
							</cfif>
				   )				   
			ORDER BY MAIN_STREET_NAME 
					|| CASE WHEN MAIN_ROUTE_NUM IS NOT NULL THEN ' (' || MAIN_ROUTE_NUM || ')' ELSE '' END
					|| CASE WHEN CROSS1_STREET_NAME IS NOT NULL OR CROSS1_ROUTE_NUM IS NOT NULL THEN ' and' ELSE '' END
					|| CASE WHEN CROSS1_STREET_NAME IS NOT NULL THEN ' ' || CROSS1_STREET_NAME ELSE '' END
					|| CASE WHEN CROSS1_ROUTE_NUM IS NOT NULL THEN ' (' || CROSS1_ROUTE_NUM || ')' ELSE '' END
					|| CASE WHEN CROSS2_STREET_NAME IS NOT NULL OR CROSS2_ROUTE_NUM IS NOT NULL THEN ' and' ELSE '' END
					|| CASE WHEN CROSS2_STREET_NAME IS NOT NULL THEN ' ' || CROSS2_STREET_NAME ELSE '' END
					|| CASE WHEN CROSS2_ROUTE_NUM IS NOT NULL THEN ' (' || CROSS2_ROUTE_NUM || ')' ELSE '' END
		<cfelse>
		<!--- If display is zoomed out too, far, use a query that returns no rows --->
			SELECT  INTERSECTION_ID, MAIN_STREET_NAME, CROSS1_STREET_NAME, CROSS2_STREET_NAME,
					MAIN_ROUTE_NUM, CROSS1_ROUTE_NUM, CROSS2_ROUTE_NUM, MUNICIPALITY, CITY_NUM,
					Latitude, Longitude
			FROM    I_INTERSECTION
			WHERE	INTERSECTION_ID < 0
		</cfif>
	</cfquery>
	
	<!--- Queries of the principle query, to return unique, sorted values from various fields of the
	      main query for populating the query criteria drop-down lists. --->
	
	<!--- This query returns the subset of the result set that lies within the bounds of the
		  Google Map display --->
	<cfquery name="meetAllCriteria" dbtype="query">
		<!--- Only return rows for the query if some criteria have been specified (never return all rows) --->
		<cfif numCriteria GREATER THAN 0>
			SELECT  INTERSECTION_ID, MAIN_STREET_NAME, CROSS1_STREET_NAME, CROSS2_STREET_NAME, 
					MAIN_ROUTE_NUM, CROSS1_ROUTE_NUM, CROSS2_ROUTE_NUM, MUNICIPALITY, CITY_NUM, Latitude, Longitude,
					Int_Desc
			FROM    meetNonSpatialCriteria
			WHERE   Latitude >= #FORM.minY# AND Latitude <= #FORM.maxY# AND
					Longitude >= ( 0 - #Abs(FORM.minX)# ) AND Longitude <= ( 0 - #Abs(FORM.maxX)# )
			ORDER BY Int_Desc
		<cfelse>
			SELECT  INTERSECTION_ID, MAIN_STREET_NAME, CROSS1_STREET_NAME, CROSS2_STREET_NAME, 
					MAIN_ROUTE_NUM, CROSS1_ROUTE_NUM, CROSS2_ROUTE_NUM, MUNICIPALITY, CITY_NUM, Latitude, Longitude
			FROM    meetNonSpatialCriteria
			WHERE	INTERSECTION_ID < 0
		</cfif>
	</cfquery>

	<cfquery name="baseOfSubqueries" datasource="cms_tad">
		SELECT  Int.INTERSECTION_ID, Int.MAIN_STREET_NAME, 
		        Int.CROSS1_STREET_NAME, Int.CROSS1_ROUTE_NUM, Int.CROSS2_STREET_NAME, Int.CROSS2_ROUTE_NUM,
				Int.MAIN_ROUTE_NUM,
				Int.MUNICIPALITY, Int.CITY_NUM,
				CASE WHEN Crash.ALL_CRASHES IS NULL THEN '0-4'
					 WHEN Crash.ALL_CRASHES BETWEEN 0 AND 4 THEN '0-4'
					 WHEN Crash.ALL_CRASHES BETWEEN 5 AND 14 THEN '5-14'
					 WHEN Crash.ALL_CRASHES BETWEEN 15 AND 29 THEN '15-29'
					 WHEN Crash.ALL_CRASHES >= 30 THEN '30+' 
				END AS Crashes,
				CASE WHEN Crash.ALL_CRASHES IS NULL THEN 0
					 WHEN Crash.ALL_CRASHES BETWEEN 0 AND 4 THEN 0
					 WHEN Crash.ALL_CRASHES BETWEEN 5 AND 14 THEN 5
					 WHEN Crash.ALL_CRASHES BETWEEN 15 AND 29 THEN 15
					 WHEN Crash.ALL_CRASHES >= 30 THEN 30 
				END AS Crash_List_Order,
				CASE WHEN Crash.INVOLVE_BIKE_PED IS NULL OR Crash.INVOLVE_BIKE_PED = 0 THEN 'None'
					 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 1 AND 2 THEN '1-2'
					 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 3 AND 4 THEN '3-4'
					 WHEN Crash.INVOLVE_BIKE_PED >= 5 THEN '5+' 
				END AS Bike_Ped_Crashes,
				CASE WHEN Crash.INVOLVE_BIKE_PED IS NULL OR Crash.INVOLVE_BIKE_PED = 0 THEN 0
					 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 1 AND 2 THEN 1
					 WHEN Crash.INVOLVE_BIKE_PED BETWEEN 3 AND 4 THEN 3
					 WHEN Crash.INVOLVE_BIKE_PED >= 5 THEN 5 
				END AS Bike_Ped_Crash_List_Order,
				Perf.LOS_AM, Perf.LOS_PM, 
				CASE CHR(GREATEST( ASCII(CASE WHEN Perf.LOS_AM IS NULL THEN ' ' ELSE Perf.LOS_AM END),
							       ASCII(CASE WHEN Perf.LOS_PM IS NULL THEN ' ' ELSE Perf.LOS_PM END)))
					WHEN 'A' THEN 'LOS A-D'
					WHEN 'B' THEN 'LOS A-D'
					WHEN 'C' THEN 'LOS A-D'
					WHEN 'D' THEN 'LOS A-D'
					WHEN 'E' THEN 'LOS E-F'
					WHEN 'F' THEN 'LOS E-F'
					ELSE ''
				END AS LOS,				
				Int.Latitude, Int.Longitude,
				MAIN_STREET_NAME 
				|| CASE WHEN MAIN_ROUTE_NUM IS NOT NULL THEN ' (' || MAIN_ROUTE_NUM || ')' ELSE '' END
				|| CASE WHEN CROSS1_STREET_NAME IS NOT NULL OR CROSS1_ROUTE_NUM IS NOT NULL THEN ' and' ELSE '' END
				|| CASE WHEN CROSS1_STREET_NAME IS NOT NULL THEN ' ' || CROSS1_STREET_NAME ELSE '' END
				|| CASE WHEN CROSS1_ROUTE_NUM IS NOT NULL THEN ' (' || CROSS1_ROUTE_NUM || ')' ELSE '' END
				|| CASE WHEN CROSS2_STREET_NAME IS NOT NULL OR CROSS2_ROUTE_NUM IS NOT NULL THEN ' and' ELSE '' END
				|| CASE WHEN CROSS2_STREET_NAME IS NOT NULL THEN ' ' || CROSS2_STREET_NAME ELSE '' END
				|| CASE WHEN CROSS2_ROUTE_NUM IS NOT NULL THEN ' (' || CROSS2_ROUTE_NUM || ')' ELSE '' END "Int_Desc",
				CASE WHEN Rte.ROUTE_SYSTEM = 'I'  THEN 'Interstate'
					  WHEN Rte.ROUTE_SYSTEM = 'US' THEN 'US'
					  WHEN Rte.ROUTE_SYSTEM = 'SR' THEN 'MA'
					  ELSE Rte.ROUTE_SYSTEM
				END AS "RTE_SYSTEM",
				Rte.ROUTE_NUMBER,
				to_number(replace(replace(Rte.ROUTE_NUMBER,'A','.1'),'*','0'),'999.9') AS ROUTE_NUMBER_AS_NUMBER
				
		FROM    I_INTERSECTION Int
				LEFT OUTER JOIN I_PERFORMANCE AS Perf ON Int.INTERSECTION_ID = Perf.INTERSECTION_ID
				LEFT OUTER JOIN I_CRASHES AS Crash ON Int.INTERSECTION_ID = Crash.INTERSECTION_ID 
				LEFT OUTER JOIN I_INT_ROUTE_JCTN AS Rte ON Int.INTERSECTION_ID = Rte.INTERSECTION_ID				
		WHERE   Int.MOST_RECENT_REPORT_YEAR >= 2000 AND
				CAST ((CASE WHEN Int.Latitude IS NULL THEN 0 ELSE Int.Latitude END) AS NUMERIC)  <> 0 AND 
				CAST ((CASE WHEN Int.Longitude IS NULL THEN 0 ELSE Int.Longitude END) AS NUMERIC)  <> 0
    </cfquery>
   
	<cfquery name="townList" dbtype="query">
		SELECT DISTINCT CITY_NUM, MUNICIPALITY FROM baseOfSubqueries WHERE MUNICIPALITY <> '' ORDER BY MUNICIPALITY
	</cfquery>
	<cfquery name="LOSList" dbtype="query">
		SELECT DISTINCT LOS FROM baseOfSubqueries WHERE LOS <> '' ORDER BY LOS
	</cfquery>
    <cfquery name="routeList" dbtype="query">
    	SELECT DISTINCT RTE_SYSTEM, ROUTE_NUMBER, ROUTE_NUMBER_AS_NUMBER FROM baseOfSubqueries WHERE ROUTE_NUMBER <> '' 
        ORDER BY ROUTE_NUMBER_AS_NUMBER, RTE_SYSTEM
    </cfquery>
	<cfquery name="crashList" dbtype="query">
		SELECT DISTINCT Crashes, Crash_List_Order FROM baseOfSubqueries ORDER BY Crash_List_Order
	</cfquery>
	<cfquery name="bikePedCrashList" dbtype="query">
		SELECT DISTINCT Bike_Ped_Crashes, Bike_Ped_Crash_List_Order FROM baseOfSubqueries 
		ORDER BY Bike_Ped_Crash_List_Order
	</cfquery>

	<cfquery name="resultExtents" dbtype="query">
		SELECT min(Longitude) AS minX, max(Longitude) AS maxX, min(Latitude) AS minY, max(Latitude) AS maxY 
		FROM meetNonSpatialCriteria
	</cfquery>
	

	<link rel="stylesheet" type="text/css" href="mms_intersection.css">

	<script language="JavaScript" type="text/javascript">
	
	// Opens an intersection record detail page using a hidden form. Invoked by a click on either
	// a row in the main query result list or the Google Maps Infowindow balloon (both on the main query page)
	function openIntDetail(int_id) {
		document.getElementById("intersection_id").value = int_id;
		// Following commented out line was necessary with Chrome when form used POST method,
		// since Chrome does not actuate a form a second time unless the action target has
		// changed, which it typically wouldn't with POSTed parms. Addition of random URL parm
		// was a workaround, but now the form uses GET, so action target is different for
		// each detail page (unless user requests same detail page twice in a row!)
		//	document.getElementById("detailRequestForm").action = "mms_intersection_detail.cfm?" + Math.round(Math.random()*1000000);
		document.getElementById("detailRequestForm").submit();
		return void(0);
	}

	// Runs every time the page loads to push data from the query result set into appropriate Javascript variables
	// and HTML document nodes (on the main query page). Specifically, it copies a 
	// result set table constructed on this page by ColdFusion into a corresponding [visible] element on the main
	// query page. It also initializes the Javascript full intersection array (once only), and sets the 
	// result set array, geographic limits, and record count variables (every time). Finally, it calls a function
	// on the parent page to adjust the Google Map display.
	function processResultData() {
		//alert("Response page loaded");
		var p = parent;
		p.framesLoaded++;	// page load handlers here and on the main page increment this variable
		if (p.framesLoaded >= 2)  {	// following block executes only if both this page and parent page have finished loading
			// copy result set table from "staging area" on this page to visible area of parent page
			p.document.getElementById("results").innerHTML =
				document.getElementById("results").innerHTML;
			p.boolNewResultSetToMap = true;
			var i;

			// always initialize arrays of intersections
			p.arrDispResultSet = [];
			p.arrDispNotResultSet = [];
			<cfoutput query="meetAllCriteria">
			p.arrDispResultSet.push([#INTERSECTION_ID#,"#MUNICIPALITY#","#MAIN_STREET_NAME#","#MAIN_ROUTE_NUM#","#CROSS1_STREET_NAME#","#CROSS1_ROUTE_NUM#","#CROSS2_STREET_NAME#","#CROSS2_ROUTE_NUM#",#Latitude#,#Longitude#,"#Int_Desc#"]);</cfoutput>
			<cfoutput query="othersMeetSpatialCriteria">
			p.arrDispNotResultSet.push([#INTERSECTION_ID#,"#MUNICIPALITY#","#MAIN_STREET_NAME#","#MAIN_ROUTE_NUM#","#CROSS1_STREET_NAME#","#CROSS1_ROUTE_NUM#","#CROSS2_STREET_NAME#","#CROSS2_ROUTE_NUM#",#Latitude#,#Longitude#,"#Int_Desc#"]);</cfoutput>

/*temp = false;
errMsg = "";
for (i = 0; i < p.arrDispNotResultSet.length - 1; i++) {
	if (p.arrDispNotResultSet[i][10] > p.arrDispNotResultSet[i+1][10]) {
		errMsg = errMsg + p.arrDispNotResultSet[i][10] + " is not less than " + p.arrDispNotResultSet[i+1][10] + "\n"
	}
}
alert(errMsg);
*/
			// set the variables indicating the geographic limits of the result set
			<cfif resultExtents.RecordCount EQ 0>
				p.boolNewExtent = false;
			<cfelse>
				<cfoutput query="resultExtents">
					if (p.minX == #minX# && p.maxX == #maxX# && p.minY == #minY# && p.maxY == #maxY#) {
						p.boolNewExtent = false;
					} else {
						p.boolNewExtent = true;
					}
					p.minX = #minX#;
					p.maxX = #maxX#;
					p.minY = #minY#;
					p.maxY = #maxY#;
				</cfoutput>
			</cfif>

			// set the variable giving the record count of the result set
			<cfoutput>
				p.numResults = #meetNonSpatialCriteria.RecordCount#;
				var otherSpatialResults = #othersMeetSpatialCriteria.RecordCount#;
				var blah = #FORM.retrieveAllMarkersInExtent#;
			</cfoutput>
			
			// set variable that reveals if result set is result of not specifying any criteria
			<cfoutput>
				p.numCriteriaSpecified = #numCriteria#;
			</cfoutput>

			// if the query did not specify a geographic extent (was not submitted due
			// to user moving around in map window), then update the extent to fit
			// the result set (which action will cause a new query to be submitted
			// specifying geographic extent and causing execution of other branch of this
			// if statement)
			<cfif FORM.updateExtent IS 1 and meetNonSpatialCriteria.RecordCount GT 0>
				p.adjustMapToResultSet();	// update the extent of the map
			// otherwise, query was submitted for current map window extent, so don't
			// update the map extents--just used response data to update what markers
			// are added to the map display
			<cfelse>
				p.manageMarkersForExtent();	// update the markers shown on the map
			</cfif>
		}
	}
	
	/**********
	  DOQUERY
	**********/
	// Each of the visible query criteria form elements have onchange handlers. Submitting the query request
	// from a hidden, shadow form allows the values of the form to be changed programatically (when multiple
	// values must be set simultaneously--as when clearing multiple criteria) without triggering a cascade
	// of redundant events. This function is triggered by events on the elements of the visible form 
	// ("change" for the criteria drop-down lists, and "click" for the reset button).
	function doQuery(elementValue,updateExtent) {
		var visForm = document.forms["tabularQuery"];
		var hiddenForm = document.forms["hiddenQuery"];
		// If the value of the triggering element is 999 or "999", meaning clear all query criteria, 
		// set each value in the hidden form to indicate "no query restriction."
		if (String(elementValue) == "999") {
			hiddenForm.elements["municipality"].value = 999;
			hiddenForm.elements["route"].value = "999";
			hiddenForm.elements["LOS"].value = "999";
			hiddenForm.elements["crashes"].value = "999";
			hiddenForm.elements["bikePedCrashes"].value = "999";
			hiddenForm.elements["minX"].value = -180;
			hiddenForm.elements["maxX"].value = 0;
			hiddenForm.elements["minY"].value = 0;
			hiddenForm.elements["maxY"].value = 90;
			hiddenForm.elements["retrieveAllMarkersInExtent"].value = false;
		// Otherwise, just copy the values of the visible form elements to the hidden form elements,
		} else {
			hiddenForm.elements["municipality"].value = visForm.elements["municipality"].value;
			hiddenForm.elements["route"].value = visForm.elements["route"].value;
			hiddenForm.elements["LOS"].value = visForm.elements["LOS"].value;
			hiddenForm.elements["crashes"].value = visForm.elements["crashes"].value;
			hiddenForm.elements["bikePedCrashes"].value = visForm.elements["bikePedCrashes"].value;
		}
		if (updateExtent) hiddenForm.elements["updateExtent"].value = 1
		else hiddenForm.elements["updateExtent"].value = 0;
		// and submit the hidden form. The response is targeted to the inline response frame.
		/* alert("muni " + hiddenForm.elements["municipality"].value + 
			"\nroute " + hiddenForm.elements["route"].value +
			"\nLOS " + hiddenForm.elements["LOS"].value +
			"\ncrashes " + hiddenForm.elements["crashes"].value +
			"\nbikePedCrashes " + hiddenForm.elements["bikePedCrashes"].value +
			"\nminX " + hiddenForm.elements["minX"].value +
			"\nmaxX " + hiddenForm.elements["maxX"].value +
			"\nminY " + hiddenForm.elements["minY"].value +
			"\nmaxY " + hiddenForm.elements["maxY"].value +
			"\nretrieveAllMarkersInExtent " + hiddenForm.elements["retrieveAllMarkersInExtent"].value +
			"\nupdateExtent " + hiddenForm.elements["updateExtent"].value); */
		hiddenForm.submit();
	}
	</script>

</head>

<body onLoad="processResultData()">
<div id="tabularQueryDiv">
	<form name="tabularQuery" id="tabularQuery">
		<table id="tabularQueryTbl">
			<tr>
				<td class="tabularQueryTableCell" height="20"><b>Search by:</b></td>
				<td style="text-align:center">
					<input type="button" id="reset" value="New search" onClick="doQuery(999,true)" />
				</td>
			</tr>
		</table>
		<div class="queryListGroup" style="width:100%">
			<label for="municipality">Municipality:</label>
			<select name="municipality" id="municipality" size="1" style="width:100%" <!---onChange="doQuery(this.value,true)"--->>
				<cfif multipleCriteria 
					OR numCriteria GREATER THAN 0 AND FORM.municipality GREATER THAN 997>
					<option value=998 <cfif FORM.municipality GREATER THAN 997>selected</cfif>
					><cfoutput>#otherCriteriaPhrase#</cfoutput></option>
				<cfelse>
					<option value=999 <cfif FORM.municipality GREATER THAN 997>selected</cfif>
					>All</option>
				</cfif>
				<cfoutput query="townList">
				<option value="#CITY_NUM#"
					<cfif IsDefined("FORM.municipality")><cfif FORM.municipality IS CITY_NUM>selected</cfif></cfif>
					>#MUNICIPALITY#</option>
				</cfoutput>
			</select>
		</div>
		<div class="queryListGroup">
			<label for="LOS">Level of service:</label>
			<select name="LOS" id="LOS" size="1" style="width:100%" <!---onChange="doQuery(this.value,true)"--->>
				<cfif multipleCriteria
					OR numCriteria GREATER THAN 0 AND "+999+998+" CONTAINS FORM.LOS>
					<option value="998" <cfif "+999+998+" CONTAINS FORM.LOS>selected</cfif>
					><cfoutput>#otherCriteriaPhrase#</cfoutput></option>
				<cfelse>
					<option value="999" <cfif "+999+998+" CONTAINS FORM.LOS>selected</cfif>
					>All</option>
				</cfif>
				<cfoutput query="LOSList">
				<option value="#LOS#"
					<cfif IsDefined("FORM.LOS")><cfif FORM.LOS IS LOS>selected</cfif></cfif>
					>#LOS#</option>
				</cfoutput>
			</select>
		</div>&nbsp;
		<div class="queryListGroup">
			<label for="route">Route #<!--#-->:</label>
			<select name="route" id="route" size="1" style="width:100%" <!---onChange="doQuery(this.value,true)"--->>
				<cfif multipleCriteria
					OR numCriteria GREATER THAN 0 AND "+999+998+" CONTAINS FORM.route>
					<option value="998" <cfif "+999+998+" CONTAINS FORM.route>selected</cfif>
					><cfoutput>#otherCriteriaPhrase#</cfoutput></option>
				<cfelse>
					<option value="999" <cfif "+999+998+" CONTAINS FORM.route>selected</cfif>
					>All</option>
				</cfif>
				<cfoutput query="routeList">
				<option value="#Rte_System# #ROUTE_NUMBER#"
					<cfif IsDefined("FORM.route")><cfif FORM.route IS #Rte_System# & " " & #ROUTE_NUMBER#>selected</cfif></cfif>
					>#Rte_System# #ROUTE_NUMBER#</option>
				</cfoutput>
			</select>
		</div>
		<div class="queryListGroup">
			<label for="crashes">Total Crashes <br />(3-yr. span):</label>
			<select name="crashes" id="crashes" size="1" style="width:100%" <!---onChange="doQuery(this.value,true)"--->>
				<cfif multipleCriteria
					OR numCriteria GREATER THAN 0 AND "+999+998+" CONTAINS FORM.crashes>
					<option value="998" <cfif "+999+998+" CONTAINS FORM.crashes>selected</cfif>
					><cfoutput>#otherCriteriaPhrase#</cfoutput></option>
				<cfelse>
					<option value="999" <cfif "+999+998+" CONTAINS FORM.crashes>selected</cfif>
					>All</option>
				</cfif>
				<cfoutput query="crashList">
				<option value="#Crashes#"
					<cfif IsDefined("FORM.crashes")><cfif FORM.crashes IS crashes>selected</cfif></cfif>
					>#Crashes#</option>
				</cfoutput>
			</select>
		</div>&nbsp;
		<div class="queryListGroup">
			<label for="bikePedCrashes">Bike/Ped. Crashes (3-yr. span):</label>
			<select name="bikePedCrashes" id="bikePedCrashes" size="1" style="width:100%" <!---onChange="doQuery(this.value,true)"--->>
				<cfif multipleCriteria
					OR numCriteria GREATER THAN 0 AND "+999+998+" CONTAINS FORM.bikePedCrashes>
					<option value="998" <cfif "+999+998+" CONTAINS FORM.bikePedCrashes>selected</cfif>
					><cfoutput>#otherCriteriaPhrase#</cfoutput></option>
				<cfelse>
					<option value="999" <cfif "+999+998+" CONTAINS FORM.bikePedCrashes>selected</cfif>
					>All</option>
				</cfif>
				<cfoutput query="bikePedCrashList">
				<option value="#Bike_Ped_Crashes#"
					<cfif IsDefined("FORM.bikePedCrashes")><cfif FORM.bikePedCrashes IS Bike_Ped_Crashes>selected</cfif></cfif>
					>#Bike_Ped_Crashes#</option>
				</cfoutput>
			</select>
		</div>

        <div id="queryButtonDiv" align="center">
            <input type="button" id="searchButton" value="Search for intersections" onClick="doQuery('ignore',true)"/>
        </div>						
        
	</form>

	<form action="mms_intersection_response.cfm" method="post" name="hiddenQuery" id="hiddenQuery" target="response">
		<input type="Hidden" name="municipality">
		<input type="Hidden" name="route">
		<input type="Hidden" name="LOS">
		<input type="Hidden" name="crashes">
		<input type="Hidden" name="bikePedCrashes">
		<cfoutput>
			<input type="Hidden" name="minX" value="#FORM.minX#">
			<input type="Hidden" name="maxX" value="#FORM.maxX#">
			<input type="Hidden" name="minY" value="#FORM.minY#">
			<input type="Hidden" name="maxY" value="#FORM.maxY#">
			<input type="Hidden" name="retrieveAllMarkersInExtent" value="#FORM.retrieveAllMarkersInExtent#">
			<input type="Hidden" name="updateExtent" value="#FORM.updateExtent#">
		</cfoutput>
	</form>
	
	<!--- Hidden form used by openIntDetail function to open an intersection detail page for a specific intersection --->
	<form action="mms_intersection_detail.cfm" method="get" name="detailRequestForm" id="detailRequestForm" 
		target="_blank">
		<input type="hidden" name="intersection_id" id="intersection_id" value="">
	</form>
	<br><br><br><br><br>
</div>

<!--- Hidden table of result set to be copied to visible area of parent page --->
<div id="results" style="display:none;">
		<cfoutput><cfif numCriteria IS NOT 0>
			<b>Intersections matching criteria: #meetNonSpatialCriteria.RecordCount#</b><br>
			<table class="resultTable" cellspacing="0" cellpadding="0" border="0">
				<tr>
					<th class="resultTableLocCell">Intersection Description</th>
					<th class="resultTableTownCell">Town</th>
				</tr>
		</cfif></cfoutput>
		<cfoutput query="meetNonSpatialCriteria"><cfif numCriteria IS NOT 0>
			<tr>
			    <td class="resultTableLocCell">
				<a id="list#Int_Desc#" href="javascript:window.response.openIntDetail(#INTERSECTION_ID#);" 
					 onmouseover="markerHilite('#Replace(Int_Desc,"'","\'")#')" 
					 onmouseout="markerUnHilite('#Replace(Int_Desc,"'","\'")#')">#Int_Desc#</a></td>
			    <td class="resultTableTownCell"><b>#MUNICIPALITY#</b></td>
			</tr>
		</cfif></cfoutput>
		<cfoutput><cfif numCriteria IS NOT 0>
			</table>
		</cfif></cfoutput>
</div>
</body>
</html>
