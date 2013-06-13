<?php

class created
{    
    function createTables($cn)
    {
        include_once 'commons.php';
        $common=new commons();
        
        mysql_select_db($common->database);
        
        $cmd = "CREATE TABLE $common->table_name
        (VNumber int not null primary key auto_increment,
         ax VARCHAR(40),
         ay VARCHAR(40),
         az VARCHAR(40),
         tm VARCHAR(40),
         dt VARCHAR(40),
         lt VARCHAR(40),
         ln VARCHAR(40),
         al VARCHAR(40),
         sp VARCHAR(40),
         cs VARCHAR(40),
         temp VARCHAR(40),
         battery VARCHAR(40),
	 battVolt VARCHAR(40))";

        mysql_query($cmd, $cn) or die(mysql_error());
        echo "COW_DATA table created.. <br/>";
    }

    function createDatabase()
    {
        include_once 'commons.php';
        $common=new commons();
        
        $database= $common->database;

        $cn=$common->connection();
        
        $cmd = "CREATE DATABASE $database";
        mysql_query($cmd, $cn) or die(mysql_error());
        echo 'Database created..<br/>';
        $this->createTables($cn);
    }
}
?>
