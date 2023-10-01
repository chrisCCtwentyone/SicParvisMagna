HEX

\Load after i2c.f file

\This file provide functions to communicate with DHT-11 temperature and humidity
\sensor.

\Define the GPIO pin to which the DHT11 is connected
11 CONSTANT DHT11
18 CONSTANT BUTTON

\Define variables to store the temperature and humidity
VARIABLE DATAS
VARIABLE TEMP_INT
VARIABLE HUMIDITY_INT
VARIABLE TEMP_KELVIN

\Defines function to prepare DHT-11 to send data
: SET-DHT11 ( -- )
    DHT11 01 CONFIGURE          \Set the pin to output
    DHT11 SET_LOW               \Set the pin to low
    4650 DELAY                  \Wait 18ms (expressed in us to use the DELAY function)
    DHT11 SET_HIGH              \Set the pin to high
    DHT11 00 CONFIGURE ;        \Set the pin to input

\Set the GPIO pin of button to input mode
: SET-BUTTON ( -- )
    BUTTON 00 CONFIGURE ;

\Defines a function that waits as long as sensor sends a low signal
\It's used to check the 80us low signal sent by the sensor to signal the start of the data
: WAIT-LOW ( -- )
    BEGIN
        DHT11 READ
        LOW =
    WHILE
    REPEAT ;

\Defines a function that waits as long as sensor sends a high signal
\It's used to check the 80us high signal sent by the sensor to signal the start of the data
: WAIT-HIGH ( -- )
    BEGIN
        DHT11 READ
        HIGH =
    WHILE
    REPEAT ;

\Gets data from DHT11
: DHT-START ( -- )
    WAIT-LOW                            \Wait for the sensor to send a low signal
    WAIT-HIGH                           \Wait for the sensor to send a high signal
    1F BEGIN                            \Until we have read 5 bytes
        DATAS DUP @ 1 LSHIFT SWAP !     \Shift the bits to the left and store the value in DATAS
        WAIT-LOW TIMER @                \Wait for the sensor to send a low signal and read the timer
        WAIT-HIGH TIMER @               \Wait for the sensor to send a high signal and read the timer
        SWAP - 32 >                     \Subtract the two timers and check if the result is greater than 32 (50us between two bits)
        IF                              \If the result is greater than 32 (50us passed between two bits)
            DATAS DUP @ 1 OR SWAP !     \Add a 1 to the DATAS variable
        THEN                            
            1 - DUP 0 >                  \Decrement the counter and check if it is greater than 0
        WHILE 
        REPEAT
        DROP ;

\Memorize the integer part of humidity
: READ-HUMIDITY-INT ( -- )
    DATAS @ 
    18 RSHIFT               \Shift the bits to the right to get the integer part of humidity
    HUMIDITY_INT ! ;

\Memorize the integer part of temperature
: READ-TEMP-INT ( -- )
    DATAS @ 
    8 RSHIFT FF AND        \Shift the bits to the right to get the integer part of temperature
    DUP DUP 13 >           \Check if the value is greater than 19
    SWAP 32 <              \Check if the value is lower than 50
    AND  .S                 \Check if the value is between 19 and 50
    IF
        TEMP_INT !         \If the value is between 19 and 50, store it in TEMP_INT
    ELSE
        DROP
    THEN ;

\Reads data from DHT11
: READ-DATA ( -- )
    READ-HUMIDITY-INT
    READ-TEMP-INT ;

\Converts the temperature from Celsius to Kelvin
: CELSIUS-TO-KELVIN ( -- )
    TEMP_INT @ 111 + TEMP_KELVIN ! ;

\Prints the humidity
: PRINT-HUMIDITY ( -- )
    DECIMAL
    ." Humidity : " HUMIDITY_INT ?  ." % " CR
    HEX ;

\Prints the temperature
: PRINT-TEMPERATURE ( -- )
    DECIMAL
    ." Temperature : " TEMP_INT ? ." ° C" CR CR 
    HEX ;

\Prints temperature in Kelvin scale
: PRINT-TEMPERATURE-KELVIN ( -- )
    DECIMAL
    ." Temperature : " TEMP_KELVIN ? ." ° K" CR CR 
    HEX ;

\Prints all
: PRINT-DATA ( -- )
    PRINT-HUMIDITY
    PRINT-TEMPERATURE
    PRINT-TEMPERATURE-KELVIN ;

\Make a measurement and print the values
: MEASURE ( -- )
    0 DATAS !
    0 TEMP_KELVIN ! 
    SET-DHT11
    DHT-START
    READ-DATA
    CELSIUS-TO-KELVIN
    PRINT-DATA ;

