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

