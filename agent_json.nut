const FEED_ID = "Feed_ID_HERE";
const API_KEY = "API_KEY_HERE";

local T =-1;//Temperature_SHT20
local RH=-1 ; //RHumidity_SHT20
local I=-1 ; // Illuminace_BH1750
local P=-1 ; //Pressure_BMP180
local Sensordata="";
local t=-1 ; //Measurement time

// Log the URLs we need
server.log("Get Temperature:" + http.agenturl() + "?sensor=T") ;
server.log("Get RHumidity:" + http.agenturl() + "?sensor=RH") ;
server.log("Get RHumidity:" + http.agenturl() + "?sensor=P") ;
server.log("Get Illuminace:" + http.agenturl() + "?sensor=I") ;
server.log("Get ALL sensors:" + http.agenturl() + "?sensor=ALL") ;

function requestHandler(request, response) {
  try {
      
    // check if the user sent sensor as a query parameter
    if ("sensor" in request.query) {
      
      if (request.query.sensor== "T" ) {
     // send a response back saying everything was OK.   
     response.send(200, "OK! "+"Temperature_SHT20="+T+"  °C") ;
     }
     
      if (request.query.sensor== "RH" ) {
     // send a response back saying everything was OK.   
     response.send(200, "OK! "+"RHumidity_SHT20="+RH+" %") ;
     }
     
      if (request.query.sensor== "I" ) {
     // send a response back saying everything was OK.   
     response.send(200, "OK! "+"Illuminace_BH1750="+I+" Lx") ;
     }
     
      if (request.query.sensor== "P" ) {
     // send a response back saying everything was OK.   
     response.send(200, "OK! "+"Pressure_BMP180="+P+" kbar") ;
     }
     
      if (request.query.sensor== "ALL" ) {
     // send a response back saying everything was OK.   
     response.send(200, http.jsonencode(Sensordata) ) ;
     }
      }
     
  } catch (ex) {
    response.send(500, "Internal Server Error: " + ex) ;
  }
}
 
// register the HTTP handler
http.onrequest(requestHandler) ;
//
//
device.on("sensordata", function(sensordata) {
Sensordata=sensordata ;   
local t_now=date() ;
t= format("%04d-%02d-%02d", t_now.year, t_now.month+1, t_now.day)+" "+format("%02d:%02d:%02d", t_now.hour, t_now.min, t_now.sec)
server.log("Measurement_time:"+t) ;
Sensordata.at<-t ;
T=  sensordata.Temperature_SHT20 ;
server.log("Temperature_SHT20="+T+"  °C") ;
RH= sensordata.RHumidity_SHT20 ;
server.log("RHumidity_SHT20="+RH+" %") ;
I= sensordata.Illuminace_BH1750 ;
server.log("Illuminace_BH1750="+I+" Lx") ;
P=  sensordata.Pressure_BMP180  ;
server.log("Pressure_BMP180="+P+" kbar") ;
 
// Set URL to your web service
local url = "https://api.xively.com/v2/feeds/" + FEED_ID + ".json" ;
 
// Set Content-Type header to json
local headers ={"X-ApiKey":API_KEY, "Content-Type": "application/json", "User-Agent":"xively-Imp-Lib/1.0"};
 
// encode data and log
  
local body = http.jsonencode({"version":"1.0.0","datastreams" : [
  {
 "id" : "Temperature_SHT20",
      "current_value" : sensordata.Temperature_SHT20 
      },
  {
 "id" : "RHumidity_SHT20",
      "current_value" : sensordata.RHumidity_SHT20
    },
  {
 "id" : "Illuminace_BH1750",
      "current_value" : sensordata.Illuminace_BH1750
    },
  { 
 "id" : "Pressure_BMP180",
      "current_value" :sensordata.Pressure_BMP180 
    },
 { 
 "id" : "Temperature_BMP180",
      "current_value" : sensordata.Temperature_BMP180 
    },
  {    
 "id" : "Power_supply_voltage",
      "current_value" : sensordata.Power_supply_voltage
    }
 ]
 
    });
    
    
 // server.log(body);
  
  // send data to your web service
http.put(url, headers, body).sendsync();
  
});


    
    
 // server.log(body);
  
  // send data to your web service
http.put(url, headers, body).sendsync();
  
});
 
