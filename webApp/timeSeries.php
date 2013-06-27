<!DOCTYPE html>
<html>
	<head>
		<script
			src="http://maps.googleapis.com/maps/api/js?key=AIzaSyDY0kkJiTPVd2U7aTOAwhc9ySH6oHxOIYM&sensor=false">
		</script>
		<script>
			var x=new google.maps.LatLng(52.395715,3.888916);
			var stavanger=new google.maps.LatLng(58.983991,5.734863);
			var amsterdam=new google.maps.LatLng(52.395715,4.888916);
			var london=new google.maps.LatLng(51.508742,-0.120850);

			function initialize()
			{
				var mapProp = {
					center:x,
					zoom:4,
					mapTypeId:google.maps.MapTypeId.ROADMAP
				};
  
				var map=new google.maps.Map(document.getElementById("googleMap"),mapProp);

				var myTrip=[stavanger,amsterdam,london];
				var flightPath=new google.maps.Polyline({
					path:myTrip,
					strokeColor:"#0000FF",
					strokeOpacity:0.8,
					strokeWeight:2
				});

				flightPath.setMap(map);
			}

			google.maps.event.addDomListener(window, 'load', initialize);
		</script>
	</head>

	<body>
		<div id="googleMap" style="width:500px;height:380px;"></div>
	</body>
</html>

