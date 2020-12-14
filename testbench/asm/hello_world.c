#include "defines.h"
#define STDOUT 		 0xd0580000
#define RV_ICCM_SADR 0xee000000
​
void whisperPutc(char c, int addr)
{
  *(volatile char*)(addr) = c;
}
​
void whisperPuts(const char* s)
{
  while (*s)
    whisperPutc(*s++, STDOUT);
}
​
__asm (".section .text");
__asm (".global _start");
__asm ("_start:");
​
// Enable Caches in MRAC
__asm ("    li x1, 0x5f555555");
__asm ("    csrw 0x7c0, x1");
​
__asm ("    jal main");
​
// Write 0xff to STDOUT for TB to termiate test.
__asm ("_finish:");
__asm ("    li x3, 0xd0580000");
__asm ("    addi x5, x0, 0xff");
__asm ("    sb x5, 0(x3)");
__asm ("    beq x0, x0, _finish");
__asm (".rept 100");
__asm ("    nop");
__asm (".endr");
​
void main()
{
  char* str = "********************************\nThis string was printed using C.\n********************************\n";
  whisperPuts(str);
  char p = 'p';
  whisperPutc(p, STDOUT+1);
  char d = *(volatile char*)(STDOUT+1);
  whisperPutc(d, STDOUT);
