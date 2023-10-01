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


