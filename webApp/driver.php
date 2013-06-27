<?

if((isset($_POST['submit'])&&($_POST['submit']=="CREATE DATABASE")))
{
    include_once 'creations.php';
    $aCreation=new created();

    $aCreation->createDatabase();
}
else if((isset($_POST['submit'])&&($_POST['submit']=="DROP DATABASE")))
{
    include_once 'resets.php';
    $reset=new resets();

    $reset->deleteDatabase();
}
else if($_POST['submit']=="GET_DATA")
{
    $noOfDays=$_POST["noOfDays"];
    
    include_once 'dataRetrievals.php';
    $retrieve = new dataRetrievals();
    
    print $retrieve->getLatestValues($noOfDays);
}
?>
