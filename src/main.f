HEX

\Load after temphum.f

\This file is the main file of the program. It contains the main loop and the
\functions to change the mode of the system.

\ Creates constant for 2 seconds delay.
1E8480 CONSTANT 2SECONDS

\The systems can switch between CLEAR (0), CELSIUS (1), KELVIN (2).
VARIABLE MODE 

\Change mode of the system.
: CHANGE-MODE ( -- )
    MODE @ 1 + 3 MOD MODE ! ;

\ Welcome quote to start the program.
: QUOTE ( -- )
    CLEAR_LCD
    RH_LINE1
    S" Sic Parvis Magna " PRINT-STRING
    RH_LINE2
    2SECONDS DELAY 
    CLEAR_LCD
    RH_LINE1
    S" Waiting for "        PRINT-STRING
    2SECONDS DELAY
    RH_LINE2
    S" the Launch... "       PRINT-STRING ; 

\Setup the system to work. 
: SETUP ( -- )
    INIT_I2C        \ Initializes the I2C interface
    INIT_LCD        \ Initializes the LCD
    SET-BUTTON
    QUOTE ;

: WORK-CELSIUS ( -- )
    MEASURE        \ Measures the temperature and humidity
    DATA-CELSIUS ; \ Prints the temperature in Celsius and humidity in %

: WORK-KELVIN ( -- )
    MEASURE         \ Measures the temperature and humidity
    DATA-KELVIN ;   \ Prints the temperature in Kelvin and humidity in %

: LAUNCH ( -- ) 
    BEGIN
        2SECONDS DELAY BUTTON READ  \ Waits for 2 seconds and reads the button
        IF                          \ If the button is pressed
            CHANGE-MODE             \ Changes the mode
        THEN                        
        MODE @ 1 =                  \ If the mode is Celsius
        IF                          \ Then
            WORK-CELSIUS            \ Work in Celsius
        ELSE                        \ Else if
        MODE @ 2 =
        IF 
            WORK-KELVIN             \ Work in Kelvin
        ELSE
            CLEAR_LCD
        THEN
        THEN
    AGAIN ; 
            




