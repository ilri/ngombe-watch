/**
To Do List
`````````````
- Create a linked list of received data that is yet to be saved to the db/file. This list should be dumped to the db/file once the connection is restored.
 */

#include <netinet/in.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include <stdlib.h>

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
    int iteration_sleep = 2; //the number of seconds to sleep in the middle of iterationsstruct test_struct
    struct timeval timeout;
    timeout.tv_sec = 120; //the timout for receiving data from client before closing connection i seconds
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
