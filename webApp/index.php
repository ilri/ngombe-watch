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
				function getValues(param) {

					valuesT = "";
					for (var i = 0; i < obj.length; i++) {
						if(param != "GPS"){
							valuesT += obj[i]["dt"];
							valuesT += ",";

							valuesT += obj[i][param];
							valuesT += "\n";
						}

						else if (param === "GPS") {

							valuesT +=obj[i]["lt"];
							valuesT += ",";

							valuesT += obj[i]["ln"];

							valuesT += "\n";
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
					var gpsV = coords.split(",");
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

					if(mantLat[0] === '0' || mantLon[0]==='0'){
						alert(mantLat + ","+ mantLon);
					}

					//now construct the final coordinates
					gpsV[0] = (latF).toString() + "." + (lat).toString();
					gpsV[1] = (lonF).toString() + "." + (lon).toString();
					coords = gpsV[0] + "," + gpsV[1];
					return coords;
				}

				var gpsLt = f1("lt", noOfDays);//other factor to be plotted vs time
				var gpsLn = f1("ln", noOfDays);//other factor to be plotted vs time
				gpsLtB = gpsLt.split(",");
				gpsLnB = gpsLn.split(",");

				getValues("GPS");

				locT = valuesT.split("\n");
				
				//now convert the values to usable GPS values
				for (i = 0; i < locT.length; i++) {
					locT[i] = getRealGPS(locT[i]);
					
					//now using the valid coordinates, create objects that can be accessed
					aval = locT[i].split(",");//get the respective lt and long
					myPath[i] = new coordObjs(aval[0],aval[1]);//new obj based on the given coord
				}
				
				function coordObjs(lt,ln){
					this.latd=lt;
					this.longd=ln;	
				}
				
				//now draw the map based on the coordns of the path given		
			var x = new google.maps.LatLng(-parseFloat(myPath[0].latd),parseFloat(myPath[0].longd));
			
			var myPathway = [];
			for(var i=0; i < myPath.length-1; i++){
				myPathway[myPathway.length] = new google.maps.LatLng(-parseFloat(myPath[i].latd),parseFloat(myPath[i].longd));
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
