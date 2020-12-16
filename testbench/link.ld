
OUTPUT_ARCH( "riscv" )
ENTRY(_start)
MEMORY
{
  insn : ORIGIN = 0x00000000, LENGTH = 0x10000
  data : ORIGIN = 0x7fffff00, LENGTH = 0x10000
}

SECTIONS
{
  .text :
  {
    *(.text*)
  } > insn
  
  .data :
  {
    . = 0x0;
    . = ALIGN(0x100);
    *(.data*)
  } > data

  .data :
  {
    . = ALIGN(0x100);
    *(.extra*)
    STACK = ALIGN(16) + 0x8000;
  } > data
}
