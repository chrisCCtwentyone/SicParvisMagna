\ Annotation has been removed from this file to expedite processing.

: '\n' 10 ;
: BL 32 ;
: ':' [ CHAR : ] LITERAL ;
: ';' [ CHAR ; ] LITERAL ;
: '(' [ CHAR ( ] LITERAL ;
: ')' [ CHAR ) ] LITERAL ;
: '"' [ CHAR " ] LITERAL ;
: 'A' [ CHAR A ] LITERAL ;
: '0' [ CHAR 0 ] LITERAL ;
: '-' [ CHAR - ] LITERAL ;
: '.' [ CHAR . ] LITERAL ;
: ( IMMEDIATE 1 BEGIN KEY DUP '(' = IF DROP 1+ ELSE ')' = IF 1- THEN THEN DUP 0= UNTIL DROP ;
: SPACES ( n -- ) BEGIN DUP 0> WHILE SPACE 1- REPEAT DROP ;
: WITHIN -ROT OVER <= IF > IF TRUE ELSE FALSE THEN ELSE 2DROP FALSE THEN ;
: ALIGNED ( c-addr -- a-addr ) 3 + 3 INVERT AND ;
: ALIGN HERE @ ALIGNED HERE ! ;
: C, HERE @ C! 1 HERE +! ;
: S" IMMEDIATE ( -- addr len )
	STATE @ IF
		' LITS , HERE @ 0 ,
		BEGIN KEY DUP '"'
                <> WHILE C, REPEAT
		DROP DUP HERE @ SWAP - 4- SWAP ! ALIGN
	ELSE
		HERE @
		BEGIN KEY DUP '"'
                <> WHILE OVER C! 1+ REPEAT
		DROP HERE @ - HERE @ SWAP
	THEN
;
: ." IMMEDIATE ( -- )
	STATE @ IF
		[COMPILE] S" ' TELL ,
	ELSE
		BEGIN KEY DUP '"' = IF DROP EXIT THEN EMIT AGAIN
	THEN
;
: DICT WORD FIND ;
: VALUE ( n -- ) WORD CREATE DOCOL , ' LIT , , ' EXIT , ;
: TO IMMEDIATE ( n -- )
        DICT >DFA 4+
	STATE @ IF ' LIT , , ' ! , ELSE ! THEN
;
: +TO IMMEDIATE
        DICT >DFA 4+
	STATE @ IF ' LIT , , ' +! , ELSE +! THEN
;
: ID. 4+ COUNT F_LENMASK AND BEGIN DUP 0> WHILE SWAP COUNT EMIT SWAP 1- REPEAT 2DROP ;
: ?HIDDEN 4+ C@ F_HIDDEN AND ;
: ?IMMEDIATE 4+ C@ F_IMMED AND ;
: WORDS LATEST @ BEGIN ?DUP WHILE DUP ?HIDDEN NOT IF DUP ID. SPACE THEN @ REPEAT CR ;
: FORGET DICT DUP @ LATEST ! HERE ! ;
: CFA> LATEST @ BEGIN ?DUP WHILE 2DUP SWAP < IF NIP EXIT THEN @ REPEAT DROP 0 ;
: SEE
	DICT HERE @ LATEST @
	BEGIN 2 PICK OVER <> WHILE NIP DUP @ REPEAT
	DROP SWAP ':' EMIT SPACE DUP ID. SPACE
	DUP ?IMMEDIATE IF ." IMMEDIATE " THEN
	>DFA BEGIN 2DUP
        > WHILE DUP @ CASE
		' LIT OF 4 + DUP @ . ENDOF
		' LITS OF [ CHAR S ] LITERAL EMIT '"' EMIT SPACE
			4 + DUP @ SWAP 4 + SWAP 2DUP TELL '"' EMIT SPACE + ALIGNED 4 -
		ENDOF
		' 0BRANCH OF ." 0BRANCH ( " 4 + DUP @ . ." ) " ENDOF
		' BRANCH OF ." BRANCH ( " 4 + DUP @ . ." ) " ENDOF
		' ' OF [ CHAR ' ] LITERAL EMIT SPACE 4 + DUP @ CFA> ID. SPACE ENDOF
		' EXIT OF 2DUP 4 + <> IF ." EXIT " THEN ENDOF
		DUP CFA> ID. SPACE
	ENDCASE 4 + REPEAT
	';' EMIT CR 2DROP
;
: :NONAME 0 0 CREATE HERE @ DOCOL , ] ;
: ['] IMMEDIATE ' LIT , ;
: EXCEPTION-MARKER RDROP 0 ;
: CATCH ( xt -- exn? ) DSP@ 4+ >R ' EXCEPTION-MARKER 4+ >R EXECUTE ;
: THROW ( n -- ) ?DUP IF
	RSP@ BEGIN DUP R0 4-
        < WHILE DUP @ ' EXCEPTION-MARKER 4+
		= IF 4+ RSP! DUP DUP DUP R> 4- SWAP OVER ! DSP! EXIT THEN
	4+ REPEAT DROP
	CASE
		0 1- OF ." ABORTED" CR ENDOF
		." UNCAUGHT THROW " DUP . CR
	ENDCASE QUIT THEN
;
: ABORT ( -- ) 0 1- THROW ;
: PRINT-STACK-TRACE
	RSP@ BEGIN DUP R0 4-
        < WHILE DUP @ CASE
		' EXCEPTION-MARKER 4+ OF ." CATCH ( DSP=" 4+ DUP @ U. ." ) " ENDOF
		DUP CFA> ?DUP IF 2DUP ID. [ CHAR + ] LITERAL EMIT SWAP >DFA 4+ - . THEN
	ENDCASE 4+ REPEAT DROP CR
;
: BINARY ( -- ) 2 BASE ! ;
: OCTAL ( -- ) 8 BASE ! ;
: 2# BASE @ 2 BASE ! WORD NUMBER DROP SWAP BASE ! ;
: 8# BASE @ 8 BASE ! WORD NUMBER DROP SWAP BASE ! ;
: # ( b -- n ) BASE @ SWAP BASE ! WORD NUMBER DROP SWAP BASE ! ;
: UNUSED ( -- n ) PAD HERE @ - 4/ ;
: WELCOME
	S" TEST-MODE" FIND NOT IF
		." JONESFORTH VERSION " VERSION . CR
		UNUSED . ." CELLS REMAINING" CR
		." OK "
	THEN
;
WELCOME
HIDE WELCOME
HEX

3F000000 CONSTANT PERI_BASE    \ Base address of peripherals
3F200000 CONSTANT GPIO_BASE    \ Base address of GPIO peripheral
GPIO_BASE CONSTANT GPFSEL       \ GPIO Function Select
GPIO_BASE 1C + CONSTANT GPSET   \ GPIO Pin Output Set
GPIO_BASE 28 + CONSTANT GPCLR   \ GPIO Pin Output Clear
GPIO_BASE 34 + CONSTANT GPLEV   \ GPIO Pin Level
3000      CONSTANT TIMER_OFFSET \ Offset for the System Timer
PERI_BASE TIMER_OFFSET + 04 + CONSTANT TIMER \ Creates constant for the System Timer Counter Lower bits.

VARIABLE LAST_TIME \ Creates variabile to store last time read.

00          CONSTANT LOW \ Creates constant for LOW bit value.

01          CONSTANT HIGH \ Creates constant for HIGH bit value.

00          CONSTANT INPUT \ Creates constant for input function.

01          CONSTANT OUTPUT \ Creates constant for output function.

04          CONSTANT ALT0   \ Creates constant for alternate function 0.

\ Multiplies a number (hex) by 4 (shifts left by 2) to refer to word offsets of GPIO registers
: >WORD ( n -- word ) 
2 LSHIFT ;

\ Returns GPFSEL register address for a given GPIO pin (hex)
: GPFSEL_ADDR ( pin -- addr )
0A / 
>WORD GPIO_BASE + ;

\ Returns GPSET register address for a given GPIO pin.
: GPSET_ADDR ( gpio_pin_number -- gpio_pin_address )
    20 /                                     \ GPSET register number
    >WORD GPSET + ;

\ Returns GPCLR register address for a given GPIO pin.
: GPCLR_ADDR ( gpio_pin_number -- gpio_pin_address )
    20 /                                     \ GPCLR register number
    >WORD GPCLR + ;

\ Returns GPLEV register address for a given GPIO pin.
: GPLEV_ADDR ( gpio_pin_number -- gpio_pin_address )
    20 /                                     \ GPLEV register number (word of 32 bits)
    >WORD GPLEV + ;                          \ Gets the address

\ Returns a 32 bit word with just one bit high in the proper positon for a GPIO pin.
: BIT>WORD ( gpio_pin_number -- bit_word )
    20 MOD                                   \ The result is mod 32 (0-31)
    01 SWAP LSHIFT ;                        \ Swap and shit 01 by the result of MOD obtaining all 0 except 1 position

\ Returns 0 or 1 depending on the value of the bit in a given position of a given 32 bit word.
: WORD>BIT ( bit_word bit_number -- bit_value )
    RSHIFT 01 AND ;                          

\ Copies the top of the return stack wihout affecting it
: R@ ( -- top_of_return_stack )
    R> R> TUCK >R >R ;                    

\ Creates mask for a given GPIO pin.
: MASK ( gpio_pin_number -- mask )
    0A MOD                                   \ Offset (base 10) for gpio_pin_number in GPFSEL contents
    DUP 2* +                                 \ Multiplies by 3 to get the real offset 
    07 SWAP LSHIFT INVERT ;                  \ Returns the mask (INVERT inverts bits value)

\ Sets a GPIO output high for a given GPIO pin.
: SET_HIGH ( gpio_pin_number -- )
    DUP BIT>WORD                             \ Gets the right bit position to update the contents of GPSET
    SWAP GPSET_ADDR ! ;                      \ Updates the content of GPSET

\ Sets a GPIO output low for a given GPIO pin.
: SET_LOW ( gpio_pin_number -- )
    DUP BIT>WORD                             \ Gets the right bit position to update the contents of GPCLR
    SWAP GPCLR_ADDR ! ;                      \ Updates the contents of GPCLR


\ Returns 0 or 1 depending on the level (low or high) of a specific GPIO pin when set as input.
: READ ( gpio_pin_number -- )
    DUP GPLEV_ADDR @                              \ Gets the contents of GPLEV register
    SWAP WORD>BIT ;

\Clears specified bits of a given word and a pattern.
: BIC ( word pattern -- word_clear_bits )
    INVERT AND ;

\ Returns a configuration for a GPFSEL contents update given a functionality in 0-7 and a GPIO pin number.
\IT ONLY RETURNS, DOESNT APPLY THE CONFIGURATION
\000 = GPIO Pin is an input
\001 = GPIO Pin is an output
\100 = GPIO Pin takes alternate function 0
\101 = GPIO Pin takes alternate function 1
\110 = GPIO Pin takes alternate function 2
\111 = GPIO Pin takes alternate function 3
\011 = GPIO Pin takes alternate function 4
\010 = GPIO Pin takes alternate function 5 ;
: CONFIGURATION ( functionality_number gpio_pin_number -- configuration_for_GPFSEL )
    0A MOD                                   \ Offset (base 10) for gpio_pin_number in GPFSEL contents
    DUP 2* +                                 \ Multiplies by 3 to get the real offset
    LSHIFT ;                                 \ Return the content to update pin's functionality 



\ Configures a specific functionality for a GPFSEL given its number and the functionality in 0-7.
\001 = GPIO Pin is an output
\100 = GPIO Pin takes alternate function 0
\101 = GPIO Pin takes alternate function 1
\110 = GPIO Pin takes alternate function 2
\111 = GPIO Pin takes alternate function 3
\011 = GPIO Pin takes alternate function 4
\010 = GPIO Pin takes alternate function 5 ;
: CONFIGURE ( gpio_pin_number functionality_number -- )
    SWAP DUP GPFSEL_ADDR >R                  \ Gets GPFSEL register address and stores in the return stack
    DUP MASK                                 \ Gets the mask for gpio_pin_number
    R@ @ AND                                 \ Cleans up the GPFSEL register contents for gpio_pin_number fetching the value of address stored in return stack
    -ROT CONFIGURATION OR                    \ Updates the contents to set up the functionality
    R> ! ;                                   \ Stores the new value in the GPFSEL register address

\ Starts the timer by storing the time read in LAST_TIME.
\ Usage: TIMER START
: START ( timer_address -- )
    @ LAST_TIME ! ;                 \ Stores the time read

\ Stops the timer by subtracting the time stored in LAST_TIME to the current time.
\ Usage: TIMER STOP
: STOP ( timer_address -- time_in_us )
    @ LAST_TIME @ - ;               \ Gets the time passed

\ Delays by a certain amount of time.
: DELAY ( delay_amount_in_us -- )
    TIMER START 
    BEGIN 
        DUP        
        TIMER STOP                  \ Gets the time passed
        <                           \ Checks if the time passed is less than the delay amount
    UNTIL DROP ;

\Load file after utils.f
HEX

\ BSC1 (Broadcom serial control 1) is the reference master, masters 2 and 7 aren't accessible for the user. 
804000 CONSTANT BSC1      \ Base address of BSC1 register

\This offsets are relative to the base address of BSC1 register.
\See BCM2711 ARM Peripherals for more details.
BSC1 PERI_BASE +             CONSTANT CTRL
BSC1 PERI_BASE + 04 +        CONSTANT STATUS
BSC1 PERI_BASE + 08 +        CONSTANT DLEN
BSC1 PERI_BASE + 0C +        CONSTANT SLAVE
BSC1 PERI_BASE + 10 +        CONSTANT FIFO
BSC1 PERI_BASE + 14 +        CONSTANT DIV
BSC1 PERI_BASE + 18 +        CONSTANT DEL
BSC1 PERI_BASE + 1C +        CONSTANT CLKT

\Set slave address
: SET_SLAVE ( addr -- )
  SLAVE ! ;

\Set amount of data bytes to be transmitted
: SET_DLEN ( n -- )
  DLEN ! ;

\Set FIFO data in 8 bits at time to transmit on the bus
: APPEND_FIFO ( n -- )
  FIFO ! ;

\Reset CTRL register without changing reserved bits.
\Reserved bits are bits 31:16, 14:11, 6, and 3:1 (see BCM2711 ARM Peripherals);
: RESET_CTRL ( -- )
  CTRL @ 87B1 BIC CTRL ! ;

\Reset STATUS register without changing reserved bits.
\Reserved bits are 31:10 (see BCM2711 ARM Peripherals);
\Use 302 because other bits are read-only flags. 9 is CLKT, 8 is ERR, 1 is DONE.
\Set bits at 1 because they are cleared by writing 1 to them.
: RESET_STATUS ( -- )
  STATUS @ 302 OR STATUS ! ;

\Clear FIFO register without changing reserved bits.
\Sets bits 5:4 of CTRL register to X1 or 1X to clear before the new frame starts.
: CLEAR_FIFO ( -- )
  CTRL @ 10 OR CTRL ! ;

\Set the CTRL register to start the transmission.
\Need to set all bits to 0 except 15 (I2CEN) to enable the BSC controller;
\and 7 (TA) to start the transmission.
\Interrupts are disabled.
: TRANSFER ( -- )
  CTRL @ 8080 OR CTRL ! ;

\Transfers the data through the I2C bus.
\The data is sent in 8 bits at time.
: >I2C
  RESET_STATUS
  RESET_CTRL
  CLEAR_FIFO
  01 SET_DLEN
  APPEND_FIFO
  TRANSFER ;

\Set up I2C bus and slave address.
\Use GPIO pin 2 for Serial Data (SDA) and pin 3 for Serial Clock (SCL). This functions
\are defined on respective ALT0 function of the pins.
\My LCD address, according to a I2C scan, is 0x27 so I set it as slave address.

: INIT_I2C
  02 ALT0 CONFIGURE
  03 ALT0 CONFIGURE
  27 SET_SLAVE ;

\Our data transfer structure is: D7 D6 D5 D4 BL EN RW RS, to send a byte we need to divide it
\ in two parts (nibbles) and send them in two different frames followed by a combination of
\ BL EN RW RS bits. The first frame is the most significant nibble and the second frame is
\ the least significant nibble.
\If a byte is a part of a command (RS = 0) then RW is 0 and EN is 1. And the transfer is obtained
\by sending: HIGH 1 1 0 0 -> HIGH 1 0 0 0 -> LOW 1 1 0 0 -> LOW 1 0 0 0;
\If a byte is a part of a data (RS = 1) then RW is 0 and EN is 1. And the transfer is obtained
\by sending: HIGH 1 1 0 1 -> HIGH 1 0 0 1 -> LOW 1 1 0 1 -> LOW 1 0 0 1;
\RW is always 0 because we are writing to the LCD display.

\Define a word that returns settings parts to be sent based on a truth value that indicates 
\if the byte is a part of a command or a data.
: SETTINGS ( value -- setting_1 setting_2 )
  IF 
    0C 08   \Command
  ELSE
    0D 09   \Data
  THEN ;

\Given setting_1 and setting_2 returns a nibble linked to the settings.
: COMPOSE ( setting_1 setting_2 nibble  -- nibble_setting_2 nibble_setting_1 )
  04 LSHIFT DUP \setting_1 setting_2 nibble_to_byte nibble_to_byte
  ROT OR        \setting_1 nibble_to_byte nibble_to_byte_setting_2 (OR between setting_2 and nibble_to_byte)
  -ROT OR ;     \nibble_to_byte_setting_2 nibble_to_byte_setting_1 (OR between setting_1 and nibble_to_byte)

\Returns lower nibble of a byte (LSB nibble).
: >NIBBLE ( byte -- l_nibble )
  0F AND ;

\Divides a byte in two nibbles.
: BYTE>NIBBLES ( byte -- l_nibble h_nibble )
  DUP >NIBBLE \Returns l_nibble
  SWAP 04 RSHIFT >NIBBLE ; \Returns h_nibble

\Sends a nibble to LCD display with the settings (expressed as a truth value).
: SEND_NIBBLE ( nibble value -- )
  SETTINGS ROT \setting_1 setting_2 nibble
  COMPOSE      \gets the two bites to send (nibbles aggregated with settings)
  >I2C 1000 DELAY
  >I2C 1000 DELAY ;

\Transmit input to LCD given instruction or data. 
: >LCD ( value -- )
  DUP 08 WORD>BIT >R \Stores command/data bit in R stack
  BYTE>NIBBLES R@    \Creates two nibbles from the byte
  SEND_NIBBLE R>     \Sends the first nibble (h_nibble)
  SEND_NIBBLE ;       \Sends the second nibble (l_nibble)


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

HEX

\Load this file after temphum.f

\This files provide words to work with the LCD display.

\Returns ASCII code of 0.
: '0' ( -- 0_ascii )
  [ CHAR 0 ] LITERAL ;

\Set up the LCD to 4 bits mode and turn on/off cursor and cursor position.
: INIT_LCD ( -- )
    102 >LCD        \ 4 bits mode
    10C >LCD ;       \ Turn on/off cursor and cursor position

\Clear the LCD screen.
: CLEAR_LCD ( -- )
    101 >LCD ;         \ Clear LCD screen

\Move cursor to first cell of first line. RH stands for Return Home.
: RH_LINE1 ( -- )
    102 >LCD ;         \ Move cursor to first cell of first line

\Move cursor to first cell of second line. RH stands for Return Home.
: RH_LINE2 ( -- )
    1C0 >LCD ;          \ Move cursor to first cell of second line

\Print strings on the LCD.
: PRINT-STRING ( address length -- )
    OVER + SWAP     \address_last_char+1 address_first_char
    BEGIN           \While there are chars to print
        DUP C@ >LCD \Print char at address_first_char location
        1+          \add 1 to address_first_char
        2DUP =      \are we done? String is terminated?
    UNTIL 2DROP ;   \If not, repeat. 


DECIMAL \Convert the base to decimal base.

: DEC>ASCII ( 1_digit_dec -- 1_digit_ascii )
    '0' + ; \Add 0_ascii symbol to get specific digit ascii symbol

\Print a 2 digits decimal number on the LCD.
: PRINT-DEC ( 2_digits_dec -- )
    DUP 10 / DEC>ASCII >LCD \Print first digit
    10 MOD DEC>ASCII >LCD   \Print second digit
    HEX ;  

\Print a 3 digits decimal number on the LCD.
: PRINT-DEC3 ( 3_digits_dec -- )
    DUP 100 / DEC>ASCII >LCD \Print first digit
    DUP 10 / 10 MOD DEC>ASCII >LCD \Print second digit
    10 MOD DEC>ASCII >LCD   \Print third digit
    ;

\Print the humidity value on the LCD.
: HUMID>LCD ( -- )
    RH_LINE1
    S" Humidity: " PRINT-STRING
    HUMIDITY_INT @ PRINT-DEC            
    S" % " PRINT-STRING ;

\Prints the temperature in Celsius to LCD.
: CELS>LCD ( -- )
    RH_LINE2
    S" Temp: " PRINT-STRING
    TEMP_INT @ PRINT-DEC
    223 >LCD \Print degree symbol
    S" C" PRINT-STRING ; 

\Prints the temperature in Kelvin to LCD.
: KELV>LCD ( -- )
    RH_LINE2
    S" Temp in K: " PRINT-STRING
    TEMP_KELVIN @ PRINT-DEC3
    223 >LCD \Print degree symbol
    S" K" PRINT-STRING ;

\Prints the two measures using Celsius for temperature.
: DATA-CELSIUS ( -- )
    CLEAR_LCD
    HUMID>LCD
    CELS>LCD ;

\Prints the two measures using Kelvin for temperature.
: DATA-KELVIN ( -- )
    CLEAR_LCD
    HUMID>LCD
    KELV>LCD ;


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
            




