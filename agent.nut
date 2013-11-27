const FEED_ID = "FEED_ID_HERE" ;
const API_KEY = "API_KEY_HERE" ;

local T =-1;//Temperature_SHT20
local RH=-1 ; //RHumidity_SHT20
local I=-1 ; // Illuminace_BH1750
local P=-1 ; //Pressure_BMP180
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
     response.send(200,t+" , "+T+" , "+RH+" , "+P+" , "+I ) ;
     }
     
     }
  } catch (ex) {
    response.send(500, "Internal Server Error: " + ex) ;
  }
}
 
// register the HTTP handler
http.onrequest(requestHandler) ;


device.on("Temperature_SHT20", function(read_T) {
T=format( "%.1f" , read_T) ;
local t_now=date() ;
t=format("%04d-%02d-%02d", t_now.year, t_now.month+1, t_now.day)+" "+format("%02d:%02d:%02d", t_now.hour, t_now.min, t_now.sec)
server.log("Measurement_time:"+t) ;

server.log("Temperature_SHT20="+T+"  °C") ;
local xively_url = "https://api.xively.com/v2/feeds/" + FEED_ID + ".csv";       //setup url for csv
//server.log(xively_url);
local body="Temperature_SHT20"+","+T ;
//server.log(body);       
local req = http.put(xively_url, {"X-ApiKey":API_KEY, "Content-Type":"text/csv", "User-Agent":"xively-Imp-Lib/1.0"}, body);     //add headers
local res = req.sendsync();         //send request
if(res.statuscode != 200) {
    server.log("error sending message: "+res.body);
    }else server.log("OK!");
  }) ; 

device.on("RHumidity_SHT20", function(read_RH) {
RH=read_RH  ;
server.log("RHumidity_SHT20="+RH+" %") ;
local xively_url = "https://api.xively.com/v2/feeds/" + FEED_ID + ".csv";       //setup url for csv
//server.log(xively_url);
local body="RHumidity_SHT20"+","+RH ;
//server.log(body);       
local req = http.put(xively_url, {"X-ApiKey":API_KEY, "Content-Type":"text/csv", "User-Agent":"xively-Imp-Lib/1.0"}, body);     //add headers
local res = req.sendsync();         //send request
if(res.statuscode != 200) {
    server.log("error sending message: "+res.body);
    }else server.log("OK!");
    }) ; 

device.on("Illuminace_BH1750", function(read_I) {
I=read_I ;
server.log("Illuminace_BH1750="+I+" Lx") ;
local xively_url = "https://api.xively.com/v2/feeds/" + FEED_ID + ".csv";       //setup url for csv
//server.log(xively_url);
local body="Illuminace_BH1750"+","+I ;
//server.log(body);       
local req = http.put(xively_url, {"X-ApiKey":API_KEY, "Content-Type":"text/csv", "User-Agent":"xively-Imp-Lib/1.0"}, body);     //add headers
local res = req.sendsync();         //send request
if(res.statuscode != 200) {
    server.log("error sending message: "+res.body);
    }else server.log("OK!");
    }) ; 
    
device.on("Pressure_BMP180", function(read_P) {
P=format( "%.2f", read_P ) ;
server.log("Pressure_BMP180="+P+" kbar") ;
local xively_url = "https://api.xively.com/v2/feeds/" + FEED_ID + ".csv" ;       //setup url for csv
//server.log(xively_url);
local body="Pressure_BMP180"+","+P ;
//server.log(body);       
local req = http.put(xively_url, {"X-ApiKey":API_KEY, "Content-Type":"text/csv", "User-Agent":"xively-Imp-Lib/1.0"}, body);     //add headers
local res = req.sendsync();         //send request
if(res.statuscode != 200) {
    server.log("error sending message: "+res.body);
    }else server.log("OK!");
        }) ; 


        
device.on("Temperature_BMP180", function(read_T) {
local T_BMP180=read_T ;
server.log("Temperature_BMP180 ="+T_BMP180+" °C") ;
local xively_url = "https://api.xively.com/v2/feeds/" + FEED_ID + ".csv" ;       //setup url for csv
//server.log(xively_url);
local body="Temperature_BMP180"+","+T_BMP180 ;
//server.log(body);       
local req = http.put(xively_url, {"X-ApiKey":API_KEY, "Content-Type":"text/csv", "User-Agent":"xively-Imp-Lib/1.0"}, body);     //add headers
local res = req.sendsync();         //send request
if(res.statuscode != 200) {
    server.log("error sending message: "+res.body) ;
    }else server.log("OK!") ;
        }) ;
        
device.on("Power_supply_voltage", function(read_V) {
local V=read_V ;
server.log("The imp power-supply voltage ="+V+" V") ;
local xively_url = "https://api.xively.com/v2/feeds/" + FEED_ID + ".csv" ;       //setup url for csv
//server.log(xively_url);
local body="Power_supply_voltage"+","+V ;
//server.log(body);       
local req = http.put(xively_url, {"X-ApiKey":API_KEY, "Content-Type":"text/csv", "User-Agent":"xively-Imp-Lib/1.0"}, body);     //add headers
local res = req.sendsync();         //send request
if(res.statuscode != 200) {
    server.log("error sending message: "+res.body);
    }else server.log("OK!");
        }) ;
 
