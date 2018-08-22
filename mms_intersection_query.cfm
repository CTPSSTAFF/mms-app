<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<head>

    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <META http-equiv="Expires" content="Tue, 20 Aug 1996 14:25:27 GMT">
	<title>Mobility Monitoring System Intersection Database Query</title>

	<link rel="stylesheet" type="text/css" href="mms_intersection.css">

	<script type="text/javascript" src="//maps.googleapis.com/maps/api/js?sensor=false"></script>

    <script type="text/javascript">
	var map;	// static reference to Map canvas
	var infoWindow;		// static reference to Google reusable info window for all the markers
	var legendTxtHilite, legendTxtRegular;	// static references to legend text HTML nodes in document
	var cLegendTxtHilite = "Intersections matching search criteria";
	var cLegendTxtRegular = "Other monitored intersections";
	
	// all the arrays below have a primary index based on intersections' INTERSECTION_ID value
	var arrDispResultSet = []; // 2-D array to hold intersection information for records in result set and display bounds
	var arrDispNotResultSet = []; // 2-D array to hold intersection info for records not in result set but in display bounds
	var cIDIdx = 0, cMunIdx = 1, cMainStrIdx = 2, cMainRteIdx = 3, cStr1Idx = 4; // index constants for easy access to
	var cRte1Idx = 5, cStr2Idx = 6, cRte2Idx = 7, cLatIdx = 8, cLngIdx = 9, cIntDescIdx = 10;	// 2nd dimension of arr data
	var arrMarkersResultSet = [];// array to hold Google Map markers for intersections in result set and display bounds
	var arrMarkersNotResultSet = [];// array to hold markers for intersections not in result set but in display bounds
	var arrMapped = [];	// array of Booleans indicating which Google Map overlay markers have been added to map
	var arrToMap = [];	// array of Booleans indicating which Google Map overlay markers should be added to map next
	var arrResultSet = [];	// array of Booleans indicating intersections that are part of current result set
	var numCriteriaSpecified = 0;	// details how many criteria drop-down lists have a specific option selected
	
	var minX, maxX, minY, maxY, numResults;	// variables characterizing the current result set
	var framesLoaded = 0;	// helps to indicate when both the parent frame and inline ColdFusion frame have been loaded
	var cDisplayLimit = 80;	// to help maintain performance, no more than this number of overlay markers are added to Google Map
	var cZoomThreshold = 10;	// intersections outside the result set are only shown at this zoom level or higher
	var cMapAreaMarginFactor = 1.3;	// linear scale factor for area slightly larger than Google Map area (pre-add markers just outside currently visible area)
	var cSrcMarkerHilite = "images/marker_link_blue.png", cSrcMarkerHilitePr = "images/marker_link_blue.gif";
	var cSrcMarkerRegular = "images/marker_dark_blue.png", cSrcMarkerRegularPr = "images/marker_dark_blue.gif";
	var cSrcMarkerHover = "images/marker_link_hover.png";
	//var iconRegular = new GIcon(G_DEFAULT_ICON,cSrcMarkerRegular);
	//iconRegular.printImage = cSrcMarkerRegularPr;
	//iconRegular.mozPrintImage = cSrcMarkerRegular;
	//var iconHilite = new GIcon(G_DEFAULT_ICON,cSrcMarkerHilite);
	//iconHilite.printImage = cSrcMarkerHilitePr;
	//iconHilite.mozPrintImage = cSrcMarkerHilite;
	var boolNewResultSetToMap = true;
	var boolNewExtent = true;
	
	/****************
	  MOVEENDHANDLER
	*****************/
	// this event handler executes every time the area shown in the Google Map changes
	function moveendHandler() {
		// determine the maximum and minimum latitude and longitude of the Google Map area
		var mapBounds = map.getBounds();
		var mapSW = mapBounds.getSouthWest(), mapNE = mapBounds.getNorthEast();
		var mapLatMin = mapSW.lat(), mapLatMax = mapNE.lat(), mapLngMin = mapSW.lng(), mapLngMax = mapNE.lng();
		// and find out the zoom level
		var zoomLevel = map.getZoom();

		// determine the maximum and minimum latitude and longitude of an area slightly larger than the Google Map area
		var centerLat = (mapLatMax + mapLatMin) / 2, centerLng = (mapLngMax + mapLngMin) / 2;
		var newHalfSpanLat = (mapLatMax - mapLatMin) * cMapAreaMarginFactor / 2;
		var newHalfSpanLng = (mapLngMax - mapLngMin) * cMapAreaMarginFactor / 2;
		var mapLatMarginMin = centerLat - newHalfSpanLat, mapLatMarginMax = centerLat + newHalfSpanLat;
		var mapLngMarginMin = centerLng - newHalfSpanLng, mapLngMarginMax = centerLng + newHalfSpanLng;

		// do a new query for intersections in the map window
		if (framesLoaded >= 2) {
			var hiddenForm = window.response.document.forms["hiddenQuery"];
			if (zoomLevel >= cZoomThreshold) hiddenForm.elements["retrieveAllMarkersInExtent"].value = 1
			else hiddenForm.elements["retrieveAllMarkersInExtent"].value = 0;
			hiddenForm.elements["minX"].value = mapLngMarginMin;
			hiddenForm.elements["maxX"].value = mapLngMarginMax;
			hiddenForm.elements["minY"].value = mapLatMarginMin;
			hiddenForm.elements["maxY"].value = mapLatMarginMax;
			window.response.doQuery(0,false);
		}
	}
	
	/*************************
	  MANAGEMARKERSFOREXTENT
	*************************/
	// This routine manages arrays that keep track of the markers currently added to the map display,
	// updating them to reflect the result sets from the query response, and doing the corresponding 
	// adding and removing of markers
	function manageMarkersForExtent() {

		var i = 0;	// index to arrays of result set intersection info
		var intMarkerIdx	// index to most recently added element of marker array
		var intMarkersDisplayed = 0;	// running count of markers added to display
		var marker;
		
		// first, move the marker display arrays into temporary array variables so the
		// original arrays can be rebuilt
		var arrMarkersResultSetTemp = [];
		var arrMarkersNotResultSetTemp = [];
		while (arrMarkersResultSet.length > 0) {
			arrMarkersResultSetTemp.push(arrMarkersResultSet.pop());
		}
		while (arrMarkersNotResultSet.length > 0) {
			arrMarkersNotResultSetTemp.push(arrMarkersNotResultSet.pop());
		}
		
		// Both the result set arrays and the displayed marker arrays are sorted by intersection description, 
		// so we can walk through them in parallel, removing markers that are not in the result set
		// array, and addding markers that are not in the displayed marker arrays. Start with markers
		// that meet search criteria, being careful not to exceed the limit on total markers displayed.
		marker = arrMarkersResultSetTemp.pop();
		while (i < arrDispResultSet.length && i < cDisplayLimit) {
			// if displayed markers have lower ID than current result set element, remove them from display
			if (marker) {
				if (marker.getTitle() < arrDispResultSet[i][cIntDescIdx]) {
					google.maps.event.clearListeners(marker,"mouseover");	// clean up event listeners
					google.maps.event.clearListeners(marker,"mouseout");
					google.maps.event.clearListeners(marker,"click");
					marker.setMap(null);					// remove the overlay
					marker = arrMarkersResultSetTemp.pop();
				// if displayed marker has same ID as current result set element, push marker variable
				// back into the displayed marker array [from temp array]
				} else if (marker.getTitle() == arrDispResultSet[i][cIntDescIdx]) {
					arrMarkersResultSet.push(marker);
					marker = arrMarkersResultSetTemp.pop();
					i = i + 1;
				// otherwise current result set element describes marker not yet displayed or part of 
				// displayed marker array, so create the marker from the info, add it to the display, and
				// push its variable into the array
				} else {
					arrMarkersResultSet.push(MMSMarker(i, true));
					intMarkerIdx = arrMarkersResultSet.length - 1;
					arrMarkersResultSet[intMarkerIdx].setMap(map);		// add the overlay
					addMarkerMouseoutListener(arrMarkersResultSet[intMarkerIdx], (numCriteriaSpecified > 0));	// add mouseout event listener for overlay
					addMarkerMouseoverListener(arrMarkersResultSet[intMarkerIdx], (numCriteriaSpecified > 0));	// add mouseover event listener for overlay
					addMarkerClickListener(arrMarkersResultSet[intMarkerIdx]);	// add click event listener for overlay
					i = i + 1;
				}
			} else {
				arrMarkersResultSet.push(MMSMarker(i, true));
				intMarkerIdx = arrMarkersResultSet.length - 1;
				arrMarkersResultSet[intMarkerIdx].setMap(map);				// add the overlay
				addMarkerMouseoutListener(arrMarkersResultSet[intMarkerIdx], (numCriteriaSpecified > 0));	// add mouseout event listener for overlay
				addMarkerMouseoverListener(arrMarkersResultSet[intMarkerIdx], (numCriteriaSpecified > 0));	// add mouseover event listener for overlay
				addMarkerClickListener(arrMarkersResultSet[intMarkerIdx]);	// add click event listener for overlay
				i = i + 1;
			}
		}
		while (marker) {
			google.maps.event.clearListeners(marker,"mouseover");	// clean up event listeners
			google.maps.event.clearListeners(marker,"mouseout");
			google.maps.event.clearListeners(marker,"click");
			marker.setMap(null);					// remove the overlay
			marker = arrMarkersResultSetTemp.pop();
		}
		intMarkersDisplayed = i;
		i = 0;
		// repeat the loop above for intersections falling within the display extent that are not in the
		// result set, assuming the number of markers added to the map has not yet exceeded the display limit
		marker = arrMarkersNotResultSetTemp.pop();
		while (i < arrDispNotResultSet.length && (i+intMarkersDisplayed) < cDisplayLimit) {
			// if displayed markers have lower ID than current result set element, remove them from display
			if (marker) {
				if (marker.getTitle() < arrDispNotResultSet[i][cIntDescIdx]) {
					google.maps.event.clearListeners(marker,"mouseover");	// clean up event listeners
					google.maps.event.clearListeners(marker,"mouseout");
					google.maps.event.clearListeners(marker,"click");
					marker.setMap(null);					// remove the overlay
					marker = arrMarkersNotResultSetTemp.pop();
				// if displayed marker has same ID as current result set element, push marker variable
				// back into the displayed marker array [from temp array]
				} else if (marker.getTitle() == arrDispNotResultSet[i][cIntDescIdx]) {
					arrMarkersNotResultSet.push(marker);
					//alert("transferred non-result-set marker");
					marker = arrMarkersNotResultSetTemp.pop();
					i = i + 1;
				// otherwise current result set element describes marker not yet displayed or part of 
				// displayed marker array, so create the marker from the info, add it to the display, and
				// push its variable into the array
				} else {
					arrMarkersNotResultSet.push(MMSMarker(i, false));
					intMarkerIdx = arrMarkersNotResultSet.length - 1;
					arrMarkersNotResultSet[intMarkerIdx].setMap(map);		// add the overlay
					addMarkerMouseoutListener(arrMarkersNotResultSet[intMarkerIdx], false);	// add mouseout event listener for overlay
					addMarkerMouseoverListener(arrMarkersNotResultSet[intMarkerIdx], false);	// add mouseover event listener for overlay
					addMarkerClickListener(arrMarkersNotResultSet[intMarkerIdx]);	// add click event listener for overlay
					i = i + 1;
				}
			} else {
				arrMarkersNotResultSet.push(MMSMarker(i, false));
				intMarkerIdx = arrMarkersNotResultSet.length - 1;
				arrMarkersNotResultSet[intMarkerIdx].setMap(map);		// add the overlay
				addMarkerMouseoutListener(arrMarkersNotResultSet[intMarkerIdx], false);	// add mouseout event listener for overlay
				addMarkerMouseoverListener(arrMarkersNotResultSet[intMarkerIdx], false);	// add mouseover event listener for overlay
				addMarkerClickListener(arrMarkersNotResultSet[intMarkerIdx]);	// add click event listener for overlay
				i = i + 1;
			}
		}
		while (marker) {
			google.maps.event.clearListeners(marker,"mouseover");	// clean up event listeners
			google.maps.event.clearListeners(marker,"mouseout");
			google.maps.event.clearListeners(marker,"click");
			marker.setMap(null);					// remove the overlay
			//alert("tried to remove non-result-set marker");
			marker = arrMarkersNotResultSetTemp.pop();
		}
		var zoomLevel = map.getZoom();
		// if overlay limit was reached, adjust visual warning in legend for result set intersections
		if (intMarkersDisplayed >= cDisplayLimit) 
			legendTxtHilite.innerHTML = cLegendTxtHilite + 
				". <b>Some within the current map bounds are not shown. Zoom in to see them.</b>"
		else legendTxtHilite.innerHTML = cLegendTxtHilite;
		// adjust visual warning in legend for non-result-set intersections
		if (zoomLevel < cZoomThreshold) {
			legendTxtRegular.innerHTML = cLegendTxtRegular +
				" <b>shown only at higher zoom levels</b>"
		} else if ((intMarkersDisplayed+i) >= cDisplayLimit) {
			legendTxtRegular.innerHTML = cLegendTxtRegular +
				". <b>Some in the current map are not shown. Zoom in further to see them.</b>"
		} else legendTxtRegular.innerHTML = cLegendTxtRegular;
	}
	
	/*****************************
	  ADDMARKERMOUSEOVERLISTENER
	*****************************/
	// This event handler executes every time the mouse moves over a marker overlay in the Google Map.
	// It uses so-called "closures," which can cause memory leak problems if not cleaned up properly.
	function addMarkerMouseoverListener(objMarker, isInResultSet) {
		if (isInResultSet) {
			google.maps.event.addListener(objMarker, "mouseover", function() {
				objMarker.setIcon(cSrcMarkerHover);	// change color of marker to highlight color
				var DOMElement = document.getElementById("list" + objMarker.getTitle());
				if (DOMElement)				// add highlight color to text in corresponding item of result set list
					DOMElement.innerHTML = '<span style="color:rgb(11,98,166)">' + DOMElement.innerHTML + "</span>";
			});
		} else {
			google.maps.event.addListener(objMarker, "mouseover", function() {
				objMarker.setIcon(cSrcMarkerHover);	// change color of marker to highlight color
			});
		}
	}
	
	/****************************
	  ADDMARKERMOUSEOUTLISTENER
	****************************/
	// This event handler executes every time the mouse moves off a marker overlay in the Google Map.
	// It uses so-called "closures," which can cause memory leak problems if not cleaned up properly.
	function addMarkerMouseoutListener(objMarker, isInResultSet) {
		if (isInResultSet) {
			google.maps.event.addListener(objMarker, "mouseout", function() {
				objMarker.setIcon(cSrcMarkerHilite);	// 1) highlight color (marker belongs to result set)
				var DOMElement = document.getElementById("list" + objMarker.getTitle());
				if (DOMElement)	// remove highlight color from text in corresponding item of result set list
					DOMElement.innerHTML = DOMElement.innerHTML.substring(DOMElement.innerHTML.indexOf(">")+1,
						DOMElement.innerHTML.lastIndexOf("<"));
			});
		} else {
			google.maps.event.addListener(objMarker, "mouseout", function() {
				objMarker.setIcon(cSrcMarkerRegular);	// 2) regular color (marker does NOT belong to result set)
			});
		}
	}
		
	/*************************
	  ADDMARKERCLICKLISTENER
	*************************/
	// This event handler executes when a marker overlay in the Google Map is clicked.
	// It uses so-called "closures," which can cause memory leak problems if not cleaned up properly.
	function addMarkerClickListener(objMarker) {
		google.maps.event.addListener(objMarker, 'click', function() {
			infoWindow.setContent(objMarker.infoWindowHtml);
			infoWindow.open(map, objMarker);
		});
	}
	
	/***************
	  MARKERHILITE
	***************/
	// Invoked by moving the mouse over an item in the result set list. Highlights the corresponding overlay
	// marker in the Google Map, if it has been added to the map
	function markerHilite(strTitle) {
		var i = 0;
		while (i < arrMarkersResultSet.length && arrMarkersResultSet[i].getTitle() != strTitle) i = i + 1;
		if (i < arrMarkersResultSet.length) arrMarkersResultSet[i].setIcon(cSrcMarkerHover);
	}
	
	/*****************
	  MARKERUNHILITE
	*****************/
	// Invoked by moving the mouse off an item in the result set list. Unhighlights the corresponding overlay
	// marker in the Google Map, if it has been added to the map
	function markerUnHilite(strTitle) {
		var i = 0;
		while (i < arrMarkersResultSet.length && arrMarkersResultSet[i].getTitle() != strTitle) i = i + 1;
		if (i < arrMarkersResultSet.length) arrMarkersResultSet[i].setIcon(cSrcMarkerHilite);
	}
	
	/*******
	  LOAD
	*******/
	// Executes once, when this page has loaded. Initializes the Google Map and sets a few variables
	// pointing to HTML nodes in the legend for later use. If the inline frame of response data from ColdFusion
	// has already loaded by the time this page finishes (seems unlikely!), then the load handler for the
	// inline frame is re-triggered.
    function load() {
	  //alert("Request page loaded");
		var myOptions = {
			center: new google.maps.LatLng(42.1, -71.7),
			zoom: 8,
			mapTypeId: google.maps.MapTypeId.ROADMAP,
			mapTypeControlOptions: {'style': google.maps.MapTypeControlStyle.DROPDOWN_MENU},
			panControl: false,
			streetViewControl: false,
			zoomControlOptions: {'style': 'SMALL'},
			scaleControl: true,
			overviewMapControl: true,
			overviewMapControlOptions: {'opened': true}
		};

	  map = new google.maps.Map(document.getElementById("map"), myOptions);
	  infoWindow = new google.maps.InfoWindow({'maxWidth': 210}); // create the re-usable info window for all the markers

	  legendTxtHilite = document.getElementById("legendTxtHiliteMarker");
	  legendTxtRegular = document.getElementById("legendTxtRegularMarker");

	  google.maps.event.addListener(map, "idle", moveendHandler);

	  framesLoaded++;
	  if (framesLoaded == 2) {	// if results page loaded and arrMarkers not yet initialized
	  	window.response.processResultData();
	  }
    }
	
	/************
	  MMSMARKER
	************/
	// Creates and returns a Google Maps overlay marker for the specified intersection, using either the highlight
	// color (for intersections in the result set) or the regular color
	function MMSMarker(intArrIdx,isInResultSet) {
		var strHTML = "";
		var arrRow;
		if (isInResultSet) arrRow = arrDispResultSet[intArrIdx]
		else arrRow = arrDispNotResultSet[intArrIdx];
		// First, set up the HTML string to be shown in the "InfoWindow" bubble of the Google Map
		// when the overlay marker is clicked. It is a table of location description for the intersection
		// that can be clicked to open a page of detailed information for the intersection.
		// Surround table with link so contents highlight as one item when mouse rolls over
		strHTML = '<a href="javascript:window.response.openIntDetail(' + arrRow[cIDIdx] + ');">' +
			// however, Internet Explorer does not correctly activate the table as a link, so add event handler
			// to the table that accomplishes the same thing (opening the intersection detail window on click)
			'<table class="iWinGTbl" onclick="window.response.openIntDetail(' + arrRow[cIDIdx] + ');">' +
			// if either main street or main route is not blank, add table row and cell
			((arrRow[cMainStrIdx] != "" || arrRow[cMainRteIdx] != "") ? '<tr><td colspan="2">' : "") +
			// insert main street value (may be blank)
			arrRow[cMainStrIdx] +
			// if main route is not blank, then add it, on new row and enclose in parentheses if main street was not blank
			(arrRow[cMainRteIdx] != "" ? ( (arrRow[cMainStrIdx] != "" ? 
				' (' : "") + arrRow[cMainRteIdx] + 
				(arrRow[cMainStrIdx] != "" ? ')' : "") ) : "") + 
			// if either main street or main route was not blank, close table row
			((arrRow[cMainStrIdx] != "" || arrRow[cMainRteIdx] != "") ? '</td></tr>' : "") +
			// if either cross street 1 or cross route 1 is not blank, add table row and cell and "at"
			((arrRow[cStr1Idx] != "" || arrRow[cRte1Idx] != "") ? 
				'<tr><td class="iWinGCol1">at</td><td class="iWinGCol2">' : "") +
			// insert cross street 1 value (may be blank)
			(arrRow[cStr1Idx] != "" ? arrRow[cStr1Idx] : "") +
			// if cross route 1 is not blank, then add it, on new row and enclose in parentheses if cross street 1 was not blank
			(arrRow[cRte1Idx] != "" ? ( (arrRow[cStr1Idx] != "" ? 
				' (' : "") + 
				arrRow[cRte1Idx] + (arrRow[cStr1Idx] != "" ? ')' : "") ) : "") + 
			// if either cross street 1 or cross route 1 was not blank, close table row
			((arrRow[cStr1Idx] != "" || arrRow[cRte1Idx] != "") ? '</td></tr>' : "") +
			// if either cross street 2 or cross route 2 is not blank, add table row and cell and "and"
			((arrRow[cStr2Idx] != "" || arrRow[cRte2Idx] != "") ? 
				'<tr><td class="iWinGCol1">and</td><td>' : "") +
			// insert cross street 2 value (may be blank)
			(arrRow[cStr2Idx] != "" ? arrRow[cStr2Idx] : "") +
			// if cross route 2 is not blank, then add it, on new row and enclose in parentheses if cross street 2 was not blank
			(arrRow[cRte2Idx] != "" ? ( (arrRow[cStr2Idx] != "" ? 
				' (' : "") + 
				arrRow[cRte2Idx] + (arrRow[cStr2Idx] != "" ? ')' : "") ) : "") + 
			// if either cross street 1 or cross route 1 was not blank, close table row
			((arrRow[cStr2Idx] != "" || arrRow[cRte2Idx] != "") ? '</td></tr>' : "") +
			// if town is not blank, add it, on a new table row
			(arrRow[cMunIdx] != "" ? ('<tr><td class="iWinGCol1">in</td><td class="iWinGCol2">' + 
				arrRow[cMunIdx] + '</td></tr>') : "") +
			'</table></a>';

		var strMarkerTitle = "";
		// Next, set up the string to be shown in a tool tip when user hovers over the marker
		// Always start with main street value (may be blank)
		strMarkerTitle = arrRow[cIntDescIdx];

		var markerNew, markerOpts;
		markerOpts = {
			'map': map,
			'title': String(strMarkerTitle),
			'visible': true,
			'position': new google.maps.LatLng(arrRow[cLatIdx], arrRow[cLngIdx]),
			'shadow': new google.maps.MarkerImage('images/shadow50.png',
												  new google.maps.Size(37,34),
												  new google.maps.Point(0,0),
												  new google.maps.Point(9,33))
		};
		if (isInResultSet) markerOpts.icon = cSrcMarkerHilite;
		else markerOpts.icon = cSrcMarkerRegular;
		markerNew = new google.maps.Marker(markerOpts); // create the new marker and add it to the map
		markerNew.infoWindowHtml = strHTML; // and associate the HTML string with it (not part of Google API)
		return markerNew;
	}
	
	/***********************
	  ADJUSTMAPTORESULTSET
	***********************/
	// This function should be triggered by the load handler of the inline frame of response data from ColdFusion.
	// It adjusts the area shown in the Google Map to comfortably contain the intersections in the response data.
	// In adjusting the area, it will in turn cause the moveend event handler of the Google Map to execute.
	function adjustMapToResultSet()  {
		// create a bounds object using the minimum and maximum latitude and longitude indicated in the response data
		var bounds = new google.maps.LatLngBounds(new google.maps.LatLng(minY, minX), 
												  new google.maps.LatLng(maxY, maxX));
		// If no new extent came back from result set, 
		// then don't bother calling fitBounds, but instead manually trigger manageMarkersForExtent, which would
		// normally be triggered by a change in the map bounds. Even if the bounds haven't changed--as would be the
		// case when going to or from a zero-result set--the markers may need to be recolored.
		if (!boolNewExtent) {
			manageMarkersForExtent();
		} else {
			// first, temporarily set the minimum zoom level of the map so that a bounds based on a single point doesn't
			// zoom in too far
			map.setOptions({'maxZoom': 17});
			// set the viewport to contain the bounds
			map.fitBounds(bounds);
			// set the minimum zoom level back to the default for the map type
			map.setOptions({'maxZoom': null});
		}
	}

	</script>
	
</head>

<body onLoad="load()">

	<div id="visContent">
		<h1>Monitored Intersections in the Boston Region M<span style="display:none">.</span>P<span style="display:none">.</span>O<span style="display:none">.</span> Area</h1>
		<div id="geoQuery">
			<div id="mapMessage">
				<div id="instructionDiv">
					Search for an intersection or a set of intersections by 
					selecting items from the pull-down menus below or
					by zooming in on the map. 
					Your results will appear below as you narrow your search.
				</div>

				<table id="mapMessageTable">
					<tr>
						<td style="width:35px;"><script type="text/javascript">
							if (navigator.platform.indexOf("Win32") >= 0 && navigator.appVersion.indexOf("MSIE 6") >= 0) {
								document.write('<IMG alt="Legend symbol of highlighted map marker" src="' +
									cSrcMarkerHilitePr + ' ">');
							} else {
								document.write('<IMG alt="Legend symbol of highlighted map marker" src="' +
									cSrcMarkerHilite + ' ">');
							}
							</script>
						</td>
						<td id="legendTxtHiliteMarker" style="text-align:left;"><script type="text/javascript">
							document.write(cLegendTxtHilite);
							</script>
						</td>
					</tr>
					<tr>
						<td style="width:35px;"><script type="text/javascript">
							if (navigator.platform.indexOf("Win32") >= 0 && navigator.appVersion.indexOf("MSIE 6") >= 0) {
								document.write('<IMG alt="Legend symbol of regular map marker" src="' +
									cSrcMarkerRegularPr + ' ">');
							} else {
								document.write('<IMG alt="Legend symbol of regular map marker" src="' +
									cSrcMarkerRegular + ' ">');
							}
							</script>
						</td>
						<td id="legendTxtRegularMarker" 
							style="text-align:left;"><script type="text/javascript">
							document.write(cLegendTxtRegular);
							</script>
						</td>
					</tr>
				</table>

				<script type="text/javascript">
					var strHTML1 = '<iframe id="response" scrolling="no" name="response" style="height:';
					var strHTML2 = 'em;" src="mms_intersection_response.cfm" frameborder="0" marginwidth="0" marginheight="0"></iframe>';
					if (navigator.userAgent.indexOf("Mac") >= 0) document.writeln(strHTML1 + '16' + strHTML2)
					else if (navigator.userAgent.indexOf("Chrome") >= 0) document.writeln(strHTML1 + '16' + strHTML2)
					else document.writeln(strHTML1 + '16' + strHTML2);
				</script>
	
			</div>
			<div id="map"></div>

		</div>

		<div id="results"></div>
	</div>
	
	<script type="text/javascript">
 
	var _gaq = _gaq || [];
	_gaq.push(['_setAccount', 'UA-39489988-1']);
	_gaq.push(['_setDomainName', 'ctps.org']);
	_gaq.push(['_setAllowLinker', true]);
	_gaq.push(['_trackPageview']);
 
	(function() {
		var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
		ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
		var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
	})();
 
	</script>	
	
</body>

</html>
