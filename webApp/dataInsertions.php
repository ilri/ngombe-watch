<?php

/**
 * Description of dataInsertions
 *
 * @author emma
 */
class dataInsertions
{

    //put your code here
    function addToDB($ax, $ay, $az, $temp, $battery, $tm, $dt, $lt, $ln, $al, $sp, $cs)
    {
        include_once 'commons.php';
        $common = new commons();

        $cn = $common->connection();
        mysql_select_db($common->database);

        $cmd = "INSERT INTO $common->table_name (ax,ay,az,temp,battery,tm,dt,lt,ln,al,sp,cs) values('$ax','$ay','$az','$temp','$battery','$tm','$dt','$lt','$ln','$al','$sp','$cs')";
        if (mysql_query($cmd, $cn))
            echo "Success: $common->table_name<br />";
        else
            echo "Error: " . mysql_error() . "<br />";
        mysql_close($cn);
    }

}

?>
