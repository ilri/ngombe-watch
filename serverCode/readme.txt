1. Open the file sAdmin.php on the browser of the machine where the server is running.
2. Set the server mysql details as appropriate in the file 'commons.php'.\
3. Click "Create database on the browser 'sAdmin.php'".-> should say 
"Database created..
COW_DATA table created.. "
4. Change the server details as well on the c server file include "waspmote_server.c".
5. compile the server using this command gcc -o server waspmote_server.c -L/usr/include/mysql -lmysqlclient -I/usr/include/mysql
NB: Incase compiling has mysql errors refer to this
	(http://stackoverflow.com/questions/2778271/compiling-a-c-program-including-mysql) 
6. Run the server as usual. i.e in this case, ./server

