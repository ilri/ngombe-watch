<html>
	<head>
		<script type="text/javascript" src="../dygraphs/dygraph-combined.js"></script>
		<script type="text/javascript" src="../jquery/jquery.min.js"></script>
		<script
			src="http://maps.googleapis.com/maps/api/js?key=AIzaSyDY0kkJiTPVd2U7aTOAwhc9ySH6oHxOIYM&sensor=false">
		</script>

		<script type="text/javascript">
			var daysTimer;
			function updateCharts() {
				daysTimer = $("#daysV").val();
				outer(daysTimer);
				$("#daysV").html(daysTimer);
			}
		</script>

		<script type="text/javascript">
			function handleKeyPress(e) {
				var key = e.keyCode || e.which;
				if (key === 13) {
					updateCharts();
				}
			}
		</script>

	</head>
	<body>      
		<div id="daysL">
			<label>days</label>
			<input id="daysV" type="number" onkeypress="handleKeyPress(event);"/>
		</div>

		<div id="googleMap" style="width:900px;height:680px;"></div>
		<div id="axG" style="width:900px; height:300px;"></div>
		<div id="ayG" style="width:900px; height:300px;"></div>
		<div id="azG" style="width:900px; height:300px;"></div>
		<div id="tempG" style="width:900px; height:300px;"></div>
		<div id="batteryG" style="width:900px; height:300px;"></div>

		<script type="text/javascript">
			$("#daysV").val(1);
			outer(1);


			function outer(noOfDays) {
				var myPath = new Array();

				function f1(noOfDays) {
					var n;
					$.ajax({
						'type': 'POST',
						url: 'driver.php',
						data: {
							'submit': 'GET_DATA',
							'noOfDays': noOfDays
						},
						success: function(data) {
							n = data;
						},
						async: false

					});
					return n;
				}

				var obj = jQuery.parseJSON(f1(noOfDays));//load the values from  db

				valuesT = ""; //this is what is used for drawing the charts
				/* functions for deciding which gps points to plot */
				function getcoordinate(raw) {
					raw = raw * 0.01;
					var exploded = raw.split('.');
					exploded[1] = parseInt(exploded[1] / 60);//need to round off;
					return exploded[0] + '.' + exploded[1];
				}
				function degree2rad(deg) {
					return deg * (3.142 / 180);
				}
				function getDistance(long1, lat1, long2, lat2) {

					var radius = 6371;//of earth
					var logDiff = degree2rad(long1 - long2);
					latDiff = degree2rad(lat1 - lat2);
					var a = Math.sin(latDiff / 2) * Math.sin(latDiff / 2) + Math.cos(degree2rad(lat1)) * Math.cos(degree2rad(lat2)) * Math.sin(logDiff / 2) * Math.sin(logDiff / 2);
					c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
					d = radius * c;
					return d;
				}

				/*end functions for deciding which gps points to plot */
				function getValues(param) {

					var initLong = -1;
					var initLat;
					valuesT = "";
					for (var i = 0; i < obj.length; i++) {
						if (param !== "GPS") {
							valuesT += obj[i]["dt"];
							valuesT += ",";

							valuesT += obj[i][param];
						}

						else if (param === "GPS") {
							var dirLat = obj[i]["lt"][obj[i]["lt"].length-1];
							var dirLon = obj[i]["ln"][obj[i]["ln"].length-1];
							
							//remove the letters for calculation
							obj[i]["ln"] =obj[i]["ln"].slice(0,obj[i]["ln"].length-1);
							obj[i]["lt"] =obj[i]["lt"].slice(0,obj[i]["lt"].length-1);
					
							//filter the result				
							if (initLong === -1) {
								initLong = obj[i]["ln"];
								initLat = obj[i]["lt"];
								//recover the lost letters
								initLat = initLat + dirLat;
								intLong = initLog + dirLong;
								
								valuesT += initLat + "," + initLong;
							}
							else {
								var ln = obj[i]["ln"];
								var lt = obj[i]["lt"];
								var dist = getDistance(initLong, initLat, ln, lt);
								if (dist >= 5) {
									initLong = ln;
									initLat = lt;
									i++;
									valuesT += initLat + "," + initLong;
								}
							}
							valuesT += "\n";
							
							alert(valuesT);
							
							exit(0);
						}
					}
					
				}

				getValues("ax");
				axF = new Dygraph
					(
						// containing div
						document.getElementById("axG"),
						valuesT,
						{labels: ["Date", "ax"], title: "AX vs Time"}
					);

				getValues("ay");
				ayF = new Dygraph
					(
						// containing div
						document.getElementById("ayG"),
						valuesT,
						{labels: ["Time", "ay"], title: "AY vs Time"}
					);

				getValues("az");
				azF = new Dygraph
					(
						// containing div
						document.getElementById("azG"),
						valuesT,
						{labels: ["Time", "az"], title: "AZ vs Time"}
					);

				getValues("temp");
				tempF = new Dygraph
					(
						// containing div
						document.getElementById("tempG"),
						valuesT,
						{labels: ["Time", "temperature"], title: "Temperature vs Time"}
					);

				getValues("battery");
				batteryF = new Dygraph
					(
						// containing div
						document.getElementById("batteryG"),
						valuesT,
						{labels: ["Time", "battery"], title: "Battery vs Time"}
					);


				function getRealGPS(coords) {
					gpsV = [];
					//	if(coords === "") return;
					gpsV = coords.split(",");

					//now change the N/S/W/E to - or + 
					var latSign;
					var lonSign;

					//sign for the latitude
					if (/.+S$/.test(gpsV[0])) {
						latSign = 'n';
					}
					else if (/.+N$/.test(gpsV[0])) {
						latSign = 'p';
					}

					//sign for the longitude
					if (/.+W/.test(gpsV[1])) {
						lonSign = 'n';
					}
					else if (/.+E/.test(gpsV[1])) {
						lonSign = 'p';
					}

					//remove the letter at the end
					gpsV[0] = gpsV[0].slice(0, gpsV[0].length - 1);
					gpsV[1] = gpsV[1].slice(0, gpsV[1].length - 1);

					//alert(gpsV[1]);
					//convert each to decimal numbers	
					gpsV[0] = (parseFloat(gpsV[0]) * 0.01).toString();
					gpsV[1] = (parseFloat(gpsV[1]) * 0.01).toString();

					//get the mantissa of both	
					var lat = parseInt(gpsV[0].substring(gpsV[0].indexOf('.') + 1));
					var lon = parseInt(gpsV[1].substring(gpsV[1].indexOf('.') + 1));

					//divide by 60
					lat = parseInt(lat / 60);
					lon = parseInt(lon / 60);

					//now get the first parts
					latF = parseInt(gpsV[0].substring(0, gpsV[0].indexOf('.')));
					lonF = parseInt(gpsV[1].substring(0, gpsV[1].indexOf('.')));

					//now recover the zeros lost during division by sixty
					var mantLat = gpsV[0].substring(gpsV[0].indexOf('.') + 1);
					var mantLon = gpsV[1].substring(gpsV[1].indexOf('.') + 1);

					if (mantLon[0] === '0') {
						alert(mantLat + "," + mantLon);
					}

					//now recover the signs
					if (lonSign === 'n') {
						lonF *= -1;
					}
					if (latSign === 'n') {
						latF *= -1;
					}

					//now construct the final coordinates
					gpsV[0] = (latF).toString() + "." + (lat).toString();
					gpsV[1] = (lonF).toString() + "." + (lon).toString();
					coords = gpsV[0] + "," + gpsV[1];
					return coords;
				}
				getValues("GPS");
				locT = valuesT.split("\n");

				//now convert the values to usable GPS values
				for (i = 0; i < locT.length; i++) {
					if (locT[i] === "") {
					}
					else {
						locT[i] = getRealGPS(locT[i]);
						//now using the valid coordinates, create objects that can be accessed
						aval = locT[i].split(",");//get the respective lt and long
						myPath[i] = new coordObjs(aval[0], aval[1]);//new obj based on the given coord
					}
				}

				function coordObjs(lt, ln) {
					this.latd = lt;
					this.longd = ln;
				}

				//now draw the map based on the coordns of the path given		
				var x = new google.maps.LatLng(parseFloat(myPath[0].latd), parseFloat(myPath[0].longd));

				var myPathway = [];
				for (var i = 0; i < myPath.length - 1; i++) {
					myPathway[myPathway.length] = new google.maps.LatLng(parseFloat(myPath[i].latd), parseFloat(myPath[i].longd));
				}

				function initialize()
				{
					var mapProp = {
						center: x,
						zoom: 12,
						mapTypeId: google.maps.MapTypeId.ROADMAP
					};

					var map = new google.maps.Map(document.getElementById("googleMap"), mapProp);

					var myTrip = myPathway;
					var flightPath = new google.maps.Polyline({
						path: myTrip,
						strokeColor: "#0000FF",
						strokeOpacity: 0.8,
						strokeWeight: 2
					});

					flightPath.setMap(map);
				}
				initialize();
			}
		</script>

	</body>
</html>
