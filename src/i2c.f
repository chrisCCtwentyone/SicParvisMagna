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


