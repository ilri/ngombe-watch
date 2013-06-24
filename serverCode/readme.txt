1. The fileServer is the ececutable that is to be called by the server to stote the data to db.
The server file is the ececutable that receives data from the client and stors it to file and later calls the fileServer fro store all the  written code to the database.
3. Both the server and fileServer have to be in the same dir
To compile server- use normal gcc waspmote_server.c -o server
To compile toDB.c use gcc -o fileServer toDB.c -L/usr/include/mysql -lmysqlclient -I/usr/include/mysql

then run only server

####################

table format
CREATE TABLE COW_DATA
(VNumber int not null primary key auto_increment,
 ax VARCHAR(40),
 ay VARCHAR(40),
 az VARCHAR(40),
 dt DATETIME,
 lt VARCHAR(40),
 ln VARCHAR(40),
 al VARCHAR(40),
 sp VARCHAR(40),
 cs VARCHAR(40),
 temp VARCHAR(40),
 battery VARCHAR(40),
 battVolt VARCHAR(40));
 
