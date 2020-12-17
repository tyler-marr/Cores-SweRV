
// UART client example for the UART DPI module.
//
// Version 0.82 beta, November 2011.
//
// This example code has been tested with the OpenRISC MinSoC project,
// but should be easy to port to other platforms.
// It is designed to run without the standard C runtime library,
// so the usual printf() functions and the like are not available.

#include <stdint.h>  // For uint32_t, alternative for 32-bit systems:  typedef unsigned uint32_t;

// #include <int.h>  // For int_init() and int_add() from the MinSoC project, this is platform specific.


// --------- These definitions depend on your platform ---------

#define IN_CLK         25000000  // 25 MHz, it does not matter for the UART DPI simulation.
#define UART_BAUD_RATE 115200    // Ignored by the UART DPI simulation.

#define UART1_IRQ 2
#define UART2_IRQ 6


// This is how your processor accesses the 8-bit UART registers mapped into its memory space.
#define REG8(addr) *((volatile unsigned char *)(((uintptr_t)addr)))
static const uint32_t UART1_BASE_ADDR = 0x18000000;
static const uint32_t UART2_BASE_ADDR = 0x91000000;


// -------------------------------------------------------------

// UART registers.
#define UART_RX         (0<<3)       // In:  Receive buffer (with DLAB=0)
#define UART_TX         (0<<3)       // Out: Transmit buffer (with DLAB=0)
#define UART_DLL        (0<<3)       // Out: Divisor Latch Low (with DLAB=1)
#define UART_DLM        (1<<3)       // Out: Divisor Latch High (with DLAB=1)
#define UART_IER        (1<<3)       // Out: Interrupt Enable Register
#define UART_IIR        (2<<3)       // In:  Interrupt ID Register
#define UART_FCR        (2<<3)       // Out: FIFO Control Register
#define UART_EFR        (2<<3)       // I/O: Extended Features Register
                                     // (DLAB=1, 16C660 only)
#define UART_LCR        (3<<3)       // Out: Line Control Register
#define UART_MCR        (4<<3)       // Out: Modem Control Register
#define UART_LSR        (5<<3)       // In:  Line Status Register
#define UART_MSR        (6<<3)       // In:  Modem Status Register
#define UART_SCR        (7<<3)       // I/O: Scratch Register

// For the UART Line Status Register.
#define UART_LSR_TEMT 0x40  /* Transmitter empty */
#define UART_LSR_THRE 0x20  /* Transmit-hold-register empty */
#define UART_LSR_DR   0x01  /* Data ready to read */


// For the UART FIFO Control Register (16550 only)
#define UART_FCR_ENABLE_FIFO    0x01 /* Enable the FIFO */
#define UART_FCR_CLEAR_RCVR     0x02 /* Clear the RCVR FIFO */
#define UART_FCR_CLEAR_XMIT     0x04 /* Clear the XMIT FIFO */
#define UART_FCR_DMA_SELECT     0x08 /* For DMA applications */
#define UART_FCR_TRIGGER_MASK   0xC0 /* Mask for the FIFO trigger range */
#define UART_FCR_TRIGGER_1      0x00 /* Mask for trigger set at 1 */
#define UART_FCR_TRIGGER_4      0x40 /* Mask for trigger set at 4 */
#define UART_FCR_TRIGGER_8      0x80 /* Mask for trigger set at 8 */
#define UART_FCR_TRIGGER_14     0xC0 /* Mask for trigger set at 14 */

// For the UART Line Control Register
// Note: If the word length is 5 bits (UART_LCR_WLEN5), then setting 
//       UART_LCR_STOP will select 1.5 stop bits, not 2 stop bits.
#define UART_LCR_DLAB   0x80    /* Divisor latch access bit */
#define UART_LCR_SBC    0x40    /* Set break control */
#define UART_LCR_SPAR   0x20    /* Stick parity (?) */
#define UART_LCR_EPAR   0x10    /* Even parity select */
#define UART_LCR_PARITY 0x08    /* Parity Enable */
#define UART_LCR_STOP   0x04    /* Stop bits: 0=1 stop bit, 1= 2 stop bits */
#define UART_LCR_WLEN5  0x00    /* Wordlength: 5 bits */
#define UART_LCR_WLEN6  0x01    /* Wordlength: 6 bits */
#define UART_LCR_WLEN7  0x02    /* Wordlength: 7 bits */
#define UART_LCR_WLEN8  0x03    /* Wordlength: 8 bits */

// For the Interrupt Enable Register
#define UART_IER_MSI    0x08    /* Enable Modem status interrupt */
#define UART_IER_RLSI   0x04    /* Enable receiver line status interrupt */
#define UART_IER_THRI   0x02    /* Enable Transmitter holding register int. */
#define UART_IER_RDI    0x01    /* Enable receiver data interrupt */

// -------------------------------------------------------------
//EH1 core specfic startup

__asm (".section .text");
__asm (".global _start");
__asm ("_start:");

// Enable Caches in MRAC
__asm ("li t0, 0x5f555555");
__asm ("csrw 0x7c0, t0");

// Set stack pointer.
__asm ("la sp, STACK");

__asm ("jal main");

// Write 0xff to STDOUT for TB to termiate test.
__asm (".global _finish");
__asm ("_finish:");
__asm ("li t0, 0xd0580000");
__asm ("addi t1, zero, 0xff");
__asm ("sb t1, 0(t0)");
__asm ("beq x0, x0, _finish");
__asm (".rept 10");
__asm ("nop");
__asm (".endr");

// -------------------------------------------------------------


static void init_uart ( const uint32_t uart_base_addr )
{
    // Initialise the FIFO.
    REG8(uart_base_addr + UART_FCR) = UART_FCR_ENABLE_FIFO |
                                      UART_FCR_CLEAR_RCVR  |
                                      UART_FCR_CLEAR_XMIT  |
                                      UART_FCR_TRIGGER_4;

    // Set 8 bit char, 1 stop bit, no parity (ignored by the UART DPI module).
    REG8(uart_base_addr + UART_LCR) = UART_LCR_WLEN8 & ~(UART_LCR_STOP | UART_LCR_PARITY);

    // Set baud rate (ignored by the UART DPI module).
    const int divisor = IN_CLK/(16 * UART_BAUD_RATE);
    REG8(uart_base_addr + UART_LCR) |= UART_LCR_DLAB;
    REG8(uart_base_addr + UART_DLM) = (divisor >> 8) & 0x000000ff;
    REG8(uart_base_addr + UART_DLL) = divisor & 0x000000ff;
    REG8(uart_base_addr + UART_LCR) &= ~(UART_LCR_DLAB);
}


static void wait_for_transmit ( const uint32_t uart_base_addr )
{
    unsigned char lsr;
    
    do
    {
        lsr = REG8(uart_base_addr + UART_LSR);
    }
    while ((lsr & UART_LSR_THRE) != UART_LSR_THRE);
}


static void wait_for_recieve ( const uint32_t uart_base_addr )
{
    unsigned char lsr;
    
    do
    {
        lsr = REG8(uart_base_addr + UART_LSR);
    }
    while ((lsr & UART_LSR_DR) != UART_LSR_DR);
}

static unsigned char uart_wait_for_char( const uint32_t uart_base_addr )
{
    wait_for_recieve(uart_base_addr);
    return REG8(uart_base_addr + UART_RX);
}


static void uart_print ( const uint32_t uart_base_addr, const char * p )
{
    while ( *p != 0 )
    {
        wait_for_transmit( uart_base_addr );
        REG8(uart_base_addr + UART_TX) = *p;
        p++;
    }
}

static void uart_put ( const uint32_t uart_base_addr, const char c )
{
    wait_for_transmit( uart_base_addr );
    REG8(uart_base_addr + UART_TX) = c;
}


static void uart_1_interrupt ( void * const context )
{
    const unsigned char interrupt_id = REG8( UART1_BASE_ADDR + UART_IIR );

    if ( 0 != ( interrupt_id & 1 ) )
        uart_print( UART2_BASE_ADDR, "UART pending interrupt flag not set!\n" );
        
    const unsigned char int_number = ( interrupt_id & 14 /* 0b00001110 */ ) >> 1;

    switch ( int_number )
    {
    case 0:
        uart_print( UART2_BASE_ADDR, "UART Modem Status interrupt.\n" );
        break;
                
    case 1:
        uart_print( UART2_BASE_ADDR, "UART Transmitter Holding Register Empty interrupt.\n" );
        break;
        
    case 2:
        uart_print( UART2_BASE_ADDR, "UART Receive interrupt.\n" );
        break;

    case 6:
        uart_print( UART2_BASE_ADDR, "UART Character Timeout interrupt.\n" );
        break;
          
    default:
        uart_print( UART2_BASE_ADDR, "Invalid UART interrupt number!\n" );
        break;
    }

    
    // Read all data in the Receive FIFO.
    for ( ; ; )
    {
        const unsigned char status = REG8( UART1_BASE_ADDR + UART_LSR );
            
        if ( ! (status & 1) )
            break;

        const unsigned char c = REG8( UART1_BASE_ADDR + UART_RX );

        // Print informational messages on the UART 2.

        uart_print( UART2_BASE_ADDR, "UART received char: '" );
        
        char buffer[2];
        buffer[0] = ( c >= 32 ) ? c : '?';  // Replace all ASCII control codes with '?'.
        buffer[1] = 0;
        uart_print( UART2_BASE_ADDR, buffer );
        
        uart_print( UART2_BASE_ADDR, "'\n" );

        
        // Echo the character back to the same UART 1 interface.
        
        wait_for_transmit( UART1_BASE_ADDR );
        REG8( UART1_BASE_ADDR + UART_TX ) = c;
    }
}


int main ( void )
{
    // The simulation has 2 UARTs:
    // - UART 1 is an echo console, it echoes everything it receives back to the client.
    // - UART 2 is only used to print informational messages.

    char *str = " This was printed from within a UART programe!\n";
    char *s = str;
    while (*s++) {
        *(volatile char*)(0xd0580000) = *s;
    }

    //init_uart( UART1_BASE_ADDR );

    //REG8(UART1_BASE_ADDR + UART_LSR) = 1;

    unsigned char lsr;    
    
    //uart_print( UART1_BASE_ADDR, "Welcome to the UART 1, used as an echo terminal.\n" );

    char letter = '*';
    while (1) {

        uart_print( UART1_BASE_ADDR, "The letter recieved is [");
        letter = uart_wait_for_char(UART1_BASE_ADDR);
        uart_put( UART1_BASE_ADDR, letter );
        uart_print( UART1_BASE_ADDR, "]\n\r");

    }

    //*(volatile char*)(0xd0580000) = 0XFF;
    
    // Enable RX and TX interrupts on the UART 1. We only actually need the RX interrupt.
    REG8( UART1_BASE_ADDR + UART_IER ) = UART_IER_RDI | UART_IER_THRI;

    // Forever wait for interrupts.
    for ( ; ; )
    {
    }
}
