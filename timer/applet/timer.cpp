#define GPRS_TIMEOUT 12000 //in millisecods
#define GPRS_CONFIG_TIMEOUT 60000 //timeout the config after 1 minute and reboot
#define TCP_CONFIG_TIMEOUT 150000//tcp configuration timout* check this value

#include "WProgram.h"
void setup();
void loop();
void getDataOut();
uint8_t configTCP();
uint8_t startGPRS(int isms);
uint8_t uploadData();
uint8_t connectToServer();
uint8_t uploadTCPString(char * data);
void getFreeMem();
long stime;
uint8_t l=0;
uint8_t x;
uint8_t successSending=0;
char wholeString[300];

void setup(){
	USB.begin();
	USB.println("USB started...");
}

void loop(){
	USB.print("Loop no: ");
	USB.println(l++,DEC);

        getDataOut();
	
	getFreeMem();
	delay(3000);
}
void getDataOut(){
  
  if(startGPRS(1)){
		USB.println("GPRS_CONFIG OK: ");
		if(configTCP())
		{
			USB.println("TCP_CONFIG OK: ");
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
			USB.println("Failed to configure TCP sleep(3): ");
		}
	}
	else{ 
		USB.println("Failed to configure GPRS sleep(3): ");
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
          USB.println("deleting file...");
          //if(SD.del("raw_data1.txt")){USB.println("File deleted")}
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

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

