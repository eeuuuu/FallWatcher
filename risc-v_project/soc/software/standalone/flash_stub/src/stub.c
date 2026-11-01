#include "type.h"
#include "soc.h"
#include "bsp.h"
#include "gpio.h"
#include "spiFlash.h"

#define SPI      SYSTEM_SPI_0_IO_CTRL
#define CS       0
#define FLASH_APP 0x00390000u
#define TMP       0x00020000u
#define RUN       0x00001000u
#define SIZE      0x00050000u
#define IRAM      0xF9000C00u

__attribute__((naked, noreturn))
static void reloc(void)
{
	asm volatile(
		"lui a0, 0x20\n"
		"lui a1, 0x1\n"
		"lui a2, 0x50\n"
		"1:\n"
		"lw t0, 0(a0)\n"
		"sw t0, 0(a1)\n"
		"addi a0, a0, 4\n"
		"addi a1, a1, 4\n"
		"addi a2, a2, -4\n"
		"bnez a2, 1b\n"
		".word 0x0000100F\n"
		"lui t0, 0x1\n"
		"jalr zero, t0, 0\n"
	);
}

void main(void)
{
	u32 i;
	u32 *s;
	u32 *d;

	spiFlash_init(SPI, CS);
	spiFlash_wake(SPI, CS);
	spiFlash_exit4ByteAddr(SPI, CS);
	spiFlash_f2m(SPI, CS, FLASH_APP, TMP, SIZE);
	s = (u32 *)reloc;
	d = (u32 *)IRAM;
	for (i = 0; i < 16; i++)
		d[i] = s[i];
	asm volatile(".word 0x0000100F");
	((void (*)(void))IRAM)();
}
