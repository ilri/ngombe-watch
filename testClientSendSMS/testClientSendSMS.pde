#define GPRS_TIMEOUT 12000 //in millisecods
#define GPRS_CONFIG_TIMEOUT 60000 //timeout the config after 1 minute and reboot
#define TCP_CONFIG_TIMEOUT 150000//tcp configuration timout* check this value
#define config_file "my_config.txt"

uint8_t noOfLines = 0; //no of times the data on the SD dard is written/cycles
uint8_t maxLoopsBeforeUpload = 10;
int timeDelayForRecording = 1000; //get data after every x seconds
uint8_t successSending=0;

char t[20];
uint8_t x = 0;//variable determines if successful or not
char  wholeString[300];
uint8_t gprsRetries=0;
uint8_t loopNo=0;
long stime;
char message[100];
uint8_t mod=1;

void setup(){
	USB.begin();
}

void loop(){
	USB.print("loop no: ");
	USB.println(loopNo++,DEC);

	USB.println("sleep(8)");
	delay(8000);
	if(loopNo % 3) mod=!mod;

	//modifyString("tcpR",mod);

	modifyString("err",getErrVal("cu"));
}
uint8_t getErrVal(char *err){
	if(strcmp(err,"GPRS")==0){ return 1; }//could not configure gprs
	else if(strcmp(err,"TCP")==0){ return 2; }//could not configure tcp
	else if(strcmp(err,"cu")==0){ return 4; }//could not connect to the socket server
        else if(strcmp(err,"du")==0){ return 8; }//could not upload data to the socket server
}
void modifyString(char * field,int pro)//field is the value to bge modified, pro is 0 or 1. 1 means increase, 0 means set its value to zero
{
	x=0;
	SD.ON();
	if(SD.isFile("my_config.txt")){
		USB.println("Config file exists");
		sprintf(message,SD.catln("my_config.txt",0,SD.numln("my_config.txt")));

		USB.println("Original message: ");
		USB.println(message);

		//tokenize data
		char list[5][20];
		int i=0;
		char * pch = strtok (message,"\n");
		while (pch != NULL){
			strcpy(list[i],pch);
			pch = strtok (NULL, "\n");
			i++;
		}
		struct my_data{
			char tcpR[20];
			char tcpX[20];
			char phn1[11];
			char phn2[11];
			char errSum[20];
		};

		//now copy the data from list to the data structure
		struct my_data dat1;
		sprintf(dat1.tcpR,"%s",list[0]);
		sprintf(dat1.tcpX,"%s",list[1]);
		sprintf(dat1.phn1,"%s",list[2]);
		sprintf(dat1.phn2,"%s",list[3]);
		sprintf(dat1.errSum,"%s",list[4]);

		if((((atoi(dat1.tcpR)+1) % atoi(dat1.tcpX))==0)&&(atoi(dat1.tcpR)!=0)){//dont send sms for the first retry
			x=1;//send sms
		}//add other else ifs for other cases as necessary


		if(strcmp(field,"tcpR")==0){
			if(pro==1)
			{//set its value to +=1

				USB.println("Incrementing...");

				sprintf(dat1.tcpR,"%d",(atoi(dat1.tcpR)+1));
				sprintf(message,"%s\n%s\n%s\n%s\n%s\n",dat1.tcpR,dat1.tcpX,dat1.phn1,dat1.phn2,dat1.errSum);
			}

			else if(pro==0)
			{//set its value to zero

				USB.println("Resetting...");
				sprintf(dat1.tcpR,"%d",0);
				sprintf(message,"%s\n%s\n%s\n%s\n%s\n",dat1.tcpR,dat1.tcpX,dat1.phn1,dat1.phn2,dat1.errSum);
			}
		}
		else if(strcmp(field,"err")==0){

			USB.print("Adding error value in the config file: ");
                        USB.println(pro);
			sprintf(dat1.errSum,"%d",(atoi(dat1.errSum)+pro));
			sprintf(message,"%s\n%s\n%s\n%s\n%s\n",dat1.tcpR,dat1.tcpX,dat1.phn1,dat1.phn2,dat1.errSum);
		}
		else{
			USB.println("Strings don't match"); 
		}

		USB.println("Final message: \n");
		USB.println(message);

		if(SD.writeSD("my_config.txt",message,0)) USB.println("write new values to my_config.txt");
		USB.println("Show 'my_config.txt':  ");
		USB.println(SD.catln("my_config.txt",0,SD.numln("my_config.txt")));

		if(x==1){

			char resp[2][11];//send sms to these two numbers
			sprintf(resp[0],"%s",dat1.phn1);
			sprintf(resp[1],"%s",dat1.phn2);

			sendSMS(resp);
		}
	}
	else{
		USB.println("file does not exist");//get it from the server 
	}  
	SD.OFF();
}

void sendSMS(char resp[][11]){
	//tokenize data
	char list[5][20];
	int i=0;
	char * pch = strtok (message,"\n");
	while (pch != NULL){
		strcpy(list[i],pch);
		pch = strtok (NULL, "\n");
		i++;
	}
	//or whatever message to send
	sprintf(list[0],"%d",(atoi(list[0])+1));
	sprintf(message,"tcpRetries: %s\nmax tcp retries: %s\nerrSum: %s\n",list[0],list[1],list[4]);

	// Configure GPRS Connection
	stime = millis();
	while (!startGPRS(1) && ((millis() - stime) < GPRS_CONFIG_TIMEOUT)){
		USB.println("Trying to configure GPRS...");
		delay(2000);
		if (millis() - stime < 0) stime = millis();
	}

	// If timeout, exit. if not, try to send sms
	if (millis() - stime > GPRS_CONFIG_TIMEOUT){
		PWR.reboot();
	}
	else{
		USB.println("GPRS OK");

		//send sms
		USB.println("Sending sms to: ");
		USB.println(resp[1]);
		USB.println("Message: ");
		USB.println(message);

		if(GPRS_Pro.sendSMS(message,resp[1])) USB.println("SMS Sent OK"); // * should be replaced by the desired tlfn number
		else USB.println("Error sending sms");
	}
	GPRS_Pro.OFF();
}

//if this phase does not succeed, cellInfo will never return true
uint8_t startGPRS(int isms){
	x=0;//start when the value of x =0;

	// setup for GPRS_Pro serial port
	GPRS_Pro.ON();

	// waiting while GPRS_Pro connects to the network
	stime = millis();

	while(millis()-stime < GPRS_TIMEOUT){
		if(!GPRS_Pro.check()){
			USB.print("Configuring GPRS...");
			delay(2000);
		}
		else{
			break;
		}
	}

	// If timeout, exit. if not, try to upload
	if (millis() - stime > GPRS_TIMEOUT){
		USB.print("Timeout, GPRS failed free mem:");
		USB.println(freeMemory());
		x=0;
	}
	else{
		x=1;
	}

	if(isms==1){//this is for sending the sms
		if(!GPRS_Pro.setInfoIncomingCall()){
			x=0;
			if(!GPRS_Pro.setInfoIncomingSMS()){
				x=0;
				if(!GPRS_Pro.setTextModeSMS()){
					x=0; 
				}
			}
		}		
	}

	return x;
}

