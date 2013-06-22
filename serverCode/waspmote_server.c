/**
  To Do List
  `````````````
  - Create a linked list of received data that is yet to be saved to the db/file. This list should be dumped to the db/file once the connection is restored.
 */

#include <netinet/in.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <mysql.h>

char *server = "localhost";/* server details */
char *user = "root";
char *password = "#if!emma"; /*end server details*/
char *database = "ILRI_DB";//if changed here, change also on the server"
char *table_name = "COW_DATA";

void getValuesFromLine(char * line);//line is the json string that has been received and has to be saved to db
int storeToDB(char * ax, char *ay, char *az,char *tm, char *dt, char *lt, char *ln, char *al, char *sp, char *cs, char *temp,char *battery, char *battVolt);
char *strrev(char *str);


int main()
{
	int sockfd = -1, clientSock = -2, n, res = -1, count = -1;
	struct sockaddr_in server_addr;
	int sockfd_sleep = 1; //the number of seconds to sleep if we dont have a valid socket
	int listen_port = 8081; //the port that we are going to listen to
	int no_connections = 25; //the number of connections to accept
	int bind_sleep = 15; //the number of seconds to sleep in case a bind fails
	int error_sleep = 1; //the number of seconds to sleep when a accept or read error occurs
	int buf_len = 200; //the length of the buffer to store the string
	int iteration_sleep = 2; //the number of seconds to sleep in the middle of iterations
	struct timeval timeout;
	timeout.tv_sec = 120; //the timout for receiving data from client before closing connection i seconds
	timeout.tv_usec = 0;

	FILE *fp;

	char *of = "received_data.txt"; //the name of the output file
	char buffer[buf_len];

	while (1)
	{
		count++;
		memset(buffer, 0, sizeof (buffer)); // = '\0';
		while (sockfd == -1)
		{
			//attempt to create the socket
			sockfd = socket(AF_INET, SOCK_STREAM, 0);
			if (sockfd == -1)
			{
				printf("There was an error while creating the socket!\n I will sleep for %d seconds before trying again.\n", sockfd_sleep);
				sleep(sockfd_sleep);
			}
		}
		while (res == -1)
		{
			//if we are here.... we have a socket, lets do some initializations
			memset(&server_addr, '0', sizeof (server_addr));

			server_addr.sin_family = AF_INET;
			server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
			server_addr.sin_port = htons(listen_port);

			res = bind(sockfd, (struct sockaddr*) &server_addr, sizeof (server_addr));
			if (res == -1)
			{
				printf("There was an error while binding the script to port %d. I will sleep for %d seconds before trying again.\n", listen_port, bind_sleep);
				sleep(bind_sleep);
			}
		}

		//now listen for incoming connections
		printf("Waiting for connection....\n");
		listen(sockfd, no_connections);
		if (clientSock == -2)
		{
			clientSock = accept(sockfd, (struct sockaddr *) NULL, NULL);
		}
		if (clientSock < 0)
		{
			printf("There was an error while accepting a connection '%d' to the client. Sleeping for %d seconds b4 continuing.\n", clientSock, error_sleep);
			sleep(error_sleep);
		}
		else
		{
			printf("Connection '%d' open and active...\n", clientSock);

			//start timer and if i dont here from client in 60 seconds, close the connection
			if (setsockopt(clientSock, SOL_SOCKET, SO_RCVTIMEO, (char *) &timeout, sizeof (timeout)) < 0)
			{
				error("setsockopt failed\n");
			}
			else
			{
				printf("You have %ld seconds to send data\n", timeout.tv_sec);
				memset(buffer, 0, sizeof (buffer));
				n = read(clientSock, buffer, sizeof (buffer));
				if (n < 0)
				{
					printf("Reading error from the client socket. Sleeping for %d seconds before closing socket.\n", error_sleep);
					sleep(error_sleep);
					//could be the client is offline
					close(clientSock);
					clientSock = -2;
				}
				else
				{
					printf("size of buffer: %d\n", strlen(buffer));
					printf("is it bye? %d\n", strcmp(buffer, "bye"));

					if ((strcmp(buffer, "bye") == 0) || (strlen(buffer) == 0))
					{
						printf("Closing socket connection..\n\n");
						close(clientSock);
						clientSock = -2;
					}
					else
					{
						//we open the file and dump the data there
						fp = fopen(of, "at");
						if (!fp)
						{
							printf("Cannot open %s file for writing... this is serious!!!\nLinked lists have not been implemented yet. This data is going to be lost!! IMPLEMENT LISTS DUDE!!\n", of);
						}
						else
						{
							if (strlen(buffer) == 0)
							{
								//this could be some closing string --etc, not data that we know- do nothing
							}
							else
							{
								printf("%d: Received data:\"%s\" \n", count, buffer);
								fputs(buffer, fp);
							}
							fclose(fp);
							getValuesFromLine(buffer);
						}
					}
				}
			}
		}
		//		close(sockfd);
		sleep(iteration_sleep); //sleep after a job well done!
		//		printf("......1 iteration complete.....\n\n\n");
	}
}

//code to insert data to db

void getValuesFromLine(char * line)//line is the json string that has been received and has to be saved to
{
	if (strlen(line) > 1)
	{
		//remove the '{' and '}'
		line[0] = ' ';
		line[strlen(line) - 2] = '\0';
		//remove the extra spaces
		char *ch = line;
		char *p1 = ch;
		char *p2 = ch;
		p1 = ch;
		while (*p1 != 0)
		{
			if (isspace(*p1) || (*p1) == '\"')
			{
				++p1;
			}
			else
				*p2++ = *p1++;
		}
		*p2 = 0;

		//now the string without extra spaces is stored in 'ch'
		char * keyV[13];

		char *str = line;
		char * pch;
		pch = strtok(str, ",");
		int i = 0;
		while (pch != NULL)
		{
			keyV[i] = pch;
			pch = strtok(NULL, ",");
			i++;
		}

		//now tokenize them further
		//now each of those tokens is a key-value pair
		char *values[26];
		int k, x;
		x = 0;
		for (k = 0; k < i; k++)
		{
			char *str2 = keyV[k];
			char * pch2;
			pch2 = strtok(str2, ":");
			while (pch2 != NULL)
			{
				values[x++] = pch2;
				pch2 = strtok(NULL, ":");
			}
		}
		//call function to insert to db with the cprrect params
		storeToDB(values[1], values[3], values[5], values[7], values[9], values[11], values[13], values[15], values[17], values[19], values[21], values[23],values[25]);
		//memset(line, 0, sizeof (line));
	}
}

char *strrev(char *str)
{
	char temp[strlen(str)];
	strcpy(temp,str);
	str[0]=temp[4];
	str[1]=temp[5];
	str[2]=temp[2];
	str[3]=temp[3];
	str[4]=temp[0];
	str[5]=temp[1];
	return str;
}

int storeToDB(char * ax, char *ay, char *az,char *tm, char *dt, char *lt, char *ln, char *al, char *sp, char *cs, char *temp,char *battery, char *battVolt)
{
	int stored = 0;
	MYSQL *conn;
	MYSQL_ROW row;
	conn = mysql_init(NULL);

	/* Connect to database */
	if (!mysql_real_connect(conn, server, user, password, database, 0, NULL, 0))
	{
		fprintf(stderr, "%s\n", mysql_error(conn));
		exit(1);
	}
	char command[500];
	memset(command, 0, sizeof (command));
	strcpy(command, "INSERT INTO ");
	strcat(command, table_name);
	strcat(command, "(");
	strcat(command, "ax,ay,az,dt,lt,ln,al,sp,cs,temp,battery,battVolt) values(");
	strcat(command, "'");
	strcat(command, ax);
	strcat(command, "','");
	strcat(command, ay);
	strcat(command, "','");
	strcat(command, az);
	strcat(command, "','");

	char dt1[strlen(dt)];
	strcpy(dt1,dt);	

	strcat(command,strrev(dt1));
	tm[strlen(tm)-4]='\0';
	sprintf(command+strlen(command),"%s",tm);
	strcat(command, "','");

	strcat(command, lt);
	strcat(command, "','");
	strcat(command, ln);
	strcat(command, "','");
	strcat(command, al);
	strcat(command, "','");
	strcat(command, sp);
	strcat(command, "','");
	strcat(command, cs);
	strcat(command, "','");
	strcat(command, temp);
	strcat(command, "','");
	strcat(command, battery);
	strcat(command, "','");
	strcat(command, battVolt);
	strcat(command, "')");
	/* send SQL query */
	if (mysql_query(conn, command))
	{
		fprintf(stderr, "%s\n\n", mysql_error(conn));
		stored = 0;
	}
	else
	{
		printf("Data inserted\n");
		stored = 1;
	}

	/* close connection */
	mysql_close(conn);
	return stored;
}
