<?php
/**
 * Description of commons
 *
 * @author emma
 */
class commons
{
      var $server = 'localhost';
      var $username = 'root';
      var $password = 'bananaface!';
      var $database='ILRI_DB';
      var $table_name='COW_DATA';

    function connection()
    {
        try {
	  $conn = new PDO('mysql:host=localhost;dbname=ILRI_DB',"root",$this->password);
	}
	catch(PDOException $e) {
	    echo 'ERROR: ' . $e->getMessage();
	}
	return $conn;
    }    
}
?>
