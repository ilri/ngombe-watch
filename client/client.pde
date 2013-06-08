#define GPRS_TIMEOUT 12000 //in millisecods
#define GPRS_CONFIG_TIMEOUT 60000 //timeout the config after 1 minute and reboot
#define TCP_CONFIG_TIMEOUT 150000//tcp configuration timout* check this value

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
char message[50];//useful for dealing with the values on the sd card and sending the sms

void setup(){
	USB.begin();
	// setup the GPS module
	USB.print("Setting up GPS...");
	GPS.ON();

	// waiting for GPS is connected to satellites
	while (!GPS.check()){
		USB.println("Waiting for GPS connection");
		delay(1000);
	}
}

void loop(){
	USB.print("Loop no: .");
	USB.println(loopNo++,DEC);

	for (noOfLines = 0; noOfLines < maxLoopsBeforeUpload; noOfLines++){
		getValues();
		USB.print(wholeString);
		writeToFile(wholeString);
		delay(timeDelayForRecording);
	}
	getDataOut();
	getFreeMem();
}
void getDataOut(){

	if(startGPRS(1)){
		USB.println("GPRS_CONFIG OK: ");
		if(configTCP())
		{
			USB.println("TCP_CONFIG OK: ");
			modifyString("tcpR",0);//Reset the tcpR count

			if(connectToServer()){

				USB.println("OPEN_SOCKET OK: ");
				if(uploadData())
				{
					USB.println("Data uploaded successfully");
				}
				else
				{
					USB.println("Data could not be uploaded"); 
				}
			}
			else
			{
				USB.println("Failed to connect to the socket server"); 
			}
		}
		else
		{
			USB.println("Failed to configure TCP ");
			modifyString("tcpR",1);//increase no of tcp retries
		}
	}
	else{ 
		USB.println("Failed to configure GPRS: ");
	}
	GPRS_Pro.OFF();
}
uint8_t configTCP()
{
	x=0;
	//now tcp connection
	stime = millis();
	while((millis()-stime) < TCP_CONFIG_TIMEOUT){
		if(!GPRS_Pro.configureGPRS_TCP_UDP(SINGLE_CONNECTION,NON_TRANSPARENT)){
			USB.println("Trying TCP connection..");
			delay(3000);
		}
		else{
			break;
		}
	}

	if (millis() - stime > TCP_CONFIG_TIMEOUT){
		USB.print("TCP config timout, mem: ");
		USB.println(freeMemory());
		x=0; 
	}
	else{
		x=1;
	}

	return x;
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
			USB.println("Configuring GPRS...");
			delay(2000);
		}
		else{
			break;
		}
	}

	// If timeout, exit. if not, try to upload
	if (millis() - stime > GPRS_TIMEOUT){
		USB.print("Timeout, free mem:");
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

uint8_t uploadData(){
	x=0;
	//only try sending string if connected to tcp server
	USB.println("Begin sending data...");
	SD.ON();

	if(!SD.isFile("raw_data1.txt")){
		USB.println("File does not exist");
	}
	else{
		for(int i=0;i<SD.numln("raw_data1.txt");i++){
			sprintf(wholeString,"%s",SD.catln("raw_data1.txt",i,1));

			if(uploadTCPString(wholeString))
			{
				USB.print(i);
				USB.println(": sent"); 
				successSending=1;
			}
			else
			{
				USB.print("Failed sending at line: ");// if one fails, then the rest are bound to fail as well.
				USB.println(i);
				successSending=0;
				break;
			}
		}
	}
	if(successSending==1)
	{
		if(SD.del("raw_data1.txt")){USB.println("File deleted");}
	}

	SD.OFF();
	//'bye' tells the server to end the connection on his side
	uploadTCPString("bye");
	//USB.println("Sending succeeded.");
	// Close socket
	GPRS_Pro.closeSocket();
	return x;	
}
uint8_t connectToServer()
{
	x=0;
	//only try opening tcp connection if config was OK.
	if (GPRS_Pro.createSocket(TCP_CLIENT, "54.235.113.108", "8081")){
		x=1;
	}
	else{
		USB.print("Error opening the socket: free mem: "); // will simply go on but append to that file- server error
		x=0;
	}
	return x;
}

uint8_t uploadTCPString(char * data)
{
	x=0;
	if (GPRS_Pro.sendData(data)){
		x=1;
	}
	else{
		x=0;
	}
	return x;
}

void getFreeMem()
{
	USB.print("mem: ");
	USB.println(freeMemory());
}

void getValues(){
	//construct the json string
	sprintf(wholeString, "%s", "{");
	getAccelerometerReading();
	getGPS();
	getTemperature();
	getBatteryLevel();
	sprintf(wholeString + strlen(wholeString), "%s", "}\n");
}

void getGPS(){
	// open the uart
	GPS.begin();
	// Inits the GPS module
	GPS.init();

	// Checking for satellite connection
	while(!GPS.check()){
		USB.println("W8 4 GPS");
		delay(1000);
	}

	GPS.getPosition();

	sprintf(wholeString + strlen(wholeString), "%s", "\"tm\":\"");
	sprintf(wholeString + strlen(wholeString), "%s", GPS.timeGPS);
	sprintf(wholeString + strlen(wholeString), "%s", "\",");

	sprintf(wholeString + strlen(wholeString), "%s", "\"dt\":\"");
	sprintf(wholeString + strlen(wholeString), "%s", GPS.dateGPS);
	sprintf(wholeString + strlen(wholeString), "%s", "\",");

	sprintf(wholeString + strlen(wholeString), "%s", "\"lt\":\"");
	sprintf(wholeString + strlen(wholeString), "%s", GPS.latitude);
	sprintf(wholeString + strlen(wholeString), "%s", "\",");

	sprintf(wholeString + strlen(wholeString), "%s", "\"ln\":\"");
	sprintf(wholeString + strlen(wholeString), "%s", GPS.longitude);
	sprintf(wholeString + strlen(wholeString), "%s", "\",");

	sprintf(wholeString + strlen(wholeString), "%s", "\"al\":\"");
	sprintf(wholeString + strlen(wholeString), "%s", GPS.altitude);
	sprintf(wholeString + strlen(wholeString), "%s", "\",");

	sprintf(wholeString + strlen(wholeString), "%s", "\"sp\":\"");
	sprintf(wholeString + strlen(wholeString), "%s", GPS.speed);
	sprintf(wholeString + strlen(wholeString), "%s", "\",");

	sprintf(wholeString + strlen(wholeString), "%s", "\"cs\":\"");
	sprintf(wholeString + strlen(wholeString), "%s", GPS.course);
	sprintf(wholeString + strlen(wholeString), "%s", "\",");

	// Closing UART
	GPS.close();
}

// Show the remaining battery level

void getBatteryLevel(){
	sprintf(wholeString + strlen(wholeString), "%s", "\"batt\":");
	sprintf(wholeString + strlen(wholeString), "%d",PWR.getBatteryLevel());
	sprintf(wholeString + strlen(wholeString), "%s", ",");

	// Show the battery Volts
	sprintf(wholeString + strlen(wholeString),"%s","\"battVolt\":");
	Utils.float2String(PWR.getBatteryVolts(),t, 4);
	sprintf(wholeString + strlen(wholeString),"%s",t);
}

void getTemperature(){
	int x_acc = RTC.getTemperature();

	sprintf(wholeString+strlen(wholeString),"%s", "\"temp\":");
	sprintf(t, "%d", x_acc);
	sprintf(wholeString+strlen(wholeString),"%s", t);
	sprintf(wholeString+strlen(wholeString),"%s",",");
}

void getAccelerometerReading(){
	ACC.ON(); //put on the accelerometer
	byte check = ACC.check();
	if (check != 0x3A){ 
	}
	else{
		//----------X Values-----------------------
		//format: {"ax":131,"ay":-19,"az":983}
		sprintf(wholeString + strlen(wholeString), "%s", "\"ax\":");
		sprintf(wholeString + strlen(wholeString), "%d", ACC.getX());
		sprintf(wholeString + strlen(wholeString), "%s", ",");
		//----------Y Values-----------------------

		sprintf(wholeString + strlen(wholeString), "%s", "\"ay\":");
		sprintf(wholeString + strlen(wholeString), "%d", ACC.getY());
		sprintf(wholeString + strlen(wholeString), "%s", ",");

		//----------Z Values-----------------------
		sprintf(wholeString + strlen(wholeString), "%s", "\"az\":");
		sprintf(wholeString + strlen(wholeString), "%d", ACC.getZ());
		sprintf(wholeString + strlen(wholeString), "%s", ",");
	}
	ACC.close(); //put off the accelerometer
}

uint8_t writeToFile(char *value){
	x=0;//start when the value of x =0;
	/*
	   Error codes
	   1 if the writing/appending was successful
	   -1 if unsuccessful writing.
	   -3 if error appending
	   -5 Folder doesnt exist but not created
	 */

	SD.ON();

	if (SD.isFile("raw_data1.txt") == 1){
		if (SD.appendln("raw_data1.txt", value) == 1){
			x = 1; //append successful
		}
		else{
			x = -3; //unsuccessful- could not append to that file
		}
	}
	else{
		if (SD.create("raw_data1.txt")){
			if (SD.writeSD("raw_data1.txt", value, 0)){
				x = 1; //write successful
			}
			else{
				x = -1; //unsuccessful- could not write to that file
			}
		}
	}
	SD.OFF();
	return x;
}

void modifyString(char * field,int pro)//field is the value to be modified, pro is 0 or 1. 1 means increase, 0 means set its value to zero
{
	x=0;
	SD.ON();
	if(SD.isFile("my_config.txt")){
		//USB.println("Config file exists");
		sprintf(message,"%s",SD.catln("my_config.txt",0,SD.numln("my_config.txt")));

		//USB.println("Original message: ");
		//USB.println(message);

		//tokenize data
		char list[4][20];
		int i=0;
		char * pch = strtok (message,"\n");
		while (pch != NULL){
			sprintf(list[i],"%s",pch);
			pch = strtok (NULL, "\n");
			i++;
		}
		struct my_data{
			char tcpR[20];
			char tcpX[20];
			char phn1[11];
			char phn2[11];
		};

		//now copy the data from list to the data structure
		struct my_data dat1;
		sprintf(dat1.tcpR,"%s",list[0]);
		sprintf(dat1.tcpX,"%s",list[1]);
		sprintf(dat1.phn1,"%s",list[2]);
		sprintf(dat1.phn2,"%s",list[3]);

		if((((atoi(dat1.tcpR)+1) % atoi(dat1.tcpX))==0)&&(atoi(dat1.tcpR)!=0)){//dont send sms for the first retry
			x=1;//send sms
		}//add other else ifs for other cases as necessary

		if(pro==1){//set its value to +=1
			//USB.println("Incrementing...");

			if(strcmp(field,"tcpR")==0){
				sprintf(dat1.tcpR,"%d",(atoi(dat1.tcpR)+1));
				sprintf(message,"%s\n%s\n%s\n%s\n",dat1.tcpR,dat1.tcpX,dat1.phn1,dat1.phn2);
			}//for other cases, to increment, add here
			else
			{
				//       USB.println("Strings don't match"); 
			}
		}
		else if(pro==0){//set its value to zero
			//USB.println("Resetting...");

			if(strcmp(field,"tcpR")==0){
				sprintf(dat1.tcpR,"%d",0);
				sprintf(message,"%s\n%s\n%s\n%s\n",dat1.tcpR,dat1.tcpX,dat1.phn1,dat1.phn2);
			}//for other cases, to reset, add here
			else
			{
				//     USB.println("Strings don't match"); 
			}
		}

		//USB.println("Final message: \n");
		//USB.println(message);

		if(SD.writeSD("my_config.txt",message,0)){}// USB.println("write new values to my_config.txt");
		//USB.println("Show 'my_config.txt':  ");
		//USB.println(SD.catln("my_config.txt",0,SD.numln("my_config.txt")));

		if(x==1){

			char resp[2][11];//send sms to these two numbers
			sprintf(resp[0],"%s",dat1.phn1);
			sprintf(resp[1],"%s",dat1.phn2);

			sendSMS(resp);
		}
	}
	else{
		//USB.println("file does not exist");//get it from the server 
	}  
	SD.OFF();
}

//receives a list of recepients to whom the message is sent
void sendSMS(char resp[][11]){
	//tokenize data
	char list[4][20];
	int i=0;
	char * pch = strtok (message,"\n");
	while (pch != NULL){
		sprintf(list[i],"%s",pch);
		pch = strtok (NULL, "\n");
		i++;
	}
	sprintf(list[0],"%d",(atoi(list[0])+1));
	sprintf(message,"tcpRetries: %s\nmax tcp retries: %s\nphn1: %s\nphn2: %s\n",list[0],list[1],list[2],list[3]);

	// Configure GPRS Connection
	stime = millis();
	while (!startGPRS(1) && ((millis() - stime) < GPRS_CONFIG_TIMEOUT)){
		USB.println("Trying to configure GPRS...");
		delay(2000);
		if (millis() - stime < 0) stime = millis();
	}

	// If timeout, exit. if not, try to send sms
	if (millis() - stime > GPRS_CONFIG_TIMEOUT){
		return;
	}
	else{
		//USB.println("GPRS OK");
		if(GPRS_Pro.sendSMS(message,resp[0]))  USB.println("SMS Sent OK"); // * should be replaced by the desired tlfn number
		//else USB.println("Error sending sms");

		//delay(1000);

		if(GPRS_Pro.sendSMS(message,resp[1])) USB.println("SMS Sent OK"); // * should be replaced by the desired tlfn number
		//else USB.println("Error sending sms");
	}
	GPRS_Pro.OFF();
}
