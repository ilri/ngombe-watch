<?php
/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of dataRetrievals
 *
 * @author emma
 */
class dataRetrievals {

	function getLatestValues($noOfDays) {
		$ax = "ax";
		$ay = "ay";
		$az = "az";
		$temp ="temp";
		$batt = "battery";
		$lt = "lt";
		$ln = "ln";
		$al = "al";
		$dt = "dt";

		include_once './commons.php';
		$common = new commons();

		$conn = $common->connection();

		$stmt = $conn->prepare('SELECT dt FROM COW_DATA');
		$stmt->execute();

		$result = $stmt->fetchAll();
		$data = "";

		if (count($result)) {
			foreach ($result as $row) {
				$data.=$row[0] . ",";
			}
		} else {
			echo "No rows returned.";
		}
		$data[strlen($data)-1]=" ";

		$arr = explode(',', trim($data));
		
		$date1 = new DateTime($arr[count($arr)-1]);
		$result1 = $date1->format('Y-m-d H:i:s');

		
		date_sub($date1 , date_interval_create_from_date_string($noOfDays.'days'));
		
		$result2 = $date1->format('Y-m-d H:i:s');
		
		$cmd="SELECT ".$dt.",".$ax.",".$ay.",".$az.",".$temp.",".$lt.",".$ln.",".$al.",".$batt." FROM COW_DATA WHERE dt BETWEEN '".$result2."' and '".$result1."'";
	
		$stmt = $conn->prepare($cmd);

		$stmt->execute();

		$result3 = $stmt->fetchAll();

		return json_encode($result3);
	//	print_r($result3);
		/*if (count($result3)) {
			foreach ($result3 as $row) {
				$data.=$row[0] . ",";
			}
			$data[strlen($data) - 1] = ' ';
		} else {
			echo "No rows returned.";
		}
		
		return $data;*/
	}
}
?>
