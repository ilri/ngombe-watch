/**
 Copyright 2013 ILRI, www.ilri.org

 Emmanuel Telewa  <e.telewa@cgiar.org>
 Kihara Absolomon <a.kihara@cgiar.org>
 
 This file is part of ngombe-watch.

 waspmote_server.c is a script that should be run on a server, that is used to
 receive data from the clients(waspmotes) and save the data into a 
 MySQL database. It uses TCP/IP protocols.
 
 ngombe-watch is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 ngombe-watch is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with ngombe-watch.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <netinet/in.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <mysql.h>
#include <ctype.h>
#define MAXSIZE 300
char *server = "localhost";/* server details */
char *user = "root";
char *password = "#if!emma"; /*end server details*/

char *database = "ILRI_DB";//if changed here, change also on the server"
char *table_name = "COW_DATA";

void getValuesFromLine(char * line1);//this function retrieves the required fields before passing them to storeToDB function
int storeToDB(char * ax, char *ay, char *az,char *tm, char *dt, char *lt, char *ln, char *al, char *sp, char *cs, char *temp,char *battery, char *battVolt);

int main()
{
    int sockfd = -1, clientSock = -2, n, res = -1, count = -1;
    struct sockaddr_in server_addr;
    int sockfd_sleep = 1; //the number of seconds to sleep if we dont have a valid socket
    int listen_port = 8081; //the port that we are going to listen to
    int no_connections = 25; //the number of connections to accept
    int bind_sleep = 15; //the number of seconds to sleep in case a bind fails
    int error_sleep = 1; //the number of seconds to sleep when a accept or read error occurs
    int buf_len = 300; //the length of the buffer to store the string
    int iteration_sleep = 2; //the number of seconds to sleep in the middle of iterationsstruct test_struct
    struct timeval timeout;
    timeout.tv_sec = 20; //the timout for receiving data from client before closing connection i seconds
    timeout.tv_usec = 0;

    struct buffer_struct
    {
        char val[buf_len];
        struct buffer_struct *next;
    };

    struct buffer_struct *head = NULL;
    struct buffer_struct *curr = NULL;
    struct buffer_struct *del = NULL;
    head = curr;

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
                printf("There was an error while creating the socket! I will sleep for %d seconds before trying again.\n", sockfd_sleep);
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
            printf("Connection '%d' open and active: ", clientSock);
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
                    printf("Timout Reading from the client socket. Sleeping for %d seconds\n", error_sleep);
                    sleep(error_sleep);
                    //could be the client is offline
                    close(clientSock);
                    clientSock = -2;
                }
                else
                {
                    if ((strlen(buffer) == 3 && strcmp(buffer, "bye") == 0) || (strlen(buffer) == 0))
                    {
                        printf("Closing socket connection..\n\n");
                        close(clientSock);
                        clientSock = -2;
                    }
                    else
                    {
                        //dump the data to the db
                        char buffer2[buf_len];
                        strcpy(buffer2, buffer);
                        getValuesFromLine(buffer2); //using a different memory location because of pointers- will modify contents

                        memset(buffer2, 0, sizeof (buffer2));

                        //we open the file and dump the data there
                        fp = fopen(of, "at");
                        if (!fp)
                        {
                            struct buffer_struct *ptr = (struct buffer_struct*) malloc(sizeof (struct buffer_struct));
                            strcpy(ptr->val, buffer);
                            ptr->next = NULL;
                            curr->next = ptr;
                            curr = ptr;
                            printf("Cannot open %s file for writing.... storing data in linked list....\n", of);
                        }
                        if (strlen(buffer) == 0)
                        {
                            //this could be some closing string --etc, not data that we know- do nothing
                        }
                        else
                        {
                            if (fp)
                            {
                                printf("%d: Received data: %s\n", count, buffer);
                                fputs(buffer, fp);
                            }
                            if (head != NULL && (fp || (count > 6 && count < 2) || (count > 26 && count < 20)))
                            {
                                printf("File operation resumed... dumping linked list to file...\n");
                                while (head != NULL)
                                {
                                    printf("%d: Dumped data: %s\n", count, head->val);
                                    fputs(head->val, fp);
                                    del = head;
                                    head = head->next;
                                    free(del);
                                    del = NULL;
                                }
                            }
                        }
                        fclose(fp);

                    }
                }
            }
        }
        //		close(sockfd);
        sleep(iteration_sleep); //sleep after a job well done!
        //		printf("......1 iteration complete.....\n\n\n");
    }
}

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
    strcat(command, "ax,ay,az,tm,dt,lt,ln,al,sp,cs,temp,battery,battVolt) values(");
    strcat(command, "'");
    strcat(command, ax);
    strcat(command, "','");
    strcat(command, ay);
    strcat(command, "','");
    strcat(command, az);
    strcat(command, "','");
    strcat(command, tm);
    strcat(command, "','");
    strcat(command, dt);
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
