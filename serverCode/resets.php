<?php

class resets
{
    function deleteDatabase()
    {
        include_once 'commons.php';
        $common = new commons();

        $cn = $common->connection();
        mysql_select_db($common->database);

        $cmd = "DROP DATABASE $common->database";
        mysql_query($cmd, $cn) or die(mysql_error());
        echo 'Database deleted!!<br/>';
        mysql_close($cn);
    }
}

?>
