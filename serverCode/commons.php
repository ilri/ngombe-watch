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
      var $password = 'root';
      var $database='ILRI_DB';
      var $table_name='COW_DATA';

    function connection()
    {
        $cn = mysql_connect($this->server ,$this->username,$this->password) or die(mysql_error());
        return $cn;
    }    
}
?>
