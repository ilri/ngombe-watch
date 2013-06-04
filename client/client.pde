#define GPRS_TIMEOUT 12000 //in millisecods
#define GPRS_CONFIG_TIMEOUT 60000 //timeout the config after 1 minute and reboot
#define TCP_CONFIG_TIMEOUT 150000//tcp configuration timout* check this value
#define config_file "config.txt"
#define tcp_errors_file "tcp_errors.txt"

uint8_t noOfLines = 0; //no of times the data on the SD dard is written/cycles
uint8_t maxLoopsBeforeUpload = 10;
int timeDelayForRecording = 1000; //get data after every x seconds
uint8_t successSending=0;

char t[20];
uint8_t x = 0;//variable determines if successful or not
char  wholeString[300];
uint8_t gprsRetries=0;
int loopNo=0;
long stime;

void setup(){
  USB.begin();
  // setup the GPS module
  USB.print("Setting up GPS... Free Mem: ");
  USB.println(freeMemory());

  GPS.ON();

  // waiting for GPS is connected to satellites
  while (!GPS.check()){
    USB.println("Waiting for GPS connection");
    delay(1000);
  }
}

void loop(){
  USB.print("Loop no: .");
  USB.println(loopNo++);

  for (noOfLines = 0; noOfLines < maxLoopsBeforeUpload; noOfLines++){
    getValues();
    //USB.print(wholeString);
    writeToFile(wholeString);
    delay(timeDelayForRecording);
  }
  delay(2000);
  uploadData();
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
    USB.println("Waiting 4 GPS");
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

void uploadData(){
  SD.ON();
  if (!SD.isFile("raw_data1.txt")){
    SD.OFF();
    return;
  }
  SD.OFF();

  // Configure GPRS Connection
  stime = millis();
  while (!startGPRS() && ((millis() - stime) < GPRS_CONFIG_TIMEOUT)){
    //USB.println("Trying to configure GPRS...");
    delay(2000);
    if (millis() - stime < 0) stime = millis();
  }

  // If timeout, exit. if not, try to upload
  if (millis() - stime > GPRS_CONFIG_TIMEOUT){
    USB.print("GPRS config failed, mem: ");
    USB.println(freeMemory());
    PWR.reboot();
  }
  else{
    //config tcp connection
    stime = millis();
    while((millis()-stime) < TCP_CONFIG_TIMEOUT){
      if(!GPRS_Pro.configureGPRS_TCP_UDP(SINGLE_CONNECTION,NON_TRANSPARENT)){
        //USB.println("Trying TCP connection..");
        delay(3000);
      }
      else{
        break;
      }
    }

    if (millis() - stime > TCP_CONFIG_TIMEOUT){
      USB.print("TCP config failed, mem: ");
      USB.println(freeMemory());
      sendingSMS();
      PWR.reboot();
    }
    else{
      //only try opening tcp connection if config was OK.
      if (GPRS_Pro.createSocket(TCP_CLIENT, "54.235.113.108", "8081")){
        // * should be replaced by the desired IP direction and $ by the port
        //only try sending string if connected to tcp server
        USB.println("Begin sending data...");
        SD.ON();

        for (int i = 0; i < SD.numln("raw_data1.txt"); i++){
          if (GPRS_Pro.sendData(SD.catln("raw_data1.txt", i, 1))){
            successSending=1;
          }
          else{
            USB.print("Failed sending at line: ");// if one fails, then the rest are bound to fail as well.
            USB.println(i);
            successSending=0;
            break;
          }
        }

        //if any string is not sent for whatever reason, do not delete the file
        if(successSending==1){  
          /* ToDo:
           	Get cell tower details and upload them separately
           */

          //'bye' tells the server to end the connection on his side
          USB.println("Sending succeeded.");
          GPRS_Pro.sendData("bye");

          // Close socket
          GPRS_Pro.closeSocket();

          //after upload, delete the uploaded file
          if (SD.del("raw_data1.txt")){/* What happens if file deleting fails???? */
          }
          // Close GPRS Connection after upload
          GPRS_Pro.OFF();
        }
        SD.OFF();
      }
      else{
        USB.println("Error opening the socket"); // will simply go on but append to that file- server error
      }
    }
  }
}

//if this phase does not succeed, cellInfo will never return true
uint8_t startGPRS(){
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
  return x;
}
void sendingSMS()
{
  char message[50];
  char * tcp_errors;

  SD.ON();
  if(SD.isFile(tcp_errors_file)){
    tcp_errors=SD.catln(tcp_errors_file,0,1);

    if(SD.isFile(config_file)){

      char * max_tcp_errors=SD.catln(config_file,0,1);//first index is for tcp config max errors
      
      if(atoi(tcp_errors) % atoi(max_tcp_errors)==0){
        
        char * phone_number=SD.catln(config_file,1,1);  //second index is for phone number to send sms to
        sprintf(message,"waspmote...\n Retries: %s\n and Max set retries: %s\n",tcp_errors,max_tcp_errors);
        
        GPRS_Pro.sendSMS(message,phone_number);// USB.println("SMS Sent OK"); // * should be replaced by the desired tlfn number
      }

      char * newVal;
      sprintf(newVal,"%d",(tcp_errors++));

      //now incease the value of the errors in the tcp_errors file.
      if(SD.del(tcp_errors_file)){
        if(SD.create(tcp_errors_file)){
          if(SD.writeSD(tcp_errors_file,newVal,0)){
          } 
        }
      }
      else{
        //how come we could not delete that file?
      }  
    }
  }
  else //the first time tcp_config fails
  {
    if(SD.create(tcp_errors_file)){
      if(SD.writeSD(tcp_errors_file,"0",0)){
      } 
    }
  }
  SD.OFF();
}
