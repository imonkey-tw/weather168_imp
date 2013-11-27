imp.configure("Weather168", [], []);

imp.enableblinkup(false);

imp.setpowersave(true);

/* Basic code to read temperature from BMP085 & BMP180 device via I2C */
// BMP085 and BMP180 Temperature Reader

//-----------------------------------------------------------------------------------------
class Pressure_BMP180 {
    // Data Members
    //   i2c parameters
    i2cPort = null;
    i2cAddress = null;
    oversampling_setting = 2; // 0=lowest precision/least power, 3=highest precision/most power
    //   calibration coefficients
    ac1 = 0;
	ac2 = 0;
	ac3 = 0;
	ac4 = 0;
	ac5 = 0;
	ac6 = 0;
	b1 = 0;
	b2 = 0;
	mb = 0;
	mc = 0;
	md = 0;
    
    //-------------------
    constructor( i2c_port, i2c_address7bit ) {
        // example:   local mysensor = TempDevice_BMP085(I2C_89, 0x49);
        if(i2c_port == I2C_12)
        {
            // Configure I2C bus on pins 1 & 2
            hardware.configure(I2C_12);
            hardware.i2c12.configure(CLOCK_SPEED_100_KHZ);
            i2cPort = hardware.i2c12;
        }
        else if(i2c_port == I2C_89)
        {
            // Configure I2C bus on pins 8 & 9
            hardware.configure(I2C_89);
            hardware.i2c89.configure(CLOCK_SPEED_100_KHZ);
            i2cPort = hardware.i2c89;
        }
        else
        {
            server.log("Invalid I2C port " + i2c_port + " specified in Pressure_BMP180::constructor.");
        }

        // To communicate with the device, the datasheet wants the 7 bit address + 1 bit for direction,
        // which can be left at 0 since one of the forums says the I2C always sets the last bit to the 
        // appropriate value 1/0 for read/write. We accout for the 1 bit by bitshifting <<1.
        // So, specify i2c_address7bit=0x49, and the code will use: i2cAddress= 1001001 0 = 0b1001.0010 = 0x92
        i2cAddress = (i2c_address7bit << 1);
        
        read_calibration_data();
    }

    function read_uint_register( register_address ) {
        // read two bytes from i2c device and converts it to a short  (2 byte) unsigned int.
        // register_address is MSB in format "\xAA"
    
        //local reg_dataMSB = i2cPort.read(i2cAddress, "\xB0", 1);
        //local reg_dataLSB = i2cPort.read(i2cAddress, "\xB1", 1);
        //server.log( "MSB(B0)=" + (reg_dataMSB[0] & 0xFF) + " LSB(B1)=" + (reg_dataLSB[0] & 0xFF) );
    
        // This command reads 2 bytes.  If register_address=0xAA then
        //         register 0xAA goes into reg_data[0]
        //         register 0xAB goes into reg_data[1]
        local reg_data = i2cPort.read(i2cAddress, register_address, 2);
        local output_int = ((reg_data[0] & 0xFF) << 8) | (reg_data[1] & 0xFF);
        // data sheet says that 0x0 and 0xffff denote bad reads. Can check integrity for looking for these values.
        if (output_int == null || output_int==0x0 || output_int == 0xffff){
            server.log( "ERROR: bad I2C return value" + reg_data + " from address " + register_address );
        }
        
        //server.log( "reg_data[0]=" + reg_data[0] + " reg_data[1]=" + reg_data[1] );
        return output_int;
    }

    function read_int_register( register_address ) {
        // read two bytes from i2c device and converts it to a short (2 byte) signed int.
        // register_address is MSB in format "\xAA"
        local reg_data = i2cPort.read(i2cAddress, register_address, 2);
        local output_int = ((reg_data[0] & 0xFF) << 8) | (reg_data[1] & 0xFF);
        // Is negative value? Convert from 2's complement:
        if (reg_data[0] & 0x80) {
            output_int = (0xffff ^ output_int) + 1;
            output_int *= -1;
        }
        // data sheet says that 0x0 and 0xffff denote bad reads. Can check integrity for looking for these values.
        if (output_int == null || output_int==0x0 || output_int == 0xffff){
            server.log( "ERROR: bad I2C return value" + reg_data + " from address " + register_address );
            //server.sleepfor(2); // puts the Imp into DEEP SLEEP, powering it down for 5 seconds. when it wakes, it re-downloads its firmware and starts over.
        }
        return output_int;
    }

    //-------------------
    function read_calibration_data() {
        // The BMP085 has 11 words of calibration data that the factor stores on
        //    the device's EEprom. Each device has different coefficients that need to be
        //    read at power up.
        // all values are signed SHORT, except where noted
        ac1 = read_int_register("\xAA");
        ac2 = read_int_register("\xAC");
	    ac3 = read_int_register("\xAE");
	    ac4 = read_uint_register("\xB0"); // needs to be unsigned short
	    ac5 = read_uint_register("\xB2"); // needs to be unsigned short
	    ac6 = read_uint_register("\xB4"); // needs to be unsigned short
	    b1  = read_int_register("\xB6");
	    b2  = read_int_register("\xB8");
	    mb  = read_int_register("\xBA");
	    mc  = read_int_register("\xBC");
	    md  = read_int_register("\xBE");
        
        /*
        server.log( "Finished cal reading ac1=" + ac1 + " and ac2=" + ac2 );
        server.log( "Finished cal reading ac3=" + ac3 + " and ac4=" + ac4 );
        server.log( "Finished cal reading ac5=" + ac5 + " and ac6=" + ac6 );
        server.log( "Finished cal reading b1=" + b1 + " and b2=" + b2 );
        server.log( "Finished cal reading mb=" + mb + " and mc=" + mc + " and md=" + md );
        */
    }   
    
    //-------------------
    function read_temperature_Celsius() {
        
        // to write to our i2c device this we need to mask the last bit into a 1.
        i2cPort.write(i2cAddress | 0x01, "\xF4\x2E" ); // write 0x2E into register 0xF4
        // Wait for conversion to finish. datasheet wants 4.5ms, we double it:
        imp.sleep(0.01);
     
        // Read msb and lsb
        local ut = read_int_register("\xF6");
        //server.log( "Reading UT=" + ut );
        
        // Calculate calibrated temperature:
        // Code is derived from http://forums.electricimp.com/discussion/736/bmp085-sensor-i2c#Item_5        
        //   or datasheet page 13
	    local x1 = (ut - ac6) * ac5 >> 15;
	    local x2 = (mc << 11) / (x1 + md);        
        local temp = ((x1 + x2 + 8) >> 4)*0.1;
        return temp;
    }

    //-------------------
    function read_pressure_kilopascal() {
        // Returns the atmospheric pressure in kilopascals.
        // note!: the datasheet suggests the device uses the previous temperature reading for this,
        //    so do a read_temp_Celsius() before a pressure reading.
            
        // ----  Do TEMPERATURE conversion ----
        // to do this we need to mask the last bit into a 1.
        i2cPort.write(i2cAddress | 0x01, "\xF4\x2E" ); // write 0x2E into register 0xF4
        // Wait for conversion to finish. datasheet wants 4.5ms, we double it:
        imp.sleep(0.01);
        local ut = read_int_register("\xF6");
        // Calculate calibrated temperature:
        local x1 = (ut - ac6) * ac5 >> 15;
	    local x2 = (mc << 11) / (x1 + md);        
        local b5 = x1 + x2;
    	//local temperature = ((b5 + 8) >> 4)*0.1;

    	//calculate true pressure
	    local b6 = b5 - 4000;
	    x1 = (b2 * (b6 * b6 >> 12)) >> 11; 
	    x2 = (ac2 * b6) >> 11;
	    local x3 = x1 + x2;
	    local b3 = (((ac1 * 4 + x3)<<oversampling_setting) + 2) >> 2;
	    x1 = ac3 * b6 >> 13;
	    x2 = (b1 * (b6 * b6 >> 12)) >> 16;
	    x3 = ((x1 + x2) + 2) >> 2;
		local b4 = (ac4 * (x3 + 32768)) >> 15;

        // to write to our i2c device this we need to mask the last bit into a 1.
        // write 0x34+(oversampling_setting<<6) into register 0xF4
        i2cPort.write(i2cAddress | 0x01, format("%c%c", 0xF4, 0x34+(oversampling_setting<<6) ) ); 
        // Wait for conversion to finish. datasheet wants 4.5ms, we double it:
        imp.sleep(0.01*oversampling_setting+0.01);
        local reg_data = i2cPort.read(i2cAddress, "\xF6", 3);
        local up = ( ((reg_data[0] & 0xFF) << 16) | ((reg_data[1] & 0xFF) << 8) | (reg_data[2]&0xFF) )
                    >> (8-oversampling_setting);
	    local b7 = (up - b3) * (50000 >> oversampling_setting);
	    local p = b7 < 0x80000000 ? (b7 * 2) / b4 : (b7 / b4) * 2;
	    x1 = (p >> 8) * (p >> 8);
	    x1 = (x1 * 3038) >> 16;
	    x2 = (-7357 * p) >> 16;
        
	    local pressure = p + ((x1 + x2 + 3791) >> 4);  // pascals
        return pressure / 1000.;  // kilopascals
    }
    
}

//end BMP180---------------------------------------------------------------

//Illuminace_BH1750
function BH1750(){
const BH1750Address = 0x23 ; //0x23 7bits I2C address
const Resolution1Lx =0x10 ;
BH1750 <- hardware.i2c89 ;
BH1750.configure(CLOCK_SPEED_100_KHZ) ;

local result_BH1750= BH1750.read(BH1750Address<<1, format("%c",Resolution1Lx), 2) ;
local Illuminace_BH1750 = ((result_BH1750[0] << 8) + result_BH1750[1]/1.2).tointeger() ;
//server.log("Illuminace_BH1750="+Illuminace_BH1750+" Lx") ;
//agent.send("Measurement_I", Illuminace_BH1750) ;
return Illuminace_BH1750 ;
}
//----------------------------------------------------------------

//Temperature_SHT20 :
function SHT20_T(){
const SHT20Address       = 0x40 ;
const TempNoHoldCmd      = 0xF3 ;
const RHumidityNoHoldCmd = 0xF5 ;
SHT20 <-hardware.i2c89 ;
SHT20.configure(CLOCK_SPEED_100_KHZ) ;

SHT20.write(SHT20Address<<1,format("%c",TempNoHoldCmd)) ;
imp.sleep(0.1) ;
local result_SHT20=SHT20.read(SHT20Address<<1,"", 2) ;
local Temperature_SHT20=-46.85 + 175.72 / 65536.0 *((result_SHT20[0]<<8)+((result_SHT20[1]>>2)<<2)).tofloat() ;
//server.log("Temperature_SHT20="+format("%.1f",Temperature_SHT20)+" C") ;
//agent.send("Measurement_T",Temperature_SHT20) ;
return Temperature_SHT20 ;
}
//----------------------------------------------------------------

//RHumidity_SHT20:
function SHT20_RH(){
const SHT20Address       = 0x40 ;
const TempNoHoldCmd      = 0xF3 ;
const RHumidityNoHoldCmd = 0xF5 ;
SHT20 <-hardware.i2c89 ;
SHT20.configure(CLOCK_SPEED_100_KHZ) ;

SHT20.write(SHT20Address<<1,format("%c",RHumidityNoHoldCmd)) ;
imp.sleep(0.1) ;
local result_SHT20=SHT20.read(SHT20Address<<1,"", 2) ;
local RHumidity_SHT20=(-6.0 + 125.0 / 65536.0 *((result_SHT20[0]<<8)+((result_SHT20[1]>>2)<<2)).tofloat()).tointeger() ;
//server.log("RHumidity_SHT20="+RHumidity_SHT20+" %") ;
//agent.send("Measurement_RH",RHumidity_SHT20) ;
return RHumidity_SHT20 ;
}

//----------------------------------------------------------------

local BMP180 = Pressure_BMP180(I2C_89, 0x77);


imp.onidle(function() {

//Measurement Temperature_SHT20  :
agent.send("Temperature_SHT20",SHT20_T()) ;

//Measurement RHumidity_SHT20  :
agent.send("RHumidity_SHT20",SHT20_RH()) ;

//Measurement Illuminace_BH1750  :
agent.send("Illuminace_BH1750",BH1750()) ;

//Measurement Pressure_BMP180  :
agent.send("Pressure_BMP180",  BMP180.read_pressure_kilopascal()) ;

//Measurement Temperature_BMP180 :
agent.send("Temperature_BMP180" , BMP180.read_temperature_Celsius()) ;

//Measurement the imp power-supply voltage :
agent.send("Power_supply_voltage",hardware.voltage()) ;

server.sleepfor(60 - (time() % 60)) ;

});
