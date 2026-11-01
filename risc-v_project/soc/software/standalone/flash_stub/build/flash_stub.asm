
build/flash_stub.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00001197          	auipc	gp,0x1
    1004:	ce818193          	addi	gp,gp,-792 # 1ce8 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	00004117          	auipc	sp,0x4
    100c:	50810113          	addi	sp,sp,1288 # 5510 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	80c18513          	addi	a0,gp,-2036 # 14f4 <_data>
	la a1, _data
    1014:	80c18593          	addi	a1,gp,-2036 # 14f4 <_data>
	la a2, _edata
    1018:	81c18613          	addi	a2,gp,-2020 # 1504 <__bss_start>
	bgeu a1, a2, 2f
    101c:	00c5fc63          	bgeu	a1,a2,1034 <init+0x2c>
1:
	lw t0, (a0)
    1020:	00052283          	lw	t0,0(a0)
	sw t0, (a1)
    1024:	0055a023          	sw	t0,0(a1)
	addi a0, a0, 4
    1028:	00450513          	addi	a0,a0,4
	addi a1, a1, 4
    102c:	00458593          	addi	a1,a1,4
	bltu a1, a2, 1b
    1030:	fec5e8e3          	bltu	a1,a2,1020 <init+0x18>
2:

	/* Clear bss section */
	la a0, __bss_start
    1034:	81c18513          	addi	a0,gp,-2020 # 1504 <__bss_start>
	la a1, _end
    1038:	82018593          	addi	a1,gp,-2016 # 1508 <_end>
	bgeu a0, a1, 2f
    103c:	00b57863          	bgeu	a0,a1,104c <init+0x44>
1:
	sw zero, (a0)
    1040:	00052023          	sw	zero,0(a0)
	addi a0, a0, 4
    1044:	00450513          	addi	a0,a0,4
	bltu a0, a1, 1b
    1048:	feb56ce3          	bltu	a0,a1,1040 <init+0x38>

#ifndef NO_LIBC_INIT_ARRAY
	call __libc_init_array
#endif

	call main
    104c:	00c000ef          	jal	ra,1058 <main>

00001050 <mainDone>:
mainDone:
    j mainDone
    1050:	0000006f          	j	1050 <mainDone>

00001054 <_init>:


	.globl _init
_init:
    ret
    1054:	00008067          	ret

Disassembly of section .text:

00001058 <main>:
    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    1058:	f80147b7          	lui	a5,0xf8014
    105c:	0007a423          	sw	zero,8(a5) # f8014008 <__freertos_irq_stack_top+0xf800eaf8>
    1060:	00200713          	li	a4,2
    1064:	02e7a023          	sw	a4,32(a5)
    1068:	00500693          	li	a3,5
    106c:	02d7a223          	sw	a3,36(a5)
    1070:	02e7a423          	sw	a4,40(a5)
    1074:	00700713          	li	a4,7
    1078:	02e7a623          	sw	a4,44(a5)
        return *((volatile u32*) address);
    107c:	f8b0c7b7          	lui	a5,0xf8b0c
    1080:	ff87a703          	lw	a4,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
    1084:	f8b0c6b7          	lui	a3,0xf8b0c
*          not yet elapsed.
*
******************************************************************************/
    static void clint_uDelay(u32 usec, u32 hz, u32 reg){
        u32 mTimePerUsec = hz/1000000;
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    1088:	06470713          	addi	a4,a4,100
    108c:	ff86a783          	lw	a5,-8(a3) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    1090:	40f707b3          	sub	a5,a4,a5
    1094:	fe07dce3          	bgez	a5,108c <main+0x34>
 *
 * @return The availability of command buffer space (lower 16 bits of SPI buffer)
 *
 ******************************************************************************/
    static u32 spi_cmdAvailability(u32 reg){
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1098:	00010737          	lui	a4,0x10
    109c:	f8014637          	lui	a2,0xf8014
    10a0:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
#ifdef SYSTEM_SPI_2_IO_CTRL
    	if(reg == SYSTEM_SPI_2_IO_CTRL) cmdFifo_depth = SYSTEM_SPI_2_IO_PARAMETER_CMD_FIFO_DEPTH;
#endif

    	bsp_uDelay(1);
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    10a4:	10000693          	li	a3,256
    10a8:	00462783          	lw	a5,4(a2) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    10ac:	00e7f7b3          	and	a5,a5,a4
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    10b0:	fed79ce3          	bne	a5,a3,10a8 <main+0x50>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    10b4:	00010737          	lui	a4,0x10
    10b8:	f80146b7          	lui	a3,0xf8014
    10bc:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    10c0:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    10c4:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    10c8:	fe078ce3          	beqz	a5,10c0 <main+0x68>
        *((volatile u32*) address) = data;
    10cc:	000017b7          	lui	a5,0x1
    10d0:	80078793          	addi	a5,a5,-2048 # 800 <CUSTOM2+0x7a5>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    10d4:	00010737          	lui	a4,0x10
    10d8:	00f6a023          	sw	a5,0(a3)
    10dc:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    10e0:	f80146b7          	lui	a3,0xf8014
    10e4:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    10e8:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    10ec:	fe078ce3          	beqz	a5,10e4 <main+0x8c>
        *((volatile u32*) address) = data;
    10f0:	000017b7          	lui	a5,0x1
    10f4:	88078793          	addi	a5,a5,-1920 # 880 <CUSTOM2+0x825>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    10f8:	00010737          	lui	a4,0x10
    10fc:	00f6a023          	sw	a5,0(a3)
    1100:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    1104:	f80146b7          	lui	a3,0xf8014
    1108:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    110c:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    1110:	fe078ce3          	beqz	a5,1108 <main+0xb0>
        *((volatile u32*) address) = data;
    1114:	1ab00793          	li	a5,427
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1118:	00010737          	lui	a4,0x10
    111c:	00f6a023          	sw	a5,0(a3)
    1120:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    1124:	f80146b7          	lui	a3,0xf8014
    1128:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    112c:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    1130:	fe078ce3          	beqz	a5,1128 <main+0xd0>
        *((volatile u32*) address) = data;
    1134:	000017b7          	lui	a5,0x1
    1138:	80078793          	addi	a5,a5,-2048 # 800 <CUSTOM2+0x7a5>
    113c:	00f6a023          	sw	a5,0(a3)
        return *((volatile u32*) address);
    1140:	f8b0c7b7          	lui	a5,0xf8b0c
    1144:	ff87a703          	lw	a4,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
    1148:	f8b0c6b7          	lui	a3,0xf8b0c
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    114c:	06470713          	addi	a4,a4,100
    1150:	ff86a783          	lw	a5,-8(a3) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    1154:	40f707b3          	sub	a5,a4,a5
    1158:	fe07dce3          	bgez	a5,1150 <main+0xf8>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    115c:	00010737          	lui	a4,0x10
    1160:	f8014637          	lui	a2,0xf8014
    1164:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    1168:	10000693          	li	a3,256
    116c:	00462783          	lw	a5,4(a2) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1170:	00e7f7b3          	and	a5,a5,a4
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    1174:	fed79ce3          	bne	a5,a3,116c <main+0x114>
    1178:	f8b0c7b7          	lui	a5,0xf8b0c
    117c:	ff87a703          	lw	a4,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    1180:	000027b7          	lui	a5,0x2
    1184:	71078793          	addi	a5,a5,1808 # 2710 <__global_pointer$+0xa28>
    1188:	00f70733          	add	a4,a4,a5
    118c:	f8b0c6b7          	lui	a3,0xf8b0c
    1190:	ff86a783          	lw	a5,-8(a3) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    1194:	40f707b3          	sub	a5,a4,a5
    1198:	fe07dce3          	bgez	a5,1190 <main+0x138>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    119c:	00010737          	lui	a4,0x10
    11a0:	f80146b7          	lui	a3,0xf8014
    11a4:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    11a8:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    11ac:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    11b0:	fe078ce3          	beqz	a5,11a8 <main+0x150>
        *((volatile u32*) address) = data;
    11b4:	000017b7          	lui	a5,0x1
    11b8:	88078793          	addi	a5,a5,-1920 # 880 <CUSTOM2+0x825>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    11bc:	00010737          	lui	a4,0x10
    11c0:	00f6a023          	sw	a5,0(a3)
    11c4:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    11c8:	f80146b7          	lui	a3,0xf8014
    11cc:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    11d0:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    11d4:	fe078ce3          	beqz	a5,11cc <main+0x174>
        *((volatile u32*) address) = data;
    11d8:	19f00793          	li	a5,415
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    11dc:	00010737          	lui	a4,0x10
    11e0:	00f6a023          	sw	a5,0(a3)
    11e4:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    11e8:	f80146b7          	lui	a3,0xf8014
    11ec:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    11f0:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    11f4:	fe078ce3          	beqz	a5,11ec <main+0x194>
        *((volatile u32*) address) = data;
    11f8:	20000793          	li	a5,512
    11fc:	00f6a023          	sw	a5,0(a3)
        return *((volatile u32*) address);
    1200:	f8014737          	lui	a4,0xf8014
    1204:	00472783          	lw	a5,4(a4) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
        return read_u32(reg + SPI_BUFFER) >> 16;
    1208:	0107d793          	srli	a5,a5,0x10
        while(spi_rspOccupancy(reg) == 0);
    120c:	fe078ce3          	beqz	a5,1204 <main+0x1ac>
    1210:	f8b0c7b7          	lui	a5,0xf8b0c
    1214:	00072583          	lw	a1,0(a4)
    1218:	ff87a703          	lw	a4,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    121c:	000077b7          	lui	a5,0x7
    1220:	53078793          	addi	a5,a5,1328 # 7530 <__freertos_irq_stack_top+0x2020>
        return read_u32(reg + SPI_DATA);
    1224:	0ff5f593          	andi	a1,a1,255
    1228:	00f70733          	add	a4,a4,a5
    122c:	f8b0c6b7          	lui	a3,0xf8b0c
    1230:	ff86a783          	lw	a5,-8(a3) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    1234:	40f707b3          	sub	a5,a4,a5
    1238:	fe07dce3          	bgez	a5,1230 <main+0x1d8>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    123c:	00010737          	lui	a4,0x10
    1240:	f80146b7          	lui	a3,0xf8014
    1244:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    1248:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    124c:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    1250:	fe078ce3          	beqz	a5,1248 <main+0x1f0>
        *((volatile u32*) address) = data;
    1254:	000017b7          	lui	a5,0x1
    1258:	80078793          	addi	a5,a5,-2048 # 800 <CUSTOM2+0x7a5>
    125c:	00f6a023          	sw	a5,0(a3)
        return *((volatile u32*) address);
    1260:	f8b0c7b7          	lui	a5,0xf8b0c
    1264:	ff87a703          	lw	a4,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
    1268:	f8b0c6b7          	lui	a3,0xf8b0c
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    126c:	06470713          	addi	a4,a4,100
    1270:	ff86a783          	lw	a5,-8(a3) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    1274:	40f707b3          	sub	a5,a4,a5
    1278:	fe07dce3          	bgez	a5,1270 <main+0x218>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    127c:	00010737          	lui	a4,0x10
    1280:	f8014637          	lui	a2,0xf8014
    1284:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    1288:	10000693          	li	a3,256
    128c:	00462783          	lw	a5,4(a2) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1290:	00e7f7b3          	and	a5,a5,a4
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    1294:	fed79ce3          	bne	a5,a3,128c <main+0x234>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1298:	00010737          	lui	a4,0x10
    129c:	f80146b7          	lui	a3,0xf8014
    12a0:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    12a4:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    12a8:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    12ac:	fe078ce3          	beqz	a5,12a4 <main+0x24c>
        *((volatile u32*) address) = data;
    12b0:	000017b7          	lui	a5,0x1
    12b4:	88078793          	addi	a5,a5,-1920 # 880 <CUSTOM2+0x825>
    12b8:	00f6a023          	sw	a5,0(a3)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    12bc:	00010737          	lui	a4,0x10
    * @param cs 32-bit bitwise chip select setting
    * @param mid 8-bit SPI Flash Manufacturer ID.
*
******************************************************************************/
    static void spiFlash_exit4ByteAddr_(u32 spi, u32 cs, u8 mid){
        switch(mid){
    12c0:	09d00793          	li	a5,157
        return *((volatile u32*) address);
    12c4:	f80146b7          	lui	a3,0xf8014
    12c8:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    12cc:	18f58263          	beq	a1,a5,1450 <main+0x3f8>
    12d0:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    12d4:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    12d8:	fe078ce3          	beqz	a5,12d0 <main+0x278>
        *((volatile u32*) address) = data;
    12dc:	1e900793          	li	a5,489
    12e0:	00f6a023          	sw	a5,0(a3)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    12e4:	00010737          	lui	a4,0x10
        return *((volatile u32*) address);
    12e8:	f80146b7          	lui	a3,0xf8014
    12ec:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    12f0:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    12f4:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    12f8:	fe078ce3          	beqz	a5,12f0 <main+0x298>
        *((volatile u32*) address) = data;
    12fc:	000017b7          	lui	a5,0x1
    1300:	80078793          	addi	a5,a5,-2048 # 800 <CUSTOM2+0x7a5>
    1304:	00f6a023          	sw	a5,0(a3)
        return *((volatile u32*) address);
    1308:	f8b0c7b7          	lui	a5,0xf8b0c
    130c:	ff87a703          	lw	a4,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
    1310:	f8b0c6b7          	lui	a3,0xf8b0c
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    1314:	06470713          	addi	a4,a4,100
    1318:	ff86a783          	lw	a5,-8(a3) # f8b0bff8 <__freertos_irq_stack_top+0xf8b06ae8>
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    131c:	40f707b3          	sub	a5,a4,a5
    1320:	fe07dce3          	bgez	a5,1318 <main+0x2c0>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1324:	00010737          	lui	a4,0x10
    1328:	f8014637          	lui	a2,0xf8014
    132c:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    1330:	10000693          	li	a3,256
    1334:	00462783          	lw	a5,4(a2) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1338:	00e7f7b3          	and	a5,a5,a4
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    133c:	fed79ce3          	bne	a5,a3,1334 <main+0x2dc>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1340:	00010737          	lui	a4,0x10
    1344:	f80146b7          	lui	a3,0xf8014
    1348:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    134c:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    1350:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    1354:	fe078ce3          	beqz	a5,134c <main+0x2f4>
        *((volatile u32*) address) = data;
    1358:	000017b7          	lui	a5,0x1
    135c:	88078793          	addi	a5,a5,-1920 # 880 <CUSTOM2+0x825>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1360:	00010737          	lui	a4,0x10
    1364:	00f6a023          	sw	a5,0(a3)
    1368:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    136c:	f80146b7          	lui	a3,0xf8014
    1370:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    1374:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    1378:	fe078ce3          	beqz	a5,1370 <main+0x318>
        *((volatile u32*) address) = data;
    137c:	10b00793          	li	a5,267
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1380:	00010737          	lui	a4,0x10
    1384:	00f6a023          	sw	a5,0(a3)
    1388:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    138c:	f80146b7          	lui	a3,0xf8014
    1390:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    1394:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    1398:	fe078ce3          	beqz	a5,1390 <main+0x338>
        *((volatile u32*) address) = data;
    139c:	13900793          	li	a5,313
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    13a0:	00010737          	lui	a4,0x10
    13a4:	00f6a023          	sw	a5,0(a3)
    13a8:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    13ac:	f80146b7          	lui	a3,0xf8014
    13b0:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    13b4:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    13b8:	fe078ce3          	beqz	a5,13b0 <main+0x358>
        *((volatile u32*) address) = data;
    13bc:	10000793          	li	a5,256
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    13c0:	00010737          	lui	a4,0x10
    13c4:	00f6a023          	sw	a5,0(a3)
    13c8:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    13cc:	f80146b7          	lui	a3,0xf8014
    13d0:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    13d4:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    13d8:	fe078ce3          	beqz	a5,13d0 <main+0x378>
        *((volatile u32*) address) = data;
    13dc:	10000793          	li	a5,256
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    13e0:	00010737          	lui	a4,0x10
    13e4:	00f6a023          	sw	a5,0(a3)
    13e8:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        return *((volatile u32*) address);
    13ec:	f80146b7          	lui	a3,0xf8014
    13f0:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    13f4:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    13f8:	fe078ce3          	beqz	a5,13f0 <main+0x398>
        *((volatile u32*) address) = data;
    13fc:	10000793          	li	a5,256
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1400:	00010637          	lui	a2,0x10
    1404:	00f6a023          	sw	a5,0(a3)
        return *((volatile u32*) address);
    1408:	f8014737          	lui	a4,0xf8014
        spi_write(spi, 0x0B);
        spi_write(spi, flashAddress >> 16);
        spi_write(spi, flashAddress >>  8);
        spi_write(spi, flashAddress >>  0);
        spi_write(spi, 0);
        uint8_t *ram = (uint8_t *) memoryAddress;
    140c:	000206b7          	lui	a3,0x20
    1410:	fff60613          	addi	a2,a2,-1 # ffff <__freertos_irq_stack_top+0xaaef>
        *((volatile u32*) address) = data;
    1414:	20000813          	li	a6,512
        for(u32 idx = 0;idx < size;idx++){
    1418:	00070537          	lui	a0,0x70
        return *((volatile u32*) address);
    141c:	00472783          	lw	a5,4(a4) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    1420:	00c7f7b3          	and	a5,a5,a2
        while(spi_cmdAvailability(reg) == 0);
    1424:	fe078ce3          	beqz	a5,141c <main+0x3c4>
        *((volatile u32*) address) = data;
    1428:	01072023          	sw	a6,0(a4)
        return *((volatile u32*) address);
    142c:	00472783          	lw	a5,4(a4)
        return read_u32(reg + SPI_BUFFER) >> 16;
    1430:	0107d793          	srli	a5,a5,0x10
        while(spi_rspOccupancy(reg) == 0);
    1434:	fe078ce3          	beqz	a5,142c <main+0x3d4>
    1438:	00072583          	lw	a1,0(a4)
            u8 value = spi_read(spi);
            *ram++ = value;
    143c:	00168793          	addi	a5,a3,1 # 20001 <__freertos_irq_stack_top+0x1aaf1>
        return read_u32(reg + SPI_DATA);
    1440:	00b68023          	sb	a1,0(a3)
        for(u32 idx = 0;idx < size;idx++){
    1444:	02a78263          	beq	a5,a0,1468 <main+0x410>
    1448:	00078693          	mv	a3,a5
    144c:	fd1ff06f          	j	141c <main+0x3c4>
    1450:	0046a783          	lw	a5,4(a3)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1454:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    1458:	fe078ce3          	beqz	a5,1450 <main+0x3f8>
        *((volatile u32*) address) = data;
    145c:	12900793          	li	a5,297
    1460:	00f6a023          	sw	a5,0(a3)
    1464:	e81ff06f          	j	12e4 <main+0x28c>
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    1468:	00010737          	lui	a4,0x10
        return *((volatile u32*) address);
    146c:	f80146b7          	lui	a3,0xf8014
    1470:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xaaef>
    1474:	0046a783          	lw	a5,4(a3) # f8014004 <__freertos_irq_stack_top+0xf800eaf4>
    1478:	00e7f7b3          	and	a5,a5,a4
        while(spi_cmdAvailability(reg) == 0);
    147c:	fe078ce3          	beqz	a5,1474 <main+0x41c>
        *((volatile u32*) address) = data;
    1480:	000017b7          	lui	a5,0x1
	spiFlash_exit4ByteAddr(SPI, CS);
	spiFlash_f2m(SPI, CS, FLASH_APP, TMP, SIZE);
	s = (u32 *)reloc;
	d = (u32 *)IRAM;
	for (i = 0; i < 16; i++)
		d[i] = s[i];
    1484:	f9001337          	lui	t1,0xf9001
    1488:	00001737          	lui	a4,0x1
    148c:	4c478613          	addi	a2,a5,1220 # 14c4 <reloc>
    1490:	c0030313          	addi	t1,t1,-1024 # f9000c00 <__freertos_irq_stack_top+0xf8ffb6f0>
    1494:	4c478793          	addi	a5,a5,1220
    1498:	80070713          	addi	a4,a4,-2048 # 800 <CUSTOM2+0x7a5>
    149c:	00e6a023          	sw	a4,0(a3)
    14a0:	04060613          	addi	a2,a2,64
    14a4:	40f305b3          	sub	a1,t1,a5
    14a8:	0007a683          	lw	a3,0(a5)
    14ac:	00f58733          	add	a4,a1,a5
    14b0:	00478793          	addi	a5,a5,4
    14b4:	00d72023          	sw	a3,0(a4)
	for (i = 0; i < 16; i++)
    14b8:	fef618e3          	bne	a2,a5,14a8 <main+0x450>
    14bc:	0000100f          	fence.i
	asm volatile(".word 0x0000100F");
	((void (*)(void))IRAM)();
    14c0:	00030067          	jr	t1

000014c4 <reloc>:
	asm volatile(
    14c4:	00020537          	lui	a0,0x20
    14c8:	000015b7          	lui	a1,0x1
    14cc:	00050637          	lui	a2,0x50
    14d0:	00052283          	lw	t0,0(a0) # 20000 <__freertos_irq_stack_top+0x1aaf0>
    14d4:	0055a023          	sw	t0,0(a1) # 1000 <_start>
    14d8:	00450513          	addi	a0,a0,4
    14dc:	00458593          	addi	a1,a1,4
    14e0:	ffc60613          	addi	a2,a2,-4 # 4fffc <__freertos_irq_stack_top+0x4aaec>
    14e4:	fe0616e3          	bnez	a2,14d0 <reloc+0xc>
    14e8:	0000100f          	fence.i
    14ec:	000012b7          	lui	t0,0x1
    14f0:	00028067          	jr	t0 # 1000 <_start>
