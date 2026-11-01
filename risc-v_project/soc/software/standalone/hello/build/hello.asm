
build/hello.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00046197          	auipc	gp,0x46
    1004:	3b818193          	addi	gp,gp,952 # 473b8 <__global_pointer$>
.global smp_lottery_target
.global smp_lottery_lock
.global smp_slave


  sw x0, smp_lottery_lock, a1
    1008:	00065597          	auipc	a1,0x65
    100c:	5c05ae23          	sw	zero,1500(a1) # 665e4 <smp_lottery_lock>

00001010 <smp_tyranny>:

smp_tyranny:
  csrr a0, mhartid
    1010:	f1402573          	csrr	a0,mhartid
  beqz a0, init
    1014:	04050663          	beqz	a0,1060 <init>

00001018 <smp_slave>:

smp_slave:
	lw a0, smp_lottery_lock
    1018:	00065517          	auipc	a0,0x65
    101c:	5cc52503          	lw	a0,1484(a0) # 665e4 <smp_lottery_lock>
	beqz a0, smp_slave
    1020:	fe050ce3          	beqz	a0,1018 <smp_slave>

	fence r, r
    1024:	0220000f          	fence	r,r
    1028:	0000100f          	fence.i
	//li a1, -1
	//amoadd.w x0, a1,(a0)

	.word(0x100F) //i$ flush
	lw a5, smp_lottery_target
    102c:	00065797          	auipc	a5,0x65
    1030:	5b47a783          	lw	a5,1460(a5) # 665e0 <smp_lottery_target>
	li a0, 0
    1034:	00000513          	li	a0,0
	li a1, 0
    1038:	00000593          	li	a1,0
	li a2, 0
    103c:	00000613          	li	a2,0
	jr a5
    1040:	00078067          	jr	a5

00001044 <smp_unlock>:

.global   smp_unlock
.type    smp_unlock,%function
smp_unlock:
	sw a0, smp_lottery_target, a1
    1044:	00065597          	auipc	a1,0x65
    1048:	58a5ae23          	sw	a0,1436(a1) # 665e0 <smp_lottery_target>
	fence w, w
    104c:	0110000f          	fence	w,w
	li a0, 1
    1050:	00100513          	li	a0,1
	sw a0, smp_lottery_lock, a1
    1054:	00065597          	auipc	a1,0x65
    1058:	58a5a823          	sw	a0,1424(a1) # 665e4 <smp_lottery_lock>
    ret
    105c:	00008067          	ret

00001060 <init>:
#endif

init:
	la sp, _sp
    1060:	00069117          	auipc	sp,0x69
    1064:	59010113          	addi	sp,sp,1424 # 6a5f0 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1068:	00005517          	auipc	a0,0x5
    106c:	5b050513          	addi	a0,a0,1456 # 6618 <_data>
	la a1, _data
    1070:	00005597          	auipc	a1,0x5
    1074:	5a858593          	addi	a1,a1,1448 # 6618 <_data>
	la a2, _edata
    1078:	84018613          	addi	a2,gp,-1984 # 46bf8 <__bss_start>
	bgeu a1, a2, 2f
    107c:	00c5fc63          	bgeu	a1,a2,1094 <init+0x34>
1:
	lw t0, (a0)
    1080:	00052283          	lw	t0,0(a0)
	sw t0, (a1)
    1084:	0055a023          	sw	t0,0(a1)
	addi a0, a0, 4
    1088:	00450513          	addi	a0,a0,4
	addi a1, a1, 4
    108c:	00458593          	addi	a1,a1,4
	bltu a1, a2, 1b
    1090:	fec5e8e3          	bltu	a1,a2,1080 <init+0x20>
2:

	/* Clear bss section */
	la a0, __bss_start
    1094:	84018513          	addi	a0,gp,-1984 # 46bf8 <__bss_start>
	la a1, _end
    1098:	00065597          	auipc	a1,0x65
    109c:	55058593          	addi	a1,a1,1360 # 665e8 <_end>
	bgeu a0, a1, 2f
    10a0:	00b57863          	bgeu	a0,a1,10b0 <init+0x50>
1:
	sw zero, (a0)
    10a4:	00052023          	sw	zero,0(a0)
	addi a0, a0, 4
    10a8:	00450513          	addi	a0,a0,4
	bltu a0, a1, 1b
    10ac:	feb56ce3          	bltu	a0,a1,10a4 <init+0x44>
2:

#ifndef NO_LIBC_INIT_ARRAY
	call __libc_init_array
    10b0:	010000ef          	jal	ra,10c0 <__libc_init_array>
#endif

	call main
    10b4:	298000ef          	jal	ra,134c <main>

000010b8 <mainDone>:
mainDone:
    j mainDone
    10b8:	0000006f          	j	10b8 <mainDone>

000010bc <_init>:


	.globl _init
_init:
    ret
    10bc:	00008067          	ret

Disassembly of section .text:

000010c0 <__libc_init_array>:
    10c0:	ff010113          	addi	sp,sp,-16
    10c4:	00812423          	sw	s0,8(sp)
    10c8:	01212023          	sw	s2,0(sp)
    10cc:	00005417          	auipc	s0,0x5
    10d0:	54c40413          	addi	s0,s0,1356 # 6618 <_data>
    10d4:	00005917          	auipc	s2,0x5
    10d8:	54490913          	addi	s2,s2,1348 # 6618 <_data>
    10dc:	40890933          	sub	s2,s2,s0
    10e0:	00112623          	sw	ra,12(sp)
    10e4:	00912223          	sw	s1,4(sp)
    10e8:	40295913          	srai	s2,s2,0x2
    10ec:	00090e63          	beqz	s2,1108 <__libc_init_array+0x48>
    10f0:	00000493          	li	s1,0
    10f4:	00042783          	lw	a5,0(s0)
    10f8:	00148493          	addi	s1,s1,1
    10fc:	00440413          	addi	s0,s0,4
    1100:	000780e7          	jalr	a5
    1104:	fe9918e3          	bne	s2,s1,10f4 <__libc_init_array+0x34>
    1108:	00005417          	auipc	s0,0x5
    110c:	51040413          	addi	s0,s0,1296 # 6618 <_data>
    1110:	00005917          	auipc	s2,0x5
    1114:	50890913          	addi	s2,s2,1288 # 6618 <_data>
    1118:	40890933          	sub	s2,s2,s0
    111c:	40295913          	srai	s2,s2,0x2
    1120:	00090e63          	beqz	s2,113c <__libc_init_array+0x7c>
    1124:	00000493          	li	s1,0
    1128:	00042783          	lw	a5,0(s0)
    112c:	00148493          	addi	s1,s1,1
    1130:	00440413          	addi	s0,s0,4
    1134:	000780e7          	jalr	a5
    1138:	fe9918e3          	bne	s2,s1,1128 <__libc_init_array+0x68>
    113c:	00c12083          	lw	ra,12(sp)
    1140:	00812403          	lw	s0,8(sp)
    1144:	00412483          	lw	s1,4(sp)
    1148:	00012903          	lw	s2,0(sp)
    114c:	01010113          	addi	sp,sp,16
    1150:	00008067          	ret

00001154 <memcpy>:
    1154:	00a5c7b3          	xor	a5,a1,a0
    1158:	0037f793          	andi	a5,a5,3
    115c:	00c508b3          	add	a7,a0,a2
    1160:	06079263          	bnez	a5,11c4 <memcpy+0x70>
    1164:	00300793          	li	a5,3
    1168:	04c7fe63          	bgeu	a5,a2,11c4 <memcpy+0x70>
    116c:	00357793          	andi	a5,a0,3
    1170:	00050713          	mv	a4,a0
    1174:	06079863          	bnez	a5,11e4 <memcpy+0x90>
    1178:	ffc8f613          	andi	a2,a7,-4
    117c:	fe060793          	addi	a5,a2,-32
    1180:	08f76c63          	bltu	a4,a5,1218 <memcpy+0xc4>
    1184:	02c77c63          	bgeu	a4,a2,11bc <memcpy+0x68>
    1188:	00058693          	mv	a3,a1
    118c:	00070793          	mv	a5,a4
    1190:	0006a803          	lw	a6,0(a3)
    1194:	00478793          	addi	a5,a5,4
    1198:	00468693          	addi	a3,a3,4
    119c:	ff07ae23          	sw	a6,-4(a5)
    11a0:	fec7e8e3          	bltu	a5,a2,1190 <memcpy+0x3c>
    11a4:	fff60793          	addi	a5,a2,-1
    11a8:	40e787b3          	sub	a5,a5,a4
    11ac:	ffc7f793          	andi	a5,a5,-4
    11b0:	00478793          	addi	a5,a5,4
    11b4:	00f70733          	add	a4,a4,a5
    11b8:	00f585b3          	add	a1,a1,a5
    11bc:	01176863          	bltu	a4,a7,11cc <memcpy+0x78>
    11c0:	00008067          	ret
    11c4:	00050713          	mv	a4,a0
    11c8:	ff157ce3          	bgeu	a0,a7,11c0 <memcpy+0x6c>
    11cc:	0005c783          	lbu	a5,0(a1)
    11d0:	00170713          	addi	a4,a4,1
    11d4:	00158593          	addi	a1,a1,1
    11d8:	fef70fa3          	sb	a5,-1(a4)
    11dc:	ff1768e3          	bltu	a4,a7,11cc <memcpy+0x78>
    11e0:	00008067          	ret
    11e4:	0005c683          	lbu	a3,0(a1)
    11e8:	00170713          	addi	a4,a4,1
    11ec:	00377793          	andi	a5,a4,3
    11f0:	fed70fa3          	sb	a3,-1(a4)
    11f4:	00158593          	addi	a1,a1,1
    11f8:	f80780e3          	beqz	a5,1178 <memcpy+0x24>
    11fc:	0005c683          	lbu	a3,0(a1)
    1200:	00170713          	addi	a4,a4,1
    1204:	00377793          	andi	a5,a4,3
    1208:	fed70fa3          	sb	a3,-1(a4)
    120c:	00158593          	addi	a1,a1,1
    1210:	fc079ae3          	bnez	a5,11e4 <memcpy+0x90>
    1214:	f65ff06f          	j	1178 <memcpy+0x24>
    1218:	0005a683          	lw	a3,0(a1)
    121c:	0045a283          	lw	t0,4(a1)
    1220:	0085af83          	lw	t6,8(a1)
    1224:	00c5af03          	lw	t5,12(a1)
    1228:	0105ae83          	lw	t4,16(a1)
    122c:	0145ae03          	lw	t3,20(a1)
    1230:	0185a303          	lw	t1,24(a1)
    1234:	01c5a803          	lw	a6,28(a1)
    1238:	02458593          	addi	a1,a1,36
    123c:	00d72023          	sw	a3,0(a4)
    1240:	ffc5a683          	lw	a3,-4(a1)
    1244:	00572223          	sw	t0,4(a4)
    1248:	01f72423          	sw	t6,8(a4)
    124c:	01e72623          	sw	t5,12(a4)
    1250:	01d72823          	sw	t4,16(a4)
    1254:	01c72a23          	sw	t3,20(a4)
    1258:	00672c23          	sw	t1,24(a4)
    125c:	01072e23          	sw	a6,28(a4)
    1260:	02470713          	addi	a4,a4,36
    1264:	fed72e23          	sw	a3,-4(a4)
    1268:	faf768e3          	bltu	a4,a5,1218 <memcpy+0xc4>
    126c:	f19ff06f          	j	1184 <memcpy+0x30>

00001270 <memset>:
    1270:	00f00313          	li	t1,15
    1274:	00050713          	mv	a4,a0
    1278:	02c37e63          	bgeu	t1,a2,12b4 <memset+0x44>
    127c:	00f77793          	andi	a5,a4,15
    1280:	0a079063          	bnez	a5,1320 <memset+0xb0>
    1284:	08059263          	bnez	a1,1308 <memset+0x98>
    1288:	ff067693          	andi	a3,a2,-16
    128c:	00f67613          	andi	a2,a2,15
    1290:	00e686b3          	add	a3,a3,a4
    1294:	00b72023          	sw	a1,0(a4)
    1298:	00b72223          	sw	a1,4(a4)
    129c:	00b72423          	sw	a1,8(a4)
    12a0:	00b72623          	sw	a1,12(a4)
    12a4:	01070713          	addi	a4,a4,16
    12a8:	fed766e3          	bltu	a4,a3,1294 <memset+0x24>
    12ac:	00061463          	bnez	a2,12b4 <memset+0x44>
    12b0:	00008067          	ret
    12b4:	40c306b3          	sub	a3,t1,a2
    12b8:	00269693          	slli	a3,a3,0x2
    12bc:	00000297          	auipc	t0,0x0
    12c0:	005686b3          	add	a3,a3,t0
    12c4:	00c68067          	jr	12(a3)
    12c8:	00b70723          	sb	a1,14(a4)
    12cc:	00b706a3          	sb	a1,13(a4)
    12d0:	00b70623          	sb	a1,12(a4)
    12d4:	00b705a3          	sb	a1,11(a4)
    12d8:	00b70523          	sb	a1,10(a4)
    12dc:	00b704a3          	sb	a1,9(a4)
    12e0:	00b70423          	sb	a1,8(a4)
    12e4:	00b703a3          	sb	a1,7(a4)
    12e8:	00b70323          	sb	a1,6(a4)
    12ec:	00b702a3          	sb	a1,5(a4)
    12f0:	00b70223          	sb	a1,4(a4)
    12f4:	00b701a3          	sb	a1,3(a4)
    12f8:	00b70123          	sb	a1,2(a4)
    12fc:	00b700a3          	sb	a1,1(a4)
    1300:	00b70023          	sb	a1,0(a4)
    1304:	00008067          	ret
    1308:	0ff5f593          	andi	a1,a1,255
    130c:	00859693          	slli	a3,a1,0x8
    1310:	00d5e5b3          	or	a1,a1,a3
    1314:	01059693          	slli	a3,a1,0x10
    1318:	00d5e5b3          	or	a1,a1,a3
    131c:	f6dff06f          	j	1288 <memset+0x18>
    1320:	00279693          	slli	a3,a5,0x2
    1324:	00000297          	auipc	t0,0x0
    1328:	005686b3          	add	a3,a3,t0
    132c:	00008293          	mv	t0,ra
    1330:	fa0680e7          	jalr	-96(a3)
    1334:	00028093          	mv	ra,t0
    1338:	ff078793          	addi	a5,a5,-16
    133c:	40f70733          	sub	a4,a4,a5
    1340:	00f60633          	add	a2,a2,a5
    1344:	f6c378e3          	bgeu	t1,a2,12b4 <memset+0x44>
    1348:	f3dff06f          	j	1284 <memset+0x14>

0000134c <main>:
        live_img[i] = (int8_t)((int)p - 128);
    }
}

void main()
{
    134c:	e6010113          	addi	sp,sp,-416
    1350:	18112e23          	sw	ra,412(sp)
    1354:	18812c23          	sw	s0,408(sp)
    1358:	18912a23          	sw	s1,404(sp)
    135c:	19212823          	sw	s2,400(sp)
    1360:	19312623          	sw	s3,396(sp)
    1364:	19412423          	sw	s4,392(sp)
    1368:	19512223          	sw	s5,388(sp)
    136c:	19612023          	sw	s6,384(sp)
    1370:	17712e23          	sw	s7,380(sp)
    1374:	17812c23          	sw	s8,376(sp)
    1378:	17912a23          	sw	s9,372(sp)
    137c:	17a12823          	sw	s10,368(sp)
    1380:	17b12623          	sw	s11,364(sp)
    uint32_t n, t0, dt, seq;
    int pd_sticky, pd_miss, empty_cnt, lp, lp_prev, nobox_cnt;
    int have_prev;
    uint32_t last_lp_tx;

    csr_write(mstatus, 0);
    1384:	30005073          	csrwi	mstatus,0
    csr_write(mie, 0);
    1388:	30405073          	csrwi	mie,0

    bsp_printf("pdti8 selftest start\r\n");
    138c:	00047537          	lui	a0,0x47
    1390:	9f450513          	addi	a0,a0,-1548 # 469f4 <CSWTCH.112+0x94>
    1394:	054030ef          	jal	ra,43e8 <bsp_printf>
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    1398:	f8b0c437          	lui	s0,0xf8b0c
    139c:	ff842783          	lw	a5,-8(s0) # f8b0bff8 <__freertos_irq_stack_top+0xf8aa1a08>
    t0 = clint_getTimeLow(SYSTEM_CLINT_CTRL);
    pdti8_run(pd_img_person, &person, &nop);
    13a0:	0000a537          	lui	a0,0xa
    13a4:	0d310613          	addi	a2,sp,211
    13a8:	0d210593          	addi	a1,sp,210
    13ac:	8c050513          	addi	a0,a0,-1856 # 98c0 <pd_img_person>
    13b0:	189040ef          	jal	ra,5d38 <pdti8_run>
    dt = clint_getTimeLow(SYSTEM_CLINT_CTRL) - t0;
    bsp_printf("static person p=%d n=%d\r\n", (int)person, (int)nop);
    13b4:	0d310603          	lb	a2,211(sp)
    13b8:	0d210583          	lb	a1,210(sp)
    13bc:	ff842783          	lw	a5,-8(s0)
    13c0:	00047537          	lui	a0,0x47
    13c4:	a0c50513          	addi	a0,a0,-1524 # 46a0c <CSWTCH.112+0xac>
    13c8:	020030ef          	jal	ra,43e8 <bsp_printf>
    if (person > nop)
    13cc:	0d210703          	lb	a4,210(sp)
    13d0:	0d310783          	lb	a5,211(sp)
    13d4:	3ce7d8e3          	bge	a5,a4,1fa4 <main+0xc58>
        bsp_printf("static person OK\r\n");
    13d8:	00047537          	lui	a0,0x47
    13dc:	a2850513          	addi	a0,a0,-1496 # 46a28 <CSWTCH.112+0xc8>
    13e0:	008030ef          	jal	ra,43e8 <bsp_printf>
    else
        bsp_printf("static person FAIL\r\n");
    (void)dt;

    pdti8_run(pd_img_noperson, &person, &nop);
    13e4:	00007537          	lui	a0,0x7
    13e8:	0d310613          	addi	a2,sp,211
    13ec:	0d210593          	addi	a1,sp,210
    13f0:	4c050513          	addi	a0,a0,1216 # 74c0 <pd_img_noperson>
    13f4:	145040ef          	jal	ra,5d38 <pdti8_run>
    bsp_printf("static noperson p=%d n=%d %s\r\n",
    13f8:	0d210583          	lb	a1,210(sp)
    13fc:	0d310603          	lb	a2,211(sp)
    1400:	38c5cce3          	blt	a1,a2,1f98 <main+0xc4c>
    1404:	000476b7          	lui	a3,0x47
    1408:	9ec68693          	addi	a3,a3,-1556 # 469ec <CSWTCH.112+0x8c>
    140c:	00047537          	lui	a0,0x47
    1410:	a5450513          	addi	a0,a0,-1452 # 46a54 <CSWTCH.112+0xf4>
    1414:	7d5020ef          	jal	ra,43e8 <bsp_printf>
               (int)person, (int)nop,
               (person < nop) ? "OK" : "FAIL");

    t3_track_init();
    1418:	58c030ef          	jal	ra,49a4 <t3_track_init>
    person = 0;
    nop = 0;
    voice_hold = 0;
    last_lp_tx = 0;
    idle_arm = 0;
    bsp_printf("voice UART J7-38/37 + I2C mux J7-39/40\r\n");
    141c:	00047537          	lui	a0,0x47
    1420:	a7450513          	addi	a0,a0,-1420 # 46a74 <CSWTCH.112+0x114>
    idle_arm = 0;
    1424:	8a01a823          	sw	zero,-1872(gp) # 46c68 <idle_arm>
    person = 0;
    1428:	0c010923          	sb	zero,210(sp)
    nop = 0;
    142c:	0c0109a3          	sb	zero,211(sp)
    bsp_printf("voice UART J7-38/37 + I2C mux J7-39/40\r\n");
    1430:	7b9020ef          	jal	ra,43e8 <bsp_printf>
    {
        int vself = 0;
        voice_hold = 0;
        vself = voice_update(4);
        if (vself)
            bsp_printf("voice selftest OK\r\n");
    1434:	00047537          	lui	a0,0x47
    1438:	aa050513          	addi	a0,a0,-1376 # 46aa0 <CSWTCH.112+0x140>
    143c:	7ad020ef          	jal	ra,43e8 <bsp_printf>
        else
            bsp_printf("voice selftest FAIL\r\n");
        voice_hold = 0;
    1440:	8a01a623          	sw	zero,-1876(gp) # 46c64 <voice_hold>
    1444:	00100793          	li	a5,1
    1448:	04f12e23          	sw	a5,92(sp)
    144c:	000477b7          	lui	a5,0x47
    1450:	96078793          	addi	a5,a5,-1696 # 46960 <CSWTCH.112>
    1454:	0cf12623          	sw	a5,204(sp)
    1458:	000067b7          	lui	a5,0x6
    145c:	6a878793          	addi	a5,a5,1704 # 66a8 <_data+0x90>
    1460:	0af12e23          	sw	a5,188(sp)
    1464:	0004f7b7          	lui	a5,0x4f
    1468:	48078d93          	addi	s11,a5,1152 # 4f480 <thumb>
        uint32_t x1 = b1 & 0x7ff, y1 = (b1 >> 16) & 0x7ff;
        uint32_t x0b = b2 & 0x7ff, y0b = (b2 >> 16) & 0x7ff;
        uint32_t x1b = b3 & 0x7ff, y1b = (b3 >> 16) & 0x7ff;
        uint32_t vv = read_u32(GRAY_VOICE);
        uint32_t lpr = read_u32(GRAY_LP);
        uint32_t vtrk = vv & 0xffff;
    146c:	000107b7          	lui	a5,0x10
    1470:	fff78793          	addi	a5,a5,-1 # ffff <pd_w26+0x353f>
    1474:	08f12c23          	sw	a5,152(sp)
    1478:	000027b7          	lui	a5,0x2
    147c:	40078793          	addi	a5,a5,1024 # 2400 <send_tcp+0x28c>
    1480:	0af12223          	sw	a5,164(sp)
        t_ms = clint_getTimeLow(SYSTEM_CLINT_CTRL) / (SYSTEM_CLINT_HZ / 1000u);
        has_thumb = 1;
        t3_make_thumb(gray_now, thumb);
        t3_send_event(seq, t_ms, (uint8_t)code, (uint8_t)score,
                      (uint8_t)pd_on, (uint8_t)pd_sc, (uint8_t)sht, (uint8_t)ta, (uint8_t)to,
                      (uint8_t)lp, (uint16_t)fr, (uint16_t)(dt / (SYSTEM_CLINT_HZ / 1000u)),
    1484:	000187b7          	lui	a5,0x18
    1488:	6a078793          	addi	a5,a5,1696 # 186a0 <pd_w26+0xbbe0>
    148c:	0af12c23          	sw	a5,184(sp)
        http_set_status(evt_name(code), (int)score, (int)pd_on, (int)pd_sc, lp,
                        (int)sht, (int)ta, (int)to, ntrk,
                        (int)(dt / (SYSTEM_CLINT_HZ / 1000u)),
                        (int)x0, (int)y0, (int)x1, (int)y1, voice);
        if (has_thumb)
            http_set_thumb(thumb, T3_THUMB_N);
    1490:	000017b7          	lui	a5,0x1
    1494:	90078793          	addi	a5,a5,-1792 # 900 <CUSTOM2+0x8a5>
    last_lp_tx = 0;
    1498:	0c012023          	sw	zero,192(sp)
    nobox_cnt = 0;
    149c:	08012a23          	sw	zero,148(sp)
    lp_prev = 0;
    14a0:	00000b13          	li	s6,0
    pd_miss = 0;
    14a4:	0c012423          	sw	zero,200(sp)
    pd_sticky = 0;
    14a8:	00000d13          	li	s10,0
    seq = 0;
    14ac:	06012c23          	sw	zero,120(sp)
            http_set_thumb(thumb, T3_THUMB_N);
    14b0:	0cf12223          	sw	a5,196(sp)
        http_poll();
    14b4:	4b0010ef          	jal	ra,2964 <http_poll>
    14b8:	f81007b7          	lui	a5,0xf8100
    14bc:	0047a703          	lw	a4,4(a5) # f8100004 <__freertos_irq_stack_top+0xf8095a14>
    14c0:	0087aa83          	lw	s5,8(a5)
    14c4:	00c7a503          	lw	a0,12(a5)
    14c8:	06e12a23          	sw	a4,116(sp)
    14cc:	0147a403          	lw	s0,20(a5)
        uint32_t mot = (ev >> 4) & 1;
    14d0:	00455593          	srli	a1,a0,0x4
    14d4:	0015f593          	andi	a1,a1,1
    14d8:	0187a483          	lw	s1,24(a5)
    14dc:	0307ac03          	lw	s8,48(a5)
    14e0:	0347ae83          	lw	t4,52(a5)
    14e4:	0247a703          	lw	a4,36(a5)
    14e8:	02c7a983          	lw	s3,44(a5)
    14ec:	06b12823          	sw	a1,112(sp)
        uint32_t vtrk = vv & 0xffff;
    14f0:	09812583          	lw	a1,152(sp)
        uint32_t ta = (st >> 8) & 0xff;
    14f4:	008ad813          	srli	a6,s5,0x8
        uint32_t to = (st >> 16) & 0xff;
    14f8:	010ad893          	srli	a7,s5,0x10
        uint32_t vrx = (vv >> 16) & 1;
    14fc:	01075613          	srli	a2,a4,0x10
        uint32_t vsw = (vv >> 17) & 1;
    1500:	01175693          	srli	a3,a4,0x11
        uint32_t ta = (st >> 8) & 0xff;
    1504:	09012223          	sw	a6,132(sp)
        uint32_t vtrk = vv & 0xffff;
    1508:	00b77733          	and	a4,a4,a1
        uint32_t ta = (st >> 8) & 0xff;
    150c:	0ff87813          	andi	a6,a6,255
        uint32_t code = (ev >> 1) & 7;
    1510:	00155313          	srli	t1,a0,0x1
        uint32_t ta = (st >> 8) & 0xff;
    1514:	05012a23          	sw	a6,84(sp)
        uint32_t vtrk = vv & 0xffff;
    1518:	08e12023          	sw	a4,128(sp)
        uint32_t to = (st >> 16) & 0xff;
    151c:	0ff8f813          	andi	a6,a7,255
        uint32_t vrx = (vv >> 16) & 1;
    1520:	00167713          	andi	a4,a2,1
        uint32_t code = (ev >> 1) & 7;
    1524:	00737b93          	andi	s7,t1,7
        uint32_t to = (st >> 16) & 0xff;
    1528:	07012223          	sw	a6,100(sp)
        uint32_t score = st & 0xff;
    152c:	0ffaf313          	andi	t1,s5,255
        uint32_t sht = (st >> 24) & 0xff;
    1530:	018ad813          	srli	a6,s5,0x18
        uint32_t vrx = (vv >> 16) & 1;
    1534:	08e12623          	sw	a4,140(sp)
        uint32_t vsw = (vv >> 17) & 1;
    1538:	0016f713          	andi	a4,a3,1
        uint32_t x0 = b0 & 0x7ff, y0 = (b0 >> 16) & 0x7ff;
    153c:	01045913          	srli	s2,s0,0x10
        uint32_t x1 = b1 & 0x7ff, y1 = (b1 >> 16) & 0x7ff;
    1540:	0104da13          	srli	s4,s1,0x10
        uint32_t to = (st >> 16) & 0xff;
    1544:	09112423          	sw	a7,136(sp)
        fus_evt = (code == 1 || code == 3 || code == 4);
    1548:	00100793          	li	a5,1
        uint32_t score = st & 0xff;
    154c:	06612623          	sw	t1,108(sp)
        uint32_t sht = (st >> 24) & 0xff;
    1550:	05012c23          	sw	a6,88(sp)
        uint32_t vsw = (vv >> 17) & 1;
    1554:	08e12823          	sw	a4,144(sp)
        uint32_t x0 = b0 & 0x7ff, y0 = (b0 >> 16) & 0x7ff;
    1558:	7ff47413          	andi	s0,s0,2047
    155c:	7ff97913          	andi	s2,s2,2047
        uint32_t x1 = b1 & 0x7ff, y1 = (b1 >> 16) & 0x7ff;
    1560:	7ff4f493          	andi	s1,s1,2047
    1564:	7ffa7a13          	andi	s4,s4,2047
        fus_evt = (code == 1 || code == 3 || code == 4);
    1568:	10fb8c63          	beq	s7,a5,1680 <main+0x334>
    156c:	00300793          	li	a5,3
    1570:	10fb8863          	beq	s7,a5,1680 <main+0x334>
        bw = (x1 > x0) ? (x1 - x0) : 0;
    1574:	62946e63          	bltu	s0,s1,1bb0 <main+0x864>
        bh = (y1 > y0) ? (y1 - y0) : 0;
    1578:	0a012023          	sw	zero,160(sp)
    157c:	01497663          	bgeu	s2,s4,1588 <main+0x23c>
    1580:	412a07b3          	sub	a5,s4,s2
    1584:	0af12023          	sw	a5,160(sp)
        if (!fus_box && code != 4)
    1588:	00400793          	li	a5,4
    158c:	08fb9c63          	bne	s7,a5,1624 <main+0x2d8>
    1590:	06012023          	sw	zero,96(sp)
            nobox_cnt = 0;
    1594:	08012a23          	sw	zero,148(sp)
        lp = (int)(lpr & 1u);
    1598:	0019f993          	andi	s3,s3,1
        if (lp && !lp_prev)
    159c:	0a098a63          	beqz	s3,1650 <main+0x304>
    15a0:	000b1863          	bnez	s6,15b0 <main+0x264>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    15a4:	f81007b7          	lui	a5,0xf8100
    15a8:	00b00713          	li	a4,11
    15ac:	02e7a423          	sw	a4,40(a5) # f8100028 <__freertos_irq_stack_top+0xf8095a38>
    if (code == 3 || code == 4 || code == 5)
    15b0:	ffdb8793          	addi	a5,s7,-3
    15b4:	00200713          	li	a4,2
    15b8:	0af76a63          	bltu	a4,a5,166c <main+0x320>
    15bc:	00700793          	li	a5,7
        voice_hold--;
    15c0:	8af1a623          	sw	a5,-1876(gp) # 46c64 <voice_hold>
        return 1;
    15c4:	00100b13          	li	s6,1
        if (lp && !fus_box && code != 4) {
    15c8:	0e098863          	beqz	s3,16b8 <main+0x36c>
    15cc:	06012783          	lw	a5,96(sp)
    15d0:	0e079463          	bnez	a5,16b8 <main+0x36c>
    15d4:	00400c93          	li	s9,4
    15d8:	0f9b8063          	beq	s7,s9,16b8 <main+0x36c>
            t3_track_clear();
    15dc:	3ec030ef          	jal	ra,49c8 <t3_track_clear>
    15e0:	f81007b7          	lui	a5,0xf8100
    15e4:	0007a823          	sw	zero,16(a5) # f8100010 <__freertos_irq_stack_top+0xf8095a20>
        return *((volatile u32*) address);
    15e8:	f8b0c7b7          	lui	a5,0xf8b0c
    15ec:	ff87ac03          	lw	s8,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8aa1a08>
            t_ms = clint_getTimeLow(SYSTEM_CLINT_CTRL) / (SYSTEM_CLINT_HZ / 1000u);
    15f0:	0b812703          	lw	a4,184(sp)
            if ((t_ms - last_lp_tx) >= 400u) {
    15f4:	18f00793          	li	a5,399
            t_ms = clint_getTimeLow(SYSTEM_CLINT_CTRL) / (SYSTEM_CLINT_HZ / 1000u);
    15f8:	02ec5c33          	divu	s8,s8,a4
            if ((t_ms - last_lp_tx) >= 400u) {
    15fc:	0c012703          	lw	a4,192(sp)
    1600:	40ec0733          	sub	a4,s8,a4
    1604:	62e7e063          	bltu	a5,a4,1c24 <main+0x8d8>

        for (i = 0; i < T3_GRAY_N; i++)
            gray_prev[i] = gray_now[i];
        have_prev = 1;
        seq++;
        n++;
    1608:	05c12783          	lw	a5,92(sp)
        lp = (int)(lpr & 1u);
    160c:	00098b13          	mv	s6,s3
    1610:	00178793          	addi	a5,a5,1
    1614:	04f12e23          	sw	a5,92(sp)
    1618:	e9dff06f          	j	14b4 <main+0x168>
        bh = (y1 > y0) ? (y1 - y0) : 0;
    161c:	f74962e3          	bltu	s2,s4,1580 <main+0x234>
    1620:	0a012023          	sw	zero,160(sp)
            nobox_cnt++;
    1624:	09412783          	lw	a5,148(sp)
            pd_sticky = 0;
    1628:	00200713          	li	a4,2
    162c:	06012023          	sw	zero,96(sp)
            nobox_cnt++;
    1630:	00178793          	addi	a5,a5,1
    1634:	08f12a23          	sw	a5,148(sp)
            pd_sticky = 0;
    1638:	00f727b3          	slt	a5,a4,a5
    163c:	0017c793          	xori	a5,a5,1
    1640:	40f007b3          	neg	a5,a5
        lp = (int)(lpr & 1u);
    1644:	0019f993          	andi	s3,s3,1
            pd_sticky = 0;
    1648:	00fd7d33          	and	s10,s10,a5
        if (lp && !lp_prev)
    164c:	f4099ae3          	bnez	s3,15a0 <main+0x254>
        if (!lp && lp_prev)
    1650:	f60b00e3          	beqz	s6,15b0 <main+0x264>
        *((volatile u32*) address) = data;
    1654:	f81007b7          	lui	a5,0xf8100
    1658:	00c00713          	li	a4,12
    165c:	02e7a423          	sw	a4,40(a5) # f8100028 <__freertos_irq_stack_top+0xf8095a38>
    if (code == 3 || code == 4 || code == 5)
    1660:	ffdb8793          	addi	a5,s7,-3
    1664:	00200713          	li	a4,2
    1668:	f4f77ae3          	bgeu	a4,a5,15bc <main+0x270>
    if (voice_hold > 0) {
    166c:	8ac1a783          	lw	a5,-1876(gp) # 46c64 <voice_hold>
    return 0;
    1670:	00000b13          	li	s6,0
    if (voice_hold > 0) {
    1674:	f4f05ae3          	blez	a5,15c8 <main+0x27c>
    1678:	fff78793          	addi	a5,a5,-1
    167c:	f45ff06f          	j	15c0 <main+0x274>
        bw = (x1 > x0) ? (x1 - x0) : 0;
    1680:	f8947ee3          	bgeu	s0,s1,161c <main+0x2d0>
        bh = (y1 > y0) ? (y1 - y0) : 0;
    1684:	f9497ee3          	bgeu	s2,s4,1620 <main+0x2d4>
    1688:	412a07b3          	sub	a5,s4,s2
    168c:	0af12023          	sw	a5,160(sp)
        bw = (x1 > x0) ? (x1 - x0) : 0;
    1690:	40848733          	sub	a4,s1,s0
        fus_box = fus_evt && (bw > 80) && (bh > 40);
    1694:	05000793          	li	a5,80
    1698:	f8e7f6e3          	bgeu	a5,a4,1624 <main+0x2d8>
    169c:	0a012703          	lw	a4,160(sp)
    16a0:	02800793          	li	a5,40
    16a4:	eee7f2e3          	bgeu	a5,a4,1588 <main+0x23c>
    16a8:	00100793          	li	a5,1
    16ac:	06f12023          	sw	a5,96(sp)
            nobox_cnt = 0;
    16b0:	08012a23          	sw	zero,148(sp)
    16b4:	ee5ff06f          	j	1598 <main+0x24c>
    16b8:	000507b7          	lui	a5,0x50
    16bc:	0004d737          	lui	a4,0x4d
    16c0:	d8078c93          	addi	s9,a5,-640 # 4fd80 <gray_now>
    16c4:	08070713          	addi	a4,a4,128 # 4d080 <live_img>
                last_lp_tx = t_ms;
    16c8:	d8078613          	addi	a2,a5,-640
    16cc:	f81016b7          	lui	a3,0xf8101
        return *((volatile u32*) address);
    16d0:	0006a783          	lw	a5,0(a3) # f8101000 <__freertos_irq_stack_top+0xf8096a10>
        gray_now[i] = (uint8_t)p;
    16d4:	00170713          	addi	a4,a4,1
    16d8:	00468693          	addi	a3,a3,4
    16dc:	0ff7f793          	andi	a5,a5,255
        live_img[i] = (int8_t)((int)p - 128);
    16e0:	f8078593          	addi	a1,a5,-128
        gray_now[i] = (uint8_t)p;
    16e4:	00f60023          	sb	a5,0(a2)
        live_img[i] = (int8_t)((int)p - 128);
    16e8:	feb70fa3          	sb	a1,-1(a4)
    16ec:	00160613          	addi	a2,a2,1
    for (i = 0; i < T3_GRAY_N; i++) {
    16f0:	feed90e3          	bne	s11,a4,16d0 <main+0x384>
        uint32_t x0b = b2 & 0x7ff, y0b = (b2 >> 16) & 0x7ff;
    16f4:	010c5f13          	srli	t5,s8,0x10
        uint32_t x1b = b3 & 0x7ff, y1b = (b3 >> 16) & 0x7ff;
    16f8:	010edf93          	srli	t6,t4,0x10
        uint32_t box2_on = (ev >> 5) & 1;
    16fc:	00555513          	srli	a0,a0,0x5
        uint32_t x0b = b2 & 0x7ff, y0b = (b2 >> 16) & 0x7ff;
    1700:	7ffc7c13          	andi	s8,s8,2047
        uint32_t x1b = b3 & 0x7ff, y1b = (b3 >> 16) & 0x7ff;
    1704:	7ffefe93          	andi	t4,t4,2047
        nd = 0;
    1708:	0c012a23          	sw	zero,212(sp)
        uint32_t box2_on = (ev >> 5) & 1;
    170c:	00157513          	andi	a0,a0,1
        uint32_t x0b = b2 & 0x7ff, y0b = (b2 >> 16) & 0x7ff;
    1710:	7fff7f13          	andi	t5,t5,2047
        uint32_t x1b = b3 & 0x7ff, y1b = (b3 >> 16) & 0x7ff;
    1714:	7fffff93          	andi	t6,t6,2047
        bw2 = (x1b > x0b) ? (x1b - x0b) : 0;
    1718:	3ddc6863          	bltu	s8,t4,1ae8 <main+0x79c>
        bh2 = (y1b > y0b) ? (y1b - y0b) : 0;
    171c:	06a12423          	sw	a0,104(sp)
    1720:	6dff7a63          	bgeu	t5,t6,1df4 <main+0xaa8>
    1724:	41ef83b3          	sub	t2,t6,t5
        bw2 = (x1b > x0b) ? (x1b - x0b) : 0;
    1728:	00000293          	li	t0,0
        if (fus_box)
    172c:	06012783          	lw	a5,96(sp)
    1730:	3c079863          	bnez	a5,1b00 <main+0x7b4>
        if (box2_vis && (bw2 > 40) && (bh2 > 20))
    1734:	06812783          	lw	a5,104(sp)
    1738:	4c079c63          	bnez	a5,1c10 <main+0x8c4>
            t3_track_clear();
    173c:	28c030ef          	jal	ra,49c8 <t3_track_clear>
            ntrk = 0;
    1740:	00000c13          	li	s8,0
    1744:	f8b0c7b7          	lui	a5,0xf8b0c
            pdti8_run(live_img, &person, &nop);
    1748:	0004d737          	lui	a4,0x4d
    174c:	08070513          	addi	a0,a4,128 # 4d080 <live_img>
    1750:	ff87a703          	lw	a4,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8aa1a08>
    1754:	0d310613          	addi	a2,sp,211
    1758:	0d210593          	addi	a1,sp,210
    175c:	06e12e23          	sw	a4,124(sp)
    1760:	5d8040ef          	jal	ra,5d38 <pdti8_run>
    1764:	f8b0c7b7          	lui	a5,0xf8b0c
                int pd = (int)person - (int)nop;
    1768:	0d210683          	lb	a3,210(sp)
    176c:	0d310603          	lb	a2,211(sp)
    1770:	ff87af83          	lw	t6,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8aa1a08>
            dt = clint_getTimeLow(SYSTEM_CLINT_CTRL) - t0;
    1774:	07c12703          	lw	a4,124(sp)
                if (pd >= 20) {
    1778:	01300793          	li	a5,19
                int pd = (int)person - (int)nop;
    177c:	40c68f33          	sub	t5,a3,a2
            dt = clint_getTimeLow(SYSTEM_CLINT_CTRL) - t0;
    1780:	40ef8fb3          	sub	t6,t6,a4
                if (pd >= 20) {
    1784:	3fe7c263          	blt	a5,t5,1b68 <main+0x81c>
                } else if (pd <= -30) {
    1788:	fe300793          	li	a5,-29
    178c:	0ff9f293          	andi	t0,s3,255
    1790:	64ff5e63          	bge	t5,a5,1dec <main+0xaa0>
                    pd_miss++;
    1794:	0c812783          	lw	a5,200(sp)
                        pd_sticky = 0;
    1798:	00200713          	li	a4,2
                if ((ta >= 8) && (ta <= 40) && (to <= ta + 3))
    179c:	02000593          	li	a1,32
                    pd_miss++;
    17a0:	00178793          	addi	a5,a5,1
                        pd_sticky = 0;
    17a4:	00f72733          	slt	a4,a4,a5
                    pd_miss++;
    17a8:	0cf12423          	sw	a5,200(sp)
                if ((ta >= 8) && (ta <= 40) && (to <= ta + 3))
    17ac:	05412783          	lw	a5,84(sp)
                        pd_sticky = 0;
    17b0:	fff70713          	addi	a4,a4,-1
    17b4:	00ed7d33          	and	s10,s10,a4
                if ((ta >= 8) && (ta <= 40) && (to <= ta + 3))
    17b8:	ff878793          	addi	a5,a5,-8
    17bc:	68f5e463          	bltu	a1,a5,1e44 <main+0xaf8>
    17c0:	05412783          	lw	a5,84(sp)
    17c4:	06412703          	lw	a4,100(sp)
    17c8:	07312e23          	sw	s3,124(sp)
    17cc:	00378793          	addi	a5,a5,3
    17d0:	40e7ec63          	bltu	a5,a4,1be8 <main+0x89c>
    17d4:	08012e23          	sw	zero,156(sp)
    17d8:	00000713          	li	a4,0
    17dc:	00000793          	li	a5,0
                    pd_sticky = 0;
    17e0:	00000d13          	li	s10,0
                if ((ta >= 8) && (ta <= 40) && (to <= ta + 3))
    17e4:	00000593          	li	a1,0
            if (pd < 0) pd = -pd;
    17e8:	40d60f33          	sub	t5,a2,a3
            if (pd > 127) pd = 127;
    17ec:	07f00693          	li	a3,127
    17f0:	01e6d463          	bge	a3,t5,17f8 <main+0x4ac>
    17f4:	07f00f13          	li	t5,127
        write_u32((pd_on << 8) | pd_sc, GRAY_PD);
    17f8:	00ff67b3          	or	a5,t5,a5
        *((volatile u32*) address) = data;
    17fc:	f81006b7          	lui	a3,0xf8100
    1800:	00f6a823          	sw	a5,16(a3) # f8100010 <__freertos_irq_stack_top+0xf8095a20>
        if (vcool > 0)
    1804:	8b41a783          	lw	a5,-1868(gp) # 46c6c <vcool>
    1808:	00f05663          	blez	a5,1814 <main+0x4c8>
            vcool--;
    180c:	fff78793          	addi	a5,a5,-1
    1810:	8af1aa23          	sw	a5,-1868(gp) # 46c6c <vcool>
        if (box2_vis && !lp && (int)code != 4) {
    1814:	06812783          	lw	a5,104(sp)
    1818:	2a078863          	beqz	a5,1ac8 <main+0x77c>
    181c:	07c12783          	lw	a5,124(sp)
    1820:	04079063          	bnez	a5,1860 <main+0x514>
    1824:	00400793          	li	a5,4
    1828:	50fb8663          	beq	s7,a5,1d34 <main+0x9e8>
            if (vtrk == 10)
    182c:	08012683          	lw	a3,128(sp)
            idle_arm = 0;
    1830:	8a01a823          	sw	zero,-1872(gp) # 46c68 <idle_arm>
            if (vtrk == 10)
    1834:	00a00793          	li	a5,10
    1838:	6ef68863          	beq	a3,a5,1f28 <main+0xbdc>
            else if (!said_multi) {
    183c:	8bc1a683          	lw	a3,-1860(gp) # 46c74 <said_multi>
    1840:	02069063          	bnez	a3,1860 <main+0x514>
    1844:	f81006b7          	lui	a3,0xf8100
    1848:	02f6a423          	sw	a5,40(a3) # f8100028 <__freertos_irq_stack_top+0xf8095a38>
                pose_said = 1;
    184c:	00100793          	li	a5,1
    1850:	8cf1a023          	sw	a5,-1856(gp) # 46c78 <pose_said>
                said_person = 1;
    1854:	8af1ac23          	sw	a5,-1864(gp) # 46c70 <said_person>
                vcool = 8;
    1858:	00800793          	li	a5,8
    185c:	8af1aa23          	sw	a5,-1868(gp) # 46c6c <vcool>
        for (i = 0; i < T3_GRAY_N; i++) {
    1860:	0a412683          	lw	a3,164(sp)
    1864:	000507b7          	lui	a5,0x50
    1868:	d8078793          	addi	a5,a5,-640 # 4fd80 <gray_now>
    186c:	00d786b3          	add	a3,a5,a3
        s = 0; mn = 255; mx = 0;
    1870:	00000e93          	li	t4,0
            uint32_t p = gray_now[i];
    1874:	000cc783          	lbu	a5,0(s9)
    1878:	001c8c93          	addi	s9,s9,1
            s += p;
    187c:	00fe8eb3          	add	t4,t4,a5
        for (i = 0; i < T3_GRAY_N; i++) {
    1880:	fedc9ae3          	bne	s9,a3,1874 <main+0x528>
        return *((volatile u32*) address);
    1884:	f8b0c7b7          	lui	a5,0xf8b0c
    1888:	ff87a383          	lw	t2,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8aa1a08>
    188c:	0ae12423          	sw	a4,168(sp)
        t3_make_thumb(gray_now, thumb);
    1890:	0004f7b7          	lui	a5,0x4f
    1894:	00050737          	lui	a4,0x50
    1898:	48078593          	addi	a1,a5,1152 # 4f480 <thumb>
    189c:	d8070513          	addi	a0,a4,-640 # 4fd80 <gray_now>
    18a0:	0bd12823          	sw	t4,176(sp)
    18a4:	0bf12a23          	sw	t6,180(sp)
    18a8:	0be12623          	sw	t5,172(sp)
    18ac:	0a512023          	sw	t0,160(sp)
    18b0:	06712023          	sw	t2,96(sp)
    18b4:	7cd030ef          	jal	ra,5880 <t3_make_thumb>
                      (uint8_t)lp, (uint16_t)fr, (uint16_t)(dt / (SYSTEM_CLINT_HZ / 1000u)),
    18b8:	0b812303          	lw	t1,184(sp)
    18bc:	0b412f83          	lw	t6,180(sp)
        t3_send_event(seq, t_ms, (uint8_t)code, (uint8_t)score,
    18c0:	06012383          	lw	t2,96(sp)
    18c4:	08814583          	lbu	a1,136(sp)
                      (uint8_t)lp, (uint16_t)fr, (uint16_t)(dt / (SYSTEM_CLINT_HZ / 1000u)),
    18c8:	026fdfb3          	divu	t6,t6,t1
        t3_send_event(seq, t_ms, (uint8_t)code, (uint8_t)score,
    18cc:	00100e13          	li	t3,1
    18d0:	00b12023          	sw	a1,0(sp)
    18d4:	03c12623          	sw	t3,44(sp)
    18d8:	07012e03          	lw	t3,112(sp)
    18dc:	0ac12f03          	lw	t5,172(sp)
    18e0:	0ffaf693          	andi	a3,s5,255
    18e4:	0a012283          	lw	t0,160(sp)
    18e8:	07415c83          	lhu	s9,116(sp)
    18ec:	07812a83          	lw	s5,120(sp)
    18f0:	03c12423          	sw	t3,40(sp)
    18f4:	10010e13          	addi	t3,sp,256
    18f8:	08414883          	lbu	a7,132(sp)
    18fc:	05812803          	lw	a6,88(sp)
    1900:	0a812703          	lw	a4,168(sp)
    1904:	01c12823          	sw	t3,16(sp)
    1908:	0fff7793          	andi	a5,t5,255
    190c:	000b8613          	mv	a2,s7
    1910:	00512223          	sw	t0,4(sp)
    1914:	000a8513          	mv	a0,s5
    1918:	01912423          	sw	s9,8(sp)
    191c:	09e12223          	sw	t5,132(sp)
    1920:	03612823          	sw	s6,48(sp)
    1924:	03412223          	sw	s4,36(sp)
    1928:	02912023          	sw	s1,32(sp)
    192c:	01212e23          	sw	s2,28(sp)
    1930:	00812c23          	sw	s0,24(sp)
    1934:	01812a23          	sw	s8,20(sp)
        t3_tx_settle();
    1938:	0bc12c83          	lw	s9,188(sp)
        t3_send_event(seq, t_ms, (uint8_t)code, (uint8_t)score,
    193c:	0263d5b3          	divu	a1,t2,t1
    1940:	010f9e13          	slli	t3,t6,0x10
    1944:	010e5e13          	srli	t3,t3,0x10
    1948:	01c12623          	sw	t3,12(sp)
    194c:	07f12023          	sw	t6,96(sp)
    1950:	4f1020ef          	jal	ra,4640 <t3_send_event>
            t3_send_thumb(seq, thumb);
    1954:	0004f7b7          	lui	a5,0x4f
    1958:	48078593          	addi	a1,a5,1152 # 4f480 <thumb>
    195c:	000a8513          	mv	a0,s5
    1960:	70d020ef          	jal	ra,486c <t3_send_thumb>
        t3_tx_settle();
    1964:	00c030ef          	jal	ra,4970 <t3_tx_settle>
    switch (code) {
    1968:	fffb8313          	addi	t1,s7,-1
    196c:	00400793          	li	a5,4
    1970:	06012f83          	lw	t6,96(sp)
    1974:	08412f03          	lw	t5,132(sp)
    1978:	0b012e83          	lw	t4,176(sp)
    197c:	0067ea63          	bltu	a5,t1,1990 <main+0x644>
    1980:	0cc12783          	lw	a5,204(sp)
    1984:	00231313          	slli	t1,t1,0x2
    1988:	006787b3          	add	a5,a5,t1
    198c:	0007ac83          	lw	s9,0(a5)
        http_set_status(evt_name(code), (int)score, (int)pd_on, (int)pd_sc, lp,
    1990:	07c12703          	lw	a4,124(sp)
    1994:	09c12603          	lw	a2,156(sp)
    1998:	06412883          	lw	a7,100(sp)
    199c:	05412803          	lw	a6,84(sp)
    19a0:	05812783          	lw	a5,88(sp)
    19a4:	06c12583          	lw	a1,108(sp)
    19a8:	000f0693          	mv	a3,t5
    19ac:	01f12223          	sw	t6,4(sp)
    19b0:	000c8513          	mv	a0,s9
    19b4:	01612c23          	sw	s6,24(sp)
    19b8:	01412a23          	sw	s4,20(sp)
    19bc:	00912823          	sw	s1,16(sp)
    19c0:	01212623          	sw	s2,12(sp)
    19c4:	00812423          	sw	s0,8(sp)
    19c8:	01812023          	sw	s8,0(sp)
    19cc:	09d12223          	sw	t4,132(sp)
    19d0:	07f12023          	sw	t6,96(sp)
    19d4:	4f5000ef          	jal	ra,26c8 <http_set_status>
            http_set_thumb(thumb, T3_THUMB_N);
    19d8:	0c412583          	lw	a1,196(sp)
    19dc:	0004f7b7          	lui	a5,0x4f
    19e0:	48078513          	addi	a0,a5,1152 # 4f480 <thumb>
    19e4:	731000ef          	jal	ra,2914 <http_set_thumb>
        http_poll();
    19e8:	77d000ef          	jal	ra,2964 <http_poll>
            (int)(s / T3_GRAY_N), (int)fr,
    19ec:	0a412783          	lw	a5,164(sp)
    19f0:	08412e83          	lw	t4,132(sp)
        uint32_t fr = read_u32(GRAY_FRAME) & 0xffff;
    19f4:	09812603          	lw	a2,152(sp)
        bsp_printf(
    19f8:	0d210683          	lb	a3,210(sp)
            (int)(s / T3_GRAY_N), (int)fr,
    19fc:	02fedeb3          	divu	t4,t4,a5
        uint32_t fr = read_u32(GRAY_FRAME) & 0xffff;
    1a00:	07412783          	lw	a5,116(sp)
        bsp_printf(
    1a04:	0d310703          	lb	a4,211(sp)
    1a08:	06012f83          	lw	t6,96(sp)
        uint32_t fr = read_u32(GRAY_FRAME) & 0xffff;
    1a0c:	00c7f7b3          	and	a5,a5,a2
        bsp_printf(
    1a10:	19805863          	blez	s8,1ba0 <main+0x854>
    1a14:	10015e03          	lhu	t3,256(sp)
    1a18:	11411f03          	lh	t5,276(sp)
    1a1c:	11611283          	lh	t0,278(sp)
    1a20:	05c12603          	lw	a2,92(sp)
    1a24:	00f12c23          	sw	a5,24(sp)
    1a28:	06812783          	lw	a5,104(sp)
    1a2c:	fff60313          	addi	t1,a2,-1
    1a30:	07012603          	lw	a2,112(sp)
    1a34:	00f12823          	sw	a5,16(sp)
    1a38:	08012783          	lw	a5,128(sp)
    1a3c:	02c12423          	sw	a2,40(sp)
    1a40:	06412603          	lw	a2,100(sp)
    1a44:	00f12423          	sw	a5,8(sp)
    1a48:	09012783          	lw	a5,144(sp)
    1a4c:	02c12223          	sw	a2,36(sp)
    1a50:	05412603          	lw	a2,84(sp)
    1a54:	00f12223          	sw	a5,4(sp)
    1a58:	08c12783          	lw	a5,140(sp)
    1a5c:	02c12023          	sw	a2,32(sp)
    1a60:	05812603          	lw	a2,88(sp)
    1a64:	00f12023          	sw	a5,0(sp)
    1a68:	02812623          	sw	s0,44(sp)
    1a6c:	00c12e23          	sw	a2,28(sp)
    1a70:	01d12a23          	sw	t4,20(sp)
    1a74:	01812623          	sw	s8,12(sp)
    1a78:	07c12803          	lw	a6,124(sp)
    1a7c:	09c12783          	lw	a5,156(sp)
    1a80:	06c12603          	lw	a2,108(sp)
    1a84:	04612623          	sw	t1,76(sp)
    1a88:	05f12423          	sw	t6,72(sp)
    1a8c:	04512223          	sw	t0,68(sp)
    1a90:	05e12023          	sw	t5,64(sp)
    1a94:	03c12e23          	sw	t3,60(sp)
    1a98:	03412c23          	sw	s4,56(sp)
    1a9c:	02912a23          	sw	s1,52(sp)
    1aa0:	03212823          	sw	s2,48(sp)
        seq++;
    1aa4:	07812303          	lw	t1,120(sp)
        bsp_printf(
    1aa8:	00047537          	lui	a0,0x47
    1aac:	000b0893          	mv	a7,s6
        seq++;
    1ab0:	00130313          	addi	t1,t1,1
        bsp_printf(
    1ab4:	000c8593          	mv	a1,s9
    1ab8:	aec50513          	addi	a0,a0,-1300 # 46aec <CSWTCH.112+0x18c>
        seq++;
    1abc:	06612c23          	sw	t1,120(sp)
        bsp_printf(
    1ac0:	129020ef          	jal	ra,43e8 <bsp_printf>
    1ac4:	b45ff06f          	j	1608 <main+0x2bc>
        } else if (((int)code == 0 || lp) && !box2_vis) {
    1ac8:	260b9263          	bnez	s7,1d2c <main+0x9e0>
            if (idle_arm < 8)
    1acc:	8b01a783          	lw	a5,-1872(gp) # 46c68 <idle_arm>
    1ad0:	00700693          	li	a3,7
    1ad4:	34f6de63          	bge	a3,a5,1e30 <main+0xae4>
                pose_said = 0;
    1ad8:	8c01a023          	sw	zero,-1856(gp) # 46c78 <pose_said>
                said_multi = 0;
    1adc:	8a01ae23          	sw	zero,-1860(gp) # 46c74 <said_multi>
                said_person = 0;
    1ae0:	8a01ac23          	sw	zero,-1864(gp) # 46c70 <said_person>
    1ae4:	d7dff06f          	j	1860 <main+0x514>
        bw2 = (x1b > x0b) ? (x1b - x0b) : 0;
    1ae8:	418e82b3          	sub	t0,t4,s8
        bh2 = (y1b > y0b) ? (y1b - y0b) : 0;
    1aec:	11ff6a63          	bltu	t5,t6,1c00 <main+0x8b4>
    1af0:	06a12423          	sw	a0,104(sp)
        bw2 = (x1b > x0b) ? (x1b - x0b) : 0;
    1af4:	00000393          	li	t2,0
        if (fus_box)
    1af8:	06012783          	lw	a5,96(sp)
    1afc:	c2078ce3          	beqz	a5,1734 <main+0x3e8>
            t3_add_box(dets, &nd, T3_MAX_TRK, (int)x0, (int)y0, (int)x1, (int)y1);
    1b00:	00048793          	mv	a5,s1
    1b04:	000a0813          	mv	a6,s4
    1b08:	00090713          	mv	a4,s2
    1b0c:	00040693          	mv	a3,s0
    1b10:	00400613          	li	a2,4
    1b14:	0d410593          	addi	a1,sp,212
    1b18:	0d810513          	addi	a0,sp,216
    1b1c:	0a512823          	sw	t0,176(sp)
    1b20:	0bf12623          	sw	t6,172(sp)
    1b24:	0bd12423          	sw	t4,168(sp)
    1b28:	09e12e23          	sw	t5,156(sp)
    1b2c:	06712e23          	sw	t2,124(sp)
    1b30:	2e4030ef          	jal	ra,4e14 <t3_add_box>
        if (box2_vis && (bw2 > 40) && (bh2 > 20))
    1b34:	06812783          	lw	a5,104(sp)
    1b38:	07c12383          	lw	t2,124(sp)
    1b3c:	09c12f03          	lw	t5,156(sp)
    1b40:	0a812e83          	lw	t4,168(sp)
    1b44:	0ac12f83          	lw	t6,172(sp)
    1b48:	0b012283          	lw	t0,176(sp)
    1b4c:	28079063          	bnez	a5,1dcc <main+0xa80>
            ntrk = t3_update(dets, nd, trks);
    1b50:	0d412583          	lw	a1,212(sp)
    1b54:	10010613          	addi	a2,sp,256
    1b58:	0d810513          	addi	a0,sp,216
    1b5c:	62c030ef          	jal	ra,5188 <t3_update>
    1b60:	00050c13          	mv	s8,a0
    1b64:	be1ff06f          	j	1744 <main+0x3f8>
    1b68:	00000293          	li	t0,0
                    lp = 0;
    1b6c:	06012e23          	sw	zero,124(sp)
                    pd_sticky = 1;
    1b70:	00100d13          	li	s10,1
                if ((ta >= 8) && (ta <= 40) && (to <= ta + 3))
    1b74:	05412783          	lw	a5,84(sp)
    1b78:	02000713          	li	a4,32
    1b7c:	ff878793          	addi	a5,a5,-8
    1b80:	04f77a63          	bgeu	a4,a5,1bd4 <main+0x888>
    1b84:	09a12e23          	sw	s10,156(sp)
    1b88:	0c012423          	sw	zero,200(sp)
            if (pd < 0) pd = -pd;
    1b8c:	001d7593          	andi	a1,s10,1
    1b90:	008d1793          	slli	a5,s10,0x8
    1b94:	0ffd7713          	andi	a4,s10,255
    1b98:	c40f5ae3          	bgez	t5,17ec <main+0x4a0>
    1b9c:	c4dff06f          	j	17e8 <main+0x49c>
        bsp_printf(
    1ba0:	00000f13          	li	t5,0
    1ba4:	00000e13          	li	t3,0
    1ba8:	00000293          	li	t0,0
    1bac:	e75ff06f          	j	1a20 <main+0x6d4>
        bh = (y1 > y0) ? (y1 - y0) : 0;
    1bb0:	25497863          	bgeu	s2,s4,1e00 <main+0xab4>
    1bb4:	412a0733          	sub	a4,s4,s2
        fus_box = fus_evt && (bw > 80) && (bh > 40);
    1bb8:	00400793          	li	a5,4
        bh = (y1 > y0) ? (y1 - y0) : 0;
    1bbc:	0ae12023          	sw	a4,160(sp)
        fus_box = fus_evt && (bw > 80) && (bh > 40);
    1bc0:	a6fb92e3          	bne	s7,a5,1624 <main+0x2d8>
        bw = (x1 > x0) ? (x1 - x0) : 0;
    1bc4:	408487b3          	sub	a5,s1,s0
        fus_box = fus_evt && (bw > 80) && (bh > 40);
    1bc8:	05000713          	li	a4,80
    1bcc:	acf768e3          	bltu	a4,a5,169c <main+0x350>
    1bd0:	9c1ff06f          	j	1590 <main+0x244>
                if ((ta >= 8) && (ta <= 40) && (to <= ta + 3))
    1bd4:	05412783          	lw	a5,84(sp)
    1bd8:	06412703          	lw	a4,100(sp)
    1bdc:	00378793          	addi	a5,a5,3
    1be0:	22e7f863          	bgeu	a5,a4,1e10 <main+0xac4>
    1be4:	0c012423          	sw	zero,200(sp)
    1be8:	09a12e23          	sw	s10,156(sp)
            if (pd < 0) pd = -pd;
    1bec:	001d7593          	andi	a1,s10,1
    1bf0:	008d1793          	slli	a5,s10,0x8
    1bf4:	0ffd7713          	andi	a4,s10,255
    1bf8:	be0f5ae3          	bgez	t5,17ec <main+0x4a0>
    1bfc:	bedff06f          	j	17e8 <main+0x49c>
        bh2 = (y1b > y0b) ? (y1b - y0b) : 0;
    1c00:	41ef83b3          	sub	t2,t6,t5
        box2_vis = box2_on || ((bw2 > 80) && (bh2 > 40));
    1c04:	24050c63          	beqz	a0,1e5c <main+0xb10>
        if (fus_box)
    1c08:	06012783          	lw	a5,96(sp)
    1c0c:	16079c63          	bnez	a5,1d84 <main+0xa38>
        if (box2_vis && (bw2 > 40) && (bh2 > 20))
    1c10:	02800793          	li	a5,40
    1c14:	1c57e063          	bltu	a5,t0,1dd4 <main+0xa88>
    1c18:	00100793          	li	a5,1
    1c1c:	06f12423          	sw	a5,104(sp)
    1c20:	b1dff06f          	j	173c <main+0x3f0>
                t3_send_event(seq, t_ms, (uint8_t)code, (uint8_t)score,
    1c24:	07012303          	lw	t1,112(sp)
    1c28:	07415f83          	lhu	t6,116(sp)
    1c2c:	08814e83          	lbu	t4,136(sp)
    1c30:	08414883          	lbu	a7,132(sp)
    1c34:	07812503          	lw	a0,120(sp)
    1c38:	00100e13          	li	t3,1
    1c3c:	02612423          	sw	t1,40(sp)
    1c40:	10010313          	addi	t1,sp,256
    1c44:	018ad813          	srli	a6,s5,0x18
    1c48:	0ffaf693          	andi	a3,s5,255
    1c4c:	00612823          	sw	t1,16(sp)
    1c50:	00000793          	li	a5,0
    1c54:	00000713          	li	a4,0
    1c58:	000b8613          	mv	a2,s7
    1c5c:	000c0593          	mv	a1,s8
    1c60:	01f12423          	sw	t6,8(sp)
    1c64:	01c12223          	sw	t3,4(sp)
    1c68:	01d12023          	sw	t4,0(sp)
    1c6c:	03612823          	sw	s6,48(sp)
    1c70:	02012623          	sw	zero,44(sp)
    1c74:	03412223          	sw	s4,36(sp)
    1c78:	02912023          	sw	s1,32(sp)
    1c7c:	01212e23          	sw	s2,28(sp)
    1c80:	00812c23          	sw	s0,24(sp)
    1c84:	00012a23          	sw	zero,20(sp)
    1c88:	00012623          	sw	zero,12(sp)
    1c8c:	1b5020ef          	jal	ra,4640 <t3_send_event>
                t3_tx_settle();
    1c90:	4e1020ef          	jal	ra,4970 <t3_tx_settle>
    switch (code) {
    1c94:	fffb8313          	addi	t1,s7,-1
                t3_tx_settle();
    1c98:	0bc12a83          	lw	s5,188(sp)
    1c9c:	006cea63          	bltu	s9,t1,1cb0 <main+0x964>
    1ca0:	0cc12783          	lw	a5,204(sp)
    1ca4:	00231313          	slli	t1,t1,0x2
    1ca8:	006787b3          	add	a5,a5,t1
    1cac:	0007aa83          	lw	s5,0(a5)
                http_set_status(evt_name(code), (int)score, 0, 0, 1,
    1cb0:	06412883          	lw	a7,100(sp)
    1cb4:	05412803          	lw	a6,84(sp)
    1cb8:	05812783          	lw	a5,88(sp)
    1cbc:	06c12583          	lw	a1,108(sp)
    1cc0:	00100713          	li	a4,1
    1cc4:	00000693          	li	a3,0
    1cc8:	00000613          	li	a2,0
    1ccc:	000a8513          	mv	a0,s5
    1cd0:	01612c23          	sw	s6,24(sp)
    1cd4:	01412a23          	sw	s4,20(sp)
    1cd8:	00912823          	sw	s1,16(sp)
    1cdc:	01212623          	sw	s2,12(sp)
    1ce0:	00812423          	sw	s0,8(sp)
    1ce4:	00012223          	sw	zero,4(sp)
    1ce8:	00012023          	sw	zero,0(sp)
    1cec:	1dd000ef          	jal	ra,26c8 <http_set_status>
                bsp_printf("EVT %s lp=1 voice=%d vrx=%d vsw=%d vtk=%d ms=0 n=%d\r\n",
    1cf0:	05c12783          	lw	a5,92(sp)
    1cf4:	09012703          	lw	a4,144(sp)
    1cf8:	08c12683          	lw	a3,140(sp)
    1cfc:	fff78813          	addi	a6,a5,-1
    1d00:	08012783          	lw	a5,128(sp)
    1d04:	00047537          	lui	a0,0x47
    1d08:	000b0613          	mv	a2,s6
    1d0c:	000a8593          	mv	a1,s5
    1d10:	ab450513          	addi	a0,a0,-1356 # 46ab4 <CSWTCH.112+0x154>
    1d14:	6d4020ef          	jal	ra,43e8 <bsp_printf>
                seq++;
    1d18:	07812783          	lw	a5,120(sp)
                last_lp_tx = t_ms;
    1d1c:	0d812023          	sw	s8,192(sp)
                seq++;
    1d20:	00178793          	addi	a5,a5,1
    1d24:	06f12c23          	sw	a5,120(sp)
            continue;
    1d28:	8e1ff06f          	j	1608 <main+0x2bc>
        } else if (((int)code == 0 || lp) && !box2_vis) {
    1d2c:	07c12783          	lw	a5,124(sp)
    1d30:	d8079ee3          	bnez	a5,1acc <main+0x780>
        } else if (!lp && vcool == 0) {
    1d34:	8b41a783          	lw	a5,-1868(gp) # 46c6c <vcool>
    1d38:	0c079863          	bnez	a5,1e08 <main+0xabc>
            int vx0 = (ntrk > 0) ? (int)trks[0].vx : 0;
    1d3c:	15805263          	blez	s8,1e80 <main+0xb34>
            idle_arm = 0;
    1d40:	8a01a823          	sw	zero,-1872(gp) # 46c68 <idle_arm>
            if (ntrk >= 2 && !said_multi && (int)code != 4) {
    1d44:	00100693          	li	a3,1
            int vx0 = (ntrk > 0) ? (int)trks[0].vx : 0;
    1d48:	11011783          	lh	a5,272(sp)
            if (ntrk >= 2 && !said_multi && (int)code != 4) {
    1d4c:	12dc0c63          	beq	s8,a3,1e84 <main+0xb38>
    1d50:	8bc1a603          	lw	a2,-1860(gp) # 46c74 <said_multi>
    1d54:	12061863          	bnez	a2,1e84 <main+0xb38>
    1d58:	00400613          	li	a2,4
    1d5c:	12cb8463          	beq	s7,a2,1e84 <main+0xb38>
        *((volatile u32*) address) = data;
    1d60:	f81007b7          	lui	a5,0xf8100
    1d64:	00a00613          	li	a2,10
    1d68:	02c7a423          	sw	a2,40(a5) # f8100028 <__freertos_irq_stack_top+0xf8095a38>
                pose_said = 1;
    1d6c:	8cd1a023          	sw	a3,-1856(gp) # 46c78 <pose_said>
                said_person = 1;
    1d70:	8ad1ac23          	sw	a3,-1864(gp) # 46c70 <said_person>
                vcool = 16;
    1d74:	01000793          	li	a5,16
                said_multi = 1;
    1d78:	8ad1ae23          	sw	a3,-1860(gp) # 46c74 <said_multi>
                vcool = 16;
    1d7c:	8af1aa23          	sw	a5,-1868(gp) # 46c6c <vcool>
    1d80:	ae1ff06f          	j	1860 <main+0x514>
            t3_add_box(dets, &nd, T3_MAX_TRK, (int)x0, (int)y0, (int)x1, (int)y1);
    1d84:	000a0813          	mv	a6,s4
    1d88:	00048793          	mv	a5,s1
    1d8c:	00090713          	mv	a4,s2
    1d90:	00040693          	mv	a3,s0
    1d94:	00400613          	li	a2,4
    1d98:	0d410593          	addi	a1,sp,212
    1d9c:	0d810513          	addi	a0,sp,216
    1da0:	0a512623          	sw	t0,172(sp)
    1da4:	0bf12423          	sw	t6,168(sp)
    1da8:	09d12e23          	sw	t4,156(sp)
    1dac:	07e12e23          	sw	t5,124(sp)
    1db0:	06712423          	sw	t2,104(sp)
    1db4:	060030ef          	jal	ra,4e14 <t3_add_box>
        if (box2_vis && (bw2 > 40) && (bh2 > 20))
    1db8:	06812383          	lw	t2,104(sp)
    1dbc:	07c12f03          	lw	t5,124(sp)
    1dc0:	09c12e83          	lw	t4,156(sp)
    1dc4:	0a812f83          	lw	t6,168(sp)
    1dc8:	0ac12283          	lw	t0,172(sp)
    1dcc:	02800793          	li	a5,40
    1dd0:	0057f663          	bgeu	a5,t0,1ddc <main+0xa90>
    1dd4:	01400793          	li	a5,20
    1dd8:	1277e663          	bltu	a5,t2,1f04 <main+0xbb8>
        if (!fus_box) {
    1ddc:	06012783          	lw	a5,96(sp)
    1de0:	06f12423          	sw	a5,104(sp)
    1de4:	d60796e3          	bnez	a5,1b50 <main+0x804>
    1de8:	e31ff06f          	j	1c18 <main+0x8cc>
        lp = (int)(lpr & 1u);
    1dec:	07312e23          	sw	s3,124(sp)
    1df0:	d85ff06f          	j	1b74 <main+0x828>
        bw2 = (x1b > x0b) ? (x1b - x0b) : 0;
    1df4:	00000293          	li	t0,0
    1df8:	00000393          	li	t2,0
    1dfc:	cfdff06f          	j	1af8 <main+0x7ac>
        bh = (y1 > y0) ? (y1 - y0) : 0;
    1e00:	0a012023          	sw	zero,160(sp)
    1e04:	f84ff06f          	j	1588 <main+0x23c>
            idle_arm = 0;
    1e08:	8a01a823          	sw	zero,-1872(gp) # 46c68 <idle_arm>
    1e0c:	a55ff06f          	j	1860 <main+0x514>
    1e10:	08012e23          	sw	zero,156(sp)
    1e14:	0c012423          	sw	zero,200(sp)
    1e18:	00000713          	li	a4,0
    1e1c:	00000793          	li	a5,0
    1e20:	00000593          	li	a1,0
                    pd_sticky = 0;
    1e24:	00000d13          	li	s10,0
            if (pd < 0) pd = -pd;
    1e28:	9c0f52e3          	bgez	t5,17ec <main+0x4a0>
    1e2c:	9bdff06f          	j	17e8 <main+0x49c>
                idle_arm++;
    1e30:	00178793          	addi	a5,a5,1
    1e34:	8af1a823          	sw	a5,-1872(gp) # 46c68 <idle_arm>
            if (idle_arm >= 8) {
    1e38:	00800693          	li	a3,8
    1e3c:	a2d792e3          	bne	a5,a3,1860 <main+0x514>
    1e40:	c99ff06f          	j	1ad8 <main+0x78c>
        pd_on = pd_sticky ? 1 : 0;
    1e44:	001d7593          	andi	a1,s10,1
            if (pd < 0) pd = -pd;
    1e48:	008d1793          	slli	a5,s10,0x8
    1e4c:	0ffd7713          	andi	a4,s10,255
        pd_on = pd_sticky ? 1 : 0;
    1e50:	09a12e23          	sw	s10,156(sp)
        lp = (int)(lpr & 1u);
    1e54:	07312e23          	sw	s3,124(sp)
    1e58:	991ff06f          	j	17e8 <main+0x49c>
        box2_vis = box2_on || ((bw2 > 80) && (bh2 > 40));
    1e5c:	0293b793          	sltiu	a5,t2,41
    1e60:	0017c793          	xori	a5,a5,1
    1e64:	05000713          	li	a4,80
    1e68:	06f12423          	sw	a5,104(sp)
    1e6c:	8c5760e3          	bltu	a4,t0,172c <main+0x3e0>
        if (fus_box)
    1e70:	06012783          	lw	a5,96(sp)
    1e74:	0c079e63          	bnez	a5,1f50 <main+0xc04>
        box2_vis = box2_on || ((bw2 > 80) && (bh2 > 40));
    1e78:	06012423          	sw	zero,104(sp)
    1e7c:	8c1ff06f          	j	173c <main+0x3f0>
            idle_arm = 0;
    1e80:	8a01a823          	sw	zero,-1872(gp) # 46c68 <idle_arm>
            } else if (pd_on && !said_person && (int)code == 1) {
    1e84:	9c058ee3          	beqz	a1,1860 <main+0x514>
    1e88:	8b81a683          	lw	a3,-1864(gp) # 46c70 <said_person>
    1e8c:	00069663          	bnez	a3,1e98 <main+0xb4c>
    1e90:	00100693          	li	a3,1
    1e94:	0adb8063          	beq	s7,a3,1f34 <main+0xbe8>
            } else if (pd_on && fus_box && !pose_said && (int)code == 3) {
    1e98:	06012683          	lw	a3,96(sp)
    1e9c:	9c0682e3          	beqz	a3,1860 <main+0x514>
    1ea0:	8c01a683          	lw	a3,-1856(gp) # 46c78 <pose_said>
    1ea4:	9a069ee3          	bnez	a3,1860 <main+0x514>
    1ea8:	00300693          	li	a3,3
    1eac:	9adb9ae3          	bne	s7,a3,1860 <main+0x514>
    if (vx > 24 || vx < -24)
    1eb0:	01878793          	addi	a5,a5,24
    1eb4:	03000693          	li	a3,48
    1eb8:	0cf6e863          	bltu	a3,a5,1f88 <main+0xc3c>
    if (bh < 280 && y1 > 500 && y0 > 200)
    1ebc:	0a012683          	lw	a3,160(sp)
    1ec0:	11700793          	li	a5,279
    1ec4:	0ad7ca63          	blt	a5,a3,1f78 <main+0xc2c>
    1ec8:	1f400793          	li	a5,500
    1ecc:	0147f663          	bgeu	a5,s4,1ed8 <main+0xb8c>
    1ed0:	0c800793          	li	a5,200
    1ed4:	0b27ee63          	bltu	a5,s2,1f90 <main+0xc44>
    if (bh < 400 && y0 > 180)
    1ed8:	0b400793          	li	a5,180
    1edc:	9927f2e3          	bgeu	a5,s2,1860 <main+0x514>
    1ee0:	01200793          	li	a5,18
    1ee4:	f81006b7          	lui	a3,0xf8100
    1ee8:	02f6a423          	sw	a5,40(a3) # f8100028 <__freertos_irq_stack_top+0xf8095a38>
                    pose_said = 1;
    1eec:	00100793          	li	a5,1
    1ef0:	8cf1a023          	sw	a5,-1856(gp) # 46c78 <pose_said>
                    said_person = 1;
    1ef4:	8af1ac23          	sw	a5,-1864(gp) # 46c70 <said_person>
                    vcool = 16;
    1ef8:	01000793          	li	a5,16
    1efc:	8af1aa23          	sw	a5,-1868(gp) # 46c6c <vcool>
    1f00:	961ff06f          	j	1860 <main+0x514>
            t3_add_box_force(dets, &nd, T3_MAX_TRK,
    1f04:	000f8813          	mv	a6,t6
    1f08:	000e8793          	mv	a5,t4
    1f0c:	000f0713          	mv	a4,t5
    1f10:	000c0693          	mv	a3,s8
    1f14:	00400613          	li	a2,4
    1f18:	0d410593          	addi	a1,sp,212
    1f1c:	0d810513          	addi	a0,sp,216
    1f20:	0d8030ef          	jal	ra,4ff8 <t3_add_box_force>
    1f24:	eb9ff06f          	j	1ddc <main+0xa90>
                said_multi = 1;
    1f28:	00100793          	li	a5,1
    1f2c:	8af1ae23          	sw	a5,-1860(gp) # 46c74 <said_multi>
    1f30:	931ff06f          	j	1860 <main+0x514>
    1f34:	f81007b7          	lui	a5,0xf8100
    1f38:	00800693          	li	a3,8
    1f3c:	02d7a423          	sw	a3,40(a5) # f8100028 <__freertos_irq_stack_top+0xf8095a38>
                said_person = 1;
    1f40:	8b71ac23          	sw	s7,-1864(gp) # 46c70 <said_person>
                vcool = 16;
    1f44:	01000793          	li	a5,16
    1f48:	8af1aa23          	sw	a5,-1868(gp) # 46c6c <vcool>
    1f4c:	915ff06f          	j	1860 <main+0x514>
            t3_add_box(dets, &nd, T3_MAX_TRK, (int)x0, (int)y0, (int)x1, (int)y1);
    1f50:	000a0813          	mv	a6,s4
    1f54:	00048793          	mv	a5,s1
    1f58:	00090713          	mv	a4,s2
    1f5c:	00040693          	mv	a3,s0
    1f60:	00400613          	li	a2,4
    1f64:	0d410593          	addi	a1,sp,212
    1f68:	0d810513          	addi	a0,sp,216
    1f6c:	6a9020ef          	jal	ra,4e14 <t3_add_box>
    1f70:	06012423          	sw	zero,104(sp)
    1f74:	bddff06f          	j	1b50 <main+0x804>
    if (bh < 400 && y0 > 180)
    1f78:	0a012683          	lw	a3,160(sp)
    1f7c:	18f00793          	li	a5,399
    1f80:	8ed7c0e3          	blt	a5,a3,1860 <main+0x514>
    1f84:	f55ff06f          	j	1ed8 <main+0xb8c>
    if (vx > 24 || vx < -24)
    1f88:	01300793          	li	a5,19
    1f8c:	f59ff06f          	j	1ee4 <main+0xb98>
    if (bh < 280 && y1 > 500 && y0 > 200)
    1f90:	02100793          	li	a5,33
    1f94:	f51ff06f          	j	1ee4 <main+0xb98>
    bsp_printf("static noperson p=%d n=%d %s\r\n",
    1f98:	000476b7          	lui	a3,0x47
    1f9c:	9e868693          	addi	a3,a3,-1560 # 469e8 <CSWTCH.112+0x88>
    1fa0:	c6cff06f          	j	140c <main+0xc0>
        bsp_printf("static person FAIL\r\n");
    1fa4:	00047537          	lui	a0,0x47
    1fa8:	a3c50513          	addi	a0,a0,-1476 # 46a3c <CSWTCH.112+0xdc>
    1fac:	43c020ef          	jal	ra,43e8 <bsp_printf>
    1fb0:	c34ff06f          	j	13e4 <main+0x98>

00001fb4 <inet_cksum>:

static uint16_t inet_cksum(const uint8_t *p, int n, uint32_t extra)
{
    uint32_t s = extra;
    int i;
    for (i = 0; i < n - 1; i += 2)
    1fb4:	00100793          	li	a5,1
    1fb8:	02b7da63          	bge	a5,a1,1fec <inet_cksum+0x38>
    1fbc:	ffe58813          	addi	a6,a1,-2
    1fc0:	ffe87793          	andi	a5,a6,-2
    1fc4:	00250813          	addi	a6,a0,2
    1fc8:	00050713          	mv	a4,a0
    1fcc:	01078833          	add	a6,a5,a6
        s += ((uint32_t)p[i] << 8) | p[i + 1];
    1fd0:	00074783          	lbu	a5,0(a4)
    1fd4:	00174683          	lbu	a3,1(a4)
    1fd8:	00270713          	addi	a4,a4,2
    1fdc:	00879793          	slli	a5,a5,0x8
    1fe0:	00d7e7b3          	or	a5,a5,a3
    1fe4:	00f60633          	add	a2,a2,a5
    for (i = 0; i < n - 1; i += 2)
    1fe8:	fee814e3          	bne	a6,a4,1fd0 <inet_cksum+0x1c>
    if (n & 1)
    1fec:	0015f793          	andi	a5,a1,1
    1ff0:	00078a63          	beqz	a5,2004 <inet_cksum+0x50>
        s += (uint32_t)p[n - 1] << 8;
    1ff4:	00b505b3          	add	a1,a0,a1
    1ff8:	fff5c783          	lbu	a5,-1(a1)
    1ffc:	00879793          	slli	a5,a5,0x8
    2000:	00f60633          	add	a2,a2,a5
    while (s >> 16)
    2004:	01065793          	srli	a5,a2,0x10
    2008:	00078e63          	beqz	a5,2024 <inet_cksum+0x70>
        s = (s & 0xffffu) + (s >> 16);
    200c:	00010737          	lui	a4,0x10
    2010:	fff70713          	addi	a4,a4,-1 # ffff <pd_w26+0x353f>
    2014:	00e67633          	and	a2,a2,a4
    2018:	00f60633          	add	a2,a2,a5
    while (s >> 16)
    201c:	01065793          	srli	a5,a2,0x10
    2020:	fe079ae3          	bnez	a5,2014 <inet_cksum+0x60>
    return (uint16_t)~s;
    2024:	fff64613          	not	a2,a2
}
    2028:	01061513          	slli	a0,a2,0x10
    202c:	01055513          	srli	a0,a0,0x10
    2030:	00008067          	ret

00002034 <uitoa.part.0>:
static unsigned uitoa(char *d, unsigned v)
{
    char tmp[12];
    unsigned n = 0, i = 0;
    if (v == 0) { d[0] = '0'; return 1; }
    while (v) { tmp[n++] = (char)('0' + (v % 10)); v /= 10; }
    2034:	06058263          	beqz	a1,2098 <uitoa.part.0+0x64>
    2038:	00050693          	mv	a3,a0
static unsigned uitoa(char *d, unsigned v)
    203c:	ff010113          	addi	sp,sp,-16
    unsigned n = 0, i = 0;
    2040:	00000513          	li	a0,0
    while (v) { tmp[n++] = (char)('0' + (v % 10)); v /= 10; }
    2044:	00a00613          	li	a2,10
    2048:	00900893          	li	a7,9
    204c:	0080006f          	j	2054 <uitoa.part.0+0x20>
    2050:	00080593          	mv	a1,a6
    2054:	02c5f7b3          	remu	a5,a1,a2
    2058:	00150513          	addi	a0,a0,1
    205c:	00410713          	addi	a4,sp,4
    2060:	00a70733          	add	a4,a4,a0
    2064:	03078793          	addi	a5,a5,48
    2068:	fef70fa3          	sb	a5,-1(a4)
    206c:	02c5d833          	divu	a6,a1,a2
    2070:	feb8e0e3          	bltu	a7,a1,2050 <uitoa.part.0+0x1c>
    2074:	00510613          	addi	a2,sp,5
    2078:	00c0006f          	j	2084 <uitoa.part.0+0x50>
    207c:	ffe74783          	lbu	a5,-2(a4)
    2080:	fff70713          	addi	a4,a4,-1
    while (n) d[i++] = tmp[--n];
    2084:	00f68023          	sb	a5,0(a3)
    2088:	00168693          	addi	a3,a3,1
    208c:	fec718e3          	bne	a4,a2,207c <uitoa.part.0+0x48>
    return i;
}
    2090:	01010113          	addi	sp,sp,16
    2094:	00008067          	ret
    unsigned n = 0, i = 0;
    2098:	00000513          	li	a0,0
}
    209c:	00008067          	ret

000020a0 <kv.constprop.4>:

static unsigned append(char *d, unsigned n, const char *s)
{
    while (*s) d[n++] = *s++;
    20a0:	000066b7          	lui	a3,0x6
    20a4:	00047737          	lui	a4,0x47
    return n;
}

static unsigned kv(char *d, unsigned n, const char *k, const char *id)
    20a8:	06400813          	li	a6,100
    while (*s) d[n++] = *s++;
    20ac:	03c00893          	li	a7,60
    20b0:	61868693          	addi	a3,a3,1560 # 6618 <_data>
    20b4:	f8070713          	addi	a4,a4,-128 # 46f80 <page.3199>
    20b8:	0100006f          	j	20c8 <kv.constprop.4+0x28>
    20bc:	00080893          	mv	a7,a6
    20c0:	0016c803          	lbu	a6,1(a3)
    20c4:	00078513          	mv	a0,a5
    20c8:	00150793          	addi	a5,a0,1
    20cc:	00f70333          	add	t1,a4,a5
    20d0:	ff130fa3          	sb	a7,-1(t1)
    20d4:	00168693          	addi	a3,a3,1
    20d8:	fe0812e3          	bnez	a6,20bc <kv.constprop.4+0x1c>
    20dc:	0005c803          	lbu	a6,0(a1)
    20e0:	02080263          	beqz	a6,2104 <kv.constprop.4+0x64>
    20e4:	fff54513          	not	a0,a0
    20e8:	00178793          	addi	a5,a5,1
    20ec:	00f708b3          	add	a7,a4,a5
    20f0:	00f506b3          	add	a3,a0,a5
    20f4:	ff088fa3          	sb	a6,-1(a7)
    20f8:	00d586b3          	add	a3,a1,a3
    20fc:	0006c803          	lbu	a6,0(a3)
    2100:	fe0814e3          	bnez	a6,20e8 <kv.constprop.4+0x48>
    2104:	000066b7          	lui	a3,0x6
    2108:	02f00593          	li	a1,47
    210c:	03c00813          	li	a6,60
    2110:	63068693          	addi	a3,a3,1584 # 6630 <_data+0x18>
    2114:	0100006f          	j	2124 <kv.constprop.4+0x84>
    2118:	00058813          	mv	a6,a1
    211c:	0016c583          	lbu	a1,1(a3)
    2120:	00050793          	mv	a5,a0
    2124:	00178513          	addi	a0,a5,1
    2128:	00a708b3          	add	a7,a4,a0
    212c:	ff088fa3          	sb	a6,-1(a7)
    2130:	00168693          	addi	a3,a3,1
    2134:	fe0592e3          	bnez	a1,2118 <kv.constprop.4+0x78>
    2138:	00064583          	lbu	a1,0(a2)
    213c:	02058263          	beqz	a1,2160 <kv.constprop.4+0xc0>
    2140:	fff7c793          	not	a5,a5
    2144:	00150513          	addi	a0,a0,1
    2148:	00a70833          	add	a6,a4,a0
    214c:	00a786b3          	add	a3,a5,a0
    2150:	feb80fa3          	sb	a1,-1(a6)
    2154:	00d606b3          	add	a3,a2,a3
    2158:	0006c583          	lbu	a1,0(a3)
    215c:	fe0594e3          	bnez	a1,2144 <kv.constprop.4+0xa4>
    2160:	00a70733          	add	a4,a4,a0
    2164:	03e00793          	li	a5,62
    2168:	00f70023          	sb	a5,0(a4)
    n = append(d, n, k);
    n = append(d, n, "</span><b id=");
    n = append(d, n, id);
    n = append(d, n, ">");
    return n;
}
    216c:	00150513          	addi	a0,a0,1
    2170:	00008067          	ret

00002174 <send_tcp>:
    put16(f + 18, ++ip_id);
    2174:	8881d783          	lhu	a5,-1912(gp) # 46c40 <ip_id>
{
    2178:	fd010113          	addi	sp,sp,-48
    217c:	03212023          	sw	s2,32(sp)
    memcpy(f + 6, local_mac, 6);
    2180:	81418693          	addi	a3,gp,-2028 # 46bcc <local_mac>
{
    2184:	00060913          	mv	s2,a2
    2188:	02112623          	sw	ra,44(sp)
    218c:	02812423          	sw	s0,40(sp)
    2190:	02912223          	sw	s1,36(sp)
    2194:	01312e23          	sw	s3,28(sp)
    2198:	01412c23          	sw	s4,24(sp)
    219c:	01512a23          	sw	s5,20(sp)
    21a0:	01612823          	sw	s6,16(sp)
    21a4:	01712623          	sw	s7,12(sp)
    memcpy(f + 6, local_mac, 6);
    21a8:	0026d803          	lhu	a6,2(a3)
    memcpy(f + 0, peer_mac, 6);
    21ac:	8a018613          	addi	a2,gp,-1888 # 46c58 <peer_mac>
    unsigned ip_len = IP_HDR + TCP_HDR + plen;
    21b0:	02890713          	addi	a4,s2,40
    put16(f + 18, ++ip_id);
    21b4:	00178793          	addi	a5,a5,1
    memcpy(f + 0, peer_mac, 6);
    21b8:	00062283          	lw	t0,0(a2)
    21bc:	00465383          	lhu	t2,4(a2)
    memcpy(f + 26, local_ip, 4);
    21c0:	81018e13          	addi	t3,gp,-2032 # 46bc8 <local_ip>
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    21c4:	01071613          	slli	a2,a4,0x10
    put16(f + 18, ++ip_id);
    21c8:	01079793          	slli	a5,a5,0x10
    memcpy(f + 0, peer_mac, 6);
    21cc:	0004c437          	lui	s0,0x4c
    21d0:	88040413          	addi	s0,s0,-1920 # 4b880 <txbuf>
    put16(f + 18, ++ip_id);
    21d4:	0107d793          	srli	a5,a5,0x10
    memcpy(f + 6, local_mac, 6);
    21d8:	0006df83          	lhu	t6,0(a3)
    21dc:	0046d483          	lhu	s1,4(a3)
    memcpy(f + 26, local_ip, 4);
    21e0:	8101df03          	lhu	t5,-2032(gp) # 46bc8 <local_ip>
    21e4:	002e5e83          	lhu	t4,2(t3)
    memcpy(f + 30, peer_ip, 4);
    21e8:	89c18b93          	addi	s7,gp,-1892 # 46c54 <peer_ip>
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    21ec:	01065613          	srli	a2,a2,0x10
    memcpy(f + 30, peer_ip, 4);
    21f0:	002bd303          	lhu	t1,2(s7)
    put16(f + 18, ++ip_id);
    21f4:	88f19423          	sh	a5,-1912(gp) # 46c40 <ip_id>
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    21f8:	0087da13          	srli	s4,a5,0x8
    memcpy(f + 30, peer_ip, 4);
    21fc:	89c1de03          	lhu	t3,-1892(gp) # 46c54 <peer_ip>
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    2200:	00865613          	srli	a2,a2,0x8
    2204:	00879693          	slli	a3,a5,0x8
    memcpy(f + 6, local_mac, 6);
    2208:	01041423          	sh	a6,8(s0)
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    220c:	00871713          	slli	a4,a4,0x8
    f[12] = 0x08; f[13] = 0x00;
    2210:	00450837          	lui	a6,0x450
    f[20] = 0x40; f[21] = 0x00;
    2214:	064007b7          	lui	a5,0x6400
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    2218:	00c76733          	or	a4,a4,a2
    221c:	0146e6b3          	or	a3,a3,s4
    f[12] = 0x08; f[13] = 0x00;
    2220:	00880813          	addi	a6,a6,8 # 450008 <__freertos_irq_stack_top+0x3e5a18>
    f[20] = 0x40; f[21] = 0x00;
    2224:	04078793          	addi	a5,a5,64 # 6400040 <__freertos_irq_stack_top+0x6395a50>
    f[12] = 0x08; f[13] = 0x00;
    2228:	01042623          	sw	a6,12(s0)
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    222c:	00e41823          	sh	a4,16(s0)
    2230:	00d41923          	sh	a3,18(s0)
    f[20] = 0x40; f[21] = 0x00;
    2234:	00f42a23          	sw	a5,20(s0)
{
    2238:	00050993          	mv	s3,a0
    memcpy(f + 0, peer_mac, 6);
    223c:	00542023          	sw	t0,0(s0)
    2240:	00741223          	sh	t2,4(s0)
    memcpy(f + 6, local_mac, 6);
    2244:	01f41323          	sh	t6,6(s0)
    2248:	00941523          	sh	s1,10(s0)
    memcpy(f + 26, local_ip, 4);
    224c:	01e41d23          	sh	t5,26(s0)
    2250:	01d41e23          	sh	t4,28(s0)
    put16(f + 24, inet_cksum(f + 14, IP_HDR, 0));
    2254:	0004c537          	lui	a0,0x4c
    f[24] = 0; f[25] = 0;
    2258:	00041c23          	sh	zero,24(s0)
    put16(f + 24, inet_cksum(f + 14, IP_HDR, 0));
    225c:	00000613          	li	a2,0
    memcpy(f + 30, peer_ip, 4);
    2260:	01c41f23          	sh	t3,30(s0)
{
    2264:	00058a93          	mv	s5,a1
    memcpy(f + 30, peer_ip, 4);
    2268:	02641023          	sh	t1,32(s0)
    put16(f + 24, inet_cksum(f + 14, IP_HDR, 0));
    226c:	01400593          	li	a1,20
    2270:	88e50513          	addi	a0,a0,-1906 # 4b88e <txbuf+0xe>
    2274:	d41ff0ef          	jal	ra,1fb4 <inet_cksum>
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    2278:	8981d603          	lhu	a2,-1896(gp) # 46c50 <peer_port>
    227c:	8901d703          	lhu	a4,-1904(gp) # 46c48 <rcv_nxt>
    put32(f + 42, rcv_nxt);
    2280:	8901a783          	lw	a5,-1904(gp) # 46c48 <rcv_nxt>
    2284:	8941d683          	lhu	a3,-1900(gp) # 46c4c <snd_nxt>
    2288:	00871593          	slli	a1,a4,0x8
    put32(f + 38, snd_nxt);
    228c:	8941a483          	lw	s1,-1900(gp) # 46c4c <snd_nxt>
    2290:	00875713          	srli	a4,a4,0x8
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    2294:	00851313          	slli	t1,a0,0x8
    2298:	00e5e733          	or	a4,a1,a4
    229c:	00855513          	srli	a0,a0,0x8
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16);
    22a0:	0187d593          	srli	a1,a5,0x18
    22a4:	0107d793          	srli	a5,a5,0x10
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    22a8:	00861893          	slli	a7,a2,0x8
    22ac:	00869813          	slli	a6,a3,0x8
    22b0:	00a36533          	or	a0,t1,a0
    22b4:	00865613          	srli	a2,a2,0x8
    22b8:	0086d693          	srli	a3,a3,0x8
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16);
    22bc:	02f405a3          	sb	a5,43(s0)
    f[46] = 0x50;
    22c0:	05000793          	li	a5,80
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    22c4:	00c8e633          	or	a2,a7,a2
    22c8:	00d866b3          	or	a3,a6,a3
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16);
    22cc:	0184d893          	srli	a7,s1,0x18
    22d0:	0104d813          	srli	a6,s1,0x10
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    22d4:	00a41c23          	sh	a0,24(s0)
    f[46] = 0x50;
    22d8:	02f40723          	sb	a5,46(s0)
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    22dc:	00005537          	lui	a0,0x5
    22e0:	01000793          	li	a5,16
    22e4:	02a41123          	sh	a0,34(s0)
    22e8:	02c41223          	sh	a2,36(s0)
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16);
    22ec:	03140323          	sb	a7,38(s0)
    22f0:	030403a3          	sb	a6,39(s0)
    p[2] = (uint8_t)(v >> 8);  p[3] = (uint8_t)v;
    22f4:	02d41423          	sh	a3,40(s0)
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16);
    22f8:	02b40523          	sb	a1,42(s0)
    p[2] = (uint8_t)(v >> 8);  p[3] = (uint8_t)v;
    22fc:	02e41623          	sh	a4,44(s0)
    f[47] = flags;
    2300:	033407a3          	sb	s3,47(s0)
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    2304:	02f42823          	sw	a5,48(s0)
    f[52] = 0; f[53] = 0;
    2308:	02041a23          	sh	zero,52(s0)
    if (plen && payload)
    230c:	00090e63          	beqz	s2,2328 <send_tcp+0x1b4>
    2310:	000a8c63          	beqz	s5,2328 <send_tcp+0x1b4>
        memcpy(f + L2, payload, plen);
    2314:	0004c537          	lui	a0,0x4c
    2318:	00090613          	mv	a2,s2
    231c:	000a8593          	mv	a1,s5
    2320:	8b650513          	addi	a0,a0,-1866 # 4b8b6 <txbuf+0x36>
    2324:	e31fe0ef          	jal	ra,1154 <memcpy>
    extra += (uint32_t)(TCP_HDR + plen);
    2328:	89c1d783          	lhu	a5,-1892(gp) # 46c54 <peer_ip>
    232c:	002bd703          	lhu	a4,2(s7)
    put16(f + 50, inet_cksum(f + 34, TCP_HDR + (int)plen, extra));
    2330:	0004c537          	lui	a0,0x4c
    extra += (uint32_t)(TCP_HDR + plen);
    2334:	0087d693          	srli	a3,a5,0x8
    2338:	00879613          	slli	a2,a5,0x8
    233c:	00871793          	slli	a5,a4,0x8
    2340:	00875713          	srli	a4,a4,0x8
    2344:	00e7e7b3          	or	a5,a5,a4
    2348:	00d66633          	or	a2,a2,a3
    234c:	01061613          	slli	a2,a2,0x10
    2350:	01079793          	slli	a5,a5,0x10
    2354:	0107d793          	srli	a5,a5,0x10
    2358:	01065613          	srli	a2,a2,0x10
    235c:	00f60633          	add	a2,a2,a5
    2360:	0000d7b7          	lui	a5,0xd
    2364:	acc78793          	addi	a5,a5,-1332 # cacc <pd_w26+0xc>
    2368:	00f60633          	add	a2,a2,a5
    put16(f + 50, inet_cksum(f + 34, TCP_HDR + (int)plen, extra));
    236c:	01260633          	add	a2,a2,s2
    2370:	01490593          	addi	a1,s2,20
    2374:	8a250513          	addi	a0,a0,-1886 # 4b8a2 <txbuf+0x22>
    2378:	c3dff0ef          	jal	ra,1fb4 <inet_cksum>
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    237c:	00851793          	slli	a5,a0,0x8
    2380:	00855513          	srli	a0,a0,0x8
    2384:	00a7e533          	or	a0,a5,a0
    tx_frame(f, L2 + plen);
    2388:	001e87b7          	lui	a5,0x1e8
static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
    238c:	02a41923          	sh	a0,50(s0)
    tx_frame(f, L2 + plen);
    2390:	03690613          	addi	a2,s2,54
    2394:	48178793          	addi	a5,a5,1153 # 1e8481 <__freertos_irq_stack_top+0x17de91>
        return *((volatile u32*) address);
    2398:	f8100737          	lui	a4,0xf8100
    239c:	0080006f          	j	23a4 <send_tcp+0x230>
        if (++spin > 2000000u)
    23a0:	0e078663          	beqz	a5,248c <send_tcp+0x318>
    23a4:	04072683          	lw	a3,64(a4) # f8100040 <__freertos_irq_stack_top+0xf8095a50>
    23a8:	fff78793          	addi	a5,a5,-1
    while (tx_busy()) {
    23ac:	01269593          	slli	a1,a3,0x12
    23b0:	fe05c8e3          	bltz	a1,23a0 <send_tcp+0x22c>
    if (n < 60) {
    23b4:	03b00793          	li	a5,59
    23b8:	12c7e063          	bltu	a5,a2,24d8 <send_tcp+0x364>
    23bc:	008907b3          	add	a5,s2,s0
    23c0:	00640713          	addi	a4,s0,6
            frame[i] = 0;
    23c4:	02078b23          	sb	zero,54(a5)
    23c8:	00178793          	addi	a5,a5,1
        for (i = n; i < 60; i++)
    23cc:	fef71ce3          	bne	a4,a5,23c4 <send_tcp+0x250>
    23d0:	03f00313          	li	t1,63
    23d4:	03e00e13          	li	t3,62
    23d8:	03d00893          	li	a7,61
    if (n + 4u > TX_MAX)
    23dc:	04000513          	li	a0,64
        n = 60;
    23e0:	03c00613          	li	a2,60
            c = (c & 1u) ? (c >> 1) ^ 0xEDB88320u : (c >> 1);
    23e4:	edb88837          	lui	a6,0xedb88
    23e8:	00040693          	mv	a3,s0
    23ec:	00c40f33          	add	t5,s0,a2
    tx_frame(f, L2 + plen);
    23f0:	00040713          	mv	a4,s0
    23f4:	fff00793          	li	a5,-1
            c = (c & 1u) ? (c >> 1) ^ 0xEDB88320u : (c >> 1);
    23f8:	32080813          	addi	a6,a6,800 # edb88320 <__freertos_irq_stack_top+0xedb1dd30>
        c ^= p[i];
    23fc:	00074e83          	lbu	t4,0(a4)
    2400:	00800593          	li	a1,8
    2404:	01d7c7b3          	xor	a5,a5,t4
            c = (c & 1u) ? (c >> 1) ^ 0xEDB88320u : (c >> 1);
    2408:	0017fe93          	andi	t4,a5,1
    240c:	fff58593          	addi	a1,a1,-1
    2410:	0017d793          	srli	a5,a5,0x1
    2414:	000e8463          	beqz	t4,241c <send_tcp+0x2a8>
    2418:	0107c7b3          	xor	a5,a5,a6
        for (b = 0; b < 8; b++)
    241c:	fe0596e3          	bnez	a1,2408 <send_tcp+0x294>
    2420:	00170713          	addi	a4,a4,1
    for (i = 0; i < n; i++) {
    2424:	fcef1ce3          	bne	t5,a4,23fc <send_tcp+0x288>
    return ~c;
    2428:	fff7c793          	not	a5,a5
    frame[n + 0] = (uint8_t)crc;
    242c:	00860633          	add	a2,a2,s0
    2430:	00f60023          	sb	a5,0(a2)
    frame[n + 1] = (uint8_t)(crc >> 8);
    2434:	00888733          	add	a4,a7,s0
    2438:	0087d613          	srli	a2,a5,0x8
    243c:	00c70023          	sb	a2,0(a4)
    frame[n + 2] = (uint8_t)(crc >> 16);
    2440:	008e0733          	add	a4,t3,s0
    2444:	0107d613          	srli	a2,a5,0x10
    2448:	00c70023          	sb	a2,0(a4)
    frame[n + 3] = (uint8_t)(crc >> 24);
    244c:	0187d793          	srli	a5,a5,0x18
    2450:	00830733          	add	a4,t1,s0
    2454:	00f70023          	sb	a5,0(a4)
        *((volatile u32*) address) = data;
    2458:	00100713          	li	a4,1
    245c:	f81007b7          	lui	a5,0xf8100
    2460:	04e7a823          	sw	a4,80(a5) # f8100050 <__freertos_irq_stack_top+0xf8095a60>
    for (i = 0; i < n; i++)
    2464:	00a40433          	add	s0,s0,a0
    2468:	f8100737          	lui	a4,0xf8100
    246c:	00050a63          	beqz	a0,2480 <send_tcp+0x30c>
        write_u32(frame[i], REG_TXB);
    2470:	0006c783          	lbu	a5,0(a3)
    2474:	00168693          	addi	a3,a3,1
    2478:	04f72423          	sw	a5,72(a4) # f8100048 <__freertos_irq_stack_top+0xf8095a58>
    for (i = 0; i < n; i++)
    247c:	fe869ae3          	bne	a3,s0,2470 <send_tcp+0x2fc>
    2480:	f81007b7          	lui	a5,0xf8100
    2484:	04a7a623          	sw	a0,76(a5) # f810004c <__freertos_irq_stack_top+0xf8095a5c>
    2488:	8941a483          	lw	s1,-1900(gp) # 46c4c <snd_nxt>
    if (flags & 0x02)
    248c:	0029f793          	andi	a5,s3,2
    2490:	00078663          	beqz	a5,249c <send_tcp+0x328>
        snd_nxt += 1;
    2494:	00148493          	addi	s1,s1,1
    2498:	8891aa23          	sw	s1,-1900(gp) # 46c4c <snd_nxt>
        snd_nxt += 1;
    249c:	0019f993          	andi	s3,s3,1
    24a0:	013484b3          	add	s1,s1,s3
}
    24a4:	02c12083          	lw	ra,44(sp)
    24a8:	02812403          	lw	s0,40(sp)
    snd_nxt += plen;
    24ac:	009904b3          	add	s1,s2,s1
    24b0:	8891aa23          	sw	s1,-1900(gp) # 46c4c <snd_nxt>
}
    24b4:	02012903          	lw	s2,32(sp)
    24b8:	02412483          	lw	s1,36(sp)
    24bc:	01c12983          	lw	s3,28(sp)
    24c0:	01812a03          	lw	s4,24(sp)
    24c4:	01412a83          	lw	s5,20(sp)
    24c8:	01012b03          	lw	s6,16(sp)
    24cc:	00c12b83          	lw	s7,12(sp)
    24d0:	03010113          	addi	sp,sp,48
    24d4:	00008067          	ret
    if (n + 4u > TX_MAX)
    24d8:	03a90513          	addi	a0,s2,58
    24dc:	000017b7          	lui	a5,0x1
    24e0:	faa7e6e3          	bltu	a5,a0,248c <send_tcp+0x318>
    24e4:	03790893          	addi	a7,s2,55
    24e8:	03890e13          	addi	t3,s2,56
    24ec:	03990313          	addi	t1,s2,57
    24f0:	ef5ff06f          	j	23e4 <send_tcp+0x270>

000024f4 <http_reply>:
    d[n] = 0;
    return n;
}

static void http_reply(const char *ctype, const uint8_t *body, unsigned blen)
{
    24f4:	f2010113          	addi	sp,sp,-224
    24f8:	0c912a23          	sw	s1,212(sp)
    24fc:	00058493          	mv	s1,a1
    2500:	000065b7          	lui	a1,0x6
    2504:	0d212823          	sw	s2,208(sp)
    2508:	0c112e23          	sw	ra,220(sp)
    250c:	0c812c23          	sw	s0,216(sp)
    2510:	0d312623          	sw	s3,204(sp)
    2514:	0d412423          	sw	s4,200(sp)
    2518:	00060913          	mv	s2,a2
    251c:	05400713          	li	a4,84
    while (*s) d[n++] = *s++;
    2520:	04800693          	li	a3,72
    2524:	00000793          	li	a5,0
    2528:	68858593          	addi	a1,a1,1672 # 6688 <_data+0x70>
    252c:	0100006f          	j	253c <http_reply+0x48>
    2530:	00070693          	mv	a3,a4
    2534:	00164703          	lbu	a4,1(a2)
    2538:	00040793          	mv	a5,s0
    253c:	00178413          	addi	s0,a5,1 # 1001 <_start+0x1>
    2540:	00810633          	add	a2,sp,s0
    2544:	fed60fa3          	sb	a3,-1(a2)
    2548:	00b40633          	add	a2,s0,a1
    254c:	fe0712e3          	bnez	a4,2530 <http_reply+0x3c>
    2550:	00054703          	lbu	a4,0(a0)
    2554:	02070263          	beqz	a4,2578 <http_reply+0x84>
    2558:	fff7c693          	not	a3,a5
    255c:	00140413          	addi	s0,s0,1
    2560:	008687b3          	add	a5,a3,s0
    2564:	00810633          	add	a2,sp,s0
    2568:	00f507b3          	add	a5,a0,a5
    256c:	fee60fa3          	sb	a4,-1(a2)
    2570:	0007c703          	lbu	a4,0(a5)
    2574:	fe0714e3          	bnez	a4,255c <http_reply+0x68>
    2578:	000067b7          	lui	a5,0x6
    257c:	00a00713          	li	a4,10
    2580:	00d00693          	li	a3,13
    2584:	64078793          	addi	a5,a5,1600 # 6640 <_data+0x28>
    2588:	00c0006f          	j	2594 <http_reply+0xa0>
    258c:	00070693          	mv	a3,a4
    2590:	0017c703          	lbu	a4,1(a5)
    2594:	00140413          	addi	s0,s0,1
    2598:	00810533          	add	a0,sp,s0
    259c:	fed50fa3          	sb	a3,-1(a0)
    25a0:	00178793          	addi	a5,a5,1
    25a4:	fe0714e3          	bnez	a4,258c <http_reply+0x98>
    if (v == 0) { d[0] = '0'; return 1; }
    25a8:	0e090663          	beqz	s2,2694 <http_reply+0x1a0>
    25ac:	00090593          	mv	a1,s2
    25b0:	a85ff0ef          	jal	ra,2034 <uitoa.part.0>
    char hdr[192];
    unsigned hn = 0;
    hn = append(hdr, hn, "HTTP/1.0 200 OK\r\nContent-Type: ");
    hn = append(hdr, hn, ctype);
    hn = append(hdr, hn, "\r\nContent-Length: ");
    hn += uitoa(hdr + hn, blen);
    25b4:	000067b7          	lui	a5,0x6
    25b8:	00850433          	add	s0,a0,s0
    25bc:	00a00713          	li	a4,10
    while (*s) d[n++] = *s++;
    25c0:	00d00693          	li	a3,13
    hn += uitoa(hdr + hn, blen);
    25c4:	65478793          	addi	a5,a5,1620 # 6654 <_data+0x3c>
    25c8:	00c0006f          	j	25d4 <http_reply+0xe0>
    25cc:	00070693          	mv	a3,a4
    while (*s) d[n++] = *s++;
    25d0:	0017c703          	lbu	a4,1(a5)
    25d4:	00140413          	addi	s0,s0,1
    25d8:	00810633          	add	a2,sp,s0
    25dc:	fed60fa3          	sb	a3,-1(a2)
    25e0:	00178793          	addi	a5,a5,1
    25e4:	fe0714e3          	bnez	a4,25cc <http_reply+0xd8>
    hn = append(hdr, hn, "\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n");
    if (hn + blen > sizeof(http_pkt))
    25e8:	008909b3          	add	s3,s2,s0
    25ec:	000027b7          	lui	a5,0x2
    25f0:	0337f263          	bgeu	a5,s3,2614 <http_reply+0x120>
        return;
    memcpy(http_pkt, hdr, hn);
    if (blen)
        memcpy(http_pkt + hn, body, blen);
    send_tcp_body(http_pkt, hn + blen);
}
    25f4:	0dc12083          	lw	ra,220(sp)
    25f8:	0d812403          	lw	s0,216(sp)
    25fc:	0d412483          	lw	s1,212(sp)
    2600:	0d012903          	lw	s2,208(sp)
    2604:	0cc12983          	lw	s3,204(sp)
    2608:	0c812a03          	lw	s4,200(sp)
    260c:	0e010113          	addi	sp,sp,224
    2610:	00008067          	ret
    memcpy(http_pkt, hdr, hn);
    2614:	0004aa37          	lui	s4,0x4a
    2618:	880a0513          	addi	a0,s4,-1920 # 49880 <http_pkt>
    261c:	00040613          	mv	a2,s0
    2620:	00010593          	mv	a1,sp
    2624:	880a0a13          	addi	s4,s4,-1920
    2628:	b2dfe0ef          	jal	ra,1154 <memcpy>
    if (blen)
    262c:	06091c63          	bnez	s2,26a4 <http_reply+0x1b0>
    unsigned off = 0;
    2630:	00000593          	li	a1,0
    2634:	57800493          	li	s1,1400
    if (!plen) {
    2638:	08098063          	beqz	s3,26b8 <http_reply+0x1c4>
        unsigned n = plen - off;
    263c:	40b98733          	sub	a4,s3,a1
        send_tcp(flags, payload + off, n);
    2640:	01800513          	li	a0,24
    2644:	00e4f463          	bgeu	s1,a4,264c <http_reply+0x158>
    2648:	57800713          	li	a4,1400
        if (off + n >= plen)
    264c:	00b70433          	add	s0,a4,a1
    2650:	00ba07b3          	add	a5,s4,a1
        send_tcp(flags, payload + off, n);
    2654:	00070613          	mv	a2,a4
    2658:	00078593          	mv	a1,a5
        if (off + n >= plen)
    265c:	03346663          	bltu	s0,s3,2688 <http_reply+0x194>
        send_tcp(flags, payload + off, n);
    2660:	01900513          	li	a0,25
    2664:	b11ff0ef          	jal	ra,2174 <send_tcp>
}
    2668:	0dc12083          	lw	ra,220(sp)
    266c:	0d812403          	lw	s0,216(sp)
    2670:	0d412483          	lw	s1,212(sp)
    2674:	0d012903          	lw	s2,208(sp)
    2678:	0cc12983          	lw	s3,204(sp)
    267c:	0c812a03          	lw	s4,200(sp)
    2680:	0e010113          	addi	sp,sp,224
    2684:	00008067          	ret
        send_tcp(flags, payload + off, n);
    2688:	aedff0ef          	jal	ra,2174 <send_tcp>
        off += n;
    268c:	00040593          	mv	a1,s0
    2690:	fadff06f          	j	263c <http_reply+0x148>
    if (v == 0) { d[0] = '0'; return 1; }
    2694:	03000793          	li	a5,48
    2698:	00f50023          	sb	a5,0(a0)
    269c:	00100513          	li	a0,1
    26a0:	f15ff06f          	j	25b4 <http_reply+0xc0>
        memcpy(http_pkt + hn, body, blen);
    26a4:	00090613          	mv	a2,s2
    26a8:	00048593          	mv	a1,s1
    26ac:	008a0533          	add	a0,s4,s0
    26b0:	aa5fe0ef          	jal	ra,1154 <memcpy>
    26b4:	f7dff06f          	j	2630 <http_reply+0x13c>
        send_tcp(0x19, 0, 0);
    26b8:	00000613          	li	a2,0
    26bc:	01900513          	li	a0,25
    26c0:	ab5ff0ef          	jal	ra,2174 <send_tcp>
        return;
    26c4:	f31ff06f          	j	25f4 <http_reply+0x100>

000026c8 <http_set_status>:
}

void http_set_status(const char *evt, int score, int pd_on, int pd, int lp,
                     int sht, int ta, int to, int ntrk, int infer_ms,
                     int x0, int y0, int x1, int y1, int voice)
{
    26c8:	fd010113          	addi	sp,sp,-48
    26cc:	01512a23          	sw	s5,20(sp)
    26d0:	01612823          	sw	s6,16(sp)
    26d4:	02112623          	sw	ra,44(sp)
    26d8:	02812423          	sw	s0,40(sp)
    26dc:	02912223          	sw	s1,36(sp)
    26e0:	03212023          	sw	s2,32(sp)
    26e4:	01312e23          	sw	s3,28(sp)
    26e8:	01412c23          	sw	s4,24(sp)
    26ec:	01712623          	sw	s7,12(sp)
    26f0:	00080b13          	mv	s6,a6
    26f4:	00088a93          	mv	s5,a7
    unsigned n = 0;
    {
        unsigned k = 0;
        const char *e = evt ? evt : "空闲";
    26f8:	20050063          	beqz	a0,28f8 <http_set_status+0x230>
    26fc:	00054f03          	lbu	t5,0(a0)
        while (k < 15 && e[k]) { st_evt[k] = e[k]; k++; }
    2700:	00047eb7          	lui	t4,0x47
    2704:	bb8e8e13          	addi	t3,t4,-1096 # 46bb8 <st_evt>
        unsigned k = 0;
    2708:	00000313          	li	t1,0
    270c:	bb8e8e93          	addi	t4,t4,-1096
        while (k < 15 && e[k]) { st_evt[k] = e[k]; k++; }
    2710:	00f00813          	li	a6,15
    2714:	020f0063          	beqz	t5,2734 <http_set_status+0x6c>
    2718:	01ee8023          	sb	t5,0(t4)
    271c:	00130313          	addi	t1,t1,1
    2720:	00650f33          	add	t5,a0,t1
    2724:	001e8e93          	addi	t4,t4,1
    2728:	01030663          	beq	t1,a6,2734 <http_set_status+0x6c>
    272c:	000f4f03          	lbu	t5,0(t5)
    2730:	fe0f14e3          	bnez	t5,2718 <http_set_status+0x50>
        st_evt[k] = 0;
    }
    st_score = score; st_pd_on = pd_on; st_pd = pd; st_lp = lp;
    2734:	88b1a023          	sw	a1,-1920(gp) # 46c38 <st_score>
    2738:	86c1ae23          	sw	a2,-1924(gp) # 46c34 <st_pd_on>
    273c:	86d1ac23          	sw	a3,-1928(gp) # 46c30 <st_pd>
    2740:	86e1aa23          	sw	a4,-1932(gp) # 46c2c <st_lp>
    st_sht = sht; st_ta = ta; st_to = to; st_ntrk = ntrk; st_ms = infer_ms;
    2744:	86f1a823          	sw	a5,-1936(gp) # 46c28 <st_sht>
    2748:	03012703          	lw	a4,48(sp)
    274c:	8761a623          	sw	s6,-1940(gp) # 46c24 <st_ta>
    2750:	8751a423          	sw	s5,-1944(gp) # 46c20 <st_to>
    2754:	86e1a223          	sw	a4,-1948(gp) # 46c1c <st_ntrk>
    2758:	03412703          	lw	a4,52(sp)
    275c:	86e1a023          	sw	a4,-1952(gp) # 46c18 <st_ms>
    st_x0 = x0; st_y0 = y0; st_x1 = x1; st_y1 = y1;
    2760:	03812703          	lw	a4,56(sp)
    st_voice = voice ? 1 : 0;
    n = append(hist[hist_i], 0, st_evt);
    2764:	8401aa03          	lw	s4,-1984(gp) # 46bf8 <__bss_start>
    st_x0 = x0; st_y0 = y0; st_x1 = x1; st_y1 = y1;
    2768:	84e1ae23          	sw	a4,-1956(gp) # 46c14 <st_x0>
    276c:	03c12703          	lw	a4,60(sp)
        st_evt[k] = 0;
    2770:	006e0333          	add	t1,t3,t1
    st_x0 = x0; st_y0 = y0; st_x1 = x1; st_y1 = y1;
    2774:	84e1ac23          	sw	a4,-1960(gp) # 46c10 <st_y0>
    2778:	04012703          	lw	a4,64(sp)
    st_voice = voice ? 1 : 0;
    277c:	04812803          	lw	a6,72(sp)
    st_x0 = x0; st_y0 = y0; st_x1 = x1; st_y1 = y1;
    2780:	84e1aa23          	sw	a4,-1964(gp) # 46c0c <st_x1>
    2784:	04412703          	lw	a4,68(sp)
        st_evt[k] = 0;
    2788:	00030023          	sb	zero,0(t1)
    n = append(hist[hist_i], 0, st_evt);
    278c:	001a1b93          	slli	s7,s4,0x1
    while (*s) d[n++] = *s++;
    2790:	000e4303          	lbu	t1,0(t3)
    st_voice = voice ? 1 : 0;
    2794:	01003833          	snez	a6,a6
    n = append(hist[hist_i], 0, st_evt);
    2798:	014b84b3          	add	s1,s7,s4
    st_x0 = x0; st_y0 = y0; st_x1 = x1; st_y1 = y1;
    279c:	84e1a823          	sw	a4,-1968(gp) # 46c08 <st_y1>
    n = append(hist[hist_i], 0, st_evt);
    27a0:	8c818993          	addi	s3,gp,-1848 # 46c80 <hist>
    27a4:	00549493          	slli	s1,s1,0x5
    st_voice = voice ? 1 : 0;
    27a8:	8501a623          	sw	a6,-1972(gp) # 46c04 <st_voice>
    n = append(hist[hist_i], 0, st_evt);
    27ac:	009984b3          	add	s1,s3,s1
    while (*s) d[n++] = *s++;
    27b0:	14030c63          	beqz	t1,2908 <http_set_status+0x240>
    27b4:	00000693          	li	a3,0
    27b8:	000e0793          	mv	a5,t3
    27bc:	0080006f          	j	27c4 <http_set_status+0xfc>
    27c0:	00070693          	mv	a3,a4
    27c4:	00168713          	addi	a4,a3,1
    27c8:	00178793          	addi	a5,a5,1 # 2001 <inet_cksum+0x4d>
    27cc:	00e48633          	add	a2,s1,a4
    27d0:	fe660fa3          	sb	t1,-1(a2)
    27d4:	0007c303          	lbu	t1,0(a5)
    27d8:	fe0314e3          	bnez	t1,27c0 <http_set_status+0xf8>
    27dc:	00268413          	addi	s0,a3,2
    hist[hist_i][n++] = ' ';
    27e0:	014b87b3          	add	a5,s7,s4
    27e4:	00579793          	slli	a5,a5,0x5
    27e8:	00f987b3          	add	a5,s3,a5
    27ec:	00e78733          	add	a4,a5,a4
    27f0:	02000793          	li	a5,32
    27f4:	00f70023          	sb	a5,0(a4)
    n += uitoa(hist[hist_i] + n, (unsigned)st_score);
    27f8:	00848533          	add	a0,s1,s0
    if (v == 0) { d[0] = '0'; return 1; }
    27fc:	0e058663          	beqz	a1,28e8 <http_set_status+0x220>
    2800:	835ff0ef          	jal	ra,2034 <uitoa.part.0>
    hist[hist_i][n++] = ' ';
    2804:	014b87b3          	add	a5,s7,s4
    2808:	00579793          	slli	a5,a5,0x5
    n += uitoa(hist[hist_i] + n, (unsigned)st_score);
    280c:	00850433          	add	s0,a0,s0
    hist[hist_i][n++] = ' ';
    2810:	00f987b3          	add	a5,s3,a5
    2814:	008787b3          	add	a5,a5,s0
    2818:	02000713          	li	a4,32
    281c:	00140413          	addi	s0,s0,1
    2820:	00e78023          	sb	a4,0(a5)
    n += uitoa(hist[hist_i] + n, (unsigned)st_ta);
    2824:	00848533          	add	a0,s1,s0
    if (v == 0) { d[0] = '0'; return 1; }
    2828:	0a0b0863          	beqz	s6,28d8 <http_set_status+0x210>
    282c:	000b0593          	mv	a1,s6
    2830:	805ff0ef          	jal	ra,2034 <uitoa.part.0>
    hist[hist_i][n++] = '/';
    2834:	014b87b3          	add	a5,s7,s4
    2838:	00579793          	slli	a5,a5,0x5
    n += uitoa(hist[hist_i] + n, (unsigned)st_ta);
    283c:	00a40433          	add	s0,s0,a0
    hist[hist_i][n++] = '/';
    2840:	00f987b3          	add	a5,s3,a5
    2844:	008787b3          	add	a5,a5,s0
    2848:	02f00713          	li	a4,47
    284c:	00140413          	addi	s0,s0,1
    2850:	00e78023          	sb	a4,0(a5)
    n += uitoa(hist[hist_i] + n, (unsigned)st_to);
    2854:	00848533          	add	a0,s1,s0
    if (v == 0) { d[0] = '0'; return 1; }
    2858:	060a8863          	beqz	s5,28c8 <http_set_status+0x200>
    285c:	000a8593          	mv	a1,s5
    2860:	fd4ff0ef          	jal	ra,2034 <uitoa.part.0>
    hist[hist_i][n] = 0;
    2864:	014b8bb3          	add	s7,s7,s4
    2868:	005b9b93          	slli	s7,s7,0x5
    286c:	017989b3          	add	s3,s3,s7
    2870:	00898433          	add	s0,s3,s0
    hist_i = (hist_i + 1) & 7;
    2874:	001a0793          	addi	a5,s4,1
    if (hist_n < 8) hist_n++;
    2878:	8441a703          	lw	a4,-1980(gp) # 46bfc <hist_n>
    hist_i = (hist_i + 1) & 7;
    287c:	0077f793          	andi	a5,a5,7
    hist[hist_i][n] = 0;
    2880:	00a40433          	add	s0,s0,a0
    hist_i = (hist_i + 1) & 7;
    2884:	84f1a023          	sw	a5,-1984(gp) # 46bf8 <__bss_start>
    hist[hist_i][n] = 0;
    2888:	00040023          	sb	zero,0(s0)
    if (hist_n < 8) hist_n++;
    288c:	00700793          	li	a5,7
    2890:	00e7c663          	blt	a5,a4,289c <http_set_status+0x1d4>
    2894:	00170713          	addi	a4,a4,1
    2898:	84e1a223          	sw	a4,-1980(gp) # 46bfc <hist_n>
}
    289c:	02c12083          	lw	ra,44(sp)
    28a0:	02812403          	lw	s0,40(sp)
    28a4:	02412483          	lw	s1,36(sp)
    28a8:	02012903          	lw	s2,32(sp)
    28ac:	01c12983          	lw	s3,28(sp)
    28b0:	01812a03          	lw	s4,24(sp)
    28b4:	01412a83          	lw	s5,20(sp)
    28b8:	01012b03          	lw	s6,16(sp)
    28bc:	00c12b83          	lw	s7,12(sp)
    28c0:	03010113          	addi	sp,sp,48
    28c4:	00008067          	ret
    if (v == 0) { d[0] = '0'; return 1; }
    28c8:	03000793          	li	a5,48
    28cc:	00f50023          	sb	a5,0(a0)
    28d0:	00100513          	li	a0,1
    28d4:	f91ff06f          	j	2864 <http_set_status+0x19c>
    28d8:	03000793          	li	a5,48
    28dc:	00f50023          	sb	a5,0(a0)
    28e0:	00100513          	li	a0,1
    28e4:	f51ff06f          	j	2834 <http_set_status+0x16c>
    28e8:	03000793          	li	a5,48
    28ec:	00f50023          	sb	a5,0(a0)
    28f0:	00100513          	li	a0,1
    28f4:	f11ff06f          	j	2804 <http_set_status+0x13c>
        const char *e = evt ? evt : "空闲";
    28f8:	00006537          	lui	a0,0x6
    28fc:	0e700f13          	li	t5,231
    2900:	6a850513          	addi	a0,a0,1704 # 66a8 <_data+0x90>
    2904:	dfdff06f          	j	2700 <http_set_status+0x38>
    while (*s) d[n++] = *s++;
    2908:	00100413          	li	s0,1
    290c:	00000713          	li	a4,0
    2910:	ed1ff06f          	j	27e0 <http_set_status+0x118>

00002914 <http_set_thumb>:

void http_set_thumb(const uint8_t *th48, unsigned n)
{
    unsigned i;
    if (!th48) return;
    2914:	04050263          	beqz	a0,2958 <http_set_thumb+0x44>
    if (n > sizeof(thumb)) n = sizeof(thumb);
    2918:	000017b7          	lui	a5,0x1
    291c:	90078793          	addi	a5,a5,-1792 # 900 <CUSTOM2+0x8a5>
    2920:	00058613          	mv	a2,a1
    2924:	02b7ec63          	bltu	a5,a1,295c <http_set_thumb+0x48>
    for (i = 0; i < n; i++)
    2928:	02058463          	beqz	a1,2950 <http_set_thumb+0x3c>
    292c:	00049737          	lui	a4,0x49
    2930:	f8070713          	addi	a4,a4,-128 # 48f80 <thumb>
    2934:	00000793          	li	a5,0
        thumb[i] = th48[i];
    2938:	00f506b3          	add	a3,a0,a5
    293c:	0006c683          	lbu	a3,0(a3)
    2940:	00170713          	addi	a4,a4,1
    for (i = 0; i < n; i++)
    2944:	00178793          	addi	a5,a5,1
        thumb[i] = th48[i];
    2948:	fed70fa3          	sb	a3,-1(a4)
    for (i = 0; i < n; i++)
    294c:	fec7e6e3          	bltu	a5,a2,2938 <http_set_thumb+0x24>
    have_thumb = 1;
    2950:	00100713          	li	a4,1
    2954:	88e1a223          	sw	a4,-1916(gp) # 46c3c <have_thumb>
}
    2958:	00008067          	ret
    295c:	00078613          	mv	a2,a5
    2960:	fc9ff06f          	j	2928 <http_set_thumb+0x14>

00002964 <http_poll>:

void http_poll(void)
{
    2964:	fb010113          	addi	sp,sp,-80
    2968:	03412c23          	sw	s4,56(sp)
    296c:	03512a23          	sw	s5,52(sp)
        unsigned n, i, ihl, doff, tcp_off, pay_off, pay_len, ip_tot, tcp_seg;
        uint8_t flags;
        uint32_t seq;
        const uint8_t *ip, *tcp, *pay;

        if (!(st & ST_RXV))
    2970:	00001a37          	lui	s4,0x1
    2974:	0004dab7          	lui	s5,0x4d
{
    2978:	04812423          	sw	s0,72(sp)
    297c:	04912223          	sw	s1,68(sp)
    2980:	05212023          	sw	s2,64(sp)
    2984:	03312e23          	sw	s3,60(sp)
    2988:	03612823          	sw	s6,48(sp)
    298c:	04112623          	sw	ra,76(sp)
    2990:	03712623          	sw	s7,44(sp)
    2994:	00600493          	li	s1,6
    2998:	800a0913          	addi	s2,s4,-2048 # 800 <CUSTOM2+0x7a5>
    299c:	880a8993          	addi	s3,s5,-1920 # 4c880 <rxbuf>

        if (peer_port && get16(tcp) != peer_port)
            continue;

        if (tcp_st == SYN_RCVD && (flags & 0x10))
            tcp_st = ESTAB;
    29a0:	00200b13          	li	s6,2
        return *((volatile u32*) address);
    29a4:	f81007b7          	lui	a5,0xf8100
    29a8:	0407a503          	lw	a0,64(a5) # f8100040 <__freertos_irq_stack_top+0xf8095a50>
        if (!(st & ST_RXV))
    29ac:	01351793          	slli	a5,a0,0x13
    29b0:	1607d463          	bgez	a5,2b18 <http_poll+0x1b4>
        n = st & ST_LEN;
    29b4:	fffa0793          	addi	a5,s4,-1
    29b8:	00f57533          	and	a0,a0,a5
        if (n > sizeof(rxbuf)) n = sizeof(rxbuf);
    29bc:	00050613          	mv	a2,a0
    29c0:	00a97463          	bgeu	s2,a0,29c8 <http_poll+0x64>
    29c4:	00090613          	mv	a2,s2
        for (i = 0; i < n; i++)
    29c8:	16050e63          	beqz	a0,2b44 <http_poll+0x1e0>
    29cc:	880a8713          	addi	a4,s5,-1920
    29d0:	00000793          	li	a5,0
    29d4:	f81005b7          	lui	a1,0xf8100
    29d8:	0445a683          	lw	a3,68(a1) # f8100044 <__freertos_irq_stack_top+0xf8095a54>
    29dc:	00170713          	addi	a4,a4,1
    29e0:	00178793          	addi	a5,a5,1
            rxbuf[i] = (uint8_t)read_u32(REG_RXB);
    29e4:	fed70fa3          	sb	a3,-1(a4)
        for (i = 0; i < n; i++)
    29e8:	fec7e8e3          	bltu	a5,a2,29d8 <http_poll+0x74>
        *((volatile u32*) address) = data;
    29ec:	00100793          	li	a5,1
    29f0:	04f5a023          	sw	a5,64(a1)
        if (n < 54) continue;
    29f4:	03500793          	li	a5,53
    29f8:	10a7fc63          	bgeu	a5,a0,2b10 <http_poll+0x1ac>
        ihl = (ip[0] & 0x0f) * 4;
    29fc:	00e9c783          	lbu	a5,14(s3)
        if (ihl < 20) continue;
    2a00:	01300593          	li	a1,19
        ihl = (ip[0] & 0x0f) * 4;
    2a04:	00f7f793          	andi	a5,a5,15
    2a08:	00279793          	slli	a5,a5,0x2
        if (ihl < 20) continue;
    2a0c:	10f5d263          	bge	a1,a5,2b10 <http_poll+0x1ac>
        if (n < tcp_off + 20) continue;
    2a10:	02278713          	addi	a4,a5,34
    2a14:	0ee66e63          	bltu	a2,a4,2b10 <http_poll+0x1ac>
        tcp_off = 14 + ihl;
    2a18:	00e78513          	addi	a0,a5,14
        tcp = rxbuf + tcp_off;
    2a1c:	00a986b3          	add	a3,s3,a0
static uint16_t get16(const uint8_t *p) { return ((uint16_t)p[0] << 8) | p[1]; }
    2a20:	0026c703          	lbu	a4,2(a3)
    2a24:	0036c883          	lbu	a7,3(a3)
        if (get16(tcp + 2) != 80)
    2a28:	05000813          	li	a6,80
static uint16_t get16(const uint8_t *p) { return ((uint16_t)p[0] << 8) | p[1]; }
    2a2c:	00871713          	slli	a4,a4,0x8
    2a30:	01176733          	or	a4,a4,a7
        if (get16(tcp + 2) != 80)
    2a34:	01071713          	slli	a4,a4,0x10
    2a38:	41075713          	srai	a4,a4,0x10
    2a3c:	0d071a63          	bne	a4,a6,2b10 <http_poll+0x1ac>
        doff = ((tcp[12] >> 4) & 0x0f) * 4;
    2a40:	00c6c703          	lbu	a4,12(a3)
    2a44:	00475713          	srli	a4,a4,0x4
    2a48:	00271713          	slli	a4,a4,0x2
        if (doff < 20) continue;
    2a4c:	0ce5d263          	bge	a1,a4,2b10 <http_poll+0x1ac>
static uint16_t get16(const uint8_t *p) { return ((uint16_t)p[0] << 8) | p[1]; }
    2a50:	0109c583          	lbu	a1,16(s3)
    2a54:	0119c803          	lbu	a6,17(s3)
    2a58:	00e50533          	add	a0,a0,a4
    2a5c:	00859593          	slli	a1,a1,0x8
        ip_tot = get16(ip + 2);
    2a60:	0105e5b3          	or	a1,a1,a6
        tcp_seg = (ip_tot > ihl) ? (ip_tot - ihl) : 0;
    2a64:	0eb7fc63          	bgeu	a5,a1,2b5c <http_poll+0x1f8>
    2a68:	40f587b3          	sub	a5,a1,a5
        pay_len = (tcp_seg > doff) ? (tcp_seg - doff) : 0;
    2a6c:	0ef77863          	bgeu	a4,a5,2b5c <http_poll+0x1f8>
    2a70:	40e787b3          	sub	a5,a5,a4
    2a74:	00e58593          	addi	a1,a1,14
        if (pay_off + pay_len > n)
    2a78:	00b67663          	bgeu	a2,a1,2a84 <http_poll+0x120>
            pay_len = (n > pay_off) ? (n - pay_off) : 0;
    2a7c:	00000793          	li	a5,0
    2a80:	0ec56463          	bltu	a0,a2,2b68 <http_poll+0x204>
        flags = tcp[13];
    2a84:	00d6c603          	lbu	a2,13(a3)
        if (flags & 0x04) {
    2a88:	00467713          	andi	a4,a2,4
    2a8c:	08071063          	bnez	a4,2b0c <http_poll+0x1a8>
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
    2a90:	0046c703          	lbu	a4,4(a3)
    2a94:	0056c583          	lbu	a1,5(a3)
           ((uint32_t)p[2] << 8) | p[3];
    2a98:	0076c883          	lbu	a7,7(a3)
    2a9c:	0066c803          	lbu	a6,6(a3)
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
    2aa0:	01059593          	slli	a1,a1,0x10
    2aa4:	01871713          	slli	a4,a4,0x18
    2aa8:	00b76733          	or	a4,a4,a1
           ((uint32_t)p[2] << 8) | p[3];
    2aac:	01176733          	or	a4,a4,a7
    2ab0:	00881813          	slli	a6,a6,0x8
        if (flags & 0x02) {
    2ab4:	00267593          	andi	a1,a2,2
           ((uint32_t)p[2] << 8) | p[3];
    2ab8:	01076733          	or	a4,a4,a6
        if (flags & 0x02) {
    2abc:	0c059263          	bnez	a1,2b80 <http_poll+0x21c>
        if (peer_port && get16(tcp) != peer_port)
    2ac0:	8981d803          	lhu	a6,-1896(gp) # 46c50 <peer_port>
    2ac4:	00080c63          	beqz	a6,2adc <http_poll+0x178>
static uint16_t get16(const uint8_t *p) { return ((uint16_t)p[0] << 8) | p[1]; }
    2ac8:	0006c583          	lbu	a1,0(a3)
    2acc:	0016c883          	lbu	a7,1(a3)
    2ad0:	00859693          	slli	a3,a1,0x8
        if (peer_port && get16(tcp) != peer_port)
    2ad4:	0116e6b3          	or	a3,a3,a7
    2ad8:	02d81c63          	bne	a6,a3,2b10 <http_poll+0x1ac>
        if (tcp_st == SYN_RCVD && (flags & 0x10))
    2adc:	8a81a583          	lw	a1,-1880(gp) # 46c60 <tcp_st>
    2ae0:	00100693          	li	a3,1
    2ae4:	08d58663          	beq	a1,a3,2b70 <http_poll+0x20c>

        if (pay_len) {
    2ae8:	10079c63          	bnez	a5,2c00 <http_poll+0x29c>
            rcv_nxt = seq + pay_len;
            handle_get(pay, pay_len);
            tcp_st = LISTEN;
            return;
        }
        if (flags & 0x01) {
    2aec:	00167613          	andi	a2,a2,1
    2af0:	02060063          	beqz	a2,2b10 <http_poll+0x1ac>
            rcv_nxt = seq + 1;
    2af4:	00170713          	addi	a4,a4,1
            send_tcp(0x11, 0, 0);
    2af8:	00000613          	li	a2,0
    2afc:	00000593          	li	a1,0
    2b00:	01100513          	li	a0,17
            rcv_nxt = seq + 1;
    2b04:	88e1a823          	sw	a4,-1904(gp) # 46c48 <rcv_nxt>
            send_tcp(0x11, 0, 0);
    2b08:	e6cff0ef          	jal	ra,2174 <send_tcp>
            tcp_st = LISTEN;
    2b0c:	8a01a423          	sw	zero,-1880(gp) # 46c60 <tcp_st>
    2b10:	fff48493          	addi	s1,s1,-1
    for (hop = 0; hop < 6; hop++) {
    2b14:	e80498e3          	bnez	s1,29a4 <http_poll+0x40>
        }
    }
}
    2b18:	04c12083          	lw	ra,76(sp)
    2b1c:	04812403          	lw	s0,72(sp)
    2b20:	04412483          	lw	s1,68(sp)
    2b24:	04012903          	lw	s2,64(sp)
    2b28:	03c12983          	lw	s3,60(sp)
    2b2c:	03812a03          	lw	s4,56(sp)
    2b30:	03412a83          	lw	s5,52(sp)
    2b34:	03012b03          	lw	s6,48(sp)
    2b38:	02c12b83          	lw	s7,44(sp)
    2b3c:	05010113          	addi	sp,sp,80
    2b40:	00008067          	ret
    2b44:	f81007b7          	lui	a5,0xf8100
    2b48:	00100713          	li	a4,1
    2b4c:	04e7a023          	sw	a4,64(a5) # f8100040 <__freertos_irq_stack_top+0xf8095a50>
        if (n < 54) continue;
    2b50:	fff48493          	addi	s1,s1,-1
    for (hop = 0; hop < 6; hop++) {
    2b54:	e40498e3          	bnez	s1,29a4 <http_poll+0x40>
    2b58:	fc1ff06f          	j	2b18 <http_poll+0x1b4>
    2b5c:	00050593          	mv	a1,a0
        pay_len = (tcp_seg > doff) ? (tcp_seg - doff) : 0;
    2b60:	00000793          	li	a5,0
    2b64:	f15ff06f          	j	2a78 <http_poll+0x114>
            pay_len = (n > pay_off) ? (n - pay_off) : 0;
    2b68:	40a607b3          	sub	a5,a2,a0
    2b6c:	f19ff06f          	j	2a84 <http_poll+0x120>
        if (tcp_st == SYN_RCVD && (flags & 0x10))
    2b70:	01067693          	andi	a3,a2,16
    2b74:	f6068ae3          	beqz	a3,2ae8 <http_poll+0x184>
            tcp_st = ESTAB;
    2b78:	8b61a423          	sw	s6,-1880(gp) # 46c60 <tcp_st>
    2b7c:	f6dff06f          	j	2ae8 <http_poll+0x184>
static uint16_t get16(const uint8_t *p) { return ((uint16_t)p[0] << 8) | p[1]; }
    2b80:	0006c783          	lbu	a5,0(a3)
    2b84:	0016c583          	lbu	a1,1(a3)
            memcpy(peer_mac, rxbuf + 6, 6);
    2b88:	0069d283          	lhu	t0,6(s3)
    2b8c:	0089df83          	lhu	t6,8(s3)
    2b90:	00a9df03          	lhu	t5,10(s3)
    2b94:	8a018693          	addi	a3,gp,-1888 # 46c58 <peer_mac>
            iss += 64000u;
    2b98:	88c1a803          	lw	a6,-1908(gp) # 46c44 <iss>
static uint16_t get16(const uint8_t *p) { return ((uint16_t)p[0] << 8) | p[1]; }
    2b9c:	00879793          	slli	a5,a5,0x8
    2ba0:	00b7e7b3          	or	a5,a5,a1
            memcpy(peer_ip, ip + 12, 4);
    2ba4:	01a9de83          	lhu	t4,26(s3)
            memcpy(peer_mac, rxbuf + 6, 6);
    2ba8:	00569023          	sh	t0,0(a3)
    2bac:	01f69123          	sh	t6,2(a3)
    2bb0:	01e69223          	sh	t5,4(a3)
            iss += 64000u;
    2bb4:	00010637          	lui	a2,0x10
            memcpy(peer_ip, ip + 12, 4);
    2bb8:	01c9de03          	lhu	t3,28(s3)
            iss += 64000u;
    2bbc:	a0060613          	addi	a2,a2,-1536 # fa00 <pd_w26+0x2f40>
            rcv_nxt = seq + 1;
    2bc0:	00170713          	addi	a4,a4,1
            peer_port = get16(tcp);
    2bc4:	88f19c23          	sh	a5,-1896(gp) # 46c50 <peer_port>
            iss += 64000u;
    2bc8:	00c80833          	add	a6,a6,a2
            rcv_nxt = seq + 1;
    2bcc:	88e1a823          	sw	a4,-1904(gp) # 46c48 <rcv_nxt>
            memcpy(peer_ip, ip + 12, 4);
    2bd0:	89c18393          	addi	t2,gp,-1892 # 46c54 <peer_ip>
    2bd4:	89d19e23          	sh	t4,-1892(gp) # 46c54 <peer_ip>
            snd_nxt = iss;
    2bd8:	8901aa23          	sw	a6,-1900(gp) # 46c4c <snd_nxt>
            send_tcp(0x12, 0, 0);
    2bdc:	00000613          	li	a2,0
            tcp_st = SYN_RCVD;
    2be0:	00100793          	li	a5,1
            send_tcp(0x12, 0, 0);
    2be4:	00000593          	li	a1,0
    2be8:	01200513          	li	a0,18
            memcpy(peer_ip, ip + 12, 4);
    2bec:	01c39123          	sh	t3,2(t2)
            iss += 64000u;
    2bf0:	8901a623          	sw	a6,-1908(gp) # 46c44 <iss>
            tcp_st = SYN_RCVD;
    2bf4:	8af1a423          	sw	a5,-1880(gp) # 46c60 <tcp_st>
            send_tcp(0x12, 0, 0);
    2bf8:	d7cff0ef          	jal	ra,2174 <send_tcp>
            continue;
    2bfc:	f15ff06f          	j	2b10 <http_poll+0x1ac>
            rcv_nxt = seq + pay_len;
    2c00:	00e78733          	add	a4,a5,a4
    2c04:	88e1a823          	sw	a4,-1904(gp) # 46c48 <rcv_nxt>
    while (i + 4 < n && !(data[i] == 'G' && data[i + 1] == 'E' && data[i + 2] == 'T' && data[i + 3] == ' '))
    2c08:	00400713          	li	a4,4
    2c0c:	00f76463          	bltu	a4,a5,2c14 <http_poll+0x2b0>
    2c10:	4680106f          	j	4078 <__stack_size+0x78>
    2c14:	00a985b3          	add	a1,s3,a0
    2c18:	00058693          	mv	a3,a1
    2c1c:	04700813          	li	a6,71
    2c20:	00150893          	addi	a7,a0,1
    2c24:	04500e93          	li	t4,69
    2c28:	05400e13          	li	t3,84
    2c2c:	02000313          	li	t1,32
    2c30:	0140006f          	j	2c44 <http_poll+0x2e0>
    2c34:	00170713          	addi	a4,a4,1
    2c38:	00168693          	addi	a3,a3,1
    2c3c:	00e79463          	bne	a5,a4,2c44 <http_poll+0x2e0>
    2c40:	4380106f          	j	4078 <__stack_size+0x78>
    2c44:	0006c603          	lbu	a2,0(a3)
    2c48:	ff0616e3          	bne	a2,a6,2c34 <http_poll+0x2d0>
    2c4c:	0016c603          	lbu	a2,1(a3)
    2c50:	ffd612e3          	bne	a2,t4,2c34 <http_poll+0x2d0>
    2c54:	0026c603          	lbu	a2,2(a3)
    2c58:	fdc61ee3          	bne	a2,t3,2c34 <http_poll+0x2d0>
    2c5c:	0036ca03          	lbu	s4,3(a3)
    2c60:	fc6a1ae3          	bne	s4,t1,2c34 <http_poll+0x2d0>
    while (i < n && data[i] == ' ')
    2c64:	02000693          	li	a3,32
    2c68:	00e58633          	add	a2,a1,a4
    2c6c:	00064603          	lbu	a2,0(a2)
    2c70:	20d61263          	bne	a2,a3,2e74 <http_poll+0x510>
        i++;
    2c74:	00170713          	addi	a4,a4,1
    while (i < n && data[i] == ' ')
    2c78:	fef768e3          	bltu	a4,a5,2c68 <http_poll+0x304>
        path[0] = '/';
    2c7c:	02f00793          	li	a5,47
    2c80:	00f11023          	sh	a5,0(sp)
        if (path[i] != want[i])
    2c84:	000077b7          	lui	a5,0x7
    2c88:	02100613          	li	a2,33
    2c8c:	02010693          	addi	a3,sp,32
    2c90:	00110713          	addi	a4,sp,1
    2c94:	29278793          	addi	a5,a5,658 # 7292 <_data+0xc7a>
    while (want[i]) {
    2c98:	07400593          	li	a1,116
    2c9c:	40d60633          	sub	a2,a2,a3
        if (path[i] != want[i])
    2ca0:	00074503          	lbu	a0,0(a4)
    2ca4:	00e606b3          	add	a3,a2,a4
    2ca8:	00170713          	addi	a4,a4,1
    2cac:	02b51863          	bne	a0,a1,2cdc <http_poll+0x378>
    while (want[i]) {
    2cb0:	0007c583          	lbu	a1,0(a5)
    2cb4:	00178793          	addi	a5,a5,1
    2cb8:	fe0594e3          	bnez	a1,2ca0 <http_poll+0x33c>
    return path[i] == 0 || path[i] == '?' || path[i] == '#';
    2cbc:	02010793          	addi	a5,sp,32
    2cc0:	00d787b3          	add	a5,a5,a3
    2cc4:	fe07c783          	lbu	a5,-32(a5)
    2cc8:	0a078063          	beqz	a5,2d68 <http_poll+0x404>
    2ccc:	03f00713          	li	a4,63
    2cd0:	08e78c63          	beq	a5,a4,2d68 <http_poll+0x404>
    2cd4:	02300713          	li	a4,35
    2cd8:	08e78863          	beq	a5,a4,2d68 <http_poll+0x404>
        if (path[i] != want[i])
    2cdc:	00114703          	lbu	a4,1(sp)
    2ce0:	07400793          	li	a5,116
    2ce4:	00f71e63          	bne	a4,a5,2d00 <http_poll+0x39c>
    return path[i] == 0 || path[i] == '?' || path[i] == '#';
    2ce8:	00214783          	lbu	a5,2(sp)
    2cec:	06078e63          	beqz	a5,2d68 <http_poll+0x404>
    2cf0:	03f00713          	li	a4,63
    2cf4:	06e78a63          	beq	a5,a4,2d68 <http_poll+0x404>
    2cf8:	02300713          	li	a4,35
    2cfc:	06e78663          	beq	a5,a4,2d68 <http_poll+0x404>
        if (path[i] != want[i])
    2d00:	00010693          	mv	a3,sp
    2d04:	00007737          	lui	a4,0x7
    2d08:	00100593          	li	a1,1
    2d0c:	00110793          	addi	a5,sp,1
    2d10:	29a70713          	addi	a4,a4,666 # 729a <_data+0xc82>
    while (want[i]) {
    2d14:	07400513          	li	a0,116
    2d18:	40d585b3          	sub	a1,a1,a3
        if (path[i] != want[i])
    2d1c:	0007c803          	lbu	a6,0(a5)
    2d20:	00f58633          	add	a2,a1,a5
    2d24:	00178793          	addi	a5,a5,1
    2d28:	02a81863          	bne	a6,a0,2d58 <http_poll+0x3f4>
    while (want[i]) {
    2d2c:	00074503          	lbu	a0,0(a4)
    2d30:	00170713          	addi	a4,a4,1
    2d34:	fe0514e3          	bnez	a0,2d1c <http_poll+0x3b8>
    return path[i] == 0 || path[i] == '?' || path[i] == '#';
    2d38:	02010793          	addi	a5,sp,32
    2d3c:	00c787b3          	add	a5,a5,a2
    2d40:	fe07c783          	lbu	a5,-32(a5)
    2d44:	02078263          	beqz	a5,2d68 <http_poll+0x404>
    2d48:	03f00713          	li	a4,63
    2d4c:	00e78e63          	beq	a5,a4,2d68 <http_poll+0x404>
    2d50:	02300713          	li	a4,35
    2d54:	00e78a63          	beq	a5,a4,2d68 <http_poll+0x404>
        if (path[i] != want[i])
    2d58:	02f00793          	li	a5,47
    2d5c:	19c0006f          	j	2ef8 <http_poll+0x594>
        || path_has(path, "/t.b") || (path[0] == '/' && path[1] == 't' && path[2] == 0)) {
    2d60:	00214783          	lbu	a5,2(sp)
    2d64:	540792e3          	bnez	a5,3aa8 <http_poll+0x1144>
    memset(d, 0, 54);
    2d68:	000477b7          	lui	a5,0x47
    2d6c:	f8478793          	addi	a5,a5,-124 # 46f84 <page.3199+0x4>
    2d70:	0007a023          	sw	zero,0(a5)
    2d74:	0007a223          	sw	zero,4(a5)
    2d78:	0007a423          	sw	zero,8(a5)
    2d7c:	0007a623          	sw	zero,12(a5)
    2d80:	0007a823          	sw	zero,16(a5)
    2d84:	0007aa23          	sw	zero,20(a5)
    2d88:	0007ac23          	sw	zero,24(a5)
    2d8c:	0007ae23          	sw	zero,28(a5)
    2d90:	0207a023          	sw	zero,32(a5)
    2d94:	0207a223          	sw	zero,36(a5)
    2d98:	0207a423          	sw	zero,40(a5)
    2d9c:	0207a623          	sw	zero,44(a5)
    2da0:	02079823          	sh	zero,48(a5)
    d[0] = 'B';
    2da4:	0d3657b7          	lui	a5,0xd365
    2da8:	000479b7          	lui	s3,0x47
    2dac:	d4278793          	addi	a5,a5,-702 # d364d42 <__freertos_irq_stack_top+0xd2fa752>
    p[0] = (uint8_t)v;
    2db0:	f8098493          	addi	s1,s3,-128 # 46f80 <page.3199>
    d[0] = 'B';
    2db4:	f8f9a023          	sw	a5,-128(s3)
    p[0] = (uint8_t)v;
    2db8:	43600793          	li	a5,1078
    2dbc:	00f49523          	sh	a5,10(s1)
    2dc0:	02800793          	li	a5,40
    2dc4:	00f48723          	sb	a5,14(s1)
    2dc8:	03000793          	li	a5,48
    2dcc:	00f48923          	sb	a5,18(s1)
    2dd0:	fd000793          	li	a5,-48
    2dd4:	00f49b23          	sh	a5,22(s1)
    p[2] = (uint8_t)(v >> 16);
    2dd8:	fff00793          	li	a5,-1
    2ddc:	00f49c23          	sh	a5,24(s1)
    p[0] = (uint8_t)v;
    2de0:	00800793          	li	a5,8
    2de4:	00f48e23          	sb	a5,28(s1)
    p[1] = (uint8_t)(v >> 8);
    2de8:	00900793          	li	a5,9
    p[0] = (uint8_t)v;
    2dec:	00100713          	li	a4,1
    p[1] = (uint8_t)(v >> 8);
    2df0:	02f481a3          	sb	a5,35(s1)
    2df4:	000477b7          	lui	a5,0x47
    p[0] = (uint8_t)v;
    2df8:	00e48d23          	sb	a4,26(s1)
    p[1] = (uint8_t)(v >> 8);
    2dfc:	02e487a3          	sb	a4,47(s1)
    2e00:	02e489a3          	sb	a4,51(s1)
    for (i = 0; i < 256; i++) {
    2e04:	fb678793          	addi	a5,a5,-74 # 46fb6 <page.3199+0x36>
    2e08:	00000713          	li	a4,0
    2e0c:	10000613          	li	a2,256
        d[54 + i * 4 + 0] = (uint8_t)i;
    2e10:	0ff77693          	andi	a3,a4,255
    2e14:	00d78023          	sb	a3,0(a5)
        d[54 + i * 4 + 1] = (uint8_t)i;
    2e18:	00d780a3          	sb	a3,1(a5)
        d[54 + i * 4 + 2] = (uint8_t)i;
    2e1c:	00d78123          	sb	a3,2(a5)
        d[54 + i * 4 + 3] = 0;
    2e20:	000781a3          	sb	zero,3(a5)
    for (i = 0; i < 256; i++) {
    2e24:	00170713          	addi	a4,a4,1
    2e28:	00478793          	addi	a5,a5,4
    2e2c:	fec712e3          	bne	a4,a2,2e10 <http_poll+0x4ac>
    if (have_thumb)
    2e30:	8841a783          	lw	a5,-1916(gp) # 46c3c <have_thumb>
        memcpy(d + BMP_OFF, thumb, 48u * 48u);
    2e34:	00001637          	lui	a2,0x1
    2e38:	90060613          	addi	a2,a2,-1792 # 900 <CUSTOM2+0x8a5>
    if (have_thumb)
    2e3c:	00079463          	bnez	a5,2e44 <http_poll+0x4e0>
    2e40:	2740106f          	j	40b4 <__stack_size+0xb4>
        memcpy(d + BMP_OFF, thumb, 48u * 48u);
    2e44:	000495b7          	lui	a1,0x49
    2e48:	f8058593          	addi	a1,a1,-128 # 48f80 <thumb>
    2e4c:	43648513          	addi	a0,s1,1078
    2e50:	b04fe0ef          	jal	ra,1154 <memcpy>
        http_reply("image/bmp", page, pn);
    2e54:	00001637          	lui	a2,0x1
    2e58:	00007537          	lui	a0,0x7
    2e5c:	d3660613          	addi	a2,a2,-714 # d36 <CUSTOM2+0xcdb>
    2e60:	f8098593          	addi	a1,s3,-128
    2e64:	2a850513          	addi	a0,a0,680 # 72a8 <_data+0xc90>
    2e68:	e8cff0ef          	jal	ra,24f4 <http_reply>
            tcp_st = LISTEN;
    2e6c:	8a01a423          	sw	zero,-1880(gp) # 46c60 <tcp_st>
            return;
    2e70:	ca9ff06f          	j	2b18 <http_poll+0x1b4>
    path[0] = 0;
    2e74:	00010023          	sb	zero,0(sp)
    while (i < n && data[i] != ' ' && data[i] != '\r' && data[i] != '\n' && j < 30) {
    2e78:	e0f772e3          	bgeu	a4,a5,2c7c <http_poll+0x318>
    2e7c:	00d00693          	li	a3,13
    2e80:	ded60ee3          	beq	a2,a3,2c7c <http_poll+0x318>
    2e84:	00a00693          	li	a3,10
    2e88:	ded60ae3          	beq	a2,a3,2c7c <http_poll+0x318>
    2e8c:	01170733          	add	a4,a4,a7
    2e90:	00a78533          	add	a0,a5,a0
    2e94:	00010693          	mv	a3,sp
    2e98:	00e98733          	add	a4,s3,a4
    2e9c:	00a989b3          	add	s3,s3,a0
    2ea0:	00400537          	lui	a0,0x400
    2ea4:	00068593          	mv	a1,a3
    2ea8:	01e10313          	addi	t1,sp,30
    2eac:	01600893          	li	a7,22
    2eb0:	00950513          	addi	a0,a0,9 # 400009 <__freertos_irq_stack_top+0x395a19>
        path[j++] = (char)data[i++];
    2eb4:	00c58023          	sb	a2,0(a1)
        path[j] = 0;
    2eb8:	000580a3          	sb	zero,1(a1)
    2ebc:	00158593          	addi	a1,a1,1
    while (i < n && data[i] != ' ' && data[i] != '\r' && data[i] != '\n' && j < 30) {
    2ec0:	02e98463          	beq	s3,a4,2ee8 <http_poll+0x584>
    2ec4:	00074603          	lbu	a2,0(a4)
    2ec8:	00170713          	addi	a4,a4,1
    2ecc:	ff660793          	addi	a5,a2,-10
    2ed0:	0ff7f793          	andi	a5,a5,255
    2ed4:	00f55833          	srl	a6,a0,a5
    2ed8:	00187813          	andi	a6,a6,1
    2edc:	00f8e463          	bltu	a7,a5,2ee4 <http_poll+0x580>
    2ee0:	00081463          	bnez	a6,2ee8 <http_poll+0x584>
    2ee4:	fcb318e3          	bne	t1,a1,2eb4 <http_poll+0x550>
    if (path[0] == 0) {
    2ee8:	00014783          	lbu	a5,0(sp)
    2eec:	d80788e3          	beqz	a5,2c7c <http_poll+0x318>
    if (path[0] == '/' && path[1] == 'p' && (path[2] == '?' || path[2] == 0)) {
    2ef0:	02f00713          	li	a4,47
    2ef4:	0ee78e63          	beq	a5,a4,2ff0 <http_poll+0x68c>
    2ef8:	00014603          	lbu	a2,0(sp)
    2efc:	00068713          	mv	a4,a3
        for (j = 0; needle[j] && path[i + j] == needle[j]; j++)
    2f00:	02f00313          	li	t1,47
    2f04:	00060593          	mv	a1,a2
    2f08:	000078b7          	lui	a7,0x7
    2f0c:	02659663          	bne	a1,t1,2f38 <http_poll+0x5d4>
    2f10:	2a288813          	addi	a6,a7,674 # 72a2 <_data+0xc8a>
    2f14:	00070513          	mv	a0,a4
    2f18:	07400593          	li	a1,116
    2f1c:	00154e03          	lbu	t3,1(a0)
    2f20:	00150513          	addi	a0,a0,1
    2f24:	00be1a63          	bne	t3,a1,2f38 <http_poll+0x5d4>
    2f28:	00084583          	lbu	a1,0(a6)
    2f2c:	00180813          	addi	a6,a6,1
    2f30:	fe0596e3          	bnez	a1,2f1c <http_poll+0x5b8>
    2f34:	e35ff06f          	j	2d68 <http_poll+0x404>
        if (!needle[j])
    2f38:	00170713          	addi	a4,a4,1
    for (i = 0; path[i]; i++) {
    2f3c:	00074583          	lbu	a1,0(a4)
    2f40:	fc0596e3          	bnez	a1,2f0c <http_poll+0x5a8>
        || path_has(path, "/t.b") || (path[0] == '/' && path[1] == 't' && path[2] == 0)) {
    2f44:	02f00713          	li	a4,47
    2f48:	34e78ae3          	beq	a5,a4,3a9c <http_poll+0x1138>
    for (i = 0; path[i]; i++) {
    2f4c:	300792e3          	bnez	a5,3a50 <http_poll+0x10ec>
    while (want[i]) {
    2f50:	00007637          	lui	a2,0x7
    for (i = 0; path[i]; i++) {
    2f54:	02f00713          	li	a4,47
    2f58:	00000793          	li	a5,0
    while (want[i]) {
    2f5c:	36c60613          	addi	a2,a2,876 # 736c <_data+0xd54>
        if (path[i] != want[i])
    2f60:	00f68533          	add	a0,a3,a5
    2f64:	00054503          	lbu	a0,0(a0)
        i++;
    2f68:	00178793          	addi	a5,a5,1
    while (want[i]) {
    2f6c:	00c785b3          	add	a1,a5,a2
        if (path[i] != want[i])
    2f70:	02e51663          	bne	a0,a4,2f9c <http_poll+0x638>
    while (want[i]) {
    2f74:	0005c703          	lbu	a4,0(a1)
    2f78:	fe0714e3          	bnez	a4,2f60 <http_poll+0x5fc>
    return path[i] == 0 || path[i] == '?' || path[i] == '#';
    2f7c:	02010713          	addi	a4,sp,32
    2f80:	00f707b3          	add	a5,a4,a5
    2f84:	fe07c783          	lbu	a5,-32(a5)
    2f88:	04078663          	beqz	a5,2fd4 <http_poll+0x670>
    2f8c:	03f00713          	li	a4,63
    2f90:	04e78263          	beq	a5,a4,2fd4 <http_poll+0x670>
    2f94:	02300713          	li	a4,35
    2f98:	02e78e63          	beq	a5,a4,2fd4 <http_poll+0x670>
        for (j = 0; needle[j] && path[i + j] == needle[j]; j++)
    2f9c:	06600513          	li	a0,102
    2fa0:	000075b7          	lui	a1,0x7
    for (i = 0; path[i]; i++) {
    2fa4:	0006c783          	lbu	a5,0(a3)
    2fa8:	0c078c63          	beqz	a5,3080 <http_poll+0x71c>
        for (j = 0; needle[j] && path[i + j] == needle[j]; j++)
    2fac:	0ca79663          	bne	a5,a0,3078 <http_poll+0x714>
    2fb0:	37e58613          	addi	a2,a1,894 # 737e <_data+0xd66>
    2fb4:	00068713          	mv	a4,a3
    2fb8:	06100793          	li	a5,97
    2fbc:	00174803          	lbu	a6,1(a4)
    2fc0:	00170713          	addi	a4,a4,1
    2fc4:	0af81a63          	bne	a6,a5,3078 <http_poll+0x714>
    2fc8:	00064783          	lbu	a5,0(a2)
    2fcc:	00160613          	addi	a2,a2,1
    2fd0:	fe0796e3          	bnez	a5,2fbc <http_poll+0x658>
        http_reply("text/plain", (const uint8_t *)"", 0);
    2fd4:	000065b7          	lui	a1,0x6
    2fd8:	00007537          	lui	a0,0x7
    2fdc:	00000613          	li	a2,0
    2fe0:	68458593          	addi	a1,a1,1668 # 6684 <_data+0x6c>
    2fe4:	28450513          	addi	a0,a0,644 # 7284 <_data+0xc6c>
    2fe8:	d0cff0ef          	jal	ra,24f4 <http_reply>
    2fec:	e81ff06f          	j	2e6c <http_poll+0x508>
    2ff0:	00114783          	lbu	a5,1(sp)
    if (path[0] == '/' && path[1] == 'p' && (path[2] == '?' || path[2] == 0)) {
    2ff4:	07000713          	li	a4,112
    2ff8:	00e79463          	bne	a5,a4,3000 <http_poll+0x69c>
    2ffc:	0680106f          	j	4064 <__stack_size+0x64>
    } else if (path[0] == '/' && path[1] == 'a') {
    3000:	06100713          	li	a4,97
    3004:	c8e790e3          	bne	a5,a4,2c84 <http_poll+0x320>
        if ((path[2] == '?' && path[3] == '1') || (path[2] == '1' && path[3] == 0))
    3008:	00214783          	lbu	a5,2(sp)
    300c:	03f00713          	li	a4,63
    3010:	00e79463          	bne	a5,a4,3018 <http_poll+0x6b4>
    3014:	0240106f          	j	4038 <__stack_size+0x38>
    3018:	03100713          	li	a4,49
    301c:	00e79463          	bne	a5,a4,3024 <http_poll+0x6c0>
    3020:	0340106f          	j	4054 <__stack_size+0x54>
        else if ((path[2] == '?' && path[3] == '0') || (path[2] == '0' && path[3] == 0))
    3024:	03000713          	li	a4,48
    3028:	00e78463          	beq	a5,a4,3030 <http_poll+0x6cc>
    302c:	0240106f          	j	4050 <__stack_size+0x50>
    3030:	00314783          	lbu	a5,3(sp)
    3034:	00078463          	beqz	a5,303c <http_poll+0x6d8>
    3038:	0180106f          	j	4050 <__stack_size+0x50>
    303c:	00000793          	li	a5,0
    3040:	f8100737          	lui	a4,0xf8100
    3044:	02f72c23          	sw	a5,56(a4) # f8100038 <__freertos_irq_stack_top+0xf8095a48>
        return *((volatile u32*) address);
    3048:	03872703          	lw	a4,56(a4)
            st_arm = (int)(read_u32(REG_ARM) & 1u);
    304c:	00177713          	andi	a4,a4,1
    3050:	84e1a423          	sw	a4,-1976(gp) # 46c00 <st_arm>
        http_reply("text/plain", (const uint8_t *)(st_arm ? "1" : "0"), 1);
    3054:	8481a783          	lw	a5,-1976(gp) # 46c00 <st_arm>
    3058:	1e0796e3          	bnez	a5,3a44 <http_poll+0x10e0>
    305c:	000065b7          	lui	a1,0x6
    3060:	6b458593          	addi	a1,a1,1716 # 66b4 <_data+0x9c>
    3064:	00007537          	lui	a0,0x7
    3068:	00100613          	li	a2,1
    306c:	28450513          	addi	a0,a0,644 # 7284 <_data+0xc6c>
    3070:	c84ff0ef          	jal	ra,24f4 <http_reply>
    3074:	df9ff06f          	j	2e6c <http_poll+0x508>
        if (!needle[j])
    3078:	00168693          	addi	a3,a3,1
    307c:	f29ff06f          	j	2fa4 <http_poll+0x640>
    3080:	000479b7          	lui	s3,0x47
    3084:	000077b7          	lui	a5,0x7
    3088:	f8098493          	addi	s1,s3,-128 # 46f80 <page.3199>
    308c:	f8098693          	addi	a3,s3,-128
    while (*s) d[n++] = *s++;
    3090:	03c00713          	li	a4,60
    for (i = 0; path[i]; i++) {
    3094:	00000513          	li	a0,0
    3098:	38478793          	addi	a5,a5,900 # 7384 <_data+0xd6c>
    while (*s) d[n++] = *s++;
    309c:	00150513          	addi	a0,a0,1
    30a0:	00e68023          	sb	a4,0(a3)
    30a4:	00a78633          	add	a2,a5,a0
    30a8:	00064703          	lbu	a4,0(a2)
    30ac:	00168693          	addi	a3,a3,1
    30b0:	fe0716e3          	bnez	a4,309c <http_poll+0x738>
    30b4:	000067b7          	lui	a5,0x6
    30b8:	03c00713          	li	a4,60
    30bc:	6c478793          	addi	a5,a5,1732 # 66c4 <_data+0xac>
    30c0:	00150513          	addi	a0,a0,1
    30c4:	00a486b3          	add	a3,s1,a0
    30c8:	00178793          	addi	a5,a5,1
    30cc:	fee68fa3          	sb	a4,-1(a3)
    30d0:	0007c703          	lbu	a4,0(a5)
    30d4:	fe0716e3          	bnez	a4,30c0 <http_poll+0x75c>
    30d8:	000067b7          	lui	a5,0x6
    30dc:	06200713          	li	a4,98
    30e0:	6cc78793          	addi	a5,a5,1740 # 66cc <_data+0xb4>
    30e4:	00150513          	addi	a0,a0,1
    30e8:	00a486b3          	add	a3,s1,a0
    30ec:	00178793          	addi	a5,a5,1
    30f0:	fee68fa3          	sb	a4,-1(a3)
    30f4:	0007c703          	lbu	a4,0(a5)
    30f8:	fe0716e3          	bnez	a4,30e4 <http_poll+0x780>
    30fc:	000067b7          	lui	a5,0x6
    3100:	02e00713          	li	a4,46
    3104:	72078793          	addi	a5,a5,1824 # 6720 <_data+0x108>
    3108:	00150513          	addi	a0,a0,1
    310c:	00a486b3          	add	a3,s1,a0
    3110:	00178793          	addi	a5,a5,1
    3114:	fee68fa3          	sb	a4,-1(a3)
    3118:	0007c703          	lbu	a4,0(a5)
    311c:	fe0716e3          	bnez	a4,3108 <http_poll+0x7a4>
    3120:	000067b7          	lui	a5,0x6
    3124:	06800713          	li	a4,104
    3128:	75078793          	addi	a5,a5,1872 # 6750 <_data+0x138>
    312c:	00150513          	addi	a0,a0,1
    3130:	00a486b3          	add	a3,s1,a0
    3134:	00178793          	addi	a5,a5,1
    3138:	fee68fa3          	sb	a4,-1(a3)
    313c:	0007c703          	lbu	a4,0(a5)
    3140:	fe0716e3          	bnez	a4,312c <http_poll+0x7c8>
    3144:	000067b7          	lui	a5,0x6
    3148:	02e00713          	li	a4,46
    314c:	78478793          	addi	a5,a5,1924 # 6784 <_data+0x16c>
    3150:	00150513          	addi	a0,a0,1
    3154:	00a486b3          	add	a3,s1,a0
    3158:	00178793          	addi	a5,a5,1
    315c:	fee68fa3          	sb	a4,-1(a3)
    3160:	0007c703          	lbu	a4,0(a5)
    3164:	fe0716e3          	bnez	a4,3150 <http_poll+0x7ec>
    3168:	000067b7          	lui	a5,0x6
    316c:	02e00713          	li	a4,46
    3170:	7a878793          	addi	a5,a5,1960 # 67a8 <_data+0x190>
    3174:	00150513          	addi	a0,a0,1
    3178:	00a486b3          	add	a3,s1,a0
    317c:	00178793          	addi	a5,a5,1
    3180:	fee68fa3          	sb	a4,-1(a3)
    3184:	0007c703          	lbu	a4,0(a5)
    3188:	fe0716e3          	bnez	a4,3174 <http_poll+0x810>
    318c:	000067b7          	lui	a5,0x6
    3190:	02e00713          	li	a4,46
    3194:	7e878793          	addi	a5,a5,2024 # 67e8 <_data+0x1d0>
    3198:	00150513          	addi	a0,a0,1
    319c:	00a486b3          	add	a3,s1,a0
    31a0:	00178793          	addi	a5,a5,1
    31a4:	fee68fa3          	sb	a4,-1(a3)
    31a8:	0007c703          	lbu	a4,0(a5)
    31ac:	fe0716e3          	bnez	a4,3198 <http_poll+0x834>
    31b0:	000077b7          	lui	a5,0x7
    31b4:	02e00713          	li	a4,46
    31b8:	84078793          	addi	a5,a5,-1984 # 6840 <_data+0x228>
    31bc:	00150513          	addi	a0,a0,1
    31c0:	00a486b3          	add	a3,s1,a0
    31c4:	00178793          	addi	a5,a5,1
    31c8:	fee68fa3          	sb	a4,-1(a3)
    31cc:	0007c703          	lbu	a4,0(a5)
    31d0:	fe0716e3          	bnez	a4,31bc <http_poll+0x858>
    31d4:	000077b7          	lui	a5,0x7
    31d8:	02e00713          	li	a4,46
    31dc:	88c78793          	addi	a5,a5,-1908 # 688c <_data+0x274>
    31e0:	00150513          	addi	a0,a0,1
    31e4:	00a486b3          	add	a3,s1,a0
    31e8:	00178793          	addi	a5,a5,1
    31ec:	fee68fa3          	sb	a4,-1(a3)
    31f0:	0007c703          	lbu	a4,0(a5)
    31f4:	fe0716e3          	bnez	a4,31e0 <http_poll+0x87c>
    31f8:	000077b7          	lui	a5,0x7
    31fc:	02e00713          	li	a4,46
    3200:	8ec78793          	addi	a5,a5,-1812 # 68ec <_data+0x2d4>
    3204:	00150513          	addi	a0,a0,1
    3208:	00a486b3          	add	a3,s1,a0
    320c:	00178793          	addi	a5,a5,1
    3210:	fee68fa3          	sb	a4,-1(a3)
    3214:	0007c703          	lbu	a4,0(a5)
    3218:	fe0716e3          	bnez	a4,3204 <http_poll+0x8a0>
    321c:	000077b7          	lui	a5,0x7
    3220:	02300713          	li	a4,35
    3224:	91078793          	addi	a5,a5,-1776 # 6910 <_data+0x2f8>
    3228:	00150513          	addi	a0,a0,1
    322c:	00a486b3          	add	a3,s1,a0
    3230:	00178793          	addi	a5,a5,1
    3234:	fee68fa3          	sb	a4,-1(a3)
    3238:	0007c703          	lbu	a4,0(a5)
    323c:	fe0716e3          	bnez	a4,3228 <http_poll+0x8c4>
    3240:	000077b7          	lui	a5,0x7
    3244:	02e00713          	li	a4,46
    3248:	98c78793          	addi	a5,a5,-1652 # 698c <_data+0x374>
    324c:	00150513          	addi	a0,a0,1
    3250:	00a486b3          	add	a3,s1,a0
    3254:	00178793          	addi	a5,a5,1
    3258:	fee68fa3          	sb	a4,-1(a3)
    325c:	0007c703          	lbu	a4,0(a5)
    3260:	fe0716e3          	bnez	a4,324c <http_poll+0x8e8>
    3264:	000077b7          	lui	a5,0x7
    3268:	07000713          	li	a4,112
    326c:	a1478793          	addi	a5,a5,-1516 # 6a14 <_data+0x3fc>
    3270:	00150513          	addi	a0,a0,1
    3274:	00a486b3          	add	a3,s1,a0
    3278:	00178793          	addi	a5,a5,1
    327c:	fee68fa3          	sb	a4,-1(a3)
    3280:	0007c703          	lbu	a4,0(a5)
    3284:	fe0716e3          	bnez	a4,3270 <http_poll+0x90c>
    3288:	000077b7          	lui	a5,0x7
    328c:	02e00713          	li	a4,46
    3290:	a4878793          	addi	a5,a5,-1464 # 6a48 <_data+0x430>
    3294:	00150513          	addi	a0,a0,1
    3298:	00a486b3          	add	a3,s1,a0
    329c:	00178793          	addi	a5,a5,1
    32a0:	fee68fa3          	sb	a4,-1(a3)
    32a4:	0007c703          	lbu	a4,0(a5)
    32a8:	fe0716e3          	bnez	a4,3294 <http_poll+0x930>
    32ac:	000077b7          	lui	a5,0x7
    32b0:	03c00713          	li	a4,60
    32b4:	a8478793          	addi	a5,a5,-1404 # 6a84 <_data+0x46c>
    32b8:	00150513          	addi	a0,a0,1
    32bc:	00a486b3          	add	a3,s1,a0
    32c0:	00178793          	addi	a5,a5,1
    32c4:	fee68fa3          	sb	a4,-1(a3)
    32c8:	0007c703          	lbu	a4,0(a5)
    32cc:	fe0716e3          	bnez	a4,32b8 <http_poll+0x954>
    32d0:	000077b7          	lui	a5,0x7
    32d4:	03c00713          	li	a4,60
    32d8:	aa078793          	addi	a5,a5,-1376 # 6aa0 <_data+0x488>
    32dc:	00150513          	addi	a0,a0,1
    32e0:	00a486b3          	add	a3,s1,a0
    32e4:	00178793          	addi	a5,a5,1
    32e8:	fee68fa3          	sb	a4,-1(a3)
    32ec:	0007c703          	lbu	a4,0(a5)
    32f0:	fe0716e3          	bnez	a4,32dc <http_poll+0x978>
    32f4:	000077b7          	lui	a5,0x7
    32f8:	03c00713          	li	a4,60
    32fc:	ae878793          	addi	a5,a5,-1304 # 6ae8 <_data+0x4d0>
    3300:	00150513          	addi	a0,a0,1
    3304:	00a486b3          	add	a3,s1,a0
    3308:	00178793          	addi	a5,a5,1
    330c:	fee68fa3          	sb	a4,-1(a3)
    3310:	0007c703          	lbu	a4,0(a5)
    3314:	fe0716e3          	bnez	a4,3300 <http_poll+0x99c>
    3318:	000077b7          	lui	a5,0x7
    331c:	03c00713          	li	a4,60
    3320:	b2c78793          	addi	a5,a5,-1236 # 6b2c <_data+0x514>
    3324:	00150513          	addi	a0,a0,1
    3328:	00a486b3          	add	a3,s1,a0
    332c:	00178793          	addi	a5,a5,1
    3330:	fee68fa3          	sb	a4,-1(a3)
    3334:	0007c703          	lbu	a4,0(a5)
    3338:	fe0716e3          	bnez	a4,3324 <http_poll+0x9c0>
    333c:	000077b7          	lui	a5,0x7
    3340:	03c00713          	li	a4,60
    3344:	b8c78793          	addi	a5,a5,-1140 # 6b8c <_data+0x574>
    3348:	00150513          	addi	a0,a0,1
    334c:	00a486b3          	add	a3,s1,a0
    3350:	00178793          	addi	a5,a5,1
    3354:	fee68fa3          	sb	a4,-1(a3)
    3358:	0007c703          	lbu	a4,0(a5)
    335c:	fe0716e3          	bnez	a4,3348 <http_poll+0x9e4>
    n = kv(d, n, "当前事件", "e"); n = append(d, n, st_evt); n = append(d, n, "</b></div>");
    3360:	00007637          	lui	a2,0x7
    3364:	000075b7          	lui	a1,0x7
    3368:	3d060613          	addi	a2,a2,976 # 73d0 <_data+0xdb8>
    336c:	3d458593          	addi	a1,a1,980 # 73d4 <_data+0xdbc>
    3370:	d31fe0ef          	jal	ra,20a0 <kv.constprop.4>
    3374:	000477b7          	lui	a5,0x47
    3378:	bb878793          	addi	a5,a5,-1096 # 46bb8 <st_evt>
    337c:	00c0006f          	j	3388 <http_poll+0xa24>
    while (*s) d[n++] = *s++;
    3380:	00e68023          	sb	a4,0(a3)
    3384:	00150513          	addi	a0,a0,1
    3388:	0007c703          	lbu	a4,0(a5)
    338c:	00a486b3          	add	a3,s1,a0
    3390:	00178793          	addi	a5,a5,1
    3394:	fe0716e3          	bnez	a4,3380 <http_poll+0xa1c>
    3398:	000077b7          	lui	a5,0x7
    339c:	c0078b13          	addi	s6,a5,-1024 # 6c00 <_data+0x5e8>
    33a0:	03c00713          	li	a4,60
    33a4:	c0078793          	addi	a5,a5,-1024
    33a8:	00150513          	addi	a0,a0,1
    33ac:	00a486b3          	add	a3,s1,a0
    33b0:	00178793          	addi	a5,a5,1
    33b4:	fee68fa3          	sb	a4,-1(a3)
    33b8:	0007c703          	lbu	a4,0(a5)
    33bc:	fe0716e3          	bnez	a4,33a8 <http_poll+0xa44>
    n = kv(d, n, "融合置信度", "sc"); n += uitoa(d + n, (unsigned)st_score); n = append(d, n, "</b></div>");
    33c0:	00007637          	lui	a2,0x7
    33c4:	000075b7          	lui	a1,0x7
    33c8:	3e858593          	addi	a1,a1,1000 # 73e8 <_data+0xdd0>
    33cc:	3e460613          	addi	a2,a2,996 # 73e4 <_data+0xdcc>
    33d0:	cd1fe0ef          	jal	ra,20a0 <kv.constprop.4>
    33d4:	8801a583          	lw	a1,-1920(gp) # 46c38 <st_score>
    33d8:	00050913          	mv	s2,a0
    33dc:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    33e0:	4a058ae3          	beqz	a1,4094 <__stack_size+0x94>
    33e4:	c51fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "融合置信度", "sc"); n += uitoa(d + n, (unsigned)st_score); n = append(d, n, "</b></div>");
    33e8:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    33ec:	03c00713          	li	a4,60
    n = kv(d, n, "融合置信度", "sc"); n += uitoa(d + n, (unsigned)st_score); n = append(d, n, "</b></div>");
    33f0:	000b0793          	mv	a5,s6
    while (*s) d[n++] = *s++;
    33f4:	00150513          	addi	a0,a0,1
    33f8:	00a486b3          	add	a3,s1,a0
    33fc:	00178793          	addi	a5,a5,1
    3400:	fee68fa3          	sb	a4,-1(a3)
    3404:	0007c703          	lbu	a4,0(a5)
    3408:	fe0716e3          	bnez	a4,33f4 <http_poll+0xa90>
    n = kv(d, n, "语音在播", "vo"); n += uitoa(d + n, (unsigned)st_voice); n = append(d, n, "</b></div></div>");
    340c:	00007637          	lui	a2,0x7
    3410:	000075b7          	lui	a1,0x7
    3414:	3fc58593          	addi	a1,a1,1020 # 73fc <_data+0xde4>
    3418:	3f860613          	addi	a2,a2,1016 # 73f8 <_data+0xde0>
    341c:	c85fe0ef          	jal	ra,20a0 <kv.constprop.4>
    3420:	84c1a583          	lw	a1,-1972(gp) # 46c04 <st_voice>
    3424:	00050913          	mv	s2,a0
    3428:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    342c:	46058ce3          	beqz	a1,40a4 <__stack_size+0xa4>
    3430:	c05fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "语音在播", "vo"); n += uitoa(d + n, (unsigned)st_voice); n = append(d, n, "</b></div></div>");
    3434:	000077b7          	lui	a5,0x7
    3438:	c1078a93          	addi	s5,a5,-1008 # 6c10 <_data+0x5f8>
    343c:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    3440:	03c00713          	li	a4,60
    n = kv(d, n, "语音在播", "vo"); n += uitoa(d + n, (unsigned)st_voice); n = append(d, n, "</b></div></div>");
    3444:	c1078793          	addi	a5,a5,-1008
    while (*s) d[n++] = *s++;
    3448:	00150513          	addi	a0,a0,1
    344c:	00a486b3          	add	a3,s1,a0
    3450:	00178793          	addi	a5,a5,1
    3454:	fee68fa3          	sb	a4,-1(a3)
    3458:	0007c703          	lbu	a4,0(a5)
    345c:	fe0716e3          	bnez	a4,3448 <http_poll+0xae4>
    3460:	000077b7          	lui	a5,0x7
    3464:	03c00713          	li	a4,60
    3468:	bb078793          	addi	a5,a5,-1104 # 6bb0 <_data+0x598>
    346c:	00150513          	addi	a0,a0,1
    3470:	00a486b3          	add	a3,s1,a0
    3474:	00178793          	addi	a5,a5,1
    3478:	fee68fa3          	sb	a4,-1(a3)
    347c:	0007c703          	lbu	a4,0(a5)
    3480:	fe0716e3          	bnez	a4,346c <http_poll+0xb08>
    n = kv(d, n, "TinyML 有人", "tm"); n += uitoa(d + n, (unsigned)st_pd_on);
    3484:	00007637          	lui	a2,0x7
    3488:	000075b7          	lui	a1,0x7
    348c:	41058593          	addi	a1,a1,1040 # 7410 <_data+0xdf8>
    3490:	40c60613          	addi	a2,a2,1036 # 740c <_data+0xdf4>
    3494:	c0dfe0ef          	jal	ra,20a0 <kv.constprop.4>
    3498:	87c1a583          	lw	a1,-1924(gp) # 46c34 <st_pd_on>
    349c:	00050913          	mv	s2,a0
    34a0:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    34a4:	48058ee3          	beqz	a1,4140 <__stack_size+0x140>
    34a8:	b8dfe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "TinyML 有人", "tm"); n += uitoa(d + n, (unsigned)st_pd_on);
    34ac:	000077b7          	lui	a5,0x7
    34b0:	00a90933          	add	s2,s2,a0
    while (*s) d[n++] = *s++;
    34b4:	000a0713          	mv	a4,s4
    n = kv(d, n, "TinyML 有人", "tm"); n += uitoa(d + n, (unsigned)st_pd_on);
    34b8:	bd478793          	addi	a5,a5,-1068 # 6bd4 <_data+0x5bc>
    while (*s) d[n++] = *s++;
    34bc:	00190913          	addi	s2,s2,1
    34c0:	01248533          	add	a0,s1,s2
    34c4:	00178793          	addi	a5,a5,1
    34c8:	fee50fa3          	sb	a4,-1(a0)
    34cc:	0007c703          	lbu	a4,0(a5)
    34d0:	fe0716e3          	bnez	a4,34bc <http_poll+0xb58>
    n = append(d, n, " / "); n += uitoa(d + n, (unsigned)st_pd); n = append(d, n, "</b></div>");
    34d4:	8781a583          	lw	a1,-1928(gp) # 46c30 <st_pd>
    if (v == 0) { d[0] = '0'; return 1; }
    34d8:	46058ce3          	beqz	a1,4150 <__stack_size+0x150>
    34dc:	b59fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, " / "); n += uitoa(d + n, (unsigned)st_pd); n = append(d, n, "</b></div>");
    34e0:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    34e4:	03c00713          	li	a4,60
    n = append(d, n, " / "); n += uitoa(d + n, (unsigned)st_pd); n = append(d, n, "</b></div>");
    34e8:	000b0793          	mv	a5,s6
    while (*s) d[n++] = *s++;
    34ec:	00150513          	addi	a0,a0,1
    34f0:	00a486b3          	add	a3,s1,a0
    34f4:	00178793          	addi	a5,a5,1
    34f8:	fee68fa3          	sb	a4,-1(a3)
    34fc:	0007c703          	lbu	a4,0(a5)
    3500:	fe0716e3          	bnez	a4,34ec <http_poll+0xb88>
    n = kv(d, n, "轨迹数量", "nk"); n += uitoa(d + n, (unsigned)st_ntrk); n = append(d, n, "</b></div>");
    3504:	00007637          	lui	a2,0x7
    3508:	000075b7          	lui	a1,0x7
    350c:	42458593          	addi	a1,a1,1060 # 7424 <_data+0xe0c>
    3510:	42060613          	addi	a2,a2,1056 # 7420 <_data+0xe08>
    3514:	b8dfe0ef          	jal	ra,20a0 <kv.constprop.4>
    3518:	8641a583          	lw	a1,-1948(gp) # 46c1c <st_ntrk>
    351c:	00050913          	mv	s2,a0
    3520:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    3524:	42058ee3          	beqz	a1,4160 <__stack_size+0x160>
    3528:	b0dfe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "轨迹数量", "nk"); n += uitoa(d + n, (unsigned)st_ntrk); n = append(d, n, "</b></div>");
    352c:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    3530:	03c00713          	li	a4,60
    n = kv(d, n, "轨迹数量", "nk"); n += uitoa(d + n, (unsigned)st_ntrk); n = append(d, n, "</b></div>");
    3534:	000b0793          	mv	a5,s6
    while (*s) d[n++] = *s++;
    3538:	00150513          	addi	a0,a0,1
    353c:	00a486b3          	add	a3,s1,a0
    3540:	00178793          	addi	a5,a5,1
    3544:	fee68fa3          	sb	a4,-1(a3)
    3548:	0007c703          	lbu	a4,0(a5)
    354c:	fe0716e3          	bnez	a4,3538 <http_poll+0xbd4>
    n = kv(d, n, "推理耗时 ms", "ms"); n += uitoa(d + n, (unsigned)st_ms); n = append(d, n, "</b></div></div>");
    3550:	00007637          	lui	a2,0x7
    3554:	000075b7          	lui	a1,0x7
    3558:	43858593          	addi	a1,a1,1080 # 7438 <_data+0xe20>
    355c:	43460613          	addi	a2,a2,1076 # 7434 <_data+0xe1c>
    3560:	b41fe0ef          	jal	ra,20a0 <kv.constprop.4>
    3564:	8601a583          	lw	a1,-1952(gp) # 46c18 <st_ms>
    3568:	00050913          	mv	s2,a0
    356c:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    3570:	400580e3          	beqz	a1,4170 <__stack_size+0x170>
    3574:	ac1fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "推理耗时 ms", "ms"); n += uitoa(d + n, (unsigned)st_ms); n = append(d, n, "</b></div></div>");
    3578:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    357c:	03c00713          	li	a4,60
    n = kv(d, n, "推理耗时 ms", "ms"); n += uitoa(d + n, (unsigned)st_ms); n = append(d, n, "</b></div></div>");
    3580:	000a8793          	mv	a5,s5
    while (*s) d[n++] = *s++;
    3584:	00150513          	addi	a0,a0,1
    3588:	00a486b3          	add	a3,s1,a0
    358c:	00178793          	addi	a5,a5,1
    3590:	fee68fa3          	sb	a4,-1(a3)
    3594:	0007c703          	lbu	a4,0(a5)
    3598:	fe0716e3          	bnez	a4,3584 <http_poll+0xc20>
    359c:	000077b7          	lui	a5,0x7
    35a0:	03c00713          	li	a4,60
    35a4:	bd878793          	addi	a5,a5,-1064 # 6bd8 <_data+0x5c0>
    35a8:	00150513          	addi	a0,a0,1
    35ac:	00a486b3          	add	a3,s1,a0
    35b0:	00178793          	addi	a5,a5,1
    35b4:	fee68fa3          	sb	a4,-1(a3)
    35b8:	0007c703          	lbu	a4,0(a5)
    35bc:	fe0716e3          	bnez	a4,35a8 <http_poll+0xc44>
    n = kv(d, n, "芯片结温 TA", "ta"); n += uitoa(d + n, (unsigned)st_ta); n = append(d, n, " ℃</b></div>");
    35c0:	00007637          	lui	a2,0x7
    35c4:	000075b7          	lui	a1,0x7
    35c8:	44c58593          	addi	a1,a1,1100 # 744c <_data+0xe34>
    35cc:	44860613          	addi	a2,a2,1096 # 7448 <_data+0xe30>
    35d0:	ad1fe0ef          	jal	ra,20a0 <kv.constprop.4>
    35d4:	86c1a583          	lw	a1,-1940(gp) # 46c24 <st_ta>
    35d8:	00050913          	mv	s2,a0
    35dc:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    35e0:	3a058ae3          	beqz	a1,4194 <__stack_size+0x194>
    35e4:	a51fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "芯片结温 TA", "ta"); n += uitoa(d + n, (unsigned)st_ta); n = append(d, n, " ℃</b></div>");
    35e8:	000077b7          	lui	a5,0x7
    35ec:	bfc78b93          	addi	s7,a5,-1028 # 6bfc <_data+0x5e4>
    35f0:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    35f4:	000a0713          	mv	a4,s4
    n = kv(d, n, "芯片结温 TA", "ta"); n += uitoa(d + n, (unsigned)st_ta); n = append(d, n, " ℃</b></div>");
    35f8:	bfc78793          	addi	a5,a5,-1028
    while (*s) d[n++] = *s++;
    35fc:	00150513          	addi	a0,a0,1
    3600:	00a486b3          	add	a3,s1,a0
    3604:	00178793          	addi	a5,a5,1
    3608:	fee68fa3          	sb	a4,-1(a3)
    360c:	0007c703          	lbu	a4,0(a5)
    3610:	fe0716e3          	bnez	a4,35fc <http_poll+0xc98>
    n = kv(d, n, "目标温度 TO", "to"); n += uitoa(d + n, (unsigned)st_to); n = append(d, n, " ℃</b></div>");
    3614:	00007637          	lui	a2,0x7
    3618:	000075b7          	lui	a1,0x7
    361c:	46058593          	addi	a1,a1,1120 # 7460 <_data+0xe48>
    3620:	45c60613          	addi	a2,a2,1116 # 745c <_data+0xe44>
    3624:	a7dfe0ef          	jal	ra,20a0 <kv.constprop.4>
    3628:	8681a583          	lw	a1,-1944(gp) # 46c20 <st_to>
    362c:	00050913          	mv	s2,a0
    3630:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    3634:	360588e3          	beqz	a1,41a4 <__stack_size+0x1a4>
    3638:	9fdfe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "目标温度 TO", "to"); n += uitoa(d + n, (unsigned)st_to); n = append(d, n, " ℃</b></div>");
    363c:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    3640:	000a0713          	mv	a4,s4
    n = kv(d, n, "目标温度 TO", "to"); n += uitoa(d + n, (unsigned)st_to); n = append(d, n, " ℃</b></div>");
    3644:	000b8793          	mv	a5,s7
    while (*s) d[n++] = *s++;
    3648:	00150513          	addi	a0,a0,1
    364c:	00a486b3          	add	a3,s1,a0
    3650:	00178793          	addi	a5,a5,1
    3654:	fee68fa3          	sb	a4,-1(a3)
    3658:	0007c703          	lbu	a4,0(a5)
    365c:	fe0716e3          	bnez	a4,3648 <http_poll+0xce4>
    n = kv(d, n, "空气温湿度", "sh"); n += uitoa(d + n, (unsigned)st_sht); n = append(d, n, " ℃</b></div></div>");
    3660:	00007637          	lui	a2,0x7
    3664:	000075b7          	lui	a1,0x7
    3668:	47458593          	addi	a1,a1,1140 # 7474 <_data+0xe5c>
    366c:	47060613          	addi	a2,a2,1136 # 7470 <_data+0xe58>
    3670:	a31fe0ef          	jal	ra,20a0 <kv.constprop.4>
    3674:	8701a583          	lw	a1,-1936(gp) # 46c28 <st_sht>
    3678:	00050913          	mv	s2,a0
    367c:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    3680:	32058ae3          	beqz	a1,41b4 <__stack_size+0x1b4>
    3684:	9b1fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "空气温湿度", "sh"); n += uitoa(d + n, (unsigned)st_sht); n = append(d, n, " ℃</b></div></div>");
    3688:	000077b7          	lui	a5,0x7
    368c:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    3690:	000a0713          	mv	a4,s4
    n = kv(d, n, "空气温湿度", "sh"); n += uitoa(d + n, (unsigned)st_sht); n = append(d, n, " ℃</b></div></div>");
    3694:	c0c78793          	addi	a5,a5,-1012 # 6c0c <_data+0x5f4>
    while (*s) d[n++] = *s++;
    3698:	00150513          	addi	a0,a0,1
    369c:	00a486b3          	add	a3,s1,a0
    36a0:	00178793          	addi	a5,a5,1
    36a4:	fee68fa3          	sb	a4,-1(a3)
    36a8:	0007c703          	lbu	a4,0(a5)
    36ac:	fe0716e3          	bnez	a4,3698 <http_poll+0xd34>
    36b0:	000077b7          	lui	a5,0x7
    36b4:	03c00713          	li	a4,60
    36b8:	c2478793          	addi	a5,a5,-988 # 6c24 <_data+0x60c>
    36bc:	00150513          	addi	a0,a0,1
    36c0:	00a486b3          	add	a3,s1,a0
    36c4:	00178793          	addi	a5,a5,1
    36c8:	fee68fa3          	sb	a4,-1(a3)
    36cc:	0007c703          	lbu	a4,0(a5)
    36d0:	fe0716e3          	bnez	a4,36bc <http_poll+0xd58>
    n = kv(d, n, "主目标框", "bx"); n += uitoa(d + n, (unsigned)st_x0);
    36d4:	00007637          	lui	a2,0x7
    36d8:	000075b7          	lui	a1,0x7
    36dc:	48858593          	addi	a1,a1,1160 # 7488 <_data+0xe70>
    36e0:	48460613          	addi	a2,a2,1156 # 7484 <_data+0xe6c>
    36e4:	9bdfe0ef          	jal	ra,20a0 <kv.constprop.4>
    36e8:	85c1a583          	lw	a1,-1956(gp) # 46c14 <st_x0>
    36ec:	00050913          	mv	s2,a0
    36f0:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    36f4:	2c0588e3          	beqz	a1,41c4 <__stack_size+0x1c4>
    36f8:	93dfe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "主目标框", "bx"); n += uitoa(d + n, (unsigned)st_x0);
    36fc:	00a90933          	add	s2,s2,a0
    n = append(d, n, ","); n += uitoa(d + n, (unsigned)st_y0);
    3700:	8581a583          	lw	a1,-1960(gp) # 46c10 <st_y0>
    while (*s) d[n++] = *s++;
    3704:	02c00713          	li	a4,44
    3708:	012487b3          	add	a5,s1,s2
    370c:	00e78023          	sb	a4,0(a5)
    3710:	00190913          	addi	s2,s2,1
    n = append(d, n, ","); n += uitoa(d + n, (unsigned)st_y0);
    3714:	01248533          	add	a0,s1,s2
    if (v == 0) { d[0] = '0'; return 1; }
    3718:	2a058ee3          	beqz	a1,41d4 <__stack_size+0x1d4>
    371c:	919fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ","); n += uitoa(d + n, (unsigned)st_y0);
    3720:	000077b7          	lui	a5,0x7
    3724:	00a90933          	add	s2,s2,a0
    3728:	c4878793          	addi	a5,a5,-952 # 6c48 <_data+0x630>
    while (*s) d[n++] = *s++;
    372c:	00190913          	addi	s2,s2,1
    3730:	01248533          	add	a0,s1,s2
    3734:	00178793          	addi	a5,a5,1
    3738:	ff450fa3          	sb	s4,-1(a0)
    373c:	0007ca03          	lbu	s4,0(a5)
    3740:	fe0a16e3          	bnez	s4,372c <http_poll+0xdc8>
    n = append(d, n, " – "); n += uitoa(d + n, (unsigned)st_x1);
    3744:	8541a583          	lw	a1,-1964(gp) # 46c0c <st_x1>
    if (v == 0) { d[0] = '0'; return 1; }
    3748:	2a0586e3          	beqz	a1,41f4 <__stack_size+0x1f4>
    374c:	8e9fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, " – "); n += uitoa(d + n, (unsigned)st_x1);
    3750:	00a90933          	add	s2,s2,a0
    n = append(d, n, ","); n += uitoa(d + n, (unsigned)st_y1); n = append(d, n, "</b></div>");
    3754:	8501a583          	lw	a1,-1968(gp) # 46c08 <st_y1>
    while (*s) d[n++] = *s++;
    3758:	02c00713          	li	a4,44
    375c:	012487b3          	add	a5,s1,s2
    3760:	00e78023          	sb	a4,0(a5)
    3764:	00190913          	addi	s2,s2,1
    n = append(d, n, ","); n += uitoa(d + n, (unsigned)st_y1); n = append(d, n, "</b></div>");
    3768:	01248533          	add	a0,s1,s2
    if (v == 0) { d[0] = '0'; return 1; }
    376c:	26058ce3          	beqz	a1,41e4 <__stack_size+0x1e4>
    3770:	8c5fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ","); n += uitoa(d + n, (unsigned)st_y1); n = append(d, n, "</b></div>");
    3774:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    3778:	03c00793          	li	a5,60
    377c:	00150513          	addi	a0,a0,1
    3780:	00a48733          	add	a4,s1,a0
    3784:	001b0b13          	addi	s6,s6,1
    3788:	fef70fa3          	sb	a5,-1(a4)
    378c:	000b4783          	lbu	a5,0(s6)
    3790:	fe0796e3          	bnez	a5,377c <http_poll+0xe18>
    n = kv(d, n, "低功耗", "lp"); n += uitoa(d + n, (unsigned)st_lp); n = append(d, n, "</b></div></div>");
    3794:	00007637          	lui	a2,0x7
    3798:	000075b7          	lui	a1,0x7
    379c:	49c58593          	addi	a1,a1,1180 # 749c <_data+0xe84>
    37a0:	49860613          	addi	a2,a2,1176 # 7498 <_data+0xe80>
    37a4:	8fdfe0ef          	jal	ra,20a0 <kv.constprop.4>
    37a8:	8741a583          	lw	a1,-1932(gp) # 46c2c <st_lp>
    37ac:	00050913          	mv	s2,a0
    37b0:	00a48533          	add	a0,s1,a0
    if (v == 0) { d[0] = '0'; return 1; }
    37b4:	240588e3          	beqz	a1,4204 <__stack_size+0x204>
    37b8:	87dfe0ef          	jal	ra,2034 <uitoa.part.0>
    n = kv(d, n, "低功耗", "lp"); n += uitoa(d + n, (unsigned)st_lp); n = append(d, n, "</b></div></div>");
    37bc:	00a90533          	add	a0,s2,a0
    while (*s) d[n++] = *s++;
    37c0:	03c00713          	li	a4,60
    n = kv(d, n, "低功耗", "lp"); n += uitoa(d + n, (unsigned)st_lp); n = append(d, n, "</b></div></div>");
    37c4:	000a8793          	mv	a5,s5
    while (*s) d[n++] = *s++;
    37c8:	00150513          	addi	a0,a0,1
    37cc:	00a486b3          	add	a3,s1,a0
    37d0:	00178793          	addi	a5,a5,1
    37d4:	fee68fa3          	sb	a4,-1(a3)
    37d8:	0007c703          	lbu	a4,0(a5)
    37dc:	fe0716e3          	bnez	a4,37c8 <http_poll+0xe64>
    37e0:	000077b7          	lui	a5,0x7
    37e4:	03c00713          	li	a4,60
    37e8:	c5078793          	addi	a5,a5,-944 # 6c50 <_data+0x638>
    37ec:	00150513          	addi	a0,a0,1
    37f0:	00a486b3          	add	a3,s1,a0
    37f4:	00178793          	addi	a5,a5,1
    37f8:	fee68fa3          	sb	a4,-1(a3)
    37fc:	0007c703          	lbu	a4,0(a5)
    3800:	fe0716e3          	bnez	a4,37ec <http_poll+0xe88>
    3804:	000077b7          	lui	a5,0x7
    3808:	03c00713          	li	a4,60
    380c:	c7478793          	addi	a5,a5,-908 # 6c74 <_data+0x65c>
    3810:	00150513          	addi	a0,a0,1
    3814:	00a486b3          	add	a3,s1,a0
    3818:	00178793          	addi	a5,a5,1
    381c:	fee68fa3          	sb	a4,-1(a3)
    3820:	0007c703          	lbu	a4,0(a5)
    3824:	fe0716e3          	bnez	a4,3810 <http_poll+0xeac>
    3828:	000077b7          	lui	a5,0x7
    382c:	03c00713          	li	a4,60
    3830:	cbc78793          	addi	a5,a5,-836 # 6cbc <_data+0x6a4>
    3834:	00150513          	addi	a0,a0,1
    3838:	00a486b3          	add	a3,s1,a0
    383c:	00178793          	addi	a5,a5,1
    3840:	fee68fa3          	sb	a4,-1(a3)
    3844:	0007c703          	lbu	a4,0(a5)
    3848:	fe0716e3          	bnez	a4,3834 <http_poll+0xed0>
    n = kv(d, n, "当前", "ar");
    384c:	00007637          	lui	a2,0x7
    3850:	000075b7          	lui	a1,0x7
    3854:	4a860613          	addi	a2,a2,1192 # 74a8 <_data+0xe90>
    3858:	4ac58593          	addi	a1,a1,1196 # 74ac <_data+0xe94>
    385c:	845fe0ef          	jal	ra,20a0 <kv.constprop.4>
    n = append(d, n, st_arm ? "已开启 入框响" : "已关闭 入框不响");
    3860:	8481a783          	lw	a5,-1976(gp) # 46c00 <st_arm>
    3864:	1a0798e3          	bnez	a5,4214 <__stack_size+0x214>
    3868:	000077b7          	lui	a5,0x7
    386c:	d1878793          	addi	a5,a5,-744 # 6d18 <_data+0x700>
    3870:	00050613          	mv	a2,a0
    3874:	00c0006f          	j	3880 <http_poll+0xf1c>
    while (*s) d[n++] = *s++;
    3878:	00e68023          	sb	a4,0(a3)
    387c:	00160613          	addi	a2,a2,1
    3880:	40a60733          	sub	a4,a2,a0
    3884:	00e78733          	add	a4,a5,a4
    3888:	00074703          	lbu	a4,0(a4)
    388c:	00c486b3          	add	a3,s1,a2
    3890:	fe0714e3          	bnez	a4,3878 <http_poll+0xf14>
    3894:	03c00793          	li	a5,60
    3898:	00160613          	addi	a2,a2,1
    389c:	00c48733          	add	a4,s1,a2
    38a0:	001a8a93          	addi	s5,s5,1
    38a4:	fef70fa3          	sb	a5,-1(a4)
    38a8:	000ac783          	lbu	a5,0(s5)
    38ac:	fe0796e3          	bnez	a5,3898 <http_poll+0xf34>
    38b0:	000077b7          	lui	a5,0x7
    38b4:	03c00713          	li	a4,60
    38b8:	d3078793          	addi	a5,a5,-720 # 6d30 <_data+0x718>
    38bc:	00160613          	addi	a2,a2,1
    38c0:	00c486b3          	add	a3,s1,a2
    38c4:	00178793          	addi	a5,a5,1
    38c8:	fee68fa3          	sb	a4,-1(a3)
    38cc:	0007c703          	lbu	a4,0(a5)
    38d0:	fe0716e3          	bnez	a4,38bc <http_poll+0xf58>
    38d4:	000077b7          	lui	a5,0x7
    38d8:	03c00713          	li	a4,60
    38dc:	d5478793          	addi	a5,a5,-684 # 6d54 <_data+0x73c>
    38e0:	00160613          	addi	a2,a2,1
    38e4:	00c486b3          	add	a3,s1,a2
    38e8:	00178793          	addi	a5,a5,1
    38ec:	fee68fa3          	sb	a4,-1(a3)
    38f0:	0007c703          	lbu	a4,0(a5)
    38f4:	fe0716e3          	bnez	a4,38e0 <http_poll+0xf7c>
    38f8:	000077b7          	lui	a5,0x7
    38fc:	03c00713          	li	a4,60
    3900:	d9878793          	addi	a5,a5,-616 # 6d98 <_data+0x780>
    3904:	00160613          	addi	a2,a2,1
    3908:	00c486b3          	add	a3,s1,a2
    390c:	00178793          	addi	a5,a5,1
    3910:	fee68fa3          	sb	a4,-1(a3)
    3914:	0007c703          	lbu	a4,0(a5)
    3918:	fe0716e3          	bnez	a4,3904 <http_poll+0xfa0>
    391c:	000077b7          	lui	a5,0x7
    3920:	03c00713          	li	a4,60
    3924:	ddc78793          	addi	a5,a5,-548 # 6ddc <_data+0x7c4>
    3928:	00160613          	addi	a2,a2,1
    392c:	00c486b3          	add	a3,s1,a2
    3930:	00178793          	addi	a5,a5,1
    3934:	fee68fa3          	sb	a4,-1(a3)
    3938:	0007c703          	lbu	a4,0(a5)
    393c:	fe0716e3          	bnez	a4,3928 <http_poll+0xfc4>
    3940:	000077b7          	lui	a5,0x7
    3944:	03c00713          	li	a4,60
    3948:	e2078793          	addi	a5,a5,-480 # 6e20 <_data+0x808>
    394c:	00160613          	addi	a2,a2,1
    3950:	00c486b3          	add	a3,s1,a2
    3954:	00178793          	addi	a5,a5,1
    3958:	fee68fa3          	sb	a4,-1(a3)
    395c:	0007c703          	lbu	a4,0(a5)
    3960:	fe0716e3          	bnez	a4,394c <http_poll+0xfe8>
    3964:	000077b7          	lui	a5,0x7
    3968:	03c00713          	li	a4,60
    396c:	e6878793          	addi	a5,a5,-408 # 6e68 <_data+0x850>
    3970:	00160613          	addi	a2,a2,1
    3974:	00c486b3          	add	a3,s1,a2
    3978:	00178793          	addi	a5,a5,1
    397c:	fee68fa3          	sb	a4,-1(a3)
    3980:	0007c703          	lbu	a4,0(a5)
    3984:	fe0716e3          	bnez	a4,3970 <http_poll+0x100c>
    3988:	000077b7          	lui	a5,0x7
    398c:	03c00713          	li	a4,60
    3990:	eb478793          	addi	a5,a5,-332 # 6eb4 <_data+0x89c>
    3994:	00160613          	addi	a2,a2,1
    3998:	00c486b3          	add	a3,s1,a2
    399c:	00178793          	addi	a5,a5,1
    39a0:	fee68fa3          	sb	a4,-1(a3)
    39a4:	0007c703          	lbu	a4,0(a5)
    39a8:	fe0716e3          	bnez	a4,3994 <http_poll+0x1030>
    39ac:	000077b7          	lui	a5,0x7
    39b0:	03c00713          	li	a4,60
    39b4:	f0078793          	addi	a5,a5,-256 # 6f00 <_data+0x8e8>
    39b8:	00160613          	addi	a2,a2,1
    39bc:	00c486b3          	add	a3,s1,a2
    39c0:	00178793          	addi	a5,a5,1
    39c4:	fee68fa3          	sb	a4,-1(a3)
    39c8:	0007c703          	lbu	a4,0(a5)
    39cc:	fe0716e3          	bnez	a4,39b8 <http_poll+0x1054>
        int idx = (hist_i - 1 - k);
    39d0:	8401a583          	lw	a1,-1984(gp) # 46bf8 <__bss_start>
    for (k = 0; k < hist_n; k++) {
    39d4:	8441ae83          	lw	t4,-1980(gp) # 46bfc <hist_n>
        int idx = (hist_i - 1 - k);
    39d8:	fff58593          	addi	a1,a1,-1
    39dc:	00058693          	mv	a3,a1
        n = append(d, n, hist[idx]);
    39e0:	8c818813          	addi	a6,gp,-1848 # 46c80 <hist>
    39e4:	06000e13          	li	t3,96
    while (*s) d[n++] = *s++;
    39e8:	00a00313          	li	t1,10
    for (k = 0; k < hist_n; k++) {
    39ec:	40d587b3          	sub	a5,a1,a3
    39f0:	03d7d8e3          	bge	a5,t4,4220 <__stack_size+0x220>
        int idx = (hist_i - 1 - k);
    39f4:	00068793          	mv	a5,a3
        if (idx < 0) idx += 8;
    39f8:	0006d463          	bgez	a3,3a00 <http_poll+0x109c>
    39fc:	00868793          	addi	a5,a3,8
        n = append(d, n, hist[idx]);
    3a00:	03c787b3          	mul	a5,a5,t3
    3a04:	00f80733          	add	a4,a6,a5
    while (*s) d[n++] = *s++;
    3a08:	00074503          	lbu	a0,0(a4)
    3a0c:	00060793          	mv	a5,a2
    3a10:	02050063          	beqz	a0,3a30 <http_poll+0x10cc>
    3a14:	00178793          	addi	a5,a5,1
    3a18:	00f48f33          	add	t5,s1,a5
    3a1c:	40c788b3          	sub	a7,a5,a2
    3a20:	feaf0fa3          	sb	a0,-1(t5)
    3a24:	01170533          	add	a0,a4,a7
    3a28:	00054503          	lbu	a0,0(a0)
    3a2c:	fe0514e3          	bnez	a0,3a14 <http_poll+0x10b0>
    3a30:	00f48733          	add	a4,s1,a5
    3a34:	00670023          	sb	t1,0(a4)
    return n;
    3a38:	fff68693          	addi	a3,a3,-1
    while (*s) d[n++] = *s++;
    3a3c:	00178613          	addi	a2,a5,1
    3a40:	fadff06f          	j	39ec <http_poll+0x1088>
        http_reply("text/plain", (const uint8_t *)(st_arm ? "1" : "0"), 1);
    3a44:	000065b7          	lui	a1,0x6
    3a48:	6b058593          	addi	a1,a1,1712 # 66b0 <_data+0x98>
    3a4c:	e18ff06f          	j	3064 <http_poll+0x700>
    3a50:	00060713          	mv	a4,a2
    3a54:	00068793          	mv	a5,a3
        for (j = 0; needle[j] && path[i + j] == needle[j]; j++)
    3a58:	07300813          	li	a6,115
    3a5c:	00007537          	lui	a0,0x7
    3a60:	03071663          	bne	a4,a6,3a8c <http_poll+0x1128>
    3a64:	2c650593          	addi	a1,a0,710 # 72c6 <_data+0xcae>
    3a68:	00078613          	mv	a2,a5
    3a6c:	07400713          	li	a4,116
    3a70:	0100006f          	j	3a80 <http_poll+0x111c>
    3a74:	0005c703          	lbu	a4,0(a1)
    3a78:	00158593          	addi	a1,a1,1
    3a7c:	0a070263          	beqz	a4,3b20 <http_poll+0x11bc>
    3a80:	00164883          	lbu	a7,1(a2)
    3a84:	00160613          	addi	a2,a2,1
    3a88:	fee886e3          	beq	a7,a4,3a74 <http_poll+0x1110>
        if (!needle[j])
    3a8c:	00178793          	addi	a5,a5,1
    for (i = 0; path[i]; i++) {
    3a90:	0007c703          	lbu	a4,0(a5)
    3a94:	fc0716e3          	bnez	a4,3a60 <http_poll+0x10fc>
    3a98:	cb8ff06f          	j	2f50 <http_poll+0x5ec>
        || path_has(path, "/t.b") || (path[0] == '/' && path[1] == 't' && path[2] == 0)) {
    3a9c:	00114703          	lbu	a4,1(sp)
    3aa0:	07400793          	li	a5,116
    3aa4:	aaf70e63          	beq	a4,a5,2d60 <http_poll+0x3fc>
        if (path[i] != want[i])
    3aa8:	000077b7          	lui	a5,0x7
    3aac:	00100513          	li	a0,1
    3ab0:	00110713          	addi	a4,sp,1
    3ab4:	2b678793          	addi	a5,a5,694 # 72b6 <_data+0xc9e>
    while (want[i]) {
    3ab8:	07300813          	li	a6,115
    3abc:	40d50533          	sub	a0,a0,a3
        if (path[i] != want[i])
    3ac0:	00074883          	lbu	a7,0(a4)
    3ac4:	00e505b3          	add	a1,a0,a4
    3ac8:	00170713          	addi	a4,a4,1
    3acc:	03089863          	bne	a7,a6,3afc <http_poll+0x1198>
    while (want[i]) {
    3ad0:	0007c803          	lbu	a6,0(a5)
    3ad4:	00178793          	addi	a5,a5,1
    3ad8:	fe0814e3          	bnez	a6,3ac0 <http_poll+0x115c>
    return path[i] == 0 || path[i] == '?' || path[i] == '#';
    3adc:	02010793          	addi	a5,sp,32
    3ae0:	00b787b3          	add	a5,a5,a1
    3ae4:	fe07c783          	lbu	a5,-32(a5)
    3ae8:	02078c63          	beqz	a5,3b20 <http_poll+0x11bc>
    3aec:	03f00713          	li	a4,63
    3af0:	02e78863          	beq	a5,a4,3b20 <http_poll+0x11bc>
    3af4:	02300713          	li	a4,35
    3af8:	02e78463          	beq	a5,a4,3b20 <http_poll+0x11bc>
        if (path[i] != want[i])
    3afc:	00114703          	lbu	a4,1(sp)
    3b00:	07300793          	li	a5,115
    3b04:	f4f716e3          	bne	a4,a5,3a50 <http_poll+0x10ec>
    return path[i] == 0 || path[i] == '?' || path[i] == '#';
    3b08:	00214783          	lbu	a5,2(sp)
    3b0c:	00078a63          	beqz	a5,3b20 <http_poll+0x11bc>
    3b10:	03f00713          	li	a4,63
    3b14:	00e78663          	beq	a5,a4,3b20 <http_poll+0x11bc>
    3b18:	02300713          	li	a4,35
    3b1c:	f2e79ae3          	bne	a5,a4,3a50 <http_poll+0x10ec>
        for (j = 0; needle[j] && path[i + j] == needle[j]; j++)
    3b20:	000067b7          	lui	a5,0x6
    3b24:	000479b7          	lui	s3,0x47
    3b28:	07b00693          	li	a3,123
    3b2c:	00000713          	li	a4,0
    3b30:	6b878793          	addi	a5,a5,1720 # 66b8 <_data+0xa0>
    3b34:	f8098493          	addi	s1,s3,-128 # 46f80 <page.3199>
    3b38:	0080006f          	j	3b40 <http_poll+0x11dc>
    while (*s) d[n++] = *s++;
    3b3c:	00060713          	mv	a4,a2
    3b40:	00170613          	addi	a2,a4,1
    3b44:	00c485b3          	add	a1,s1,a2
    3b48:	00178793          	addi	a5,a5,1
    3b4c:	fed58fa3          	sb	a3,-1(a1)
    3b50:	0007c683          	lbu	a3,0(a5)
    3b54:	fe0694e3          	bnez	a3,3b3c <http_poll+0x11d8>
    3b58:	000476b7          	lui	a3,0x47
    3b5c:	bb868693          	addi	a3,a3,-1096 # 46bb8 <st_evt>
    3b60:	0006c783          	lbu	a5,0(a3)
    3b64:	02078263          	beqz	a5,3b88 <http_poll+0x1224>
    3b68:	fff74713          	not	a4,a4
    3b6c:	00160613          	addi	a2,a2,1
    3b70:	00c705b3          	add	a1,a4,a2
    3b74:	00c48533          	add	a0,s1,a2
    3b78:	00b685b3          	add	a1,a3,a1
    3b7c:	fef50fa3          	sb	a5,-1(a0)
    3b80:	0005c783          	lbu	a5,0(a1)
    3b84:	fe0794e3          	bnez	a5,3b6c <http_poll+0x1208>
    3b88:	000077b7          	lui	a5,0x7
    3b8c:	00060913          	mv	s2,a2
    3b90:	02200713          	li	a4,34
    3b94:	2d078793          	addi	a5,a5,720 # 72d0 <_data+0xcb8>
    3b98:	00190913          	addi	s2,s2,1
    3b9c:	40c906b3          	sub	a3,s2,a2
    3ba0:	01248533          	add	a0,s1,s2
    3ba4:	00d786b3          	add	a3,a5,a3
    3ba8:	fee50fa3          	sb	a4,-1(a0)
    3bac:	0006c703          	lbu	a4,0(a3)
    3bb0:	fe0714e3          	bnez	a4,3b98 <http_poll+0x1234>
    n = append(d, n, "\",\"score\":"); n += uitoa(d + n, (unsigned)st_score);
    3bb4:	8801a583          	lw	a1,-1920(gp) # 46c38 <st_score>
    if (v == 0) { d[0] = '0'; return 1; }
    3bb8:	38058863          	beqz	a1,3f48 <http_poll+0x15e4>
    3bbc:	c78fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, "\",\"score\":"); n += uitoa(d + n, (unsigned)st_score);
    3bc0:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"pd_on\":"); n += uitoa(d + n, (unsigned)st_pd_on);
    3bc4:	00007737          	lui	a4,0x7
    n = append(d, n, "\",\"score\":"); n += uitoa(d + n, (unsigned)st_score);
    3bc8:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3bcc:	02c00693          	li	a3,44
    3bd0:	2dc70713          	addi	a4,a4,732 # 72dc <_data+0xcc4>
    3bd4:	00190913          	addi	s2,s2,1
    3bd8:	40f90633          	sub	a2,s2,a5
    3bdc:	01248533          	add	a0,s1,s2
    3be0:	00c70633          	add	a2,a4,a2
    3be4:	fed50fa3          	sb	a3,-1(a0)
    3be8:	00064683          	lbu	a3,0(a2)
    3bec:	fe0694e3          	bnez	a3,3bd4 <http_poll+0x1270>
    n = append(d, n, ",\"pd_on\":"); n += uitoa(d + n, (unsigned)st_pd_on);
    3bf0:	87c1a583          	lw	a1,-1924(gp) # 46c34 <st_pd_on>
    if (v == 0) { d[0] = '0'; return 1; }
    3bf4:	36058263          	beqz	a1,3f58 <http_poll+0x15f4>
    3bf8:	c3cfe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"pd_on\":"); n += uitoa(d + n, (unsigned)st_pd_on);
    3bfc:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"pd\":"); n += uitoa(d + n, (unsigned)st_pd);
    3c00:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"pd_on\":"); n += uitoa(d + n, (unsigned)st_pd_on);
    3c04:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3c08:	02c00693          	li	a3,44
    3c0c:	2e870713          	addi	a4,a4,744 # 72e8 <_data+0xcd0>
    3c10:	00190913          	addi	s2,s2,1
    3c14:	40f90633          	sub	a2,s2,a5
    3c18:	01248533          	add	a0,s1,s2
    3c1c:	00c70633          	add	a2,a4,a2
    3c20:	fed50fa3          	sb	a3,-1(a0)
    3c24:	00064683          	lbu	a3,0(a2)
    3c28:	fe0694e3          	bnez	a3,3c10 <http_poll+0x12ac>
    n = append(d, n, ",\"pd\":"); n += uitoa(d + n, (unsigned)st_pd);
    3c2c:	8781a583          	lw	a1,-1928(gp) # 46c30 <st_pd>
    if (v == 0) { d[0] = '0'; return 1; }
    3c30:	32058c63          	beqz	a1,3f68 <http_poll+0x1604>
    3c34:	c00fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"pd\":"); n += uitoa(d + n, (unsigned)st_pd);
    3c38:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"ta\":"); n += uitoa(d + n, (unsigned)st_ta);
    3c3c:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"pd\":"); n += uitoa(d + n, (unsigned)st_pd);
    3c40:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3c44:	02c00693          	li	a3,44
    3c48:	2f070713          	addi	a4,a4,752 # 72f0 <_data+0xcd8>
    3c4c:	00190913          	addi	s2,s2,1
    3c50:	40f90633          	sub	a2,s2,a5
    3c54:	01248533          	add	a0,s1,s2
    3c58:	00c70633          	add	a2,a4,a2
    3c5c:	fed50fa3          	sb	a3,-1(a0)
    3c60:	00064683          	lbu	a3,0(a2)
    3c64:	fe0694e3          	bnez	a3,3c4c <http_poll+0x12e8>
    n = append(d, n, ",\"ta\":"); n += uitoa(d + n, (unsigned)st_ta);
    3c68:	86c1a583          	lw	a1,-1940(gp) # 46c24 <st_ta>
    if (v == 0) { d[0] = '0'; return 1; }
    3c6c:	30058663          	beqz	a1,3f78 <http_poll+0x1614>
    3c70:	bc4fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"ta\":"); n += uitoa(d + n, (unsigned)st_ta);
    3c74:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"to\":"); n += uitoa(d + n, (unsigned)st_to);
    3c78:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"ta\":"); n += uitoa(d + n, (unsigned)st_ta);
    3c7c:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3c80:	02c00693          	li	a3,44
    3c84:	2f870713          	addi	a4,a4,760 # 72f8 <_data+0xce0>
    3c88:	00190913          	addi	s2,s2,1
    3c8c:	40f90633          	sub	a2,s2,a5
    3c90:	01248533          	add	a0,s1,s2
    3c94:	00c70633          	add	a2,a4,a2
    3c98:	fed50fa3          	sb	a3,-1(a0)
    3c9c:	00064683          	lbu	a3,0(a2)
    3ca0:	fe0694e3          	bnez	a3,3c88 <http_poll+0x1324>
    n = append(d, n, ",\"to\":"); n += uitoa(d + n, (unsigned)st_to);
    3ca4:	8681a583          	lw	a1,-1944(gp) # 46c20 <st_to>
    if (v == 0) { d[0] = '0'; return 1; }
    3ca8:	2e058063          	beqz	a1,3f88 <http_poll+0x1624>
    3cac:	b88fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"to\":"); n += uitoa(d + n, (unsigned)st_to);
    3cb0:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"sht\":"); n += uitoa(d + n, (unsigned)st_sht);
    3cb4:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"to\":"); n += uitoa(d + n, (unsigned)st_to);
    3cb8:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3cbc:	02c00693          	li	a3,44
    3cc0:	30070713          	addi	a4,a4,768 # 7300 <_data+0xce8>
    3cc4:	00190913          	addi	s2,s2,1
    3cc8:	40f90633          	sub	a2,s2,a5
    3ccc:	01248533          	add	a0,s1,s2
    3cd0:	00c70633          	add	a2,a4,a2
    3cd4:	fed50fa3          	sb	a3,-1(a0)
    3cd8:	00064683          	lbu	a3,0(a2)
    3cdc:	fe0694e3          	bnez	a3,3cc4 <http_poll+0x1360>
    n = append(d, n, ",\"sht\":"); n += uitoa(d + n, (unsigned)st_sht);
    3ce0:	8701a583          	lw	a1,-1936(gp) # 46c28 <st_sht>
    if (v == 0) { d[0] = '0'; return 1; }
    3ce4:	2a058a63          	beqz	a1,3f98 <http_poll+0x1634>
    3ce8:	b4cfe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"sht\":"); n += uitoa(d + n, (unsigned)st_sht);
    3cec:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"lp\":"); n += uitoa(d + n, (unsigned)st_lp);
    3cf0:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"sht\":"); n += uitoa(d + n, (unsigned)st_sht);
    3cf4:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3cf8:	02c00693          	li	a3,44
    3cfc:	30870713          	addi	a4,a4,776 # 7308 <_data+0xcf0>
    3d00:	00190913          	addi	s2,s2,1
    3d04:	40f90633          	sub	a2,s2,a5
    3d08:	01248533          	add	a0,s1,s2
    3d0c:	00c70633          	add	a2,a4,a2
    3d10:	fed50fa3          	sb	a3,-1(a0)
    3d14:	00064683          	lbu	a3,0(a2)
    3d18:	fe0694e3          	bnez	a3,3d00 <http_poll+0x139c>
    n = append(d, n, ",\"lp\":"); n += uitoa(d + n, (unsigned)st_lp);
    3d1c:	8741a583          	lw	a1,-1932(gp) # 46c2c <st_lp>
    if (v == 0) { d[0] = '0'; return 1; }
    3d20:	28058463          	beqz	a1,3fa8 <http_poll+0x1644>
    3d24:	b10fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"lp\":"); n += uitoa(d + n, (unsigned)st_lp);
    3d28:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"ntrk\":"); n += uitoa(d + n, (unsigned)st_ntrk);
    3d2c:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"lp\":"); n += uitoa(d + n, (unsigned)st_lp);
    3d30:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3d34:	02c00693          	li	a3,44
    3d38:	31070713          	addi	a4,a4,784 # 7310 <_data+0xcf8>
    3d3c:	00190913          	addi	s2,s2,1
    3d40:	40f90633          	sub	a2,s2,a5
    3d44:	01248533          	add	a0,s1,s2
    3d48:	00c70633          	add	a2,a4,a2
    3d4c:	fed50fa3          	sb	a3,-1(a0)
    3d50:	00064683          	lbu	a3,0(a2)
    3d54:	fe0694e3          	bnez	a3,3d3c <http_poll+0x13d8>
    n = append(d, n, ",\"ntrk\":"); n += uitoa(d + n, (unsigned)st_ntrk);
    3d58:	8641a583          	lw	a1,-1948(gp) # 46c1c <st_ntrk>
    if (v == 0) { d[0] = '0'; return 1; }
    3d5c:	24058e63          	beqz	a1,3fb8 <http_poll+0x1654>
    3d60:	ad4fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"ntrk\":"); n += uitoa(d + n, (unsigned)st_ntrk);
    3d64:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"ms\":"); n += uitoa(d + n, (unsigned)st_ms);
    3d68:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"ntrk\":"); n += uitoa(d + n, (unsigned)st_ntrk);
    3d6c:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3d70:	02c00693          	li	a3,44
    3d74:	31c70713          	addi	a4,a4,796 # 731c <_data+0xd04>
    3d78:	00190913          	addi	s2,s2,1
    3d7c:	40f90633          	sub	a2,s2,a5
    3d80:	01248533          	add	a0,s1,s2
    3d84:	00c70633          	add	a2,a4,a2
    3d88:	fed50fa3          	sb	a3,-1(a0)
    3d8c:	00064683          	lbu	a3,0(a2)
    3d90:	fe0694e3          	bnez	a3,3d78 <http_poll+0x1414>
    n = append(d, n, ",\"ms\":"); n += uitoa(d + n, (unsigned)st_ms);
    3d94:	8601a583          	lw	a1,-1952(gp) # 46c18 <st_ms>
    if (v == 0) { d[0] = '0'; return 1; }
    3d98:	22058863          	beqz	a1,3fc8 <http_poll+0x1664>
    3d9c:	a98fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"ms\":"); n += uitoa(d + n, (unsigned)st_ms);
    3da0:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"x0\":"); n += uitoa(d + n, (unsigned)st_x0);
    3da4:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"ms\":"); n += uitoa(d + n, (unsigned)st_ms);
    3da8:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3dac:	02c00693          	li	a3,44
    3db0:	32470713          	addi	a4,a4,804 # 7324 <_data+0xd0c>
    3db4:	00190913          	addi	s2,s2,1
    3db8:	40f90633          	sub	a2,s2,a5
    3dbc:	01248533          	add	a0,s1,s2
    3dc0:	00c70633          	add	a2,a4,a2
    3dc4:	fed50fa3          	sb	a3,-1(a0)
    3dc8:	00064683          	lbu	a3,0(a2)
    3dcc:	fe0694e3          	bnez	a3,3db4 <http_poll+0x1450>
    n = append(d, n, ",\"x0\":"); n += uitoa(d + n, (unsigned)st_x0);
    3dd0:	85c1a583          	lw	a1,-1956(gp) # 46c14 <st_x0>
    if (v == 0) { d[0] = '0'; return 1; }
    3dd4:	20058263          	beqz	a1,3fd8 <http_poll+0x1674>
    3dd8:	a5cfe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"x0\":"); n += uitoa(d + n, (unsigned)st_x0);
    3ddc:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"y0\":"); n += uitoa(d + n, (unsigned)st_y0);
    3de0:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"x0\":"); n += uitoa(d + n, (unsigned)st_x0);
    3de4:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3de8:	02c00693          	li	a3,44
    3dec:	32c70713          	addi	a4,a4,812 # 732c <_data+0xd14>
    3df0:	00190913          	addi	s2,s2,1
    3df4:	40f90633          	sub	a2,s2,a5
    3df8:	01248533          	add	a0,s1,s2
    3dfc:	00c70633          	add	a2,a4,a2
    3e00:	fed50fa3          	sb	a3,-1(a0)
    3e04:	00064683          	lbu	a3,0(a2)
    3e08:	fe0694e3          	bnez	a3,3df0 <http_poll+0x148c>
    n = append(d, n, ",\"y0\":"); n += uitoa(d + n, (unsigned)st_y0);
    3e0c:	8581a583          	lw	a1,-1960(gp) # 46c10 <st_y0>
    if (v == 0) { d[0] = '0'; return 1; }
    3e10:	1c058c63          	beqz	a1,3fe8 <http_poll+0x1684>
    3e14:	a20fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"y0\":"); n += uitoa(d + n, (unsigned)st_y0);
    3e18:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"x1\":"); n += uitoa(d + n, (unsigned)st_x1);
    3e1c:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"y0\":"); n += uitoa(d + n, (unsigned)st_y0);
    3e20:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3e24:	02c00693          	li	a3,44
    3e28:	33470713          	addi	a4,a4,820 # 7334 <_data+0xd1c>
    3e2c:	00190913          	addi	s2,s2,1
    3e30:	40f90633          	sub	a2,s2,a5
    3e34:	01248533          	add	a0,s1,s2
    3e38:	00c70633          	add	a2,a4,a2
    3e3c:	fed50fa3          	sb	a3,-1(a0)
    3e40:	00064683          	lbu	a3,0(a2)
    3e44:	fe0694e3          	bnez	a3,3e2c <http_poll+0x14c8>
    n = append(d, n, ",\"x1\":"); n += uitoa(d + n, (unsigned)st_x1);
    3e48:	8541a583          	lw	a1,-1964(gp) # 46c0c <st_x1>
    if (v == 0) { d[0] = '0'; return 1; }
    3e4c:	1a058663          	beqz	a1,3ff8 <http_poll+0x1694>
    3e50:	9e4fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"x1\":"); n += uitoa(d + n, (unsigned)st_x1);
    3e54:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"y1\":"); n += uitoa(d + n, (unsigned)st_y1);
    3e58:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"x1\":"); n += uitoa(d + n, (unsigned)st_x1);
    3e5c:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3e60:	02c00693          	li	a3,44
    3e64:	33c70713          	addi	a4,a4,828 # 733c <_data+0xd24>
    3e68:	00190913          	addi	s2,s2,1
    3e6c:	40f90633          	sub	a2,s2,a5
    3e70:	01248533          	add	a0,s1,s2
    3e74:	00c70633          	add	a2,a4,a2
    3e78:	fed50fa3          	sb	a3,-1(a0)
    3e7c:	00064683          	lbu	a3,0(a2)
    3e80:	fe0694e3          	bnez	a3,3e68 <http_poll+0x1504>
    n = append(d, n, ",\"y1\":"); n += uitoa(d + n, (unsigned)st_y1);
    3e84:	8501a583          	lw	a1,-1968(gp) # 46c08 <st_y1>
    if (v == 0) { d[0] = '0'; return 1; }
    3e88:	18058063          	beqz	a1,4008 <__stack_size+0x8>
    3e8c:	9a8fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"y1\":"); n += uitoa(d + n, (unsigned)st_y1);
    3e90:	00a907b3          	add	a5,s2,a0
    n = append(d, n, ",\"voice\":"); n += uitoa(d + n, (unsigned)st_voice);
    3e94:	00007737          	lui	a4,0x7
    n = append(d, n, ",\"y1\":"); n += uitoa(d + n, (unsigned)st_y1);
    3e98:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3e9c:	02c00693          	li	a3,44
    3ea0:	34470713          	addi	a4,a4,836 # 7344 <_data+0xd2c>
    3ea4:	00190913          	addi	s2,s2,1
    3ea8:	40f90633          	sub	a2,s2,a5
    3eac:	01248533          	add	a0,s1,s2
    3eb0:	00c70633          	add	a2,a4,a2
    3eb4:	fed50fa3          	sb	a3,-1(a0)
    3eb8:	00064683          	lbu	a3,0(a2)
    3ebc:	fe0694e3          	bnez	a3,3ea4 <http_poll+0x1540>
    n = append(d, n, ",\"voice\":"); n += uitoa(d + n, (unsigned)st_voice);
    3ec0:	84c1a583          	lw	a1,-1972(gp) # 46c04 <st_voice>
    if (v == 0) { d[0] = '0'; return 1; }
    3ec4:	14058a63          	beqz	a1,4018 <__stack_size+0x18>
    3ec8:	96cfe0ef          	jal	ra,2034 <uitoa.part.0>
    3ecc:	f81007b7          	lui	a5,0xf8100
    3ed0:	0387a703          	lw	a4,56(a5) # f8100038 <__freertos_irq_stack_top+0xf8095a48>
    n = append(d, n, ",\"voice\":"); n += uitoa(d + n, (unsigned)st_voice);
    3ed4:	00a907b3          	add	a5,s2,a0
    st_arm = (int)(read_u32(REG_ARM) & 1u);
    3ed8:	00177713          	andi	a4,a4,1
    3edc:	84e1a423          	sw	a4,-1976(gp) # 46c00 <st_arm>
    n = append(d, n, ",\"arm\":"); n += uitoa(d + n, (unsigned)st_arm);
    3ee0:	000076b7          	lui	a3,0x7
    st_arm = (int)(read_u32(REG_ARM) & 1u);
    3ee4:	00078913          	mv	s2,a5
    while (*s) d[n++] = *s++;
    3ee8:	02c00613          	li	a2,44
    3eec:	35068693          	addi	a3,a3,848 # 7350 <_data+0xd38>
    3ef0:	00190913          	addi	s2,s2,1
    3ef4:	40f905b3          	sub	a1,s2,a5
    3ef8:	01248533          	add	a0,s1,s2
    3efc:	00b685b3          	add	a1,a3,a1
    3f00:	fec50fa3          	sb	a2,-1(a0)
    3f04:	0005c603          	lbu	a2,0(a1)
    3f08:	fe0614e3          	bnez	a2,3ef0 <http_poll+0x158c>
    if (v == 0) { d[0] = '0'; return 1; }
    3f0c:	10070e63          	beqz	a4,4028 <__stack_size+0x28>
    3f10:	00100593          	li	a1,1
    3f14:	920fe0ef          	jal	ra,2034 <uitoa.part.0>
    n = append(d, n, ",\"arm\":"); n += uitoa(d + n, (unsigned)st_arm);
    3f18:	00a90933          	add	s2,s2,a0
    while (*s) d[n++] = *s++;
    3f1c:	00190613          	addi	a2,s2,1
    3f20:	07d00793          	li	a5,125
    3f24:	01248933          	add	s2,s1,s2
    3f28:	00f90023          	sb	a5,0(s2)
    d[n] = 0;
    3f2c:	00c484b3          	add	s1,s1,a2
        http_reply("application/json", page, pn);
    3f30:	00007537          	lui	a0,0x7
    3f34:	f8098593          	addi	a1,s3,-128
    3f38:	35850513          	addi	a0,a0,856 # 7358 <_data+0xd40>
    d[n] = 0;
    3f3c:	00048023          	sb	zero,0(s1)
        http_reply("application/json", page, pn);
    3f40:	db4fe0ef          	jal	ra,24f4 <http_reply>
    3f44:	f29fe06f          	j	2e6c <http_poll+0x508>
    if (v == 0) { d[0] = '0'; return 1; }
    3f48:	03000793          	li	a5,48
    3f4c:	00f50023          	sb	a5,0(a0)
    3f50:	00100513          	li	a0,1
    3f54:	c6dff06f          	j	3bc0 <http_poll+0x125c>
    3f58:	03000793          	li	a5,48
    3f5c:	00f50023          	sb	a5,0(a0)
    3f60:	00100513          	li	a0,1
    3f64:	c99ff06f          	j	3bfc <http_poll+0x1298>
    3f68:	03000793          	li	a5,48
    3f6c:	00f50023          	sb	a5,0(a0)
    3f70:	00100513          	li	a0,1
    3f74:	cc5ff06f          	j	3c38 <http_poll+0x12d4>
    3f78:	03000793          	li	a5,48
    3f7c:	00f50023          	sb	a5,0(a0)
    3f80:	00100513          	li	a0,1
    3f84:	cf1ff06f          	j	3c74 <http_poll+0x1310>
    3f88:	03000793          	li	a5,48
    3f8c:	00f50023          	sb	a5,0(a0)
    3f90:	00100513          	li	a0,1
    3f94:	d1dff06f          	j	3cb0 <http_poll+0x134c>
    3f98:	03000793          	li	a5,48
    3f9c:	00f50023          	sb	a5,0(a0)
    3fa0:	00100513          	li	a0,1
    3fa4:	d49ff06f          	j	3cec <http_poll+0x1388>
    3fa8:	03000793          	li	a5,48
    3fac:	00f50023          	sb	a5,0(a0)
    3fb0:	00100513          	li	a0,1
    3fb4:	d75ff06f          	j	3d28 <http_poll+0x13c4>
    3fb8:	03000793          	li	a5,48
    3fbc:	00f50023          	sb	a5,0(a0)
    3fc0:	00100513          	li	a0,1
    3fc4:	da1ff06f          	j	3d64 <http_poll+0x1400>
    3fc8:	03000793          	li	a5,48
    3fcc:	00f50023          	sb	a5,0(a0)
    3fd0:	00100513          	li	a0,1
    3fd4:	dcdff06f          	j	3da0 <http_poll+0x143c>
    3fd8:	03000793          	li	a5,48
    3fdc:	00f50023          	sb	a5,0(a0)
    3fe0:	00100513          	li	a0,1
    3fe4:	df9ff06f          	j	3ddc <http_poll+0x1478>
    3fe8:	03000793          	li	a5,48
    3fec:	00f50023          	sb	a5,0(a0)
    3ff0:	00100513          	li	a0,1
    3ff4:	e25ff06f          	j	3e18 <http_poll+0x14b4>
    3ff8:	03000793          	li	a5,48
    3ffc:	00f50023          	sb	a5,0(a0)
    4000:	00100513          	li	a0,1
    4004:	e51ff06f          	j	3e54 <http_poll+0x14f0>
    4008:	03000793          	li	a5,48
    400c:	00f50023          	sb	a5,0(a0)
    4010:	00100513          	li	a0,1
    4014:	e7dff06f          	j	3e90 <http_poll+0x152c>
    4018:	03000793          	li	a5,48
    401c:	00f50023          	sb	a5,0(a0)
    4020:	00100513          	li	a0,1
    4024:	ea9ff06f          	j	3ecc <http_poll+0x1568>
    4028:	03000793          	li	a5,48
    402c:	00f50023          	sb	a5,0(a0)
    4030:	00100513          	li	a0,1
    4034:	ee5ff06f          	j	3f18 <http_poll+0x15b4>
        if ((path[2] == '?' && path[3] == '1') || (path[2] == '1' && path[3] == 0))
    4038:	00314783          	lbu	a5,3(sp)
    403c:	03100713          	li	a4,49
    4040:	00e78e63          	beq	a5,a4,405c <__stack_size+0x5c>
        else if ((path[2] == '?' && path[3] == '0') || (path[2] == '0' && path[3] == 0))
    4044:	03000713          	li	a4,48
    4048:	00e79463          	bne	a5,a4,4050 <__stack_size+0x50>
    404c:	ff1fe06f          	j	303c <http_poll+0x6d8>
    4050:	804ff06f          	j	3054 <http_poll+0x6f0>
        if ((path[2] == '?' && path[3] == '1') || (path[2] == '1' && path[3] == 0))
    4054:	00314783          	lbu	a5,3(sp)
    4058:	fe079ce3          	bnez	a5,4050 <__stack_size+0x50>
            set = 1;
    405c:	00100793          	li	a5,1
    4060:	fe1fe06f          	j	3040 <http_poll+0x6dc>
    if (path[0] == '/' && path[1] == 'p' && (path[2] == '?' || path[2] == 0)) {
    4064:	00214783          	lbu	a5,2(sp)
    4068:	03f00713          	li	a4,63
    406c:	04e78e63          	beq	a5,a4,40c8 <__stack_size+0xc8>
    4070:	00078463          	beqz	a5,4078 <__stack_size+0x78>
    4074:	c11fe06f          	j	2c84 <http_poll+0x320>
        http_reply("text/plain", (const uint8_t *)"ok", 2);
    4078:	000075b7          	lui	a1,0x7
    407c:	00007537          	lui	a0,0x7
    4080:	00200613          	li	a2,2
    4084:	28058593          	addi	a1,a1,640 # 7280 <_data+0xc68>
    4088:	28450513          	addi	a0,a0,644 # 7284 <_data+0xc6c>
    408c:	c68fe0ef          	jal	ra,24f4 <http_reply>
        return;
    4090:	dddfe06f          	j	2e6c <http_poll+0x508>
    if (v == 0) { d[0] = '0'; return 1; }
    4094:	03000793          	li	a5,48
    4098:	00f50023          	sb	a5,0(a0)
    409c:	00100513          	li	a0,1
    40a0:	b48ff06f          	j	33e8 <http_poll+0xa84>
    40a4:	03000793          	li	a5,48
    40a8:	00f50023          	sb	a5,0(a0)
    40ac:	00100513          	li	a0,1
    40b0:	b84ff06f          	j	3434 <http_poll+0xad0>
        memset(d + BMP_OFF, 0x40, 48u * 48u);
    40b4:	00047537          	lui	a0,0x47
    40b8:	04000593          	li	a1,64
    40bc:	3b650513          	addi	a0,a0,950 # 473b6 <page.3199+0x436>
    40c0:	9b0fd0ef          	jal	ra,1270 <memset>
    40c4:	d91fe06f          	j	2e54 <http_poll+0x4f0>
            if (path[3] == 't' && path[4] == '=')
    40c8:	00314603          	lbu	a2,3(sp)
    40cc:	07400713          	li	a4,116
                k = 3;
    40d0:	00300793          	li	a5,3
            if (path[3] == 't' && path[4] == '=')
    40d4:	0ae60663          	beq	a2,a4,4180 <__stack_size+0x180>
            while (path[k] >= '0' && path[k] <= '9') {
    40d8:	02010713          	addi	a4,sp,32
    40dc:	00f70733          	add	a4,a4,a5
    40e0:	fe074603          	lbu	a2,-32(a4)
    40e4:	00f686b3          	add	a3,a3,a5
    40e8:	00900593          	li	a1,9
    40ec:	fd060793          	addi	a5,a2,-48
    40f0:	0ff7f793          	andi	a5,a5,255
    40f4:	00000713          	li	a4,0
    40f8:	00900513          	li	a0,9
    40fc:	f6f5eee3          	bltu	a1,a5,4078 <__stack_size+0x78>
                t = t * 10u + (unsigned)(path[k] - '0');
    4100:	00271793          	slli	a5,a4,0x2
    4104:	00e787b3          	add	a5,a5,a4
    4108:	00179793          	slli	a5,a5,0x1
    410c:	00c787b3          	add	a5,a5,a2
            while (path[k] >= '0' && path[k] <= '9') {
    4110:	0016c603          	lbu	a2,1(a3)
                t = t * 10u + (unsigned)(path[k] - '0');
    4114:	fd078713          	addi	a4,a5,-48
                k++;
    4118:	00168693          	addi	a3,a3,1
            while (path[k] >= '0' && path[k] <= '9') {
    411c:	fd060593          	addi	a1,a2,-48
    4120:	0ff5f593          	andi	a1,a1,255
    4124:	fcb57ee3          	bgeu	a0,a1,4100 <__stack_size+0x100>
        if (t >= 1u && t <= 40u)
    4128:	fcf78793          	addi	a5,a5,-49
    412c:	02700693          	li	a3,39
    4130:	f4f6e4e3          	bltu	a3,a5,4078 <__stack_size+0x78>
        *((volatile u32*) address) = data;
    4134:	f81007b7          	lui	a5,0xf8100
    4138:	02e7a423          	sw	a4,40(a5) # f8100028 <__freertos_irq_stack_top+0xf8095a38>
        http_reply("text/plain", (const uint8_t *)"ok", 2);
    413c:	f3dff06f          	j	4078 <__stack_size+0x78>
    if (v == 0) { d[0] = '0'; return 1; }
    4140:	03000793          	li	a5,48
    4144:	00f50023          	sb	a5,0(a0)
    4148:	00100513          	li	a0,1
    414c:	b60ff06f          	j	34ac <http_poll+0xb48>
    4150:	03000793          	li	a5,48
    4154:	00f50023          	sb	a5,0(a0)
    4158:	00100513          	li	a0,1
    415c:	b84ff06f          	j	34e0 <http_poll+0xb7c>
    4160:	03000793          	li	a5,48
    4164:	00f50023          	sb	a5,0(a0)
    4168:	00100513          	li	a0,1
    416c:	bc0ff06f          	j	352c <http_poll+0xbc8>
    4170:	03000793          	li	a5,48
    4174:	00f50023          	sb	a5,0(a0)
    4178:	00100513          	li	a0,1
    417c:	bfcff06f          	j	3578 <http_poll+0xc14>
            if (path[3] == 't' && path[4] == '=')
    4180:	00414703          	lbu	a4,4(sp)
    4184:	03d00793          	li	a5,61
    4188:	eef718e3          	bne	a4,a5,4078 <__stack_size+0x78>
                k = 5;
    418c:	00500793          	li	a5,5
    4190:	f49ff06f          	j	40d8 <__stack_size+0xd8>
    if (v == 0) { d[0] = '0'; return 1; }
    4194:	03000793          	li	a5,48
    4198:	00f50023          	sb	a5,0(a0)
    419c:	00100513          	li	a0,1
    41a0:	c48ff06f          	j	35e8 <http_poll+0xc84>
    41a4:	03000793          	li	a5,48
    41a8:	00f50023          	sb	a5,0(a0)
    41ac:	00100513          	li	a0,1
    41b0:	c8cff06f          	j	363c <http_poll+0xcd8>
    41b4:	03000793          	li	a5,48
    41b8:	00f50023          	sb	a5,0(a0)
    41bc:	00100513          	li	a0,1
    41c0:	cc8ff06f          	j	3688 <http_poll+0xd24>
    41c4:	03000793          	li	a5,48
    41c8:	00f50023          	sb	a5,0(a0)
    41cc:	00100513          	li	a0,1
    41d0:	d2cff06f          	j	36fc <http_poll+0xd98>
    41d4:	03000793          	li	a5,48
    41d8:	00f50023          	sb	a5,0(a0)
    41dc:	00100513          	li	a0,1
    41e0:	d40ff06f          	j	3720 <http_poll+0xdbc>
    41e4:	03000793          	li	a5,48
    41e8:	00f50023          	sb	a5,0(a0)
    41ec:	00100513          	li	a0,1
    41f0:	d84ff06f          	j	3774 <http_poll+0xe10>
    41f4:	03000793          	li	a5,48
    41f8:	00f50023          	sb	a5,0(a0)
    41fc:	00100513          	li	a0,1
    4200:	d50ff06f          	j	3750 <http_poll+0xdec>
    4204:	03000793          	li	a5,48
    4208:	00f50023          	sb	a5,0(a0)
    420c:	00100513          	li	a0,1
    4210:	dacff06f          	j	37bc <http_poll+0xe58>
    n = append(d, n, st_arm ? "已开启 入框响" : "已关闭 入框不响");
    4214:	000077b7          	lui	a5,0x7
    4218:	d0478793          	addi	a5,a5,-764 # 6d04 <_data+0x6ec>
    421c:	e54ff06f          	j	3870 <http_poll+0xf0c>
    for (k = 0; k < hist_n; k++) {
    4220:	000077b7          	lui	a5,0x7
    while (*s) d[n++] = *s++;
    4224:	03c00713          	li	a4,60
    for (k = 0; k < hist_n; k++) {
    4228:	f3478793          	addi	a5,a5,-204 # 6f34 <_data+0x91c>
    while (*s) d[n++] = *s++;
    422c:	00160613          	addi	a2,a2,1
    4230:	00c486b3          	add	a3,s1,a2
    4234:	00178793          	addi	a5,a5,1
    4238:	fee68fa3          	sb	a4,-1(a3)
    423c:	0007c703          	lbu	a4,0(a5)
    4240:	fe0716e3          	bnez	a4,422c <__stack_size+0x22c>
    4244:	000077b7          	lui	a5,0x7
    4248:	03c00713          	li	a4,60
    424c:	f5078793          	addi	a5,a5,-176 # 6f50 <_data+0x938>
    4250:	00160613          	addi	a2,a2,1
    4254:	00c486b3          	add	a3,s1,a2
    4258:	00178793          	addi	a5,a5,1
    425c:	fee68fa3          	sb	a4,-1(a3)
    4260:	0007c703          	lbu	a4,0(a5)
    4264:	fe0716e3          	bnez	a4,4250 <__stack_size+0x250>
    4268:	000077b7          	lui	a5,0x7
    426c:	06900713          	li	a4,105
    4270:	f8478793          	addi	a5,a5,-124 # 6f84 <_data+0x96c>
    4274:	00160613          	addi	a2,a2,1
    4278:	00c486b3          	add	a3,s1,a2
    427c:	00178793          	addi	a5,a5,1
    4280:	fee68fa3          	sb	a4,-1(a3)
    4284:	0007c703          	lbu	a4,0(a5)
    4288:	fe0716e3          	bnez	a4,4274 <__stack_size+0x274>
    428c:	000077b7          	lui	a5,0x7
    4290:	06500713          	li	a4,101
    4294:	fe878793          	addi	a5,a5,-24 # 6fe8 <_data+0x9d0>
    4298:	00160613          	addi	a2,a2,1
    429c:	00c486b3          	add	a3,s1,a2
    42a0:	00178793          	addi	a5,a5,1
    42a4:	fee68fa3          	sb	a4,-1(a3)
    42a8:	0007c703          	lbu	a4,0(a5)
    42ac:	fe0716e3          	bnez	a4,4298 <__stack_size+0x298>
    42b0:	000077b7          	lui	a5,0x7
    42b4:	07400713          	li	a4,116
    42b8:	02c78793          	addi	a5,a5,44 # 702c <_data+0xa14>
    42bc:	00160613          	addi	a2,a2,1
    42c0:	00c486b3          	add	a3,s1,a2
    42c4:	00178793          	addi	a5,a5,1
    42c8:	fee68fa3          	sb	a4,-1(a3)
    42cc:	0007c703          	lbu	a4,0(a5)
    42d0:	fe0716e3          	bnez	a4,42bc <__stack_size+0x2bc>
    42d4:	000077b7          	lui	a5,0x7
    42d8:	07400713          	li	a4,116
    42dc:	07c78793          	addi	a5,a5,124 # 707c <_data+0xa64>
    42e0:	00160613          	addi	a2,a2,1
    42e4:	00c486b3          	add	a3,s1,a2
    42e8:	00178793          	addi	a5,a5,1
    42ec:	fee68fa3          	sb	a4,-1(a3)
    42f0:	0007c703          	lbu	a4,0(a5)
    42f4:	fe0716e3          	bnez	a4,42e0 <__stack_size+0x2e0>
    42f8:	000077b7          	lui	a5,0x7
    42fc:	06200713          	li	a4,98
    4300:	0d078793          	addi	a5,a5,208 # 70d0 <_data+0xab8>
    4304:	00160613          	addi	a2,a2,1
    4308:	00c486b3          	add	a3,s1,a2
    430c:	00178793          	addi	a5,a5,1
    4310:	fee68fa3          	sb	a4,-1(a3)
    4314:	0007c703          	lbu	a4,0(a5)
    4318:	fe0716e3          	bnez	a4,4304 <__stack_size+0x304>
    431c:	000077b7          	lui	a5,0x7
    4320:	06900713          	li	a4,105
    4324:	11878793          	addi	a5,a5,280 # 7118 <_data+0xb00>
    4328:	00160613          	addi	a2,a2,1
    432c:	00c486b3          	add	a3,s1,a2
    4330:	00178793          	addi	a5,a5,1
    4334:	fee68fa3          	sb	a4,-1(a3)
    4338:	0007c703          	lbu	a4,0(a5)
    433c:	fe0716e3          	bnez	a4,4328 <__stack_size+0x328>
    4340:	000077b7          	lui	a5,0x7
    4344:	06800713          	li	a4,104
    4348:	17078793          	addi	a5,a5,368 # 7170 <_data+0xb58>
    434c:	00160613          	addi	a2,a2,1
    4350:	00c486b3          	add	a3,s1,a2
    4354:	00178793          	addi	a5,a5,1
    4358:	fee68fa3          	sb	a4,-1(a3)
    435c:	0007c703          	lbu	a4,0(a5)
    4360:	fe0716e3          	bnez	a4,434c <__stack_size+0x34c>
    4364:	000077b7          	lui	a5,0x7
    4368:	07d00713          	li	a4,125
    436c:	1dc78793          	addi	a5,a5,476 # 71dc <_data+0xbc4>
    4370:	00160613          	addi	a2,a2,1
    4374:	00c486b3          	add	a3,s1,a2
    4378:	00178793          	addi	a5,a5,1
    437c:	fee68fa3          	sb	a4,-1(a3)
    4380:	0007c703          	lbu	a4,0(a5)
    4384:	fe0716e3          	bnez	a4,4370 <__stack_size+0x370>
    4388:	000077b7          	lui	a5,0x7
    438c:	06900713          	li	a4,105
    4390:	20c78793          	addi	a5,a5,524 # 720c <_data+0xbf4>
    4394:	00160613          	addi	a2,a2,1
    4398:	00c486b3          	add	a3,s1,a2
    439c:	00178793          	addi	a5,a5,1
    43a0:	fee68fa3          	sb	a4,-1(a3)
    43a4:	0007c703          	lbu	a4,0(a5)
    43a8:	fe0716e3          	bnez	a4,4394 <__stack_size+0x394>
    43ac:	000077b7          	lui	a5,0x7
    43b0:	03c00713          	li	a4,60
    43b4:	27078793          	addi	a5,a5,624 # 7270 <_data+0xc58>
    43b8:	00160613          	addi	a2,a2,1
    43bc:	00c486b3          	add	a3,s1,a2
    43c0:	00178793          	addi	a5,a5,1
    43c4:	fee68fa3          	sb	a4,-1(a3)
    43c8:	0007c703          	lbu	a4,0(a5)
    43cc:	fe0716e3          	bnez	a4,43b8 <__stack_size+0x3b8>
        http_reply("text/html", page, pn);
    43d0:	00007537          	lui	a0,0x7
    43d4:	f8098593          	addi	a1,s3,-128
    43d8:	4b450513          	addi	a0,a0,1204 # 74b4 <_data+0xe9c>
    d[n] = 0;
    43dc:	00068023          	sb	zero,0(a3)
        http_reply("text/html", page, pn);
    43e0:	914fe0ef          	jal	ra,24f4 <http_reply>
    43e4:	a89fe06f          	j	2e6c <http_poll+0x508>

000043e8 <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    43e8:	fa010113          	addi	sp,sp,-96
        int i;
        va_list ap;

        va_start(ap, format);

        for (i = 0; format[i]; i++)
    43ec:	00054303          	lbu	t1,0(a0)
    {
    43f0:	04f12a23          	sw	a5,84(sp)
        va_start(ap, format);
    43f4:	04410793          	addi	a5,sp,68
    {
    43f8:	02812e23          	sw	s0,60(sp)
    43fc:	02912c23          	sw	s1,56(sp)
    4400:	03212a23          	sw	s2,52(sp)
    4404:	03312823          	sw	s3,48(sp)
    4408:	04b12223          	sw	a1,68(sp)
    440c:	04c12423          	sw	a2,72(sp)
    4410:	04d12623          	sw	a3,76(sp)
    4414:	04e12823          	sw	a4,80(sp)
    4418:	05012c23          	sw	a6,88(sp)
    441c:	05112e23          	sw	a7,92(sp)
        va_start(ap, format);
    4420:	00f12623          	sw	a5,12(sp)
        for (i = 0; format[i]; i++)
    4424:	04030e63          	beqz	t1,4480 <bsp_printf+0x98>
    4428:	00047937          	lui	s2,0x47
    442c:	000474b7          	lui	s1,0x47
    4430:	00000713          	li	a4,0
            if (format[i] == '%') {
    4434:	02500293          	li	t0,37
                while (format[++i]) {
                    if (format[i] == 'c') {
    4438:	06300813          	li	a6,99
                        bsp_printf_c(va_arg(ap,int));
                        break;
                    }
                    else if (format[i] == 's') {
    443c:	07300893          	li	a7,115
                        bsp_printf_s(va_arg(ap,char*));
                        break;
                    }
                    else if (format[i] == 'd') {
    4440:	06400e13          	li	t3,100
                        bsp_printf_d(va_arg(ap,int));
                        break;
                    }
                    else if (format[i] == 'X') {
    4444:	05800e93          	li	t4,88
                        bsp_printf_X(va_arg(ap,int));
                        break;
                    }
                    else if (format[i] == 'x') {
    4448:	07800f13          	li	t5,120
                    else if (format[i] == 'f') {
                        print_float(va_arg(ap,double));
                        break;
                    }
#elif (ENABLE_PRINTF_WARNING)
                    else if (format[i] == 'f') {
    444c:	06600f93          	li	t6,102
    4450:	000479b7          	lui	s3,0x47
    4454:	f81006b7          	lui	a3,0xf8100
    4458:	9c090913          	addi	s2,s2,-1600 # 469c0 <CSWTCH.112+0x60>
    445c:	9d448493          	addi	s1,s1,-1580 # 469d4 <CSWTCH.112+0x74>
        for (i = 0; format[i]; i++)
    4460:	01010413          	addi	s0,sp,16
            *(p++) = '0' + val % 10;
    4464:	00a00393          	li	t2,10
            if (format[i] == '%') {
    4468:	04530263          	beq	t1,t0,44ac <bsp_printf+0xc4>
    446c:	0066a023          	sw	t1,0(a3) # f8100000 <__freertos_irq_stack_top+0xf8095a10>
        for (i = 0; format[i]; i++)
    4470:	00170713          	addi	a4,a4,1
    4474:	00e507b3          	add	a5,a0,a4
    4478:	0007c303          	lbu	t1,0(a5)
    447c:	fe0316e3          	bnez	t1,4468 <bsp_printf+0x80>
                }
            } else
                bsp_printf_c(format[i]);

        va_end(ap);
    }
    4480:	03c12403          	lw	s0,60(sp)
    4484:	03812483          	lw	s1,56(sp)
    4488:	03412903          	lw	s2,52(sp)
    448c:	03012983          	lw	s3,48(sp)
    4490:	06010113          	addi	sp,sp,96
    4494:	00008067          	ret
                    else if (format[i] == 's') {
    4498:	05178063          	beq	a5,a7,44d8 <bsp_printf+0xf0>
                    else if (format[i] == 'd') {
    449c:	07c78463          	beq	a5,t3,4504 <bsp_printf+0x11c>
                    else if (format[i] == 'X') {
    44a0:	0dd78a63          	beq	a5,t4,4574 <bsp_printf+0x18c>
                    else if (format[i] == 'x') {
    44a4:	11e78463          	beq	a5,t5,45ac <bsp_printf+0x1c4>
                    else if (format[i] == 'f') {
    44a8:	13f78e63          	beq	a5,t6,45e4 <bsp_printf+0x1fc>
                while (format[++i]) {
    44ac:	00170713          	addi	a4,a4,1
    44b0:	00e507b3          	add	a5,a0,a4
    44b4:	0007c783          	lbu	a5,0(a5)
    44b8:	fa078ce3          	beqz	a5,4470 <bsp_printf+0x88>
                    if (format[i] == 'c') {
    44bc:	fd079ee3          	bne	a5,a6,4498 <bsp_printf+0xb0>
                        bsp_printf_c(va_arg(ap,int));
    44c0:	00c12783          	lw	a5,12(sp)
            bsp_putChar(character);
    44c4:	0007c603          	lbu	a2,0(a5)
                        bsp_printf_c(va_arg(ap,int));
    44c8:	00478793          	addi	a5,a5,4
    44cc:	00f12623          	sw	a5,12(sp)
    44d0:	00c6a023          	sw	a2,0(a3)
            bsp_putChar(character);
    44d4:	f9dff06f          	j	4470 <bsp_printf+0x88>
                        bsp_printf_s(va_arg(ap,char*));
    44d8:	00c12783          	lw	a5,12(sp)
    44dc:	0007a603          	lw	a2,0(a5)
    44e0:	00478793          	addi	a5,a5,4
    44e4:	00f12623          	sw	a5,12(sp)
        while (*p)
    44e8:	00064783          	lbu	a5,0(a2)
    44ec:	f80782e3          	beqz	a5,4470 <bsp_printf+0x88>
            _putchar(*(p++));
    44f0:	00160613          	addi	a2,a2,1
    44f4:	00f6a023          	sw	a5,0(a3)
        while (*p)
    44f8:	00064783          	lbu	a5,0(a2)
    44fc:	fe079ae3          	bnez	a5,44f0 <bsp_printf+0x108>
    4500:	f71ff06f          	j	4470 <bsp_printf+0x88>
                        bsp_printf_d(va_arg(ap,int));
    4504:	00c12783          	lw	a5,12(sp)
    4508:	0007a603          	lw	a2,0(a5)
    450c:	00478793          	addi	a5,a5,4
    4510:	00f12623          	sw	a5,12(sp)
        if (val < 0) {
    4514:	04064663          	bltz	a2,4560 <bsp_printf+0x178>
        for (i = 0; format[i]; i++)
    4518:	00040793          	mv	a5,s0
        while (val || p == buffer) {
    451c:	00061463          	bnez	a2,4524 <bsp_printf+0x13c>
    4520:	00879e63          	bne	a5,s0,453c <bsp_printf+0x154>
            *(p++) = '0' + val % 10;
    4524:	027665b3          	rem	a1,a2,t2
    4528:	00178793          	addi	a5,a5,1
    452c:	03058593          	addi	a1,a1,48
            val = val / 10;
    4530:	02764633          	div	a2,a2,t2
            *(p++) = '0' + val % 10;
    4534:	feb78fa3          	sb	a1,-1(a5)
            val = val / 10;
    4538:	fe5ff06f          	j	451c <bsp_printf+0x134>
            bsp_printf_c(*(--p));
    453c:	fff78793          	addi	a5,a5,-1
            bsp_putChar(character);
    4540:	0007c603          	lbu	a2,0(a5)
    4544:	00c6a023          	sw	a2,0(a3)
        while (p != buffer)
    4548:	f28784e3          	beq	a5,s0,4470 <bsp_printf+0x88>
            bsp_printf_c(*(--p));
    454c:	fff78793          	addi	a5,a5,-1
            bsp_putChar(character);
    4550:	0007c603          	lbu	a2,0(a5)
    4554:	00c6a023          	sw	a2,0(a3)
        while (p != buffer)
    4558:	fe8792e3          	bne	a5,s0,453c <bsp_printf+0x154>
    455c:	f15ff06f          	j	4470 <bsp_printf+0x88>
    4560:	02d00793          	li	a5,45
    4564:	00f6a023          	sw	a5,0(a3)
            val = -val;
    4568:	40c00633          	neg	a2,a2
        for (i = 0; format[i]; i++)
    456c:	00040793          	mv	a5,s0
    4570:	fadff06f          	j	451c <bsp_printf+0x134>
                        bsp_printf_X(va_arg(ap,int));
    4574:	00c12783          	lw	a5,12(sp)
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    4578:	01c00613          	li	a2,28
    457c:	ffc00313          	li	t1,-4
            bsp_printHex(val);
    4580:	0007a583          	lw	a1,0(a5)
                        bsp_printf_X(va_arg(ap,int));
    4584:	00478793          	addi	a5,a5,4
    4588:	00f12623          	sw	a5,12(sp)
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    458c:	00c5d7b3          	srl	a5,a1,a2
    4590:	00f7f793          	andi	a5,a5,15
    4594:	00f487b3          	add	a5,s1,a5
            bsp_putChar(character);
    4598:	0007c783          	lbu	a5,0(a5)
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    459c:	ffc60613          	addi	a2,a2,-4
    45a0:	00f6a023          	sw	a5,0(a3)
    45a4:	fe6614e3          	bne	a2,t1,458c <bsp_printf+0x1a4>
    45a8:	ec9ff06f          	j	4470 <bsp_printf+0x88>
                        bsp_printf_x(va_arg(ap,int));
    45ac:	00c12783          	lw	a5,12(sp)
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    45b0:	01c00613          	li	a2,28
    45b4:	ffc00313          	li	t1,-4
        bsp_printHex_lower(val);
    45b8:	0007a583          	lw	a1,0(a5)
                        bsp_printf_x(va_arg(ap,int));
    45bc:	00478793          	addi	a5,a5,4
    45c0:	00f12623          	sw	a5,12(sp)
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    45c4:	00c5d7b3          	srl	a5,a1,a2
    45c8:	00f7f793          	andi	a5,a5,15
    45cc:	00f907b3          	add	a5,s2,a5
            bsp_putChar(character);
    45d0:	0007c783          	lbu	a5,0(a5)
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    45d4:	ffc60613          	addi	a2,a2,-4
    45d8:	00f6a023          	sw	a5,0(a3)
    45dc:	fe6614e3          	bne	a2,t1,45c4 <bsp_printf+0x1dc>
    45e0:	e91ff06f          	j	4470 <bsp_printf+0x88>
        while (*p)
    45e4:	03c00613          	li	a2,60
    45e8:	97498793          	addi	a5,s3,-1676 # 46974 <CSWTCH.112+0x14>
            _putchar(*(p++));
    45ec:	00178793          	addi	a5,a5,1
    45f0:	00c6a023          	sw	a2,0(a3)
        while (*p)
    45f4:	0007c603          	lbu	a2,0(a5)
    45f8:	fe061ae3          	bnez	a2,45ec <bsp_printf+0x204>
    45fc:	e75ff06f          	j	4470 <bsp_printf+0x88>

00004600 <t3_send_bytes>:
}

void t3_send_bytes(const uint8_t *p, unsigned n)
{
    unsigned i;
    for (i = 0; i < n; i++) {
    4600:	02058e63          	beqz	a1,463c <t3_send_bytes+0x3c>
    4604:	00b50633          	add	a2,a0,a1
        return *((volatile u32*) address);
    4608:	f81006b7          	lui	a3,0xf8100
{
    460c:	001e85b7          	lui	a1,0x1e8
    4610:	48158713          	addi	a4,a1,1153 # 1e8481 <__freertos_irq_stack_top+0x17de91>
    4614:	0080006f          	j	461c <t3_send_bytes+0x1c>
        unsigned spin = 0;
        while (read_u32(GRAY_BINSTAT) & 1u) {
            spin++;
            if (spin > 2000000u)
    4618:	02070263          	beqz	a4,463c <t3_send_bytes+0x3c>
    461c:	01c6a783          	lw	a5,28(a3) # f810001c <__freertos_irq_stack_top+0xf8095a2c>
    4620:	fff70713          	addi	a4,a4,-1
        while (read_u32(GRAY_BINSTAT) & 1u) {
    4624:	0017f793          	andi	a5,a5,1
    4628:	fe0798e3          	bnez	a5,4618 <t3_send_bytes+0x18>
                return;
        }
        write_u32((uint32_t)p[i], GRAY_BIN);
    462c:	00054783          	lbu	a5,0(a0)
        *((volatile u32*) address) = data;
    4630:	00150513          	addi	a0,a0,1
    4634:	02f6a023          	sw	a5,32(a3)
    for (i = 0; i < n; i++) {
    4638:	fcc51ce3          	bne	a0,a2,4610 <t3_send_bytes+0x10>
    }
}
    463c:	00008067          	ret

00004640 <t3_send_event>:
                   uint8_t pd_on, uint8_t conf, uint8_t sht, uint8_t ta, uint8_t to,
                   uint8_t lp, uint16_t fr, uint16_t infer_ms,
                   const t3_trk_t *trk, int ntrk,
                   uint16_t bx0, uint16_t by0, uint16_t bx1, uint16_t by1,
                   uint8_t mot, uint8_t has_thumb, uint8_t voice)
{
    4640:	ee010113          	addi	sp,sp,-288
    4644:	10812e23          	sw	s0,284(sp)
    4648:	13012e83          	lw	t4,304(sp)
    464c:	13412f83          	lw	t6,308(sp)
    4650:	14814403          	lbu	s0,328(sp)
    4654:	14c14383          	lbu	t2,332(sp)
    4658:	15014283          	lbu	t0,336(sp)
    465c:	00010f13          	mv	t5,sp
    4660:	10912c23          	sw	s1,280(sp)
    4664:	11212a23          	sw	s2,276(sp)
    4668:	11312823          	sw	s3,272(sp)
    466c:	11412623          	sw	s4,268(sp)
    4670:	11512423          	sw	s5,264(sp)
    4674:	10010e13          	addi	t3,sp,256
    4678:	000f0313          	mv	t1,t5
    uint8_t pkt[T3_EVT_SZ];
    int i, n;
    for (i = 0; i < T3_EVT_SZ; i++)
        pkt[i] = 0;
    467c:	00030023          	sb	zero,0(t1)
    4680:	00130313          	addi	t1,t1,1
    for (i = 0; i < T3_EVT_SZ; i++)
    4684:	ffc31ce3          	bne	t1,t3,467c <t3_send_event+0x3c>
    pkt[0] = T3_MAGIC0;
    4688:	56455337          	lui	t1,0x56455
    468c:	43830313          	addi	t1,t1,1080 # 56455438 <__freertos_irq_stack_top+0x563eae48>
    4690:	00612023          	sw	t1,0(sp)
    pkt[1] = T3_MAGIC1;
    pkt[2] = T3_MAGIC2;
    pkt[3] = T3_MAGIC3;
    pkt[4] = T3_VER;
    4694:	00100313          	li	t1,1
    4698:	00611223          	sh	t1,4(sp)
    pkt[5] = T3_EVT;
    pkt[6] = (uint8_t)((lp ? 1 : 0) | (has_thumb ? 2 : 0) | (mot ? 4 : 0) | (voice ? 8 : 0));
    469c:	12414303          	lbu	t1,292(sp)
    46a0:	00603333          	snez	t1,t1
    46a4:	00038863          	beqz	t2,46b4 <t3_send_event+0x74>
    46a8:	00236313          	ori	t1,t1,2
    46ac:	01831313          	slli	t1,t1,0x18
    46b0:	41835313          	srai	t1,t1,0x18
    46b4:	00040463          	beqz	s0,46bc <t3_send_event+0x7c>
    46b8:	00436313          	ori	t1,t1,4
    46bc:	00028463          	beqz	t0,46c4 <t3_send_event+0x84>
    46c0:	00836313          	ori	t1,t1,8
    46c4:	ffffca93          	not	s5,t6
    46c8:	41fada93          	srai	s5,s5,0x1f
    46cc:	00610323          	sb	t1,6(sp)
    n = ntrk;
    if (n > T3_MAX_TRK) n = T3_MAX_TRK;
    46d0:	015ffab3          	and	s5,t6,s5
    46d4:	00400313          	li	t1,4
    46d8:	01535463          	bge	t1,s5,46e0 <t3_send_event+0xa0>
    46dc:	00400a93          	li	s5,4
    put_u32(&pkt[8], seq);
    put_u32(&pkt[12], t_ms);
    pkt[16] = evt;
    pkt[17] = score;
    pkt[18] = pd_on;
    pkt[19] = conf;
    46e0:	00f109a3          	sb	a5,19(sp)
    pkt[20] = sht;
    pkt[21] = ta;
    pkt[22] = to;
    46e4:	12014783          	lbu	a5,288(sp)
    pkt[7] = (uint8_t)n;
    46e8:	0ffaf313          	andi	t1,s5,255
    46ec:	006103a3          	sb	t1,7(sp)
    pkt[22] = to;
    46f0:	00f10b23          	sb	a5,22(sp)
    p[0] = (uint8_t)v;
    46f4:	12815783          	lhu	a5,296(sp)
    p[0] = (uint8_t)v;
    46f8:	00a12423          	sw	a0,8(sp)
    46fc:	00b12623          	sw	a1,12(sp)
    p[0] = (uint8_t)v;
    4700:	00f11c23          	sh	a5,24(sp)
    4704:	12c15783          	lhu	a5,300(sp)
    pkt[16] = evt;
    4708:	00c10823          	sb	a2,16(sp)
    pkt[17] = score;
    470c:	00d108a3          	sb	a3,17(sp)
    pkt[18] = pd_on;
    4710:	00e10923          	sb	a4,18(sp)
    pkt[20] = sht;
    4714:	01010a23          	sb	a6,20(sp)
    pkt[21] = ta;
    4718:	01110aa3          	sb	a7,21(sp)
    pkt[23] = (uint8_t)n;
    471c:	00610ba3          	sb	t1,23(sp)
    p[0] = (uint8_t)v;
    4720:	00f11d23          	sh	a5,26(sp)
    put_u16(&pkt[24], fr);
    put_u16(&pkt[26], infer_ms);
    if (n > 0) {
    4724:	0bf05e63          	blez	t6,47e0 <t3_send_event+0x1a0>
    p[0] = (uint8_t)v;
    4728:	016ed783          	lhu	a5,22(t4)
    472c:	014ed683          	lhu	a3,20(t4)
    4730:	000e8713          	mv	a4,t4
    4734:	00f11f23          	sh	a5,30(sp)
    4738:	00d11e23          	sh	a3,28(sp)
    473c:	000f0793          	mv	a5,t5
    4740:	00000593          	li	a1,0
        put_u16(&pkt[28], (uint16_t)trk[0].px);
        put_u16(&pkt[30], (uint16_t)trk[0].py);
    }
    for (i = 0; i < n; i++) {
        uint8_t *q = &pkt[32 + i * 16];
        put_u16(&q[0], trk[i].tid);
    4744:	00075283          	lhu	t0,0(a4)
        q[3] = 0;
        put_u16(&q[4], trk[i].x0);
        put_u16(&q[6], trk[i].y0);
        put_u16(&q[8], trk[i].x1);
        put_u16(&q[10], trk[i].y1);
        put_u16(&q[12], (uint16_t)trk[i].cx);
    4748:	00c71803          	lh	a6,12(a4)
        put_u16(&q[14], (uint16_t)trk[i].cy);
    474c:	00e71503          	lh	a0,14(a4)
        put_u16(&q[4], trk[i].x0);
    4750:	00475f83          	lhu	t6,4(a4)
        put_u16(&q[6], trk[i].y0);
    4754:	00675e83          	lhu	t4,6(a4)
        put_u16(&q[8], trk[i].x1);
    4758:	00875303          	lhu	t1,8(a4)
        put_u16(&q[10], trk[i].y1);
    475c:	00a75883          	lhu	a7,10(a4)
    p[1] = (uint8_t)(v >> 8);
    4760:	0082da13          	srli	s4,t0,0x8
    p[0] = (uint8_t)v;
    4764:	02578023          	sb	t0,32(a5)
    p[1] = (uint8_t)(v >> 8);
    4768:	01081613          	slli	a2,a6,0x10
        q[2] = trk[i].age;
    476c:	00374283          	lbu	t0,3(a4)
    p[1] = (uint8_t)(v >> 8);
    4770:	01051693          	slli	a3,a0,0x10
    4774:	01065613          	srli	a2,a2,0x10
    4778:	0106d693          	srli	a3,a3,0x10
    477c:	008fd993          	srli	s3,t6,0x8
    4780:	008ed913          	srli	s2,t4,0x8
    4784:	00835493          	srli	s1,t1,0x8
    4788:	0088d413          	srli	s0,a7,0x8
    478c:	00865613          	srli	a2,a2,0x8
    4790:	0086d693          	srli	a3,a3,0x8
    4794:	034780a3          	sb	s4,33(a5)
        q[2] = trk[i].age;
    4798:	02578123          	sb	t0,34(a5)
        q[3] = 0;
    479c:	020781a3          	sb	zero,35(a5)
    p[0] = (uint8_t)v;
    47a0:	03f78223          	sb	t6,36(a5)
    p[1] = (uint8_t)(v >> 8);
    47a4:	033782a3          	sb	s3,37(a5)
    p[0] = (uint8_t)v;
    47a8:	03d78323          	sb	t4,38(a5)
    p[1] = (uint8_t)(v >> 8);
    47ac:	032783a3          	sb	s2,39(a5)
    p[0] = (uint8_t)v;
    47b0:	02678423          	sb	t1,40(a5)
    p[1] = (uint8_t)(v >> 8);
    47b4:	029784a3          	sb	s1,41(a5)
    p[0] = (uint8_t)v;
    47b8:	03178523          	sb	a7,42(a5)
    p[1] = (uint8_t)(v >> 8);
    47bc:	028785a3          	sb	s0,43(a5)
    p[0] = (uint8_t)v;
    47c0:	03078623          	sb	a6,44(a5)
    p[1] = (uint8_t)(v >> 8);
    47c4:	02c786a3          	sb	a2,45(a5)
    p[0] = (uint8_t)v;
    47c8:	02a78723          	sb	a0,46(a5)
    p[1] = (uint8_t)(v >> 8);
    47cc:	02d787a3          	sb	a3,47(a5)
    for (i = 0; i < n; i++) {
    47d0:	00158593          	addi	a1,a1,1
    47d4:	01870713          	addi	a4,a4,24
    47d8:	01078793          	addi	a5,a5,16
    47dc:	f755c4e3          	blt	a1,s5,4744 <t3_send_event+0x104>
    p[0] = (uint8_t)v;
    47e0:	003007b7          	lui	a5,0x300
    47e4:	03078793          	addi	a5,a5,48 # 300030 <__freertos_irq_stack_top+0x295a40>
    47e8:	06f12023          	sw	a5,96(sp)
    }
    put_u16(&pkt[96], T3_THUMB_W);
    put_u16(&pkt[98], T3_THUMB_H);
    pkt[100] = has_thumb ? (uint8_t)((T3_THUMB_N + T3_CHUNK - 1) / T3_CHUNK) : 0;
    47ec:	00038463          	beqz	t2,47f4 <t3_send_event+0x1b4>
    47f0:	00a00393          	li	t2,10
    p[0] = (uint8_t)v;
    47f4:	13815783          	lhu	a5,312(sp)
    pkt[100] = has_thumb ? (uint8_t)((T3_THUMB_N + T3_CHUNK - 1) / T3_CHUNK) : 0;
    47f8:	06710223          	sb	t2,100(sp)
    47fc:	001e8637          	lui	a2,0x1e8
    p[0] = (uint8_t)v;
    4800:	06f11423          	sh	a5,104(sp)
    4804:	13c15783          	lhu	a5,316(sp)
        return *((volatile u32*) address);
    4808:	f81006b7          	lui	a3,0xf8100
    480c:	06f11523          	sh	a5,106(sp)
    4810:	14015783          	lhu	a5,320(sp)
    4814:	06f11623          	sh	a5,108(sp)
    4818:	14415783          	lhu	a5,324(sp)
    481c:	06f11723          	sh	a5,110(sp)
    pkt[100] = has_thumb ? (uint8_t)((T3_THUMB_N + T3_CHUNK - 1) / T3_CHUNK) : 0;
    4820:	48160713          	addi	a4,a2,1153 # 1e8481 <__freertos_irq_stack_top+0x17de91>
    4824:	0080006f          	j	482c <t3_send_event+0x1ec>
            if (spin > 2000000u)
    4828:	02070263          	beqz	a4,484c <t3_send_event+0x20c>
    482c:	01c6a783          	lw	a5,28(a3) # f810001c <__freertos_irq_stack_top+0xf8095a2c>
    4830:	fff70713          	addi	a4,a4,-1
        while (read_u32(GRAY_BINSTAT) & 1u) {
    4834:	0017f793          	andi	a5,a5,1
    4838:	fe0798e3          	bnez	a5,4828 <t3_send_event+0x1e8>
        write_u32((uint32_t)p[i], GRAY_BIN);
    483c:	000f4783          	lbu	a5,0(t5)
        *((volatile u32*) address) = data;
    4840:	001f0f13          	addi	t5,t5,1
    4844:	02f6a023          	sw	a5,32(a3)
    for (i = 0; i < n; i++) {
    4848:	fdcf1ce3          	bne	t5,t3,4820 <t3_send_event+0x1e0>
    put_u16(&pkt[104], bx0);
    put_u16(&pkt[106], by0);
    put_u16(&pkt[108], bx1);
    put_u16(&pkt[110], by1);
    t3_send_bytes(pkt, T3_EVT_SZ);
}
    484c:	11c12403          	lw	s0,284(sp)
    4850:	11812483          	lw	s1,280(sp)
    4854:	11412903          	lw	s2,276(sp)
    4858:	11012983          	lw	s3,272(sp)
    485c:	10c12a03          	lw	s4,268(sp)
    4860:	10812a83          	lw	s5,264(sp)
    4864:	12010113          	addi	sp,sp,288
    4868:	00008067          	ret

0000486c <t3_send_thumb>:

void t3_send_thumb(uint32_t seq, const uint8_t *th)
{
    486c:	ef010113          	addi	sp,sp,-272
    uint8_t pkt[T3_PKT_SZ];
    unsigned off = 0;
    uint8_t idx = 0;
    uint8_t nch = (uint8_t)((T3_THUMB_N + T3_CHUNK - 1) / T3_CHUNK);
    while (off < T3_THUMB_N) {
        unsigned i, n = T3_THUMB_N - off;
    4870:	000012b7          	lui	t0,0x1
        if (n > T3_CHUNK) n = T3_CHUNK;
        for (i = 0; i < T3_PKT_SZ; i++)
            pkt[i] = 0;
        pkt[0] = T3_MAGIC0;
    4874:	564553b7          	lui	t2,0x56455
{
    4878:	10812623          	sw	s0,268(sp)
    487c:	10912423          	sw	s1,264(sp)
    4880:	11212223          	sw	s2,260(sp)
    4884:	11312023          	sw	s3,256(sp)
    4888:	00050913          	mv	s2,a0
    488c:	00058993          	mv	s3,a1
        unsigned i, n = T3_THUMB_N - off;
    4890:	90028493          	addi	s1,t0,-1792 # 900 <CUSTOM2+0x8a5>
    uint8_t idx = 0;
    4894:	00000f13          	li	t5,0
    unsigned off = 0;
    4898:	00000e13          	li	t3,0
    489c:	0f000413          	li	s0,240
    48a0:	10010693          	addi	a3,sp,256
        pkt[0] = T3_MAGIC0;
    48a4:	43838393          	addi	t2,t2,1080 # 56455438 <__freertos_irq_stack_top+0x563eae48>
        pkt[1] = T3_MAGIC1;
        pkt[2] = T3_MAGIC2;
        pkt[3] = T3_MAGIC3;
        pkt[4] = T3_VER;
    48a8:	10100513          	li	a0,257
        pkt[5] = T3_THUMB;
        pkt[6] = idx;
        pkt[7] = nch;
    48ac:	00a00593          	li	a1,10
        unsigned i, n = T3_THUMB_N - off;
    48b0:	001e8fb7          	lui	t6,0x1e8
        return *((volatile u32*) address);
    48b4:	f8100637          	lui	a2,0xf8100
    while (off < T3_THUMB_N) {
    48b8:	8ff28293          	addi	t0,t0,-1793
        unsigned i, n = T3_THUMB_N - off;
    48bc:	41c48eb3          	sub	t4,s1,t3
        if (n > T3_CHUNK) n = T3_CHUNK;
    48c0:	01d47463          	bgeu	s0,t4,48c8 <t3_send_thumb+0x5c>
    48c4:	0f000e93          	li	t4,240
        for (i = 0; i < T3_PKT_SZ; i++)
    48c8:	00010813          	mv	a6,sp
        unsigned i, n = T3_THUMB_N - off;
    48cc:	00010793          	mv	a5,sp
            pkt[i] = 0;
    48d0:	00078023          	sb	zero,0(a5)
    48d4:	00178793          	addi	a5,a5,1
        for (i = 0; i < T3_PKT_SZ; i++)
    48d8:	fed79ce3          	bne	a5,a3,48d0 <t3_send_thumb+0x64>
        pkt[5] = T3_THUMB;
    48dc:	01c987b3          	add	a5,s3,t3
        pkt[0] = T3_MAGIC0;
    48e0:	00712023          	sw	t2,0(sp)
        pkt[4] = T3_VER;
    48e4:	00a11223          	sh	a0,4(sp)
        pkt[6] = idx;
    48e8:	01e10323          	sb	t5,6(sp)
        pkt[7] = nch;
    48ec:	00b103a3          	sb	a1,7(sp)
    p[0] = (uint8_t)v;
    48f0:	01212423          	sw	s2,8(sp)
    p[0] = (uint8_t)v;
    48f4:	01c11623          	sh	t3,12(sp)
    48f8:	01d10723          	sb	t4,14(sp)
    p[1] = (uint8_t)(v >> 8);
    48fc:	000107a3          	sb	zero,15(sp)
        put_u32(&pkt[8], seq);
        put_u16(&pkt[12], (uint16_t)off);
        put_u16(&pkt[14], (uint16_t)n);
        for (i = 0; i < n; i++)
    4900:	01010713          	addi	a4,sp,16
    4904:	00fe8333          	add	t1,t4,a5
            pkt[16 + i] = th[off + i];
    4908:	0007c883          	lbu	a7,0(a5)
    490c:	00170713          	addi	a4,a4,1
    4910:	00178793          	addi	a5,a5,1
    4914:	ff170fa3          	sb	a7,-1(a4)
        for (i = 0; i < n; i++)
    4918:	fef318e3          	bne	t1,a5,4908 <t3_send_thumb+0x9c>
        unsigned i, n = T3_THUMB_N - off;
    491c:	481f8713          	addi	a4,t6,1153 # 1e8481 <__freertos_irq_stack_top+0x17de91>
    4920:	0080006f          	j	4928 <t3_send_thumb+0xbc>
            if (spin > 2000000u)
    4924:	02070263          	beqz	a4,4948 <t3_send_thumb+0xdc>
    4928:	01c62783          	lw	a5,28(a2) # f810001c <__freertos_irq_stack_top+0xf8095a2c>
    492c:	fff70713          	addi	a4,a4,-1
        while (read_u32(GRAY_BINSTAT) & 1u) {
    4930:	0017f793          	andi	a5,a5,1
    4934:	fe0798e3          	bnez	a5,4924 <t3_send_thumb+0xb8>
        write_u32((uint32_t)p[i], GRAY_BIN);
    4938:	00084783          	lbu	a5,0(a6)
        *((volatile u32*) address) = data;
    493c:	00180813          	addi	a6,a6,1
    4940:	02f62023          	sw	a5,32(a2)
    for (i = 0; i < n; i++) {
    4944:	fcd81ce3          	bne	a6,a3,491c <t3_send_thumb+0xb0>
        t3_send_bytes(pkt, T3_PKT_SZ);
        off += n;
        idx++;
    4948:	001f0f13          	addi	t5,t5,1
        off += n;
    494c:	01de0e33          	add	t3,t3,t4
        idx++;
    4950:	0fff7f13          	andi	t5,t5,255
    while (off < T3_THUMB_N) {
    4954:	f7c2f4e3          	bgeu	t0,t3,48bc <t3_send_thumb+0x50>
    }
}
    4958:	10c12403          	lw	s0,268(sp)
    495c:	10812483          	lw	s1,264(sp)
    4960:	10412903          	lw	s2,260(sp)
    4964:	10012983          	lw	s3,256(sp)
    4968:	11010113          	addi	sp,sp,272
    496c:	00008067          	ret

00004970 <t3_tx_settle>:

void t3_tx_settle(void)
{
    4970:	ff010113          	addi	sp,sp,-16
    volatile unsigned i;
    for (i = 0; i < 300000u; i++)
    4974:	00012623          	sw	zero,12(sp)
    4978:	00c12783          	lw	a5,12(sp)
    497c:	00049737          	lui	a4,0x49
    4980:	3df70713          	addi	a4,a4,991 # 493df <thumb+0x45f>
    4984:	00f76c63          	bltu	a4,a5,499c <t3_tx_settle+0x2c>
    4988:	00c12783          	lw	a5,12(sp)
    498c:	00178793          	addi	a5,a5,1
    4990:	00f12623          	sw	a5,12(sp)
    4994:	00c12783          	lw	a5,12(sp)
    4998:	fef778e3          	bgeu	a4,a5,4988 <t3_tx_settle+0x18>
        ;
}
    499c:	01010113          	addi	sp,sp,16
    49a0:	00008067          	ret

000049a4 <t3_track_init>:

void t3_track_init(void)
{
    int i;
    for (i = 0; i < T3_MAX_TRK; i++)
        s_trk[i].used = 0;
    49a4:	000527b7          	lui	a5,0x52
    49a8:	18078793          	addi	a5,a5,384 # 52180 <s_trk>
    49ac:	00078123          	sb	zero,2(a5)
    49b0:	00078d23          	sb	zero,26(a5)
    49b4:	02078923          	sb	zero,50(a5)
    49b8:	04078523          	sb	zero,74(a5)
    s_next_tid = 1;
    49bc:	00100713          	li	a4,1
    49c0:	8ce19223          	sh	a4,-1852(gp) # 46c7c <s_next_tid>
}
    49c4:	00008067          	ret

000049c8 <t3_track_clear>:

void t3_track_clear(void)
{
    int i;
    for (i = 0; i < T3_MAX_TRK; i++)
        s_trk[i].used = 0;
    49c8:	000527b7          	lui	a5,0x52
    49cc:	18078793          	addi	a5,a5,384 # 52180 <s_trk>
    49d0:	00078123          	sb	zero,2(a5)
    49d4:	00078d23          	sb	zero,26(a5)
    49d8:	02078923          	sb	zero,50(a5)
    49dc:	04078523          	sb	zero,74(a5)
}
    49e0:	00008067          	ret

000049e4 <t3_blobs>:
}

int t3_blobs(const uint8_t *g96, const uint8_t *prev96, t3_det_t *out, int maxn)
{
    int x, y, n = 0, i;
    for (y = 0; y < DH; y++) {
    49e4:	00053f37          	lui	t5,0x53
    49e8:	00002fb7          	lui	t6,0x2
{
    49ec:	fc010113          	addi	sp,sp,-64
    49f0:	00054337          	lui	t1,0x54
    49f4:	3e0f0793          	addi	a5,t5,992 # 533e0 <s_vis>
    49f8:	fa058593          	addi	a1,a1,-96
    49fc:	460f8f93          	addi	t6,t6,1120 # 2460 <send_tcp+0x2ec>
    4a00:	03312823          	sw	s3,48(sp)
    4a04:	03512423          	sw	s5,40(sp)
    4a08:	03612223          	sw	s6,36(sp)
    4a0c:	3e0f0e93          	addi	t4,t5,992
    4a10:	ce030b13          	addi	s6,t1,-800 # 53ce0 <s_fg>
    4a14:	ce030e13          	addi	t3,t1,-800
    4a18:	02812e23          	sw	s0,60(sp)
    4a1c:	02912c23          	sw	s1,56(sp)
    4a20:	03212a23          	sw	s2,52(sp)
    4a24:	03412623          	sw	s4,44(sp)
    4a28:	03712023          	sw	s7,32(sp)
    4a2c:	01812e23          	sw	s8,28(sp)
    4a30:	01912c23          	sw	s9,24(sp)
    4a34:	01a12a23          	sw	s10,20(sp)
    4a38:	01b12823          	sw	s11,16(sp)
    4a3c:	00060a93          	mv	s5,a2
    4a40:	00068993          	mv	s3,a3
    4a44:	06050893          	addi	a7,a0,96
    4a48:	00f12423          	sw	a5,8(sp)
    4a4c:	01f50fb3          	add	t6,a0,t6
    4a50:	3e0f0f13          	addi	t5,t5,992
    4a54:	ce030313          	addi	t1,t1,-800
    4a58:	40a582b3          	sub	t0,a1,a0
    4a5c:	fa088713          	addi	a4,a7,-96
    4a60:	011285b3          	add	a1,t0,a7
    4a64:	000f0613          	mv	a2,t5
    4a68:	00030693          	mv	a3,t1
        for (x = 0; x < DW; x++) {
            int g = (int)g96[(y * 2) * 96 + (x * 2)];
    4a6c:	00074503          	lbu	a0,0(a4)
            int p = (int)prev96[(y * 2) * 96 + (x * 2)];
    4a70:	0005c803          	lbu	a6,0(a1)
            int d = g - p;
    4a74:	00270713          	addi	a4,a4,2
    4a78:	00258593          	addi	a1,a1,2
    4a7c:	410507b3          	sub	a5,a0,a6
            if (d < 0) d = -d;
    4a80:	0007d463          	bgez	a5,4a88 <t3_blobs+0xa4>
    4a84:	40a807b3          	sub	a5,a6,a0
            i = y * DW + x;
            s_fg[i] = (d >= DIFF_TH) ? 1 : 0;
    4a88:	01c7a793          	slti	a5,a5,28
    4a8c:	0017c793          	xori	a5,a5,1
    4a90:	00f68023          	sb	a5,0(a3)
            s_vis[i] = 0;
    4a94:	00060023          	sb	zero,0(a2)
    4a98:	00168693          	addi	a3,a3,1
    4a9c:	00160613          	addi	a2,a2,1
        for (x = 0; x < DW; x++) {
    4aa0:	fce896e3          	bne	a7,a4,4a6c <t3_blobs+0x88>
    4aa4:	0c088893          	addi	a7,a7,192
    4aa8:	03030313          	addi	t1,t1,48
    4aac:	030f0f13          	addi	t5,t5,48
    for (y = 0; y < DH; y++) {
    4ab0:	fbf896e3          	bne	a7,t6,4a5c <t3_blobs+0x78>
    4ab4:	00001a37          	lui	s4,0x1
    4ab8:	900a0793          	addi	a5,s4,-1792 # 900 <CUSTOM2+0x8a5>
    4abc:	00fb07b3          	add	a5,s6,a5
    s_stk[sp++] = (int16_t)i;
    4ac0:	000526b7          	lui	a3,0x52
    4ac4:	00f12623          	sw	a5,12(sp)
    for (y = 0; y < DH; y++) {
    4ac8:	00012223          	sw	zero,4(sp)
    int x, y, n = 0, i;
    4acc:	00000913          	li	s2,0
        }
    }
    for (y = 0; y < DH; y++) {
    4ad0:	00000b93          	li	s7,0
    s_stk[sp++] = (int16_t)i;
    4ad4:	1e068693          	addi	a3,a3,480 # 521e0 <s_stk>
    s_vis[i] = 1;
    4ad8:	00100413          	li	s0,1
        int x = p % DW;
    4adc:	03000613          	li	a2,48
        if (x + 1 < DW && s_fg[p + 1] && !s_vis[p + 1]) {
    4ae0:	02f00493          	li	s1,47
        if (y + 1 < DH && s_fg[p + DW] && !s_vis[p + DW]) {
    4ae4:	8cfa0a13          	addi	s4,s4,-1841
                continue;
            if (area < MIN_AREA)
                continue;
            if (n < maxn) {
                out[n].x0 = (uint16_t)(x0 * 40);
                out[n].y0 = (uint16_t)(y0 * 22);
    4ae8:	01600c13          	li	s8,22
{
    4aec:	00812383          	lw	t2,8(sp)
        for (x = 0; x < DW; x++) {
    4af0:	00000813          	li	a6,0
    if (!s_fg[i] || s_vis[i])
    4af4:	010b07b3          	add	a5,s6,a6
    4af8:	0007c783          	lbu	a5,0(a5)
    4afc:	1e078263          	beqz	a5,4ce0 <t3_blobs+0x2fc>
    4b00:	0003c783          	lbu	a5,0(t2)
    4b04:	1c079e63          	bnez	a5,4ce0 <t3_blobs+0x2fc>
    s_stk[sp++] = (int16_t)i;
    4b08:	00412783          	lw	a5,4(sp)
    s_vis[i] = 1;
    4b0c:	00838023          	sb	s0,0(t2)
    4b10:	000b8893          	mv	a7,s7
    4b14:	010787b3          	add	a5,a5,a6
    4b18:	01079793          	slli	a5,a5,0x10
    4b1c:	4107d793          	srai	a5,a5,0x10
    s_stk[sp++] = (int16_t)i;
    4b20:	00f69023          	sh	a5,0(a3)
    s_vis[i] = 1;
    4b24:	00080513          	mv	a0,a6
    4b28:	000b8f13          	mv	t5,s7
    4b2c:	00080293          	mv	t0,a6
    *area = 0;
    4b30:	00000313          	li	t1,0
    s_stk[sp++] = (int16_t)i;
    4b34:	00100c93          	li	s9,1
        int x = p % DW;
    4b38:	02c7e5b3          	rem	a1,a5,a2
        int p = s_stk[--sp];
    4b3c:	fffc8713          	addi	a4,s9,-1
        (*area)++;
    4b40:	00130313          	addi	t1,t1,1
        int y = p / DW;
    4b44:	02c7cfb3          	div	t6,a5,a2
        if (x < *x0) *x0 = x;
    4b48:	0055d463          	bge	a1,t0,4b50 <t3_blobs+0x16c>
    4b4c:	00058293          	mv	t0,a1
        if (x > *x1) *x1 = x;
    4b50:	00b55463          	bge	a0,a1,4b58 <t3_blobs+0x174>
    4b54:	00058513          	mv	a0,a1
        if (y < *y0) *y0 = y;
    4b58:	01efd463          	bge	t6,t5,4b60 <t3_blobs+0x17c>
    4b5c:	000f8f13          	mv	t5,t6
        if (y > *y1) *y1 = y;
    4b60:	01f8d463          	bge	a7,t6,4b68 <t3_blobs+0x184>
    4b64:	000f8893          	mv	a7,t6
        if (x > 0 && s_fg[p - 1] && !s_vis[p - 1]) {
    4b68:	08b05263          	blez	a1,4bec <t3_blobs+0x208>
    4b6c:	fff78f93          	addi	t6,a5,-1
    4b70:	01fe0d33          	add	s10,t3,t6
    4b74:	000d4d03          	lbu	s10,0(s10)
    4b78:	020d0263          	beqz	s10,4b9c <t3_blobs+0x1b8>
    4b7c:	01fe8d33          	add	s10,t4,t6
    4b80:	000d4d83          	lbu	s11,0(s10)
    4b84:	000d9c63          	bnez	s11,4b9c <t3_blobs+0x1b8>
            s_stk[sp++] = (int16_t)(p - 1);
    4b88:	00171713          	slli	a4,a4,0x1
    4b8c:	00e68733          	add	a4,a3,a4
    4b90:	01f71023          	sh	t6,0(a4)
            s_vis[p - 1] = 1;
    4b94:	008d0023          	sb	s0,0(s10)
            s_stk[sp++] = (int16_t)(p - 1);
    4b98:	000c8713          	mv	a4,s9
        if (x + 1 < DW && s_fg[p + 1] && !s_vis[p + 1]) {
    4b9c:	04959863          	bne	a1,s1,4bec <t3_blobs+0x208>
        if (y > 0 && s_fg[p - DW] && !s_vis[p - DW]) {
    4ba0:	08f4d063          	bge	s1,a5,4c20 <t3_blobs+0x23c>
    4ba4:	fd078593          	addi	a1,a5,-48
    4ba8:	00be0fb3          	add	t6,t3,a1
    4bac:	000fcf83          	lbu	t6,0(t6)
    4bb0:	0a0f8a63          	beqz	t6,4c64 <t3_blobs+0x280>
    4bb4:	00be8fb3          	add	t6,t4,a1
    4bb8:	000fcc83          	lbu	s9,0(t6)
    4bbc:	0a0c9463          	bnez	s9,4c64 <t3_blobs+0x280>
            s_stk[sp++] = (int16_t)(p - DW);
    4bc0:	00171c93          	slli	s9,a4,0x1
    4bc4:	01059593          	slli	a1,a1,0x10
    4bc8:	4105d593          	srai	a1,a1,0x10
    4bcc:	01968cb3          	add	s9,a3,s9
            s_vis[p - DW] = 1;
    4bd0:	008f8023          	sb	s0,0(t6)
            s_stk[sp++] = (int16_t)(p - DW);
    4bd4:	00bc9023          	sh	a1,0(s9)
    4bd8:	00170713          	addi	a4,a4,1
        if (y + 1 < DH && s_fg[p + DW] && !s_vis[p + DW]) {
    4bdc:	20fa5c63          	bge	s4,a5,4df4 <t3_blobs+0x410>
    4be0:	00058793          	mv	a5,a1
        (*area)++;
    4be4:	00070c93          	mv	s9,a4
    4be8:	f51ff06f          	j	4b38 <t3_blobs+0x154>
        if (x + 1 < DW && s_fg[p + 1] && !s_vis[p + 1]) {
    4bec:	00178593          	addi	a1,a5,1
    4bf0:	00be0fb3          	add	t6,t3,a1
    4bf4:	000fcf83          	lbu	t6,0(t6)
    4bf8:	fa0f84e3          	beqz	t6,4ba0 <t3_blobs+0x1bc>
    4bfc:	00be8fb3          	add	t6,t4,a1
    4c00:	000fcc83          	lbu	s9,0(t6)
    4c04:	f80c9ee3          	bnez	s9,4ba0 <t3_blobs+0x1bc>
            s_stk[sp++] = (int16_t)(p + 1);
    4c08:	00171c93          	slli	s9,a4,0x1
    4c0c:	01968cb3          	add	s9,a3,s9
            s_vis[p + 1] = 1;
    4c10:	008f8023          	sb	s0,0(t6)
            s_stk[sp++] = (int16_t)(p + 1);
    4c14:	00bc9023          	sh	a1,0(s9)
    4c18:	00170713          	addi	a4,a4,1
        if (y > 0 && s_fg[p - DW] && !s_vis[p - DW]) {
    4c1c:	f8f4c4e3          	blt	s1,a5,4ba4 <t3_blobs+0x1c0>
        if (y + 1 < DH && s_fg[p + DW] && !s_vis[p + DW]) {
    4c20:	03078793          	addi	a5,a5,48
    4c24:	00fe05b3          	add	a1,t3,a5
    4c28:	0005c583          	lbu	a1,0(a1)
    4c2c:	02058e63          	beqz	a1,4c68 <t3_blobs+0x284>
    4c30:	00fe85b3          	add	a1,t4,a5
    4c34:	0005c583          	lbu	a1,0(a1)
    4c38:	02059863          	bnez	a1,4c68 <t3_blobs+0x284>
            s_stk[sp++] = (int16_t)(p + DW);
    4c3c:	00171593          	slli	a1,a4,0x1
            s_vis[p + DW] = 1;
    4c40:	00fe8fb3          	add	t6,t4,a5
            s_stk[sp++] = (int16_t)(p + DW);
    4c44:	01079793          	slli	a5,a5,0x10
    4c48:	4107d793          	srai	a5,a5,0x10
    4c4c:	00b685b3          	add	a1,a3,a1
    4c50:	00170713          	addi	a4,a4,1
            s_vis[p + DW] = 1;
    4c54:	008f8023          	sb	s0,0(t6)
            s_stk[sp++] = (int16_t)(p + DW);
    4c58:	00f59023          	sh	a5,0(a1)
        (*area)++;
    4c5c:	00070c93          	mv	s9,a4
    4c60:	ed9ff06f          	j	4b38 <t3_blobs+0x154>
        if (y + 1 < DH && s_fg[p + DW] && !s_vis[p + DW]) {
    4c64:	fafa5ee3          	bge	s4,a5,4c20 <t3_blobs+0x23c>
    while (sp) {
    4c68:	00070e63          	beqz	a4,4c84 <t3_blobs+0x2a0>
    4c6c:	fff70793          	addi	a5,a4,-1
    4c70:	00179793          	slli	a5,a5,0x1
    4c74:	00f687b3          	add	a5,a3,a5
    4c78:	00079783          	lh	a5,0(a5)
        (*area)++;
    4c7c:	00070c93          	mv	s9,a4
    4c80:	eb9ff06f          	j	4b38 <t3_blobs+0x154>
            if (area < MIN_AREA)
    4c84:	02700793          	li	a5,39
    4c88:	0467dc63          	bge	a5,t1,4ce0 <t3_blobs+0x2fc>
            if (n < maxn) {
    4c8c:	0d395263          	bge	s2,s3,4d50 <t3_blobs+0x36c>
                out[n].x1 = (uint16_t)((x1 + 1) * 40);
                out[n].y1 = (uint16_t)((y1 + 1) * 22);
    4c90:	00188893          	addi	a7,a7,1
                out[n].y0 = (uint16_t)(y0 * 22);
    4c94:	038f0f33          	mul	t5,t5,s8
                out[n].x0 = (uint16_t)(x0 * 40);
    4c98:	00291793          	slli	a5,s2,0x2
                out[n].x1 = (uint16_t)((x1 + 1) * 40);
    4c9c:	00150513          	addi	a0,a0,1
                out[n].x0 = (uint16_t)(x0 * 40);
    4ca0:	012787b3          	add	a5,a5,s2
    4ca4:	00229713          	slli	a4,t0,0x2
                out[n].x1 = (uint16_t)((x1 + 1) * 40);
    4ca8:	00251593          	slli	a1,a0,0x2
                out[n].x0 = (uint16_t)(x0 * 40);
    4cac:	00179793          	slli	a5,a5,0x1
    4cb0:	00e282b3          	add	t0,t0,a4
                out[n].x1 = (uint16_t)((x1 + 1) * 40);
    4cb4:	00b50533          	add	a0,a0,a1
                out[n].x0 = (uint16_t)(x0 * 40);
    4cb8:	00fa87b3          	add	a5,s5,a5
                out[n].y1 = (uint16_t)((y1 + 1) * 22);
    4cbc:	038888b3          	mul	a7,a7,s8
                out[n].x0 = (uint16_t)(x0 * 40);
    4cc0:	00329293          	slli	t0,t0,0x3
                out[n].x1 = (uint16_t)((x1 + 1) * 40);
    4cc4:	00351513          	slli	a0,a0,0x3
                out[n].x0 = (uint16_t)(x0 * 40);
    4cc8:	00579023          	sh	t0,0(a5)
                out[n].y0 = (uint16_t)(y0 * 22);
    4ccc:	01e79123          	sh	t5,2(a5)
                out[n].x1 = (uint16_t)((x1 + 1) * 40);
    4cd0:	00a79223          	sh	a0,4(a5)
                out[n].area = (uint16_t)area;
    4cd4:	00679423          	sh	t1,8(a5)
                n++;
    4cd8:	00190913          	addi	s2,s2,1
                out[n].y1 = (uint16_t)((y1 + 1) * 22);
    4cdc:	01179323          	sh	a7,6(a5)
        for (x = 0; x < DW; x++) {
    4ce0:	00180813          	addi	a6,a6,1
    4ce4:	00138393          	addi	t2,t2,1
    4ce8:	e0c816e3          	bne	a6,a2,4af4 <t3_blobs+0x110>
    4cec:	00812783          	lw	a5,8(sp)
    4cf0:	030b0b13          	addi	s6,s6,48
    for (y = 0; y < DH; y++) {
    4cf4:	001b8b93          	addi	s7,s7,1
    4cf8:	03078793          	addi	a5,a5,48
    4cfc:	00f12423          	sw	a5,8(sp)
    4d00:	00412783          	lw	a5,4(sp)
    4d04:	03078793          	addi	a5,a5,48
    4d08:	00f12223          	sw	a5,4(sp)
    4d0c:	00c12783          	lw	a5,12(sp)
    4d10:	dd679ee3          	bne	a5,s6,4aec <t3_blobs+0x108>
                }
            }
        }
    }
    return n;
}
    4d14:	03c12403          	lw	s0,60(sp)
    4d18:	00090513          	mv	a0,s2
    4d1c:	03812483          	lw	s1,56(sp)
    4d20:	03412903          	lw	s2,52(sp)
    4d24:	03012983          	lw	s3,48(sp)
    4d28:	02c12a03          	lw	s4,44(sp)
    4d2c:	02812a83          	lw	s5,40(sp)
    4d30:	02412b03          	lw	s6,36(sp)
    4d34:	02012b83          	lw	s7,32(sp)
    4d38:	01c12c03          	lw	s8,28(sp)
    4d3c:	01812c83          	lw	s9,24(sp)
    4d40:	01412d03          	lw	s10,20(sp)
    4d44:	01012d83          	lw	s11,16(sp)
    4d48:	04010113          	addi	sp,sp,64
    4d4c:	00008067          	ret
    4d50:	008add83          	lhu	s11,8(s5)
    4d54:	00aa8593          	addi	a1,s5,10
                for (i = 1; i < maxn; i++)
    4d58:	00100f93          	li	t6,1
    4d5c:	000a8d13          	mv	s10,s5
    4d60:	01344c63          	blt	s0,s3,4d78 <t3_blobs+0x394>
    4d64:	0400006f          	j	4da4 <t3_blobs+0x3c0>
    4d68:	001f8f93          	addi	t6,t6,1
                    if (out[i].area < out[w].area) w = i;
    4d6c:	00fa8d33          	add	s10,s5,a5
    4d70:	00a58593          	addi	a1,a1,10
                for (i = 1; i < maxn; i++)
    4d74:	03f98863          	beq	s3,t6,4da4 <t3_blobs+0x3c0>
                    if (out[i].area < out[w].area) w = i;
    4d78:	0085dc83          	lhu	s9,8(a1)
    4d7c:	00271793          	slli	a5,a4,0x2
    4d80:	00e787b3          	add	a5,a5,a4
    4d84:	00179793          	slli	a5,a5,0x1
    4d88:	00058d13          	mv	s10,a1
    4d8c:	fdbcfee3          	bgeu	s9,s11,4d68 <t3_blobs+0x384>
    4d90:	000f8713          	mv	a4,t6
                for (i = 1; i < maxn; i++)
    4d94:	001f8f93          	addi	t6,t6,1
    4d98:	000c8d93          	mv	s11,s9
    4d9c:	00a58593          	addi	a1,a1,10
    4da0:	fdf99ce3          	bne	s3,t6,4d78 <t3_blobs+0x394>
                if (area > (int)out[w].area) {
    4da4:	f26ddee3          	bge	s11,t1,4ce0 <t3_blobs+0x2fc>
                    out[w].y1 = (uint16_t)((y1 + 1) * 22);
    4da8:	00188893          	addi	a7,a7,1
                    out[w].y0 = (uint16_t)(y0 * 22);
    4dac:	038f0f33          	mul	t5,t5,s8
                    out[w].x1 = (uint16_t)((x1 + 1) * 40);
    4db0:	00150513          	addi	a0,a0,1
                    out[w].x0 = (uint16_t)(x0 * 40);
    4db4:	00229713          	slli	a4,t0,0x2
                    out[w].x1 = (uint16_t)((x1 + 1) * 40);
    4db8:	00251793          	slli	a5,a0,0x2
                    out[w].x0 = (uint16_t)(x0 * 40);
    4dbc:	00e282b3          	add	t0,t0,a4
                    out[w].x1 = (uint16_t)((x1 + 1) * 40);
    4dc0:	00f50533          	add	a0,a0,a5
                    out[w].x0 = (uint16_t)(x0 * 40);
    4dc4:	00329293          	slli	t0,t0,0x3
                    out[w].x1 = (uint16_t)((x1 + 1) * 40);
    4dc8:	00351513          	slli	a0,a0,0x3
                    out[w].x0 = (uint16_t)(x0 * 40);
    4dcc:	005d1023          	sh	t0,0(s10)
                    out[w].x1 = (uint16_t)((x1 + 1) * 40);
    4dd0:	00ad1223          	sh	a0,4(s10)
                    out[w].y1 = (uint16_t)((y1 + 1) * 22);
    4dd4:	038888b3          	mul	a7,a7,s8
                    out[w].y0 = (uint16_t)(y0 * 22);
    4dd8:	01ed1123          	sh	t5,2(s10)
                    out[w].area = (uint16_t)area;
    4ddc:	006d1423          	sh	t1,8(s10)
        for (x = 0; x < DW; x++) {
    4de0:	00180813          	addi	a6,a6,1
    4de4:	00138393          	addi	t2,t2,1
                    out[w].y1 = (uint16_t)((y1 + 1) * 22);
    4de8:	011d1323          	sh	a7,6(s10)
        for (x = 0; x < DW; x++) {
    4dec:	d0c814e3          	bne	a6,a2,4af4 <t3_blobs+0x110>
    4df0:	efdff06f          	j	4cec <t3_blobs+0x308>
        if (y + 1 < DH && s_fg[p + DW] && !s_vis[p + DW]) {
    4df4:	03078793          	addi	a5,a5,48
    4df8:	00fe05b3          	add	a1,t3,a5
    4dfc:	0005c583          	lbu	a1,0(a1)
    4e00:	e60586e3          	beqz	a1,4c6c <t3_blobs+0x288>
    4e04:	00fe85b3          	add	a1,t4,a5
    4e08:	0005c583          	lbu	a1,0(a1)
    4e0c:	e20588e3          	beqz	a1,4c3c <t3_blobs+0x258>
    4e10:	e5dff06f          	j	4c6c <t3_blobs+0x288>

00004e14 <t3_add_box>:
static void add_box(t3_det_t *out, int *nd, int maxn,
                   int x0, int y0, int x1, int y1, int force)
{
    int i;
    uint32_t best = 0;
    if (x1 <= x0 || y1 <= y0)
    4e14:	1ef6d063          	bge	a3,a5,4ff4 <t3_add_box+0x1e0>
    4e18:	1d075e63          	bge	a4,a6,4ff4 <t3_add_box+0x1e0>
    out[i].area = (uint16_t)(((x1 - x0) * (y1 - y0)) / 256);
    (*nd)++;
}

void t3_add_box(t3_det_t *out, int *nd, int maxn, int x0, int y0, int x1, int y1)
{
    4e1c:	fc010113          	addi	sp,sp,-64
    4e20:	03412623          	sw	s4,44(sp)
        for (i = 0; i < *nd; i++) {
    4e24:	0005aa03          	lw	s4,0(a1)
{
    4e28:	02812e23          	sw	s0,60(sp)
    4e2c:	02912c23          	sw	s1,56(sp)
    4e30:	03212a23          	sw	s2,52(sp)
    4e34:	03312823          	sw	s3,48(sp)
    4e38:	03512423          	sw	s5,40(sp)
    4e3c:	03612223          	sw	s6,36(sp)
    4e40:	03712023          	sw	s7,32(sp)
    4e44:	01812e23          	sw	s8,28(sp)
    4e48:	01912c23          	sw	s9,24(sp)
    4e4c:	01a12a23          	sw	s10,20(sp)
    4e50:	01b12823          	sw	s11,16(sp)
        for (i = 0; i < *nd; i++) {
    4e54:	13405463          	blez	s4,4f7c <t3_add_box+0x168>
    uint32_t a = (uint32_t)(ax1 - ax0) * (uint32_t)(ay1 - ay0);
    4e58:	000108b7          	lui	a7,0x10
    4e5c:	fff88893          	addi	a7,a7,-1 # ffff <pd_w26+0x353f>
    4e60:	0116fe33          	and	t3,a3,a7
    4e64:	0117f9b3          	and	s3,a5,a7
    4e68:	01187333          	and	t1,a6,a7
    4e6c:	011778b3          	and	a7,a4,a7
    4e70:	41c989b3          	sub	s3,s3,t3
    4e74:	411308b3          	sub	a7,t1,a7
    4e78:	031989b3          	mul	s3,s3,a7
    4e7c:	002a1493          	slli	s1,s4,0x2
    4e80:	014484b3          	add	s1,s1,s4
    4e84:	01069c93          	slli	s9,a3,0x10
    4e88:	01071c13          	slli	s8,a4,0x10
    4e8c:	01079b93          	slli	s7,a5,0x10
    4e90:	01081b13          	slli	s6,a6,0x10
    4e94:	010cdc93          	srli	s9,s9,0x10
    4e98:	010c5c13          	srli	s8,s8,0x10
    4e9c:	010bdb93          	srli	s7,s7,0x10
    4ea0:	010b5b13          	srli	s6,s6,0x10
    4ea4:	00149493          	slli	s1,s1,0x1
    4ea8:	00050e13          	mv	t3,a0
    4eac:	00a484b3          	add	s1,s1,a0
    uint32_t best = 0;
    4eb0:	00000a93          	li	s5,0
    uint16_t ix0 = ax0 > bx0 ? ax0 : bx0;
    4eb4:	000c8d93          	mv	s11,s9
    uint16_t iy0 = ay0 > by0 ? ay0 : by0;
    4eb8:	000c0d13          	mv	s10,s8
    uint16_t ix1 = ax1 < bx1 ? ax1 : bx1;
    4ebc:	01711623          	sh	s7,12(sp)
    uint16_t iy1 = ay1 < by1 ? ay1 : by1;
    4ec0:	01611723          	sh	s6,14(sp)
            uint32_t iou = box_iou((uint16_t)x0, (uint16_t)y0, (uint16_t)x1, (uint16_t)y1,
    4ec4:	000e5403          	lhu	s0,0(t3)
    4ec8:	002e5383          	lhu	t2,2(t3)
    4ecc:	004e5883          	lhu	a7,4(t3)
    4ed0:	006e5e83          	lhu	t4,6(t3)
    uint16_t ix0 = ax0 > bx0 ? ax0 : bx0;
    4ed4:	00040f93          	mv	t6,s0
    4ed8:	01947463          	bgeu	s0,s9,4ee0 <t3_add_box+0xcc>
    4edc:	000d8f93          	mv	t6,s11
    4ee0:	010f9f93          	slli	t6,t6,0x10
    4ee4:	010fdf93          	srli	t6,t6,0x10
    uint16_t iy0 = ay0 > by0 ? ay0 : by0;
    4ee8:	00038f13          	mv	t5,t2
    4eec:	0183f463          	bgeu	t2,s8,4ef4 <t3_add_box+0xe0>
    4ef0:	000d0f13          	mv	t5,s10
    4ef4:	010f1f13          	slli	t5,t5,0x10
    4ef8:	010f5f13          	srli	t5,t5,0x10
    uint16_t ix1 = ax1 < bx1 ? ax1 : bx1;
    4efc:	00088293          	mv	t0,a7
    4f00:	011bf463          	bgeu	s7,a7,4f08 <t3_add_box+0xf4>
    4f04:	00c15283          	lhu	t0,12(sp)
    4f08:	01029293          	slli	t0,t0,0x10
    4f0c:	0102d293          	srli	t0,t0,0x10
    uint16_t iy1 = ay1 < by1 ? ay1 : by1;
    4f10:	000e8313          	mv	t1,t4
    4f14:	01db7463          	bgeu	s6,t4,4f1c <t3_add_box+0x108>
    4f18:	00e15303          	lhu	t1,14(sp)
    4f1c:	01031313          	slli	t1,t1,0x10
    4f20:	01035313          	srli	t1,t1,0x10
    uint32_t iw = (ix1 > ix0) ? (uint32_t)(ix1 - ix0) : 0;
    4f24:	00000913          	li	s2,0
    4f28:	005ff463          	bgeu	t6,t0,4f30 <t3_add_box+0x11c>
    4f2c:	41f28933          	sub	s2,t0,t6
    uint32_t ih = (iy1 > iy0) ? (uint32_t)(iy1 - iy0) : 0;
    4f30:	00000f93          	li	t6,0
    4f34:	006f7663          	bgeu	t5,t1,4f40 <t3_add_box+0x12c>
    4f38:	41e30333          	sub	t1,t1,t5
    4f3c:	03230fb3          	mul	t6,t1,s2
    uint32_t b = (uint32_t)(bx1 - bx0) * (uint32_t)(by1 - by0);
    4f40:	408888b3          	sub	a7,a7,s0
    4f44:	407e8eb3          	sub	t4,t4,t2
    4f48:	03d888b3          	mul	a7,a7,t4
    uint32_t uni = a + b - inter;
    4f4c:	013888b3          	add	a7,a7,s3
    4f50:	41f888b3          	sub	a7,a7,t6
    if (uni == 0)
    4f54:	00088c63          	beqz	a7,4f6c <t3_add_box+0x158>
    return (inter * 100) / uni;
    4f58:	06400313          	li	t1,100
    4f5c:	026f8fb3          	mul	t6,t6,t1
    4f60:	031fd8b3          	divu	a7,t6,a7
    4f64:	011af463          	bgeu	s5,a7,4f6c <t3_add_box+0x158>
    4f68:	00088a93          	mv	s5,a7
    4f6c:	00ae0e13          	addi	t3,t3,10
        for (i = 0; i < *nd; i++) {
    4f70:	f5c49ae3          	bne	s1,t3,4ec4 <t3_add_box+0xb0>
        if (best >= 25)
    4f74:	01800893          	li	a7,24
    4f78:	0558e263          	bltu	a7,s5,4fbc <t3_add_box+0x1a8>
    if (*nd >= maxn)
    4f7c:	04ca5063          	bge	s4,a2,4fbc <t3_add_box+0x1a8>
    out[i].area = (uint16_t)(((x1 - x0) * (y1 - y0)) / 256);
    4f80:	40e808b3          	sub	a7,a6,a4
    4f84:	40d78633          	sub	a2,a5,a3
    4f88:	03160633          	mul	a2,a2,a7
    out[i].x0 = (uint16_t)x0;
    4f8c:	002a1893          	slli	a7,s4,0x2
    4f90:	014888b3          	add	a7,a7,s4
    4f94:	00189893          	slli	a7,a7,0x1
    4f98:	01150533          	add	a0,a0,a7
    4f9c:	00d51023          	sh	a3,0(a0)
    out[i].y0 = (uint16_t)y0;
    4fa0:	00e51123          	sh	a4,2(a0)
    out[i].x1 = (uint16_t)x1;
    4fa4:	00f51223          	sh	a5,4(a0)
    out[i].y1 = (uint16_t)y1;
    4fa8:	01051323          	sh	a6,6(a0)
    (*nd)++;
    4fac:	001a0a13          	addi	s4,s4,1
    out[i].area = (uint16_t)(((x1 - x0) * (y1 - y0)) / 256);
    4fb0:	40865613          	srai	a2,a2,0x8
    4fb4:	00c51423          	sh	a2,8(a0)
    (*nd)++;
    4fb8:	0145a023          	sw	s4,0(a1)
    add_box(out, nd, maxn, x0, y0, x1, y1, 0);
}
    4fbc:	03c12403          	lw	s0,60(sp)
    4fc0:	03812483          	lw	s1,56(sp)
    4fc4:	03412903          	lw	s2,52(sp)
    4fc8:	03012983          	lw	s3,48(sp)
    4fcc:	02c12a03          	lw	s4,44(sp)
    4fd0:	02812a83          	lw	s5,40(sp)
    4fd4:	02412b03          	lw	s6,36(sp)
    4fd8:	02012b83          	lw	s7,32(sp)
    4fdc:	01c12c03          	lw	s8,28(sp)
    4fe0:	01812c83          	lw	s9,24(sp)
    4fe4:	01412d03          	lw	s10,20(sp)
    4fe8:	01012d83          	lw	s11,16(sp)
    4fec:	04010113          	addi	sp,sp,64
    4ff0:	00008067          	ret
    4ff4:	00008067          	ret

00004ff8 <t3_add_box_force>:
    if (x1 <= x0 || y1 <= y0)
    4ff8:	04f6d663          	bge	a3,a5,5044 <t3_add_box_force+0x4c>
    4ffc:	05075463          	bge	a4,a6,5044 <t3_add_box_force+0x4c>
    if (*nd >= maxn)
    5000:	0005a883          	lw	a7,0(a1)
    5004:	04c8d063          	bge	a7,a2,5044 <t3_add_box_force+0x4c>
    out[i].area = (uint16_t)(((x1 - x0) * (y1 - y0)) / 256);
    5008:	40e80333          	sub	t1,a6,a4
    500c:	40d78633          	sub	a2,a5,a3
    5010:	02660633          	mul	a2,a2,t1
    out[i].x0 = (uint16_t)x0;
    5014:	00289313          	slli	t1,a7,0x2
    5018:	01130333          	add	t1,t1,a7
    501c:	00131313          	slli	t1,t1,0x1
    5020:	00650533          	add	a0,a0,t1
    5024:	00d51023          	sh	a3,0(a0)
    out[i].y0 = (uint16_t)y0;
    5028:	00e51123          	sh	a4,2(a0)
    out[i].x1 = (uint16_t)x1;
    502c:	00f51223          	sh	a5,4(a0)
    out[i].y1 = (uint16_t)y1;
    5030:	01051323          	sh	a6,6(a0)
    (*nd)++;
    5034:	00188893          	addi	a7,a7,1
    out[i].area = (uint16_t)(((x1 - x0) * (y1 - y0)) / 256);
    5038:	40865613          	srai	a2,a2,0x8
    503c:	00c51423          	sh	a2,8(a0)
    (*nd)++;
    5040:	0115a023          	sw	a7,0(a1)

void t3_add_box_force(t3_det_t *out, int *nd, int maxn, int x0, int y0, int x1, int y1)
{
    add_box(out, nd, maxn, x0, y0, x1, y1, 1);
}
    5044:	00008067          	ret

00005048 <t3_is_extra>:

int t3_is_extra(const t3_det_t *pri, const t3_det_t *b)
{
    5048:	00050793          	mv	a5,a0
    uint32_t iou, inter, ba;
    uint16_t bw, bh, ix0, iy0, ix1, iy1;
    if (!pri || !b)
    504c:	0e050e63          	beqz	a0,5148 <t3_is_extra+0x100>
    5050:	0e058c63          	beqz	a1,5148 <t3_is_extra+0x100>
        return 0;
    bw = (b->x1 > b->x0) ? (uint16_t)(b->x1 - b->x0) : 0;
    5054:	0045d703          	lhu	a4,4(a1)
    5058:	0005d683          	lhu	a3,0(a1)
        return 0;
    505c:	00000513          	li	a0,0
    bw = (b->x1 > b->x0) ? (uint16_t)(b->x1 - b->x0) : 0;
    5060:	0ee6f663          	bgeu	a3,a4,514c <t3_is_extra+0x104>
    bh = (b->y1 > b->y0) ? (uint16_t)(b->y1 - b->y0) : 0;
    5064:	0065d803          	lhu	a6,6(a1)
    5068:	0025d883          	lhu	a7,2(a1)
    bw = (b->x1 > b->x0) ? (uint16_t)(b->x1 - b->x0) : 0;
    506c:	40d70333          	sub	t1,a4,a3
    5070:	01031f13          	slli	t5,t1,0x10
    5074:	010f5f13          	srli	t5,t5,0x10
    bh = (b->y1 > b->y0) ? (uint16_t)(b->y1 - b->y0) : 0;
    5078:	0d08fa63          	bgeu	a7,a6,514c <t3_is_extra+0x104>
    if (b->area < MIN_AREA || bw < 80 || bh < 40)
    507c:	0085d583          	lhu	a1,8(a1)
    5080:	02700613          	li	a2,39
    5084:	0cb67463          	bgeu	a2,a1,514c <t3_is_extra+0x104>
    5088:	04f00593          	li	a1,79
    508c:	0de5f063          	bgeu	a1,t5,514c <t3_is_extra+0x104>
    bh = (b->y1 > b->y0) ? (uint16_t)(b->y1 - b->y0) : 0;
    5090:	41180fb3          	sub	t6,a6,a7
    5094:	010f9293          	slli	t0,t6,0x10
    5098:	0102d293          	srli	t0,t0,0x10
    if (b->area < MIN_AREA || bw < 80 || bh < 40)
    509c:	0a567863          	bgeu	a2,t0,514c <t3_is_extra+0x104>
        return 0;
    ix0 = pri->x0 > b->x0 ? pri->x0 : b->x0;
    50a0:	0007de83          	lhu	t4,0(a5)
    50a4:	00068593          	mv	a1,a3
    50a8:	01d6f463          	bgeu	a3,t4,50b0 <t3_is_extra+0x68>
    50ac:	000e8593          	mv	a1,t4
    iy0 = pri->y0 > b->y0 ? pri->y0 : b->y0;
    50b0:	0027de03          	lhu	t3,2(a5)
    ix0 = pri->x0 > b->x0 ? pri->x0 : b->x0;
    50b4:	01059593          	slli	a1,a1,0x10
    50b8:	0105d593          	srli	a1,a1,0x10
    iy0 = pri->y0 > b->y0 ? pri->y0 : b->y0;
    50bc:	00088693          	mv	a3,a7
    50c0:	01c8f463          	bgeu	a7,t3,50c8 <t3_is_extra+0x80>
    50c4:	000e0693          	mv	a3,t3
    ix1 = pri->x1 < b->x1 ? pri->x1 : b->x1;
    50c8:	0047d603          	lhu	a2,4(a5)
    iy0 = pri->y0 > b->y0 ? pri->y0 : b->y0;
    50cc:	01069513          	slli	a0,a3,0x10
    50d0:	01055513          	srli	a0,a0,0x10
    ix1 = pri->x1 < b->x1 ? pri->x1 : b->x1;
    50d4:	00070693          	mv	a3,a4
    50d8:	00e67463          	bgeu	a2,a4,50e0 <t3_is_extra+0x98>
    50dc:	00060693          	mv	a3,a2
    iy1 = pri->y1 < b->y1 ? pri->y1 : b->y1;
    50e0:	0067d883          	lhu	a7,6(a5)
    ix1 = pri->x1 < b->x1 ? pri->x1 : b->x1;
    50e4:	01069693          	slli	a3,a3,0x10
    50e8:	0106d693          	srli	a3,a3,0x10
    iy1 = pri->y1 < b->y1 ? pri->y1 : b->y1;
    50ec:	00080713          	mv	a4,a6
    50f0:	0108f463          	bgeu	a7,a6,50f8 <t3_is_extra+0xb0>
    50f4:	00088713          	mv	a4,a7
    50f8:	01071713          	slli	a4,a4,0x10
    50fc:	01075713          	srli	a4,a4,0x10
    inter = 0;
    if (ix1 > ix0 && iy1 > iy0)
    5100:	04d5e863          	bltu	a1,a3,5150 <t3_is_extra+0x108>
    uint32_t ih = (iy1 > iy0) ? (uint32_t)(iy1 - iy0) : 0;
    5104:	00000693          	li	a3,0
    5108:	00e57663          	bgeu	a0,a4,5114 <t3_is_extra+0xcc>
    510c:	40a70733          	sub	a4,a4,a0
    5110:	02d706b3          	mul	a3,a4,a3
    uint32_t a = (uint32_t)(ax1 - ax0) * (uint32_t)(ay1 - ay0);
    5114:	41d60633          	sub	a2,a2,t4
    5118:	41c887b3          	sub	a5,a7,t3
    if (uni == 0)
    511c:	00100513          	li	a0,1
    uint32_t a = (uint32_t)(ax1 - ax0) * (uint32_t)(ay1 - ay0);
    5120:	02f607b3          	mul	a5,a2,a5
    uint32_t b = (uint32_t)(bx1 - bx0) * (uint32_t)(by1 - by0);
    5124:	03f30333          	mul	t1,t1,t6
    uint32_t uni = a + b - inter;
    5128:	006787b3          	add	a5,a5,t1
    512c:	40d787b3          	sub	a5,a5,a3
    if (uni == 0)
    5130:	00078e63          	beqz	a5,514c <t3_is_extra+0x104>
    return (inter * 100) / uni;
    5134:	06400513          	li	a0,100
    5138:	02a68533          	mul	a0,a3,a0
    513c:	02f55533          	divu	a0,a0,a5
    5140:	01953513          	sltiu	a0,a0,25
    5144:	00008067          	ret
        return 0;
    5148:	00000513          	li	a0,0
    ba = (uint32_t)bw * (uint32_t)bh;
    if (ba && (inter * 100 / ba) >= 40)
        return 0;
    iou = box_iou(pri->x0, pri->y0, pri->x1, pri->y1, b->x0, b->y0, b->x1, b->y1);
    return (iou < 25) ? 1 : 0;
}
    514c:	00008067          	ret
    5150:	40b686b3          	sub	a3,a3,a1
    if (ix1 > ix0 && iy1 > iy0)
    5154:	02e57663          	bgeu	a0,a4,5180 <t3_is_extra+0x138>
        inter = (uint32_t)(ix1 - ix0) * (uint32_t)(iy1 - iy0);
    5158:	40a70733          	sub	a4,a4,a0
    515c:	02d707b3          	mul	a5,a4,a3
    if (ba && (inter * 100 / ba) >= 40)
    5160:	06400813          	li	a6,100
    5164:	02700593          	li	a1,39
        return 0;
    5168:	00000513          	li	a0,0
    if (ba && (inter * 100 / ba) >= 40)
    516c:	030787b3          	mul	a5,a5,a6
    ba = (uint32_t)bw * (uint32_t)bh;
    5170:	025f0f33          	mul	t5,t5,t0
    if (ba && (inter * 100 / ba) >= 40)
    5174:	03e7df33          	divu	t5,a5,t5
    5178:	f9e5fce3          	bgeu	a1,t5,5110 <t3_is_extra+0xc8>
}
    517c:	00008067          	ret
    5180:	00000693          	li	a3,0
    5184:	f91ff06f          	j	5114 <t3_is_extra+0xcc>

00005188 <t3_update>:
            return i;
    return -1;
}

int t3_update(const t3_det_t *dets, int nd, t3_trk_t *dst)
{
    5188:	fb010113          	addi	sp,sp,-80
    518c:	04812623          	sw	s0,76(sp)
    5190:	04912423          	sw	s1,72(sp)
    5194:	05212223          	sw	s2,68(sp)
    5198:	05312023          	sw	s3,64(sp)
    519c:	03412e23          	sw	s4,60(sp)
    51a0:	03512c23          	sw	s5,56(sp)
    51a4:	03612a23          	sw	s6,52(sp)
    51a8:	03712823          	sw	s7,48(sp)
    51ac:	03812623          	sw	s8,44(sp)
    51b0:	03912423          	sw	s9,40(sp)
    51b4:	03a12223          	sw	s10,36(sp)
    51b8:	03b12023          	sw	s11,32(sp)
    uint8_t used_t[T3_MAX_TRK];
    uint8_t used_d[T3_MAX_TRK];
    int i, j, nout = 0;
    for (i = 0; i < T3_MAX_TRK; i++) {
        used_t[i] = 0;
    51bc:	00012c23          	sw	zero,24(sp)
        used_d[i] = 0;
    51c0:	00012e23          	sw	zero,28(sp)
{
    51c4:	00c12623          	sw	a2,12(sp)
    51c8:	000527b7          	lui	a5,0x52
    }
    for (i = 0; i < nd && i < T3_MAX_TRK; i++) {
    51cc:	6ab05263          	blez	a1,5870 <t3_update+0x6e8>
    51d0:	00050e93          	mv	t4,a0
    51d4:	00000b13          	li	s6,0
    51d8:	18078793          	addi	a5,a5,384 # 52180 <s_trk>
    51dc:	01810893          	addi	a7,sp,24
        int best = -1;
    51e0:	fff00d13          	li	s10,-1
    return (inter * 100) / uni;
    51e4:	06400c93          	li	s9,100
        uint32_t best_iou = 0;
        for (j = 0; j < T3_MAX_TRK; j++) {
    51e8:	00400a13          	li	s4,4
            if (iou > best_iou) {
                best_iou = iou;
                best = j;
            }
        }
        if (best >= 0 && best_iou >= 12) {
    51ec:	00b00d93          	li	s11,11
    51f0:	00078693          	mv	a3,a5
        uint32_t best_iou = 0;
    51f4:	00000f93          	li	t6,0
        int best = -1;
    51f8:	fff00f13          	li	t5,-1
        for (j = 0; j < T3_MAX_TRK; j++) {
    51fc:	00000613          	li	a2,0
            if (!s_trk[j].used || used_t[j])
    5200:	0026c703          	lbu	a4,2(a3)
    5204:	0c070a63          	beqz	a4,52d8 <t3_update+0x150>
    5208:	00c88733          	add	a4,a7,a2
    520c:	00074703          	lbu	a4,0(a4)
    5210:	0c071463          	bnez	a4,52d8 <t3_update+0x150>
            iou = box_iou(dets[i].x0, dets[i].y0, dets[i].x1, dets[i].y1,
    5214:	000edb83          	lhu	s7,0(t4)
    5218:	0046da83          	lhu	s5,4(a3)
    521c:	002ed903          	lhu	s2,2(t4)
    5220:	004ed703          	lhu	a4,4(t4)
    5224:	006ede03          	lhu	t3,6(t4)
    5228:	0066d983          	lhu	s3,6(a3)
    522c:	0086d803          	lhu	a6,8(a3)
    5230:	00a6d383          	lhu	t2,10(a3)
    uint16_t ix0 = ax0 > bx0 ? ax0 : bx0;
    5234:	000b8493          	mv	s1,s7
    5238:	015bf463          	bgeu	s7,s5,5240 <t3_update+0xb8>
    523c:	000a8493          	mv	s1,s5
    5240:	01049493          	slli	s1,s1,0x10
    5244:	0104d493          	srli	s1,s1,0x10
    uint16_t iy0 = ay0 > by0 ? ay0 : by0;
    5248:	00090413          	mv	s0,s2
    524c:	01397463          	bgeu	s2,s3,5254 <t3_update+0xcc>
    5250:	00098413          	mv	s0,s3
    5254:	01041413          	slli	s0,s0,0x10
    5258:	01045413          	srli	s0,s0,0x10
    uint16_t ix1 = ax1 < bx1 ? ax1 : bx1;
    525c:	00070313          	mv	t1,a4
    5260:	00e87463          	bgeu	a6,a4,5268 <t3_update+0xe0>
    5264:	00080313          	mv	t1,a6
    5268:	01031313          	slli	t1,t1,0x10
    526c:	01035313          	srli	t1,t1,0x10
    uint16_t iy1 = ay1 < by1 ? ay1 : by1;
    5270:	000e0293          	mv	t0,t3
    5274:	01c3f463          	bgeu	t2,t3,527c <t3_update+0xf4>
    5278:	00038293          	mv	t0,t2
    527c:	01029293          	slli	t0,t0,0x10
    5280:	0102d293          	srli	t0,t0,0x10
    uint32_t iw = (ix1 > ix0) ? (uint32_t)(ix1 - ix0) : 0;
    5284:	00000c13          	li	s8,0
    5288:	0064f463          	bgeu	s1,t1,5290 <t3_update+0x108>
    528c:	40930c33          	sub	s8,t1,s1
    uint32_t ih = (iy1 > iy0) ? (uint32_t)(iy1 - iy0) : 0;
    5290:	00000313          	li	t1,0
    5294:	00547663          	bgeu	s0,t0,52a0 <t3_update+0x118>
    5298:	40828333          	sub	t1,t0,s0
    529c:	03830333          	mul	t1,t1,s8
    uint32_t a = (uint32_t)(ax1 - ax0) * (uint32_t)(ay1 - ay0);
    52a0:	41770733          	sub	a4,a4,s7
    52a4:	412e0e33          	sub	t3,t3,s2
    uint32_t b = (uint32_t)(bx1 - bx0) * (uint32_t)(by1 - by0);
    52a8:	41580833          	sub	a6,a6,s5
    52ac:	413383b3          	sub	t2,t2,s3
    uint32_t a = (uint32_t)(ax1 - ax0) * (uint32_t)(ay1 - ay0);
    52b0:	03c70733          	mul	a4,a4,t3
    uint32_t b = (uint32_t)(bx1 - bx0) * (uint32_t)(by1 - by0);
    52b4:	02780833          	mul	a6,a6,t2
    uint32_t uni = a + b - inter;
    52b8:	01070733          	add	a4,a4,a6
    52bc:	40670733          	sub	a4,a4,t1
    if (uni == 0)
    52c0:	00070c63          	beqz	a4,52d8 <t3_update+0x150>
    return (inter * 100) / uni;
    52c4:	03930333          	mul	t1,t1,s9
    52c8:	02e35733          	divu	a4,t1,a4
            if (iou > best_iou) {
    52cc:	00eff663          	bgeu	t6,a4,52d8 <t3_update+0x150>
    52d0:	00070f93          	mv	t6,a4
    52d4:	00060f13          	mv	t5,a2
        for (j = 0; j < T3_MAX_TRK; j++) {
    52d8:	00160613          	addi	a2,a2,1
    52dc:	01868693          	addi	a3,a3,24
    52e0:	f34610e3          	bne	a2,s4,5200 <t3_update+0x78>
        if (best >= 0 && best_iou >= 12) {
    52e4:	11af0c63          	beq	t5,s10,53fc <t3_update+0x274>
    52e8:	11fdfa63          	bgeu	s11,t6,53fc <t3_update+0x274>
            t3_trk_t *t = &s_trk[best];
            int16_t cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    52ec:	000ed283          	lhu	t0,0(t4)
    52f0:	004ede03          	lhu	t3,4(t4)
            int16_t cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    52f4:	002edf83          	lhu	t6,2(t4)
    52f8:	006ed303          	lhu	t1,6(t4)
            t->vx = (int16_t)(cx - t->cx);
    52fc:	001f1713          	slli	a4,t5,0x1
    5300:	01e706b3          	add	a3,a4,t5
    5304:	00369693          	slli	a3,a3,0x3
    5308:	00d786b3          	add	a3,a5,a3
            int16_t cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    530c:	01c28933          	add	s2,t0,t3
            int16_t cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5310:	006f84b3          	add	s1,t6,t1
            t->vx = (int16_t)(cx - t->cx);
    5314:	00c6d403          	lhu	s0,12(a3)
            t->vy = (int16_t)(cy - t->cy);
    5318:	00e6d383          	lhu	t2,14(a3)
            int16_t cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    531c:	40195913          	srai	s2,s2,0x1
            int16_t cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5320:	4014d493          	srai	s1,s1,0x1
            t->vx = (int16_t)(cx - t->cx);
    5324:	01091813          	slli	a6,s2,0x10
            t->vy = (int16_t)(cy - t->cy);
    5328:	01049613          	slli	a2,s1,0x10
            t->vx = (int16_t)(cx - t->cx);
    532c:	01085813          	srli	a6,a6,0x10
            t->vy = (int16_t)(cy - t->cy);
    5330:	01065613          	srli	a2,a2,0x10
            t->vx = (int16_t)(cx - t->cx);
    5334:	40880433          	sub	s0,a6,s0
            t->vy = (int16_t)(cy - t->cy);
    5338:	407603b3          	sub	t2,a2,t2
            t->vx = (int16_t)(cx - t->cx);
    533c:	01041413          	slli	s0,s0,0x10
            t->vy = (int16_t)(cy - t->cy);
    5340:	01039393          	slli	t2,t2,0x10
            t->vx = (int16_t)(cx - t->cx);
    5344:	01045413          	srli	s0,s0,0x10
            t->vy = (int16_t)(cy - t->cy);
    5348:	0103d393          	srli	t2,t2,0x10
            t->cx = cx;
            t->cy = cy;
            t->px = (int16_t)(cx + t->vx);
    534c:	00880833          	add	a6,a6,s0
            t->py = (int16_t)(cy + t->vy);
    5350:	00760633          	add	a2,a2,t2
            t->px = (int16_t)(cx + t->vx);
    5354:	01081813          	slli	a6,a6,0x10
            t->py = (int16_t)(cy + t->vy);
    5358:	01061613          	slli	a2,a2,0x10
            t->px = (int16_t)(cx + t->vx);
    535c:	41085813          	srai	a6,a6,0x10
            t->py = (int16_t)(cy + t->vy);
    5360:	41065613          	srai	a2,a2,0x10
            t->vx = (int16_t)(cx - t->cx);
    5364:	00869823          	sh	s0,16(a3)
            t->vy = (int16_t)(cy - t->cy);
    5368:	00769923          	sh	t2,18(a3)
            int16_t cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    536c:	01269623          	sh	s2,12(a3)
            int16_t cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5370:	00969723          	sh	s1,14(a3)
            t->px = (int16_t)(cx + t->vx);
    5374:	01069a23          	sh	a6,20(a3)
            t->py = (int16_t)(cy + t->vy);
    5378:	00c69b23          	sh	a2,22(a3)
            if (t->px < 0) t->px = 0;
    537c:	4a084c63          	bltz	a6,5834 <t3_update+0x6ac>
            if (t->py < 0) t->py = 0;
    5380:	4a064e63          	bltz	a2,583c <t3_update+0x6b4>
            if (t->px > 1919) t->px = 1919;
    5384:	77f00693          	li	a3,1919
    5388:	0106de63          	bge	a3,a6,53a4 <t3_update+0x21c>
    538c:	01e706b3          	add	a3,a4,t5
    5390:	00369693          	slli	a3,a3,0x3
    5394:	00d786b3          	add	a3,a5,a3
    5398:	77f00613          	li	a2,1919
    539c:	00c69a23          	sh	a2,20(a3)
    53a0:	01669603          	lh	a2,22(a3)
            if (t->py > 1079) t->py = 1079;
    53a4:	43700693          	li	a3,1079
    53a8:	00c6dc63          	bge	a3,a2,53c0 <t3_update+0x238>
    53ac:	01e706b3          	add	a3,a4,t5
    53b0:	00369693          	slli	a3,a3,0x3
    53b4:	00d786b3          	add	a3,a5,a3
    53b8:	43700613          	li	a2,1079
    53bc:	00c69b23          	sh	a2,22(a3)
            t->x0 = dets[i].x0;
    53c0:	01e70733          	add	a4,a4,t5
    53c4:	00371713          	slli	a4,a4,0x3
    53c8:	00e78733          	add	a4,a5,a4
            t->y0 = dets[i].y0;
            t->x1 = dets[i].x1;
            t->y1 = dets[i].y1;
            t->age = 0;
            used_t[best] = 1;
    53cc:	02010693          	addi	a3,sp,32
            t->x0 = dets[i].x0;
    53d0:	00571223          	sh	t0,4(a4)
            t->y0 = dets[i].y0;
    53d4:	01f71323          	sh	t6,6(a4)
            t->x1 = dets[i].x1;
    53d8:	01c71423          	sh	t3,8(a4)
            t->y1 = dets[i].y1;
    53dc:	00671523          	sh	t1,10(a4)
            t->age = 0;
    53e0:	000701a3          	sb	zero,3(a4)
            used_d[i] = 1;
    53e4:	01c10713          	addi	a4,sp,28
            used_t[best] = 1;
    53e8:	01e68f33          	add	t5,a3,t5
            used_d[i] = 1;
    53ec:	01670733          	add	a4,a4,s6
            used_t[best] = 1;
    53f0:	00100693          	li	a3,1
    53f4:	fedf0c23          	sb	a3,-8(t5)
            used_d[i] = 1;
    53f8:	00d70023          	sb	a3,0(a4)
    for (i = 0; i < nd && i < T3_MAX_TRK; i++) {
    53fc:	001b0b13          	addi	s6,s6,1
    5400:	01658663          	beq	a1,s6,540c <t3_update+0x284>
    5404:	00ae8e93          	addi	t4,t4,10
    5408:	df4b14e3          	bne	s6,s4,51f0 <t3_update+0x68>
    540c:	01c14b03          	lbu	s6,28(sp)
        }
    }
    /* Two FPGA boxes: do not steal the first TID by 300 px distance. */
    for (i = 0; nd < 2 && i < nd && i < T3_MAX_TRK; i++) {
        int best = -1;
        int best_d2 = 300 * 300;
    5410:	00016c37          	lui	s8,0x16
        int16_t cx, cy;
        if (used_d[i])
            continue;
        cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
        cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
        for (j = 0; j < T3_MAX_TRK; j++) {
    5414:	00000c93          	li	s9,0
    5418:	00000713          	li	a4,0
    for (i = 0; nd < 2 && i < nd && i < T3_MAX_TRK; i++) {
    541c:	00100b93          	li	s7,1
        int best_d2 = 300 * 300;
    5420:	f90c0c13          	addi	s8,s8,-112 # 15f90 <pd_w26+0x94d0>
        int best = -1;
    5424:	fff00d13          	li	s10,-1
        for (j = 0; j < T3_MAX_TRK; j++) {
    5428:	00400293          	li	t0,4
            t->px = (int16_t)(cx + t->vx);
            t->py = (int16_t)(cy + t->vy);
            if (t->px < 0) t->px = 0;
            if (t->py < 0) t->py = 0;
            if (t->px > 1919) t->px = 1919;
            if (t->py > 1079) t->py = 1079;
    542c:	43700d93          	li	s11,1079
    for (i = 0; nd < 2 && i < nd && i < T3_MAX_TRK; i++) {
    5430:	00bbc663          	blt	s7,a1,543c <t3_update+0x2b4>
    5434:	42b75463          	bge	a4,a1,585c <t3_update+0x6d4>
        if (used_d[i])
    5438:	0e0b0663          	beqz	s6,5524 <t3_update+0x39c>
    543c:	000c8463          	beqz	s9,5444 <t3_update+0x2bc>
    5440:	01610e23          	sb	s6,28(sp)
    5444:	8c41de03          	lhu	t3,-1852(gp) # 46c7c <s_next_tid>
    5448:	01b10713          	addi	a4,sp,27
    544c:	01c10613          	addi	a2,sp,28
    5450:	02010f13          	addi	t5,sp,32
    5454:	00b705b3          	add	a1,a4,a1
        for (j = 0; j < T3_MAX_TRK; j++) {
    5458:	00000413          	li	s0,0
    for (i = 0; i < T3_MAX_TRK; i++)
    545c:	00400313          	li	t1,4
            continue;
        s = alloc_slot();
        if (s < 0)
            continue;
        t = &s_trk[s];
        t->used = 1;
    5460:	00100f93          	li	t6,1
        if (used_d[i])
    5464:	00064703          	lbu	a4,0(a2)
    5468:	24070c63          	beqz	a4,56c0 <t3_update+0x538>
    for (i = 0; i < nd && i < T3_MAX_TRK; i++) {
    546c:	00b60863          	beq	a2,a1,547c <t3_update+0x2f4>
    5470:	00160613          	addi	a2,a2,1
    5474:	00a50513          	addi	a0,a0,10
    5478:	ffe616e3          	bne	a2,t5,5464 <t3_update+0x2dc>
    547c:	00040463          	beqz	s0,5484 <t3_update+0x2fc>
    5480:	8dc19223          	sh	t3,-1852(gp) # 46c7c <s_next_tid>
            continue;
        if (!used_t[j]) {
            s_trk[j].age++;
            s_trk[j].px = (int16_t)(s_trk[j].cx + s_trk[j].vx);
            s_trk[j].py = (int16_t)(s_trk[j].cy + s_trk[j].vy);
            if (s_trk[j].age >= MISS_MAX)
    5484:	00c12f03          	lw	t5,12(sp)
    5488:	06078593          	addi	a1,a5,96
        t->py = t->cy;
    548c:	00000513          	li	a0,0
                s_trk[j].used = 0;
        }
        if (s_trk[j].used && nout < T3_MAX_TRK)
    5490:	00300813          	li	a6,3
            if (s_trk[j].age >= MISS_MAX)
    5494:	00100e93          	li	t4,1
        if (!s_trk[j].used)
    5498:	0027c703          	lbu	a4,2(a5)
    549c:	04070263          	beqz	a4,54e0 <t3_update+0x358>
        if (!used_t[j]) {
    54a0:	0008c703          	lbu	a4,0(a7)
    54a4:	2c071c63          	bnez	a4,577c <t3_update+0x5f4>
            s_trk[j].age++;
    54a8:	0037c703          	lbu	a4,3(a5)
            s_trk[j].px = (int16_t)(s_trk[j].cx + s_trk[j].vx);
    54ac:	00c7d603          	lhu	a2,12(a5)
    54b0:	0107de03          	lhu	t3,16(a5)
            s_trk[j].py = (int16_t)(s_trk[j].cy + s_trk[j].vy);
    54b4:	00e7d683          	lhu	a3,14(a5)
    54b8:	0127d303          	lhu	t1,18(a5)
            s_trk[j].age++;
    54bc:	00170713          	addi	a4,a4,1
    54c0:	0ff77713          	andi	a4,a4,255
            s_trk[j].px = (int16_t)(s_trk[j].cx + s_trk[j].vx);
    54c4:	01c60633          	add	a2,a2,t3
            s_trk[j].py = (int16_t)(s_trk[j].cy + s_trk[j].vy);
    54c8:	006686b3          	add	a3,a3,t1
            s_trk[j].age++;
    54cc:	00e781a3          	sb	a4,3(a5)
            s_trk[j].px = (int16_t)(s_trk[j].cx + s_trk[j].vx);
    54d0:	00c79a23          	sh	a2,20(a5)
            s_trk[j].py = (int16_t)(s_trk[j].cy + s_trk[j].vy);
    54d4:	00d79b23          	sh	a3,22(a5)
            if (s_trk[j].age >= MISS_MAX)
    54d8:	2aeef263          	bgeu	t4,a4,577c <t3_update+0x5f4>
                s_trk[j].used = 0;
    54dc:	00078123          	sb	zero,2(a5)
        if (s_trk[j].used && nout < T3_MAX_TRK)
    54e0:	01878793          	addi	a5,a5,24
    54e4:	00188893          	addi	a7,a7,1
    for (j = 0; j < T3_MAX_TRK; j++) {
    54e8:	faf598e3          	bne	a1,a5,5498 <t3_update+0x310>
            dst[nout++] = s_trk[j];
    }
    (void)IOU_NUM;
    (void)IOU_DEN;
    return nout;
}
    54ec:	04c12403          	lw	s0,76(sp)
    54f0:	04812483          	lw	s1,72(sp)
    54f4:	04412903          	lw	s2,68(sp)
    54f8:	04012983          	lw	s3,64(sp)
    54fc:	03c12a03          	lw	s4,60(sp)
    5500:	03812a83          	lw	s5,56(sp)
    5504:	03412b03          	lw	s6,52(sp)
    5508:	03012b83          	lw	s7,48(sp)
    550c:	02c12c03          	lw	s8,44(sp)
    5510:	02812c83          	lw	s9,40(sp)
    5514:	02412d03          	lw	s10,36(sp)
    5518:	02012d83          	lw	s11,32(sp)
    551c:	05010113          	addi	sp,sp,80
    5520:	00008067          	ret
        cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    5524:	00055903          	lhu	s2,0(a0)
    5528:	00455983          	lhu	s3,4(a0)
        cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    552c:	00255a03          	lhu	s4,2(a0)
    5530:	00655a83          	lhu	s5,6(a0)
    5534:	00078693          	mv	a3,a5
        cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    5538:	01390e33          	add	t3,s2,s3
        cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    553c:	015a0333          	add	t1,s4,s5
            if (!s_trk[j].used || used_t[j])
    5540:	0026c603          	lbu	a2,2(a3)
        cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    5544:	401e5e13          	srai	t3,t3,0x1
        cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5548:	40135313          	srai	t1,t1,0x1
        for (j = 0; j < T3_MAX_TRK; j++) {
    554c:	00000e93          	li	t4,0
        cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    5550:	010e1413          	slli	s0,t3,0x10
        cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5554:	01031493          	slli	s1,t1,0x10
    5558:	001e8713          	addi	a4,t4,1
        cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    555c:	41045413          	srai	s0,s0,0x10
        cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5560:	4104d493          	srai	s1,s1,0x10
        int best_d2 = 300 * 300;
    5564:	000c0393          	mv	t2,s8
        int best = -1;
    5568:	fff00f93          	li	t6,-1
            if (!s_trk[j].used || used_t[j])
    556c:	00e88833          	add	a6,a7,a4
    5570:	04060863          	beqz	a2,55c0 <t3_update+0x438>
    5574:	fff84603          	lbu	a2,-1(a6)
    5578:	04061463          	bnez	a2,55c0 <t3_update+0x438>
            dx = (int)cx - (int)s_trk[j].cx;
    557c:	00c69f03          	lh	t5,12(a3)
            dy = (int)cy - (int)s_trk[j].cy;
    5580:	00e69803          	lh	a6,14(a3)
            dx = (int)cx - (int)s_trk[j].cx;
    5584:	41e40633          	sub	a2,s0,t5
            dy = (int)cy - (int)s_trk[j].cy;
    5588:	41048833          	sub	a6,s1,a6
            d2 = dx * dx + dy * dy;
    558c:	02c60633          	mul	a2,a2,a2
    5590:	03080833          	mul	a6,a6,a6
    5594:	01060833          	add	a6,a2,a6
            if (d2 < best_d2) {
    5598:	02785463          	bge	a6,t2,55c0 <t3_update+0x438>
        for (j = 0; j < T3_MAX_TRK; j++) {
    559c:	28570263          	beq	a4,t0,5820 <t3_update+0x698>
    55a0:	000e8f93          	mv	t6,t4
    55a4:	00080393          	mv	t2,a6
    55a8:	01868693          	addi	a3,a3,24
            if (!s_trk[j].used || used_t[j])
    55ac:	0026c603          	lbu	a2,2(a3)
        for (j = 0; j < T3_MAX_TRK; j++) {
    55b0:	00070e93          	mv	t4,a4
            dx = (int)cx - (int)s_trk[j].cx;
    55b4:	001e8713          	addi	a4,t4,1
            if (!s_trk[j].used || used_t[j])
    55b8:	00e88833          	add	a6,a7,a4
    55bc:	fa061ce3          	bnez	a2,5574 <t3_update+0x3ec>
        for (j = 0; j < T3_MAX_TRK; j++) {
    55c0:	fe5714e3          	bne	a4,t0,55a8 <t3_update+0x420>
        if (best >= 0) {
    55c4:	00100713          	li	a4,1
    55c8:	e7af84e3          	beq	t6,s10,5430 <t3_update+0x2a8>
    55cc:	001f9713          	slli	a4,t6,0x1
    55d0:	01f706b3          	add	a3,a4,t6
    55d4:	00369693          	slli	a3,a3,0x3
    55d8:	00d786b3          	add	a3,a5,a3
    55dc:	00c69f03          	lh	t5,12(a3)
            t->vx = (int16_t)(cx - t->cx);
    55e0:	01f706b3          	add	a3,a4,t6
    55e4:	00369693          	slli	a3,a3,0x3
    55e8:	00d786b3          	add	a3,a5,a3
            t->vy = (int16_t)(cy - t->cy);
    55ec:	00e6d603          	lhu	a2,14(a3)
            t->vx = (int16_t)(cx - t->cx);
    55f0:	010e1e13          	slli	t3,t3,0x10
            t->vy = (int16_t)(cy - t->cy);
    55f4:	01031313          	slli	t1,t1,0x10
            t->vx = (int16_t)(cx - t->cx);
    55f8:	010e5e13          	srli	t3,t3,0x10
            t->vy = (int16_t)(cy - t->cy);
    55fc:	01035313          	srli	t1,t1,0x10
            t->vx = (int16_t)(cx - t->cx);
    5600:	41ee0f33          	sub	t5,t3,t5
            t->vy = (int16_t)(cy - t->cy);
    5604:	40c30633          	sub	a2,t1,a2
            t->vx = (int16_t)(cx - t->cx);
    5608:	010f1f13          	slli	t5,t5,0x10
            t->vy = (int16_t)(cy - t->cy);
    560c:	01061613          	slli	a2,a2,0x10
            t->vx = (int16_t)(cx - t->cx);
    5610:	010f5f13          	srli	t5,t5,0x10
            t->vy = (int16_t)(cy - t->cy);
    5614:	01065613          	srli	a2,a2,0x10
            t->px = (int16_t)(cx + t->vx);
    5618:	01ee0e33          	add	t3,t3,t5
            t->py = (int16_t)(cy + t->vy);
    561c:	00c30333          	add	t1,t1,a2
            t->px = (int16_t)(cx + t->vx);
    5620:	010e1e13          	slli	t3,t3,0x10
            t->py = (int16_t)(cy + t->vy);
    5624:	01031313          	slli	t1,t1,0x10
            t->px = (int16_t)(cx + t->vx);
    5628:	410e5e13          	srai	t3,t3,0x10
            t->py = (int16_t)(cy + t->vy);
    562c:	41035313          	srai	t1,t1,0x10
            t->vx = (int16_t)(cx - t->cx);
    5630:	01e69823          	sh	t5,16(a3)
            t->vy = (int16_t)(cy - t->cy);
    5634:	00c69923          	sh	a2,18(a3)
            t->cx = cx;
    5638:	00869623          	sh	s0,12(a3)
            t->cy = cy;
    563c:	00969723          	sh	s1,14(a3)
            t->px = (int16_t)(cx + t->vx);
    5640:	01c69a23          	sh	t3,20(a3)
            t->py = (int16_t)(cy + t->vy);
    5644:	00669b23          	sh	t1,22(a3)
            if (t->px < 0) t->px = 0;
    5648:	1a0e4863          	bltz	t3,57f8 <t3_update+0x670>
            if (t->py < 0) t->py = 0;
    564c:	1a034a63          	bltz	t1,5800 <t3_update+0x678>
            if (t->px > 1919) t->px = 1919;
    5650:	77f00693          	li	a3,1919
    5654:	01c6de63          	bge	a3,t3,5670 <t3_update+0x4e8>
    5658:	01f706b3          	add	a3,a4,t6
    565c:	00369693          	slli	a3,a3,0x3
    5660:	00d786b3          	add	a3,a5,a3
    5664:	01669303          	lh	t1,22(a3)
    5668:	77f00613          	li	a2,1919
    566c:	00c69a23          	sh	a2,20(a3)
            if (t->py > 1079) t->py = 1079;
    5670:	006dda63          	bge	s11,t1,5684 <t3_update+0x4fc>
    5674:	01f706b3          	add	a3,a4,t6
    5678:	00369693          	slli	a3,a3,0x3
    567c:	00d786b3          	add	a3,a5,a3
    5680:	01b69b23          	sh	s11,22(a3)
            t->x0 = dets[i].x0;
    5684:	01f70733          	add	a4,a4,t6
    5688:	00371713          	slli	a4,a4,0x3
            used_t[best] = 1;
    568c:	02010693          	addi	a3,sp,32
            t->x0 = dets[i].x0;
    5690:	00e78733          	add	a4,a5,a4
            used_t[best] = 1;
    5694:	01f68fb3          	add	t6,a3,t6
            t->x0 = dets[i].x0;
    5698:	01271223          	sh	s2,4(a4)
            t->y0 = dets[i].y0;
    569c:	01471323          	sh	s4,6(a4)
            t->x1 = dets[i].x1;
    56a0:	01371423          	sh	s3,8(a4)
            t->y1 = dets[i].y1;
    56a4:	01571523          	sh	s5,10(a4)
            t->age = 0;
    56a8:	000701a3          	sb	zero,3(a4)
            used_t[best] = 1;
    56ac:	ff7f8c23          	sb	s7,-8(t6)
            used_d[i] = 1;
    56b0:	00100713          	li	a4,1
    56b4:	00100b13          	li	s6,1
    56b8:	00100c93          	li	s9,1
    56bc:	d75ff06f          	j	5430 <t3_update+0x2a8>
    56c0:	00078713          	mv	a4,a5
        if (!s_trk[i].used)
    56c4:	00274803          	lbu	a6,2(a4)
    for (i = 0; i < T3_MAX_TRK; i++)
    56c8:	00000693          	li	a3,0
        if (!s_trk[i].used)
    56cc:	01870713          	addi	a4,a4,24
    56d0:	00080c63          	beqz	a6,56e8 <t3_update+0x560>
    for (i = 0; i < T3_MAX_TRK; i++)
    56d4:	00168693          	addi	a3,a3,1
    56d8:	d8668ae3          	beq	a3,t1,546c <t3_update+0x2e4>
        if (!s_trk[i].used)
    56dc:	00274803          	lbu	a6,2(a4)
    56e0:	01870713          	addi	a4,a4,24
    56e4:	fe0818e3          	bnez	a6,56d4 <t3_update+0x54c>
        t->used = 1;
    56e8:	00169713          	slli	a4,a3,0x1
    56ec:	00d70833          	add	a6,a4,a3
    56f0:	00381813          	slli	a6,a6,0x3
    56f4:	01078833          	add	a6,a5,a6
        t->tid = s_next_tid++;
    56f8:	001e0293          	addi	t0,t3,1
    56fc:	01c81023          	sh	t3,0(a6)
        t->used = 1;
    5700:	01f81123          	sh	t6,2(a6)
        t->tid = s_next_tid++;
    5704:	01029813          	slli	a6,t0,0x10
    5708:	01085813          	srli	a6,a6,0x10
        if (s_next_tid == 0) s_next_tid = 1;
    570c:	00100e13          	li	t3,1
    5710:	10081e63          	bnez	a6,582c <t3_update+0x6a4>
        t->x0 = dets[i].x0;
    5714:	00055803          	lhu	a6,0(a0)
    5718:	00d70733          	add	a4,a4,a3
    571c:	00371713          	slli	a4,a4,0x3
    5720:	00e78733          	add	a4,a5,a4
    5724:	01071223          	sh	a6,4(a4)
        t->y0 = dets[i].y0;
    5728:	00255683          	lhu	a3,2(a0)
        t->py = t->cy;
    572c:	00100413          	li	s0,1
        t->y0 = dets[i].y0;
    5730:	00d71323          	sh	a3,6(a4)
        t->x1 = dets[i].x1;
    5734:	00455383          	lhu	t2,4(a0)
    5738:	00771423          	sh	t2,8(a4)
        t->y1 = dets[i].y1;
    573c:	00655283          	lhu	t0,6(a0)
        t->cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    5740:	00780833          	add	a6,a6,t2
    5744:	40185813          	srai	a6,a6,0x1
        t->cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5748:	005686b3          	add	a3,a3,t0
    574c:	4016d693          	srai	a3,a3,0x1
        t->cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    5750:	01081813          	slli	a6,a6,0x10
        t->cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5754:	01069693          	slli	a3,a3,0x10
        t->cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    5758:	41085813          	srai	a6,a6,0x10
        t->cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    575c:	4106d693          	srai	a3,a3,0x10
        t->y1 = dets[i].y1;
    5760:	00571523          	sh	t0,10(a4)
        t->cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
    5764:	01071623          	sh	a6,12(a4)
        t->cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
    5768:	00d71723          	sh	a3,14(a4)
        t->vx = 0;
    576c:	00072823          	sw	zero,16(a4)
        t->px = t->cx;
    5770:	01071a23          	sh	a6,20(a4)
        t->py = t->cy;
    5774:	00d71b23          	sh	a3,22(a4)
    5778:	cf5ff06f          	j	546c <t3_update+0x2e4>
            dst[nout++] = s_trk[j];
    577c:	00151713          	slli	a4,a0,0x1
    5780:	00a70733          	add	a4,a4,a0
    5784:	00371713          	slli	a4,a4,0x3
    5788:	00ef0733          	add	a4,t5,a4
        if (s_trk[j].used && nout < T3_MAX_TRK)
    578c:	d4a84ae3          	blt	a6,a0,54e0 <t3_update+0x358>
            dst[nout++] = s_trk[j];
    5790:	0007da03          	lhu	s4,0(a5)
    5794:	0027d983          	lhu	s3,2(a5)
    5798:	0047d903          	lhu	s2,4(a5)
    579c:	0067d483          	lhu	s1,6(a5)
    57a0:	0087d403          	lhu	s0,8(a5)
    57a4:	00a7d383          	lhu	t2,10(a5)
    57a8:	00c7d283          	lhu	t0,12(a5)
    57ac:	00e7df83          	lhu	t6,14(a5)
    57b0:	0127d303          	lhu	t1,18(a5)
    57b4:	0147d603          	lhu	a2,20(a5)
    57b8:	0167d683          	lhu	a3,22(a5)
    57bc:	0107de03          	lhu	t3,16(a5)
    57c0:	00150513          	addi	a0,a0,1
    57c4:	01471023          	sh	s4,0(a4)
    57c8:	01371123          	sh	s3,2(a4)
    57cc:	01271223          	sh	s2,4(a4)
    57d0:	00971323          	sh	s1,6(a4)
    57d4:	00871423          	sh	s0,8(a4)
    57d8:	00771523          	sh	t2,10(a4)
    57dc:	00571623          	sh	t0,12(a4)
    57e0:	01f71723          	sh	t6,14(a4)
    57e4:	01c71823          	sh	t3,16(a4)
    57e8:	00671923          	sh	t1,18(a4)
    57ec:	00c71a23          	sh	a2,20(a4)
    57f0:	00d71b23          	sh	a3,22(a4)
    57f4:	cedff06f          	j	54e0 <t3_update+0x358>
            if (t->px < 0) t->px = 0;
    57f8:	00069a23          	sh	zero,20(a3)
            if (t->py < 0) t->py = 0;
    57fc:	e6035ae3          	bgez	t1,5670 <t3_update+0x4e8>
    5800:	01f706b3          	add	a3,a4,t6
    5804:	00369693          	slli	a3,a3,0x3
    5808:	00d786b3          	add	a3,a5,a3
            if (t->px > 1919) t->px = 1919;
    580c:	01469603          	lh	a2,20(a3)
            if (t->py < 0) t->py = 0;
    5810:	00069b23          	sh	zero,22(a3)
            if (t->px > 1919) t->px = 1919;
    5814:	77f00693          	li	a3,1919
    5818:	e6c6d6e3          	bge	a3,a2,5684 <t3_update+0x4fc>
    581c:	e3dff06f          	j	5658 <t3_update+0x4d0>
        for (j = 0; j < T3_MAX_TRK; j++) {
    5820:	00300f93          	li	t6,3
    5824:	00600713          	li	a4,6
    5828:	db9ff06f          	j	55e0 <t3_update+0x458>
        if (s_next_tid == 0) s_next_tid = 1;
    582c:	00080e13          	mv	t3,a6
    5830:	ee5ff06f          	j	5714 <t3_update+0x58c>
            if (t->px < 0) t->px = 0;
    5834:	00069a23          	sh	zero,20(a3)
            if (t->py < 0) t->py = 0;
    5838:	b60656e3          	bgez	a2,53a4 <t3_update+0x21c>
    583c:	01e706b3          	add	a3,a4,t5
    5840:	00369693          	slli	a3,a3,0x3
    5844:	00d786b3          	add	a3,a5,a3
            if (t->px > 1919) t->px = 1919;
    5848:	01469603          	lh	a2,20(a3)
            if (t->py < 0) t->py = 0;
    584c:	00069b23          	sh	zero,22(a3)
            if (t->px > 1919) t->px = 1919;
    5850:	77f00693          	li	a3,1919
    5854:	b2c6cce3          	blt	a3,a2,538c <t3_update+0x204>
    5858:	b69ff06f          	j	53c0 <t3_update+0x238>
    585c:	000c8463          	beqz	s9,5864 <t3_update+0x6dc>
    5860:	01610e23          	sb	s6,28(sp)
    for (i = 0; i < nd && i < T3_MAX_TRK; i++) {
    5864:	00100713          	li	a4,1
    5868:	c0e59ee3          	bne	a1,a4,5484 <t3_update+0x2fc>
    586c:	bd9ff06f          	j	5444 <t3_update+0x2bc>
    for (i = 0; i < nd && i < T3_MAX_TRK; i++) {
    5870:	00000b13          	li	s6,0
    5874:	18078793          	addi	a5,a5,384
    5878:	01810893          	addi	a7,sp,24
    587c:	b95ff06f          	j	5410 <t3_update+0x288>

00005880 <t3_make_thumb>:

void t3_make_thumb(const uint8_t *g96, uint8_t *th)
{
    int y, x;
    for (y = 0; y < T3_THUMB_H; y++)
    5880:	000027b7          	lui	a5,0x2
    5884:	46078793          	addi	a5,a5,1120 # 2460 <send_tcp+0x2ec>
    5888:	06050613          	addi	a2,a0,96
    588c:	00f50533          	add	a0,a0,a5
    5890:	fa060793          	addi	a5,a2,-96
{
    5894:	00058713          	mv	a4,a1
        for (x = 0; x < T3_THUMB_W; x++)
            th[y * T3_THUMB_W + x] = g96[(y * 2) * 96 + (x * 2)];
    5898:	0007c683          	lbu	a3,0(a5)
    589c:	00170713          	addi	a4,a4,1
    58a0:	00278793          	addi	a5,a5,2
    58a4:	fed70fa3          	sb	a3,-1(a4)
        for (x = 0; x < T3_THUMB_W; x++)
    58a8:	fec798e3          	bne	a5,a2,5898 <t3_make_thumb+0x18>
    58ac:	0c078613          	addi	a2,a5,192
    58b0:	03058593          	addi	a1,a1,48
    for (y = 0; y < T3_THUMB_H; y++)
    58b4:	fca61ee3          	bne	a2,a0,5890 <t3_make_thumb+0x10>
}
    58b8:	00008067          	ret

000058bc <conv1x1.constprop.1>:
        if ((oy & 7) == 0)
            http_poll();
    }
}

static void conv1x1(const int8_t *src, int8_t *dst,
    58bc:	fb010113          	addi	sp,sp,-80
    58c0:	03912223          	sw	s9,36(sp)
    int ih, int iw, int ic, int oc,
    int izp, int ozp,
    const int8_t *w, const int32_t *b, const int32_t *m, const int32_t *s)
{
    int n = ih * iw;
    58c4:	02b50cb3          	mul	s9,a0,a1
static void conv1x1(const int8_t *src, int8_t *dst,
    58c8:	03812423          	sw	s8,40(sp)
    58cc:	03a12023          	sw	s10,32(sp)
    58d0:	00068c13          	mv	s8,a3
    58d4:	05012d03          	lw	s10,80(sp)
    58d8:	04912223          	sw	s1,68(sp)
    58dc:	05212023          	sw	s2,64(sp)
    58e0:	01b12e23          	sw	s11,28(sp)
    58e4:	002c1913          	slli	s2,s8,0x2
    58e8:	000544b7          	lui	s1,0x54
    58ec:	0005ddb7          	lui	s11,0x5d
    58f0:	04812423          	sw	s0,72(sp)
    58f4:	03312e23          	sw	s3,60(sp)
    58f8:	03412c23          	sw	s4,56(sp)
    58fc:	03512a23          	sw	s5,52(sp)
    5900:	03612823          	sw	s6,48(sp)
    5904:	03712623          	sw	s7,44(sp)
    5908:	00070a93          	mv	s5,a4
    590c:	04112623          	sw	ra,76(sp)
    5910:	00060413          	mv	s0,a2
    5914:	00078693          	mv	a3,a5
    5918:	5e048493          	addi	s1,s1,1504 # 545e0 <buf1>
    591c:	5e0d8d93          	addi	s11,s11,1504 # 5d5e0 <buf0>
    5920:	01280933          	add	s2,a6,s2
    int i, oc_i, c;
    for (i = 0; i < n; i++) {
    5924:	00000b93          	li	s7,0
    5928:	00c78733          	add	a4,a5,a2
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    592c:	40000a37          	lui	s4,0x40000
    if (x > 127) return 127;
    5930:	07f00993          	li	s3,127
    if (x < -128) return -128;
    5934:	f8000b13          	li	s6,-128
        const int8_t *px = src + i * ic;
        int8_t *py = dst + i * oc;
        for (oc_i = 0; oc_i < oc; oc_i++) {
    5938:	00088793          	mv	a5,a7
    593c:	000d0513          	mv	a0,s10
    5940:	00068593          	mv	a1,a3
    5944:	00070f93          	mv	t6,a4
    for (i = 0; i < n; i++) {
    5948:	000d8393          	mv	t2,s11
    594c:	00080293          	mv	t0,a6
            int32_t acc = b[oc_i];
    5950:	0002af03          	lw	t5,0(t0)
    5954:	00058e13          	mv	t3,a1
    5958:	00048e93          	mv	t4,s1
            const int8_t *ww = w + oc_i * ic;
            for (c = 0; c < ic; c++)
                acc += (px[c] - izp) * ww[c];
    595c:	000e8303          	lb	t1,0(t4)
    5960:	000e0603          	lb	a2,0(t3)
    5964:	001e0e13          	addi	t3,t3,1
    5968:	08030313          	addi	t1,t1,128
    596c:	02c30333          	mul	t1,t1,a2
    5970:	001e8e93          	addi	t4,t4,1
    5974:	006f0f33          	add	t5,t5,t1
            for (c = 0; c < ic; c++)
    5978:	ffcf92e3          	bne	t6,t3,595c <conv1x1.constprop.1+0xa0>
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    597c:	0007ae03          	lw	t3,0(a5)
            acc = qapply(acc, m[oc_i], s[oc_i]) + ozp;
    5980:	00052303          	lw	t1,0(a0)
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    5984:	03cf0633          	mul	a2,t5,t3
    5988:	03cf1f33          	mulh	t5,t5,t3
    598c:	01460e33          	add	t3,a2,s4
    5990:	00ce3633          	sltu	a2,t3,a2
    int32_t h = (int32_t)(ab >> 31);
    5994:	01fe5e13          	srli	t3,t3,0x1f
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    5998:	01e60633          	add	a2,a2,t5
    int32_t h = (int32_t)(ab >> 31);
    599c:	00161613          	slli	a2,a2,0x1
    59a0:	01c66e33          	or	t3,a2,t3
        return h << shift;
    59a4:	006e1633          	sll	a2,t3,t1
    if (shift < 0)
    59a8:	08034863          	bltz	t1,5a38 <conv1x1.constprop.1+0x17c>
            acc = qapply(acc, m[oc_i], s[oc_i]) + ozp;
    59ac:	00ca8333          	add	t1,s5,a2
    if (x > 127) return 127;
    59b0:	07f00613          	li	a2,127
    59b4:	0069c863          	blt	s3,t1,59c4 <conv1x1.constprop.1+0x108>
    if (x < -128) return -128;
    59b8:	0b634a63          	blt	t1,s6,5a6c <conv1x1.constprop.1+0x1b0>
    return (int8_t)x;
    59bc:	01831613          	slli	a2,t1,0x18
    59c0:	41865613          	srai	a2,a2,0x18
            py[oc_i] = sat8(acc);
    59c4:	00c38023          	sb	a2,0(t2)
    59c8:	00428293          	addi	t0,t0,4
    59cc:	00138393          	addi	t2,t2,1
    59d0:	00478793          	addi	a5,a5,4
    59d4:	00450513          	addi	a0,a0,4
    59d8:	008585b3          	add	a1,a1,s0
    59dc:	008f8fb3          	add	t6,t6,s0
        for (oc_i = 0; oc_i < oc; oc_i++) {
    59e0:	f65918e3          	bne	s2,t0,5950 <conv1x1.constprop.1+0x94>
        }
        if ((i & 63) == 0)
    59e4:	03fbf793          	andi	a5,s7,63
    59e8:	04078e63          	beqz	a5,5a44 <conv1x1.constprop.1+0x188>
    for (i = 0; i < n; i++) {
    59ec:	001b8b93          	addi	s7,s7,1
    59f0:	008484b3          	add	s1,s1,s0
    59f4:	018d8db3          	add	s11,s11,s8
    59f8:	f57c90e3          	bne	s9,s7,5938 <conv1x1.constprop.1+0x7c>
            http_poll();
    }
}
    59fc:	04c12083          	lw	ra,76(sp)
    5a00:	04812403          	lw	s0,72(sp)
    5a04:	04412483          	lw	s1,68(sp)
    5a08:	04012903          	lw	s2,64(sp)
    5a0c:	03c12983          	lw	s3,60(sp)
    5a10:	03812a03          	lw	s4,56(sp)
    5a14:	03412a83          	lw	s5,52(sp)
    5a18:	03012b03          	lw	s6,48(sp)
    5a1c:	02c12b83          	lw	s7,44(sp)
    5a20:	02812c03          	lw	s8,40(sp)
    5a24:	02412c83          	lw	s9,36(sp)
    5a28:	02012d03          	lw	s10,32(sp)
    5a2c:	01c12d83          	lw	s11,28(sp)
    5a30:	05010113          	addi	sp,sp,80
    5a34:	00008067          	ret
        return h >> (-shift);
    5a38:	40600333          	neg	t1,t1
    5a3c:	406e5633          	sra	a2,t3,t1
    5a40:	f6dff06f          	j	59ac <conv1x1.constprop.1+0xf0>
    5a44:	00e12623          	sw	a4,12(sp)
    5a48:	01112423          	sw	a7,8(sp)
    5a4c:	01012223          	sw	a6,4(sp)
    5a50:	00d12023          	sw	a3,0(sp)
            http_poll();
    5a54:	f11fc0ef          	jal	ra,2964 <http_poll>
    5a58:	00c12703          	lw	a4,12(sp)
    5a5c:	00812883          	lw	a7,8(sp)
    5a60:	00412803          	lw	a6,4(sp)
    5a64:	00012683          	lw	a3,0(sp)
    5a68:	f85ff06f          	j	59ec <conv1x1.constprop.1+0x130>
    if (x < -128) return -128;
    5a6c:	f8000613          	li	a2,-128
    5a70:	f55ff06f          	j	59c4 <conv1x1.constprop.1+0x108>

00005a74 <dw3.constprop.2>:
static void dw3(const int8_t *src, int8_t *dst,
    5a74:	f8010113          	addi	sp,sp,-128
    5a78:	07412423          	sw	s4,104(sp)
    5a7c:	00060a13          	mv	s4,a2
    int oh = (ih + stride - 1) / stride;
    5a80:	01060633          	add	a2,a2,a6
    5a84:	fff60613          	addi	a2,a2,-1
    5a88:	03064333          	div	t1,a2,a6
static void dw3(const int8_t *src, int8_t *dst,
    5a8c:	05b12623          	sw	s11,76(sp)
    5a90:	00a12623          	sw	a0,12(sp)
    5a94:	00078d93          	mv	s11,a5
    int ow = (iw + stride - 1) / stride;
    5a98:	00080513          	mv	a0,a6
    5a9c:	00d80633          	add	a2,a6,a3
    5aa0:	fff60613          	addi	a2,a2,-1
static void dw3(const int8_t *src, int8_t *dst,
    5aa4:	01012a23          	sw	a6,20(sp)
    5aa8:	02b12223          	sw	a1,36(sp)
    5aac:	05a12823          	sw	s10,80(sp)
    5ab0:	07212823          	sw	s2,112(sp)
    5ab4:	06812c23          	sw	s0,120(sp)
    5ab8:	07512223          	sw	s5,100(sp)
    5abc:	07312623          	sw	s3,108(sp)
    5ac0:	06912a23          	sw	s1,116(sp)
    5ac4:	07612023          	sw	s6,96(sp)
    5ac8:	05712e23          	sw	s7,92(sp)
    5acc:	06112e23          	sw	ra,124(sp)
    5ad0:	05812c23          	sw	s8,88(sp)
    5ad4:	05912a23          	sw	s9,84(sp)
    5ad8:	00088b13          	mv	s6,a7
    for (oy = 0; oy < oh; oy++) {
    5adc:	02012023          	sw	zero,32(sp)
    5ae0:	00068493          	mv	s1,a3
    5ae4:	00070b93          	mv	s7,a4
    int pad = ((oh - 1) * stride + 3 - ih);
    5ae8:	fff30793          	addi	a5,t1,-1
    5aec:	02a787b3          	mul	a5,a5,a0
    int oh = (ih + stride - 1) / stride;
    5af0:	02612623          	sw	t1,44(sp)
    int ow = (iw + stride - 1) / stride;
    5af4:	03064833          	div	a6,a2,a6
    int pad = ((oh - 1) * stride + 3 - ih);
    5af8:	00378793          	addi	a5,a5,3
    5afc:	414787b3          	sub	a5,a5,s4
    int ph = pad / 2;
    5b00:	fff7c613          	not	a2,a5
    5b04:	41f65613          	srai	a2,a2,0x1f
    5b08:	00c7f7b3          	and	a5,a5,a2
    5b0c:	4017d793          	srai	a5,a5,0x1
    5b10:	40f005b3          	neg	a1,a5
    5b14:	02b12a23          	sw	a1,52(sp)
    5b18:	00058d13          	mv	s10,a1
    5b1c:	00300613          	li	a2,3
    5b20:	40f60933          	sub	s2,a2,a5
    5b24:	03212823          	sw	s2,48(sp)
    5b28:	02d585b3          	mul	a1,a1,a3
    int ow = (iw + stride - 1) / stride;
    5b2c:	01012c23          	sw	a6,24(sp)
    5b30:	40f587b3          	sub	a5,a1,a5
    int oc = ic * dm;
    5b34:	03b70433          	mul	s0,a4,s11
    for (oy = 0; oy < oh; oy++) {
    5b38:	02e787b3          	mul	a5,a5,a4
    5b3c:	00141993          	slli	s3,s0,0x1
    5b40:	008989b3          	add	s3,s3,s0
    5b44:	02d50633          	mul	a2,a0,a3
    5b48:	02f12423          	sw	a5,40(sp)
    5b4c:	028805b3          	mul	a1,a6,s0
    5b50:	02e60633          	mul	a2,a2,a4
    5b54:	02b12c23          	sw	a1,56(sp)
    5b58:	02e507b3          	mul	a5,a0,a4
    5b5c:	02c12e23          	sw	a2,60(sp)
    5b60:	02e68ab3          	mul	s5,a3,a4
    5b64:	00f12e23          	sw	a5,28(sp)
    if (x < -128) return -128;
    5b68:	02812c83          	lw	s9,40(sp)
    5b6c:	03412383          	lw	t2,52(sp)
    5b70:	03012f83          	lw	t6,48(sp)
    5b74:	02412c03          	lw	s8,36(sp)
        for (ox = 0; ox < ow; ox++) {
    5b78:	00012823          	sw	zero,16(sp)
    5b7c:	08412283          	lw	t0,132(sp)
    5b80:	08812f03          	lw	t5,136(sp)
    5b84:	08c12e83          	lw	t4,140(sp)
            for (oc_i = 0; oc_i < oc; oc_i++) {
    5b88:	00000313          	li	t1,0
                int in_c = oc_i / dm;
    5b8c:	03b346b3          	div	a3,t1,s11
    5b90:	08012783          	lw	a5,128(sp)
                int32_t acc = b[oc_i];
    5b94:	0002a803          	lw	a6,0(t0)
                int in_c = oc_i / dm;
    5b98:	000d0613          	mv	a2,s10
    5b9c:	006788b3          	add	a7,a5,t1
    5ba0:	00c12783          	lw	a5,12(sp)
    5ba4:	019686b3          	add	a3,a3,s9
    5ba8:	00d786b3          	add	a3,a5,a3
                    if ((unsigned)iy >= (unsigned)ih) continue;
    5bac:	13466c63          	bltu	a2,s4,5ce4 <dw3.constprop.2+0x270>
    5bb0:	00160613          	addi	a2,a2,1
    5bb4:	015686b3          	add	a3,a3,s5
    5bb8:	013888b3          	add	a7,a7,s3
                for (ky = 0; ky < 3; ky++) {
    5bbc:	ff2618e3          	bne	a2,s2,5bac <dw3.constprop.2+0x138>
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    5bc0:	000f2683          	lw	a3,0(t5)
                acc = qapply(acc, m[oc_i], s[oc_i]) + ozp;
    5bc4:	000ea703          	lw	a4,0(t4)
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    5bc8:	02d807b3          	mul	a5,a6,a3
    5bcc:	02d81833          	mulh	a6,a6,a3
    5bd0:	400006b7          	lui	a3,0x40000
    5bd4:	00d786b3          	add	a3,a5,a3
    5bd8:	00f6b7b3          	sltu	a5,a3,a5
    int32_t h = (int32_t)(ab >> 31);
    5bdc:	01f6d693          	srli	a3,a3,0x1f
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    5be0:	01078833          	add	a6,a5,a6
    int32_t h = (int32_t)(ab >> 31);
    5be4:	00181813          	slli	a6,a6,0x1
    5be8:	00d866b3          	or	a3,a6,a3
        return h << shift;
    5bec:	00e697b3          	sll	a5,a3,a4
    if (shift < 0)
    5bf0:	12074663          	bltz	a4,5d1c <dw3.constprop.2+0x2a8>
                acc = qapply(acc, m[oc_i], s[oc_i]) + ozp;
    5bf4:	f8078713          	addi	a4,a5,-128
    if (x > 127) return 127;
    5bf8:	07f00693          	li	a3,127
    5bfc:	07f00793          	li	a5,127
    5c00:	00e6ca63          	blt	a3,a4,5c14 <dw3.constprop.2+0x1a0>
    if (x < -128) return -128;
    5c04:	f8000793          	li	a5,-128
    5c08:	12f74063          	blt	a4,a5,5d28 <dw3.constprop.2+0x2b4>
    return (int8_t)x;
    5c0c:	01871793          	slli	a5,a4,0x18
    5c10:	4187d793          	srai	a5,a5,0x18
                dst[(oy * ow + ox) * oc + oc_i] = sat8(acc);
    5c14:	006c0733          	add	a4,s8,t1
    5c18:	00f70023          	sb	a5,0(a4)
            for (oc_i = 0; oc_i < oc; oc_i++) {
    5c1c:	00130313          	addi	t1,t1,1
    5c20:	00428293          	addi	t0,t0,4
    5c24:	004f0f13          	addi	t5,t5,4
    5c28:	004e8e93          	addi	t4,t4,4
    5c2c:	f66410e3          	bne	s0,t1,5b8c <dw3.constprop.2+0x118>
    5c30:	01412703          	lw	a4,20(sp)
        for (ox = 0; ox < ow; ox++) {
    5c34:	01012783          	lw	a5,16(sp)
    5c38:	008c0c33          	add	s8,s8,s0
    5c3c:	00ef8fb3          	add	t6,t6,a4
    5c40:	00e383b3          	add	t2,t2,a4
    5c44:	01c12703          	lw	a4,28(sp)
    5c48:	00178793          	addi	a5,a5,1
    5c4c:	00f12823          	sw	a5,16(sp)
    5c50:	00ec8cb3          	add	s9,s9,a4
    5c54:	01812703          	lw	a4,24(sp)
    5c58:	f2f712e3          	bne	a4,a5,5b7c <dw3.constprop.2+0x108>
        if ((oy & 7) == 0)
    5c5c:	02012783          	lw	a5,32(sp)
    5c60:	0077f793          	andi	a5,a5,7
    5c64:	0c078663          	beqz	a5,5d30 <dw3.constprop.2+0x2bc>
    5c68:	01412703          	lw	a4,20(sp)
    5c6c:	03812683          	lw	a3,56(sp)
    for (oy = 0; oy < oh; oy++) {
    5c70:	02012783          	lw	a5,32(sp)
    5c74:	00e90933          	add	s2,s2,a4
    5c78:	00ed0d33          	add	s10,s10,a4
    5c7c:	02412703          	lw	a4,36(sp)
    5c80:	00178793          	addi	a5,a5,1
    5c84:	02f12023          	sw	a5,32(sp)
    5c88:	00d70733          	add	a4,a4,a3
    5c8c:	02e12223          	sw	a4,36(sp)
    5c90:	03c12683          	lw	a3,60(sp)
    5c94:	02812703          	lw	a4,40(sp)
    5c98:	00d70733          	add	a4,a4,a3
    5c9c:	02e12423          	sw	a4,40(sp)
    5ca0:	02c12703          	lw	a4,44(sp)
    5ca4:	ecf712e3          	bne	a4,a5,5b68 <dw3.constprop.2+0xf4>
}
    5ca8:	07c12083          	lw	ra,124(sp)
    5cac:	07812403          	lw	s0,120(sp)
    5cb0:	07412483          	lw	s1,116(sp)
    5cb4:	07012903          	lw	s2,112(sp)
    5cb8:	06c12983          	lw	s3,108(sp)
    5cbc:	06812a03          	lw	s4,104(sp)
    5cc0:	06412a83          	lw	s5,100(sp)
    5cc4:	06012b03          	lw	s6,96(sp)
    5cc8:	05c12b83          	lw	s7,92(sp)
    5ccc:	05812c03          	lw	s8,88(sp)
    5cd0:	05412c83          	lw	s9,84(sp)
    5cd4:	05012d03          	lw	s10,80(sp)
    5cd8:	04c12d83          	lw	s11,76(sp)
    5cdc:	08010113          	addi	sp,sp,128
    5ce0:	00008067          	ret
                    if ((unsigned)iy >= (unsigned)ih) continue;
    5ce4:	00088513          	mv	a0,a7
    5ce8:	00068593          	mv	a1,a3
    5cec:	00038793          	mv	a5,t2
                        if ((unsigned)ix >= (unsigned)iw) continue;
    5cf0:	0097fc63          	bgeu	a5,s1,5d08 <dw3.constprop.2+0x294>
                        acc += (src[(iy * iw + ix) * ic + in_c] - izp) *
    5cf4:	00058703          	lb	a4,0(a1)
                               w[(ky * 3 + kx) * oc + oc_i];
    5cf8:	00050e03          	lb	t3,0(a0)
                        acc += (src[(iy * iw + ix) * ic + in_c] - izp) *
    5cfc:	41670733          	sub	a4,a4,s6
    5d00:	03c70733          	mul	a4,a4,t3
    5d04:	00e80833          	add	a6,a6,a4
    5d08:	00178793          	addi	a5,a5,1
    5d0c:	017585b3          	add	a1,a1,s7
    5d10:	00850533          	add	a0,a0,s0
                    for (kx = 0; kx < 3; kx++) {
    5d14:	fdf79ee3          	bne	a5,t6,5cf0 <dw3.constprop.2+0x27c>
    5d18:	e99ff06f          	j	5bb0 <dw3.constprop.2+0x13c>
        return h >> (-shift);
    5d1c:	40e00733          	neg	a4,a4
    5d20:	40e6d7b3          	sra	a5,a3,a4
    5d24:	ed1ff06f          	j	5bf4 <dw3.constprop.2+0x180>
    if (x < -128) return -128;
    5d28:	f8000793          	li	a5,-128
    5d2c:	ee9ff06f          	j	5c14 <dw3.constprop.2+0x1a0>
            http_poll();
    5d30:	c35fc0ef          	jal	ra,2964 <http_poll>
    5d34:	f35ff06f          	j	5c68 <dw3.constprop.2+0x1f4>

00005d38 <pdti8_run>:

void pdti8_run(const int8_t *in96, int8_t *person, int8_t *no_person)
{
    const int8_t *src = in96;
    int8_t *dst = buf0;
    dw3(src, dst, 96, 96, 1, 8, 2, -1, -128, pd_w0, pd_b0, pd_m0, pd_s0);
    5d38:	00047337          	lui	t1,0x47
{
    5d3c:	fd010113          	addi	sp,sp,-48
    dw3(src, dst, 96, 96, 1, 8, 2, -1, -128, pd_w0, pd_b0, pd_m0, pd_s0);
    5d40:	8b830313          	addi	t1,t1,-1864 # 468b8 <pd_s0>
    5d44:	00612623          	sw	t1,12(sp)
    5d48:	00047337          	lui	t1,0x47
    5d4c:	8d830313          	addi	t1,t1,-1832 # 468d8 <pd_m0>
    5d50:	00612423          	sw	t1,8(sp)
    5d54:	00047337          	lui	t1,0x47
    5d58:	8f830313          	addi	t1,t1,-1800 # 468f8 <pd_b0>
    5d5c:	00612223          	sw	t1,4(sp)
    5d60:	00047337          	lui	t1,0x47
    5d64:	91830313          	addi	t1,t1,-1768 # 46918 <pd_w0>
{
    5d68:	02812423          	sw	s0,40(sp)
    dw3(src, dst, 96, 96, 1, 8, 2, -1, -128, pd_w0, pd_b0, pd_m0, pd_s0);
    5d6c:	0005d437          	lui	s0,0x5d
    5d70:	fff00893          	li	a7,-1
    5d74:	00200813          	li	a6,2
    5d78:	00800793          	li	a5,8
    5d7c:	00100713          	li	a4,1
    5d80:	06000693          	li	a3,96
    5d84:	00612023          	sw	t1,0(sp)
{
    5d88:	03212023          	sw	s2,32(sp)
    5d8c:	01312e23          	sw	s3,28(sp)
    5d90:	00058913          	mv	s2,a1
    5d94:	00060993          	mv	s3,a2
    dw3(src, dst, 96, 96, 1, 8, 2, -1, -128, pd_w0, pd_b0, pd_m0, pd_s0);
    5d98:	5e040593          	addi	a1,s0,1504 # 5d5e0 <buf0>
    5d9c:	06000613          	li	a2,96
{
    5da0:	02112623          	sw	ra,44(sp)
    5da4:	02912223          	sw	s1,36(sp)
    5da8:	01412c23          	sw	s4,24(sp)
    dw3(src, dst, 96, 96, 1, 8, 2, -1, -128, pd_w0, pd_b0, pd_m0, pd_s0);
    5dac:	cc9ff0ef          	jal	ra,5a74 <dw3.constprop.2>
    http_poll();
    5db0:	bb5fc0ef          	jal	ra,2964 <http_poll>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 48, 48, 8, 1, 1, -128, -128, pd_w1, pd_b1, pd_m1, pd_s1);
    5db4:	00047337          	lui	t1,0x47
    5db8:	81030313          	addi	t1,t1,-2032 # 46810 <pd_s1>
    5dbc:	00612623          	sw	t1,12(sp)
    5dc0:	00047337          	lui	t1,0x47
    5dc4:	83030313          	addi	t1,t1,-2000 # 46830 <pd_m1>
    5dc8:	00612423          	sw	t1,8(sp)
    5dcc:	00047337          	lui	t1,0x47
    5dd0:	85030313          	addi	t1,t1,-1968 # 46850 <pd_b1>
    5dd4:	00612223          	sw	t1,4(sp)
    5dd8:	00047337          	lui	t1,0x47
    5ddc:	000544b7          	lui	s1,0x54
    5de0:	87030313          	addi	t1,t1,-1936 # 46870 <pd_w1>
    5de4:	5e048593          	addi	a1,s1,1504 # 545e0 <buf1>
    5de8:	f8000893          	li	a7,-128
    5dec:	00100813          	li	a6,1
    5df0:	00100793          	li	a5,1
    5df4:	00800713          	li	a4,8
    5df8:	03000693          	li	a3,48
    5dfc:	03000613          	li	a2,48
    5e00:	5e040513          	addi	a0,s0,1504
    5e04:	00612023          	sw	t1,0(sp)
    5e08:	c6dff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 48, 48, 8, 16, -128, -128, pd_w2, pd_b2, pd_m2, pd_s2);
    5e0c:	00046337          	lui	t1,0x46
    5e10:	6d030313          	addi	t1,t1,1744 # 466d0 <pd_s2>
    5e14:	000468b7          	lui	a7,0x46
    5e18:	00046837          	lui	a6,0x46
    5e1c:	000467b7          	lui	a5,0x46
    5e20:	71088893          	addi	a7,a7,1808 # 46710 <pd_m2>
    5e24:	75080813          	addi	a6,a6,1872 # 46750 <pd_b2>
    5e28:	79078793          	addi	a5,a5,1936 # 46790 <pd_w2>
    5e2c:	f8000713          	li	a4,-128
    5e30:	01000693          	li	a3,16
    5e34:	00800613          	li	a2,8
    5e38:	03000593          	li	a1,48
    5e3c:	03000513          	li	a0,48
    5e40:	00612023          	sw	t1,0(sp)
    5e44:	a79ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 48, 48, 16, 1, 2, -128, -128, pd_w3, pd_b3, pd_m3, pd_s3);
    5e48:	00046337          	lui	t1,0x46
    5e4c:	58030313          	addi	t1,t1,1408 # 46580 <pd_s3>
    5e50:	00612623          	sw	t1,12(sp)
    5e54:	00046337          	lui	t1,0x46
    5e58:	5c030313          	addi	t1,t1,1472 # 465c0 <pd_m3>
    5e5c:	00612423          	sw	t1,8(sp)
    5e60:	00046337          	lui	t1,0x46
    5e64:	60030313          	addi	t1,t1,1536 # 46600 <pd_b3>
    5e68:	00612223          	sw	t1,4(sp)
    5e6c:	00046337          	lui	t1,0x46
    5e70:	64030313          	addi	t1,t1,1600 # 46640 <pd_w3>
    5e74:	5e048593          	addi	a1,s1,1504
    5e78:	f8000893          	li	a7,-128
    5e7c:	00200813          	li	a6,2
    5e80:	00100793          	li	a5,1
    5e84:	01000713          	li	a4,16
    5e88:	03000693          	li	a3,48
    5e8c:	03000613          	li	a2,48
    5e90:	5e040513          	addi	a0,s0,1504
    5e94:	00612023          	sw	t1,0(sp)
    5e98:	bddff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 24, 24, 16, 32, -128, -128, pd_w4, pd_b4, pd_m4, pd_s4);
    5e9c:	00046337          	lui	t1,0x46
    5ea0:	20030313          	addi	t1,t1,512 # 46200 <pd_s4>
    5ea4:	000468b7          	lui	a7,0x46
    5ea8:	00046837          	lui	a6,0x46
    5eac:	000467b7          	lui	a5,0x46
    5eb0:	28088893          	addi	a7,a7,640 # 46280 <pd_m4>
    5eb4:	30080813          	addi	a6,a6,768 # 46300 <pd_b4>
    5eb8:	38078793          	addi	a5,a5,896 # 46380 <pd_w4>
    5ebc:	f8000713          	li	a4,-128
    5ec0:	02000693          	li	a3,32
    5ec4:	01000613          	li	a2,16
    5ec8:	01800593          	li	a1,24
    5ecc:	01800513          	li	a0,24
    5ed0:	00612023          	sw	t1,0(sp)
    5ed4:	9e9ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 24, 24, 32, 1, 1, -128, -128, pd_w5, pd_b5, pd_m5, pd_s5);
    5ed8:	00046337          	lui	t1,0x46
    5edc:	f6030313          	addi	t1,t1,-160 # 45f60 <pd_s5>
    5ee0:	00612623          	sw	t1,12(sp)
    5ee4:	00046337          	lui	t1,0x46
    5ee8:	fe030313          	addi	t1,t1,-32 # 45fe0 <pd_m5>
    5eec:	00612423          	sw	t1,8(sp)
    5ef0:	00046337          	lui	t1,0x46
    5ef4:	06030313          	addi	t1,t1,96 # 46060 <pd_b5>
    5ef8:	00612223          	sw	t1,4(sp)
    5efc:	00046337          	lui	t1,0x46
    5f00:	0e030313          	addi	t1,t1,224 # 460e0 <pd_w5>
    5f04:	5e048593          	addi	a1,s1,1504
    5f08:	f8000893          	li	a7,-128
    5f0c:	00100813          	li	a6,1
    5f10:	00100793          	li	a5,1
    5f14:	02000713          	li	a4,32
    5f18:	01800693          	li	a3,24
    5f1c:	01800613          	li	a2,24
    5f20:	5e040513          	addi	a0,s0,1504
    5f24:	00612023          	sw	t1,0(sp)
    5f28:	b4dff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 24, 24, 32, 32, -128, -128, pd_w6, pd_b6, pd_m6, pd_s6);
    5f2c:	00046337          	lui	t1,0x46
    5f30:	9e030313          	addi	t1,t1,-1568 # 459e0 <pd_s6>
    5f34:	000468b7          	lui	a7,0x46
    5f38:	00046837          	lui	a6,0x46
    5f3c:	000467b7          	lui	a5,0x46
    5f40:	a6088893          	addi	a7,a7,-1440 # 45a60 <pd_m6>
    5f44:	ae080813          	addi	a6,a6,-1312 # 45ae0 <pd_b6>
    5f48:	b6078793          	addi	a5,a5,-1184 # 45b60 <pd_w6>
    5f4c:	f8000713          	li	a4,-128
    5f50:	02000693          	li	a3,32
    5f54:	02000613          	li	a2,32
    5f58:	01800593          	li	a1,24
    5f5c:	01800513          	li	a0,24
    5f60:	00612023          	sw	t1,0(sp)
    5f64:	959ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 24, 24, 32, 1, 2, -128, -128, pd_w7, pd_b7, pd_m7, pd_s7);
    5f68:	00045337          	lui	t1,0x45
    5f6c:	74030313          	addi	t1,t1,1856 # 45740 <pd_s7>
    5f70:	00612623          	sw	t1,12(sp)
    5f74:	00045337          	lui	t1,0x45
    5f78:	7c030313          	addi	t1,t1,1984 # 457c0 <pd_m7>
    5f7c:	00612423          	sw	t1,8(sp)
    5f80:	00046337          	lui	t1,0x46
    5f84:	84030313          	addi	t1,t1,-1984 # 45840 <pd_b7>
    5f88:	00612223          	sw	t1,4(sp)
    5f8c:	00046337          	lui	t1,0x46
    5f90:	8c030313          	addi	t1,t1,-1856 # 458c0 <pd_w7>
    5f94:	5e048593          	addi	a1,s1,1504
    5f98:	f8000893          	li	a7,-128
    5f9c:	00200813          	li	a6,2
    5fa0:	00100793          	li	a5,1
    5fa4:	02000713          	li	a4,32
    5fa8:	01800693          	li	a3,24
    5fac:	01800613          	li	a2,24
    5fb0:	5e040513          	addi	a0,s0,1504
    5fb4:	00612023          	sw	t1,0(sp)
    5fb8:	abdff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 12, 12, 32, 64, -128, -128, pd_w8, pd_b8, pd_m8, pd_s8);
    5fbc:	00045337          	lui	t1,0x45
    5fc0:	c4030313          	addi	t1,t1,-960 # 44c40 <pd_s8>
    5fc4:	000458b7          	lui	a7,0x45
    5fc8:	00045837          	lui	a6,0x45
    5fcc:	000457b7          	lui	a5,0x45
    5fd0:	d4088893          	addi	a7,a7,-704 # 44d40 <pd_m8>
    5fd4:	e4080813          	addi	a6,a6,-448 # 44e40 <pd_b8>
    5fd8:	f4078793          	addi	a5,a5,-192 # 44f40 <pd_w8>
    5fdc:	f8000713          	li	a4,-128
    5fe0:	04000693          	li	a3,64
    5fe4:	02000613          	li	a2,32
    5fe8:	00c00593          	li	a1,12
    5fec:	00c00513          	li	a0,12
    5ff0:	00612023          	sw	t1,0(sp)
    5ff4:	8c9ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 12, 12, 64, 1, 1, -128, -128, pd_w9, pd_b9, pd_m9, pd_s9);
    5ff8:	00044337          	lui	t1,0x44
    5ffc:	70030313          	addi	t1,t1,1792 # 44700 <pd_s9>
    6000:	00612623          	sw	t1,12(sp)
    6004:	00045337          	lui	t1,0x45
    6008:	80030313          	addi	t1,t1,-2048 # 44800 <pd_m9>
    600c:	00612423          	sw	t1,8(sp)
    6010:	00045337          	lui	t1,0x45
    6014:	90030313          	addi	t1,t1,-1792 # 44900 <pd_b9>
    6018:	00612223          	sw	t1,4(sp)
    601c:	00045337          	lui	t1,0x45
    6020:	a0030313          	addi	t1,t1,-1536 # 44a00 <pd_w9>
    6024:	5e048593          	addi	a1,s1,1504
    6028:	f8000893          	li	a7,-128
    602c:	00100813          	li	a6,1
    6030:	00100793          	li	a5,1
    6034:	04000713          	li	a4,64
    6038:	00c00693          	li	a3,12
    603c:	00c00613          	li	a2,12
    6040:	5e040513          	addi	a0,s0,1504
    6044:	00612023          	sw	t1,0(sp)
    6048:	a2dff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 12, 12, 64, 64, -128, -128, pd_w10, pd_b10, pd_m10, pd_s10);
    604c:	00043337          	lui	t1,0x43
    6050:	40030313          	addi	t1,t1,1024 # 43400 <pd_s10>
    6054:	000438b7          	lui	a7,0x43
    6058:	00043837          	lui	a6,0x43
    605c:	000437b7          	lui	a5,0x43
    6060:	50088893          	addi	a7,a7,1280 # 43500 <pd_m10>
    6064:	60080813          	addi	a6,a6,1536 # 43600 <pd_b10>
    6068:	70078793          	addi	a5,a5,1792 # 43700 <pd_w10>
    606c:	f8000713          	li	a4,-128
    6070:	04000693          	li	a3,64
    6074:	04000613          	li	a2,64
    6078:	00c00593          	li	a1,12
    607c:	00c00513          	li	a0,12
    6080:	00612023          	sw	t1,0(sp)
    6084:	839ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 12, 12, 64, 1, 2, -128, -128, pd_w11, pd_b11, pd_m11, pd_s11);
    6088:	00043337          	lui	t1,0x43
    608c:	ec030313          	addi	t1,t1,-320 # 42ec0 <pd_s11>
    6090:	00612623          	sw	t1,12(sp)
    6094:	00043337          	lui	t1,0x43
    6098:	fc030313          	addi	t1,t1,-64 # 42fc0 <pd_m11>
    609c:	00612423          	sw	t1,8(sp)
    60a0:	00043337          	lui	t1,0x43
    60a4:	0c030313          	addi	t1,t1,192 # 430c0 <pd_b11>
    60a8:	00612223          	sw	t1,4(sp)
    60ac:	00043337          	lui	t1,0x43
    60b0:	1c030313          	addi	t1,t1,448 # 431c0 <pd_w11>
    60b4:	5e048593          	addi	a1,s1,1504
    60b8:	f8000893          	li	a7,-128
    60bc:	00200813          	li	a6,2
    60c0:	00100793          	li	a5,1
    60c4:	04000713          	li	a4,64
    60c8:	00c00693          	li	a3,12
    60cc:	00c00613          	li	a2,12
    60d0:	5e040513          	addi	a0,s0,1504
    60d4:	00612023          	sw	t1,0(sp)
    60d8:	99dff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 64, 128, -128, -128, pd_w12, pd_b12, pd_m12, pd_s12);
    60dc:	00041337          	lui	t1,0x41
    60e0:	8c030313          	addi	t1,t1,-1856 # 408c0 <pd_s12>
    60e4:	000418b7          	lui	a7,0x41
    60e8:	00041837          	lui	a6,0x41
    60ec:	000417b7          	lui	a5,0x41
    60f0:	ac088893          	addi	a7,a7,-1344 # 40ac0 <pd_m12>
    60f4:	cc080813          	addi	a6,a6,-832 # 40cc0 <pd_b12>
    60f8:	ec078793          	addi	a5,a5,-320 # 40ec0 <pd_w12>
    60fc:	f8000713          	li	a4,-128
    6100:	08000693          	li	a3,128
    6104:	04000613          	li	a2,64
    6108:	00600593          	li	a1,6
    610c:	00600513          	li	a0,6
    6110:	00612023          	sw	t1,0(sp)
    6114:	fa8ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w13, pd_b13, pd_m13, pd_s13);
    6118:	00040337          	lui	t1,0x40
    611c:	e4030313          	addi	t1,t1,-448 # 3fe40 <pd_s13>
    6120:	00612623          	sw	t1,12(sp)
    6124:	00040337          	lui	t1,0x40
    6128:	04030313          	addi	t1,t1,64 # 40040 <pd_m13>
    612c:	00612423          	sw	t1,8(sp)
    6130:	00040337          	lui	t1,0x40
    6134:	24030313          	addi	t1,t1,576 # 40240 <pd_b13>
    6138:	00612223          	sw	t1,4(sp)
    613c:	00040337          	lui	t1,0x40
    6140:	44030313          	addi	t1,t1,1088 # 40440 <pd_w13>
    6144:	5e048593          	addi	a1,s1,1504
    6148:	f8000893          	li	a7,-128
    614c:	00100813          	li	a6,1
    6150:	00100793          	li	a5,1
    6154:	08000713          	li	a4,128
    6158:	00600693          	li	a3,6
    615c:	00600613          	li	a2,6
    6160:	5e040513          	addi	a0,s0,1504
    6164:	00612023          	sw	t1,0(sp)
    6168:	90dff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w14, pd_b14, pd_m14, pd_s14);
    616c:	0003c337          	lui	t1,0x3c
    6170:	84030313          	addi	t1,t1,-1984 # 3b840 <pd_s14>
    6174:	0003c8b7          	lui	a7,0x3c
    6178:	0003c837          	lui	a6,0x3c
    617c:	0003c7b7          	lui	a5,0x3c
    6180:	a4088893          	addi	a7,a7,-1472 # 3ba40 <pd_m14>
    6184:	c4080813          	addi	a6,a6,-960 # 3bc40 <pd_b14>
    6188:	e4078793          	addi	a5,a5,-448 # 3be40 <pd_w14>
    618c:	f8000713          	li	a4,-128
    6190:	08000693          	li	a3,128
    6194:	08000613          	li	a2,128
    6198:	00600593          	li	a1,6
    619c:	00600513          	li	a0,6
    61a0:	00612023          	sw	t1,0(sp)
    61a4:	f18ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w15, pd_b15, pd_m15, pd_s15);
    61a8:	0003b337          	lui	t1,0x3b
    61ac:	dc030313          	addi	t1,t1,-576 # 3adc0 <pd_s15>
    61b0:	00612623          	sw	t1,12(sp)
    61b4:	0003b337          	lui	t1,0x3b
    61b8:	fc030313          	addi	t1,t1,-64 # 3afc0 <pd_m15>
    61bc:	00612423          	sw	t1,8(sp)
    61c0:	0003b337          	lui	t1,0x3b
    61c4:	1c030313          	addi	t1,t1,448 # 3b1c0 <pd_b15>
    61c8:	00612223          	sw	t1,4(sp)
    61cc:	0003b337          	lui	t1,0x3b
    61d0:	3c030313          	addi	t1,t1,960 # 3b3c0 <pd_w15>
    61d4:	5e048593          	addi	a1,s1,1504
    61d8:	f8000893          	li	a7,-128
    61dc:	00100813          	li	a6,1
    61e0:	00100793          	li	a5,1
    61e4:	08000713          	li	a4,128
    61e8:	00600693          	li	a3,6
    61ec:	00600613          	li	a2,6
    61f0:	5e040513          	addi	a0,s0,1504
    61f4:	00612023          	sw	t1,0(sp)
    61f8:	87dff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w16, pd_b16, pd_m16, pd_s16);
    61fc:	00036337          	lui	t1,0x36
    6200:	7c030313          	addi	t1,t1,1984 # 367c0 <pd_s16>
    6204:	000378b7          	lui	a7,0x37
    6208:	00037837          	lui	a6,0x37
    620c:	000377b7          	lui	a5,0x37
    6210:	9c088893          	addi	a7,a7,-1600 # 369c0 <pd_m16>
    6214:	bc080813          	addi	a6,a6,-1088 # 36bc0 <pd_b16>
    6218:	dc078793          	addi	a5,a5,-576 # 36dc0 <pd_w16>
    621c:	f8000713          	li	a4,-128
    6220:	08000693          	li	a3,128
    6224:	08000613          	li	a2,128
    6228:	00600593          	li	a1,6
    622c:	00600513          	li	a0,6
    6230:	00612023          	sw	t1,0(sp)
    6234:	e88ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w17, pd_b17, pd_m17, pd_s17);
    6238:	00036337          	lui	t1,0x36
    623c:	d4030313          	addi	t1,t1,-704 # 35d40 <pd_s17>
    6240:	00612623          	sw	t1,12(sp)
    6244:	00036337          	lui	t1,0x36
    6248:	f4030313          	addi	t1,t1,-192 # 35f40 <pd_m17>
    624c:	00612423          	sw	t1,8(sp)
    6250:	00036337          	lui	t1,0x36
    6254:	14030313          	addi	t1,t1,320 # 36140 <pd_b17>
    6258:	00612223          	sw	t1,4(sp)
    625c:	00036337          	lui	t1,0x36
    6260:	34030313          	addi	t1,t1,832 # 36340 <pd_w17>
    6264:	5e048593          	addi	a1,s1,1504
    6268:	f8000893          	li	a7,-128
    626c:	00100813          	li	a6,1
    6270:	00100793          	li	a5,1
    6274:	08000713          	li	a4,128
    6278:	00600693          	li	a3,6
    627c:	00600613          	li	a2,6
    6280:	5e040513          	addi	a0,s0,1504
    6284:	00612023          	sw	t1,0(sp)
    6288:	fecff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w18, pd_b18, pd_m18, pd_s18);
    628c:	00031337          	lui	t1,0x31
    6290:	74030313          	addi	t1,t1,1856 # 31740 <pd_s18>
    6294:	000328b7          	lui	a7,0x32
    6298:	00032837          	lui	a6,0x32
    629c:	000327b7          	lui	a5,0x32
    62a0:	94088893          	addi	a7,a7,-1728 # 31940 <pd_m18>
    62a4:	b4080813          	addi	a6,a6,-1216 # 31b40 <pd_b18>
    62a8:	d4078793          	addi	a5,a5,-704 # 31d40 <pd_w18>
    62ac:	f8000713          	li	a4,-128
    62b0:	08000693          	li	a3,128
    62b4:	08000613          	li	a2,128
    62b8:	00600593          	li	a1,6
    62bc:	00600513          	li	a0,6
    62c0:	00612023          	sw	t1,0(sp)
    62c4:	df8ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w19, pd_b19, pd_m19, pd_s19);
    62c8:	00031337          	lui	t1,0x31
    62cc:	cc030313          	addi	t1,t1,-832 # 30cc0 <pd_s19>
    62d0:	00612623          	sw	t1,12(sp)
    62d4:	00031337          	lui	t1,0x31
    62d8:	ec030313          	addi	t1,t1,-320 # 30ec0 <pd_m19>
    62dc:	00612423          	sw	t1,8(sp)
    62e0:	00031337          	lui	t1,0x31
    62e4:	0c030313          	addi	t1,t1,192 # 310c0 <pd_b19>
    62e8:	00612223          	sw	t1,4(sp)
    62ec:	00031337          	lui	t1,0x31
    62f0:	2c030313          	addi	t1,t1,704 # 312c0 <pd_w19>
    62f4:	5e048593          	addi	a1,s1,1504
    62f8:	f8000893          	li	a7,-128
    62fc:	00100813          	li	a6,1
    6300:	00100793          	li	a5,1
    6304:	08000713          	li	a4,128
    6308:	00600693          	li	a3,6
    630c:	00600613          	li	a2,6
    6310:	5e040513          	addi	a0,s0,1504
    6314:	00612023          	sw	t1,0(sp)
    6318:	f5cff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w20, pd_b20, pd_m20, pd_s20);
    631c:	0002c337          	lui	t1,0x2c
    6320:	6c030313          	addi	t1,t1,1728 # 2c6c0 <pd_s20>
    6324:	0002d8b7          	lui	a7,0x2d
    6328:	0002d837          	lui	a6,0x2d
    632c:	0002d7b7          	lui	a5,0x2d
    6330:	8c088893          	addi	a7,a7,-1856 # 2c8c0 <pd_m20>
    6334:	ac080813          	addi	a6,a6,-1344 # 2cac0 <pd_b20>
    6338:	cc078793          	addi	a5,a5,-832 # 2ccc0 <pd_w20>
    633c:	f8000713          	li	a4,-128
    6340:	08000693          	li	a3,128
    6344:	08000613          	li	a2,128
    6348:	00600593          	li	a1,6
    634c:	00600513          	li	a0,6
    6350:	00612023          	sw	t1,0(sp)
    6354:	d68ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w21, pd_b21, pd_m21, pd_s21);
    6358:	0002c337          	lui	t1,0x2c
    635c:	c4030313          	addi	t1,t1,-960 # 2bc40 <pd_s21>
    6360:	00612623          	sw	t1,12(sp)
    6364:	0002c337          	lui	t1,0x2c
    6368:	e4030313          	addi	t1,t1,-448 # 2be40 <pd_m21>
    636c:	00612423          	sw	t1,8(sp)
    6370:	0002c337          	lui	t1,0x2c
    6374:	04030313          	addi	t1,t1,64 # 2c040 <pd_b21>
    6378:	00612223          	sw	t1,4(sp)
    637c:	0002c337          	lui	t1,0x2c
    6380:	24030313          	addi	t1,t1,576 # 2c240 <pd_w21>
    6384:	5e048593          	addi	a1,s1,1504
    6388:	f8000893          	li	a7,-128
    638c:	00100813          	li	a6,1
    6390:	00100793          	li	a5,1
    6394:	08000713          	li	a4,128
    6398:	00600693          	li	a3,6
    639c:	00600613          	li	a2,6
    63a0:	5e040513          	addi	a0,s0,1504
    63a4:	00612023          	sw	t1,0(sp)
    63a8:	eccff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w22, pd_b22, pd_m22, pd_s22);
    63ac:	00027337          	lui	t1,0x27
    63b0:	64030313          	addi	t1,t1,1600 # 27640 <pd_s22>
    63b4:	000288b7          	lui	a7,0x28
    63b8:	00028837          	lui	a6,0x28
    63bc:	000287b7          	lui	a5,0x28
    63c0:	84088893          	addi	a7,a7,-1984 # 27840 <pd_m22>
    63c4:	a4080813          	addi	a6,a6,-1472 # 27a40 <pd_b22>
    63c8:	c4078793          	addi	a5,a5,-960 # 27c40 <pd_w22>
    63cc:	f8000713          	li	a4,-128
    63d0:	08000693          	li	a3,128
    63d4:	08000613          	li	a2,128
    63d8:	00600593          	li	a1,6
    63dc:	00600513          	li	a0,6
    63e0:	00612023          	sw	t1,0(sp)
    63e4:	cd8ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 2, -128, -128, pd_w23, pd_b23, pd_m23, pd_s23);
    63e8:	00027337          	lui	t1,0x27
    63ec:	bc030313          	addi	t1,t1,-1088 # 26bc0 <pd_s23>
    63f0:	00612623          	sw	t1,12(sp)
    63f4:	00027337          	lui	t1,0x27
    63f8:	dc030313          	addi	t1,t1,-576 # 26dc0 <pd_m23>
    63fc:	00612423          	sw	t1,8(sp)
    6400:	00027337          	lui	t1,0x27
    6404:	fc030313          	addi	t1,t1,-64 # 26fc0 <pd_b23>
    6408:	00612223          	sw	t1,4(sp)
    640c:	00027337          	lui	t1,0x27
    6410:	1c030313          	addi	t1,t1,448 # 271c0 <pd_w23>
    6414:	5e048593          	addi	a1,s1,1504
    6418:	f8000893          	li	a7,-128
    641c:	00200813          	li	a6,2
    6420:	00100793          	li	a5,1
    6424:	08000713          	li	a4,128
    6428:	00600693          	li	a3,6
    642c:	00600613          	li	a2,6
    6430:	5e040513          	addi	a0,s0,1504
    6434:	00612023          	sw	t1,0(sp)
    6438:	e3cff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 3, 3, 128, 256, -128, -128, pd_w24, pd_b24, pd_m24, pd_s24);
    643c:	0001e337          	lui	t1,0x1e
    6440:	fc030313          	addi	t1,t1,-64 # 1dfc0 <pd_s24>
    6444:	0001e8b7          	lui	a7,0x1e
    6448:	0001e837          	lui	a6,0x1e
    644c:	0001f7b7          	lui	a5,0x1f
    6450:	3c088893          	addi	a7,a7,960 # 1e3c0 <pd_m24>
    6454:	7c080813          	addi	a6,a6,1984 # 1e7c0 <pd_b24>
    6458:	bc078793          	addi	a5,a5,-1088 # 1ebc0 <pd_w24>
    645c:	f8000713          	li	a4,-128
    6460:	10000693          	li	a3,256
    6464:	08000613          	li	a2,128
    6468:	00300593          	li	a1,3
    646c:	00300513          	li	a0,3
    6470:	00612023          	sw	t1,0(sp)
    6474:	c48ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 3, 3, 256, 1, 1, -128, -128, pd_w25, pd_b25, pd_m25, pd_s25);
    6478:	0001d337          	lui	t1,0x1d
    647c:	ac030313          	addi	t1,t1,-1344 # 1cac0 <pd_s25>
    6480:	00612623          	sw	t1,12(sp)
    6484:	0001d337          	lui	t1,0x1d
    6488:	ec030313          	addi	t1,t1,-320 # 1cec0 <pd_m25>
    648c:	00612423          	sw	t1,8(sp)
    6490:	0001d337          	lui	t1,0x1d
    6494:	2c030313          	addi	t1,t1,704 # 1d2c0 <pd_b25>
    6498:	00612223          	sw	t1,4(sp)
    649c:	0001d337          	lui	t1,0x1d
    64a0:	6c030313          	addi	t1,t1,1728 # 1d6c0 <pd_w25>
    64a4:	5e048593          	addi	a1,s1,1504
    64a8:	00612023          	sw	t1,0(sp)
    64ac:	f8000893          	li	a7,-128
    64b0:	00100813          	li	a6,1
    64b4:	00100793          	li	a5,1
    64b8:	10000713          	li	a4,256
    64bc:	00300693          	li	a3,3
    64c0:	00300613          	li	a2,3
    64c4:	5e040513          	addi	a0,s0,1504
    64c8:	dacff0ef          	jal	ra,5a74 <dw3.constprop.2>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 3, 3, 256, 256, -128, -128, pd_w26, pd_b26, pd_m26, pd_s26);
    64cc:	0000c7b7          	lui	a5,0xc
    64d0:	ec078793          	addi	a5,a5,-320 # bec0 <pd_s26>
    64d4:	00f12023          	sw	a5,0(sp)
    64d8:	0000c8b7          	lui	a7,0xc
    64dc:	0000c837          	lui	a6,0xc
    64e0:	0000d7b7          	lui	a5,0xd
    64e4:	2c088893          	addi	a7,a7,704 # c2c0 <pd_m26>
    64e8:	6c080813          	addi	a6,a6,1728 # c6c0 <pd_b26>
    64ec:	ac078793          	addi	a5,a5,-1344 # cac0 <pd_w26>
    64f0:	f8000713          	li	a4,-128
    64f4:	00300513          	li	a0,3
    64f8:	10000693          	li	a3,256
    64fc:	10000613          	li	a2,256
    6500:	00300593          	li	a1,3
    6504:	bb8ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    avgpool_valid3(src, dst, 256, -128, -128, 1908874354, -3);
    6508:	000017b7          	lui	a5,0x1
    650c:	5e040a13          	addi	s4,s0,1504
    6510:	90078713          	addi	a4,a5,-1792 # 900 <CUSTOM2+0x8a5>
    6514:	fffff837          	lui	a6,0xfffff
    6518:	a0078793          	addi	a5,a5,-1536
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    651c:	71c72537          	lui	a0,0x71c72
    6520:	00ea0733          	add	a4,s4,a4
    6524:	00fa08b3          	add	a7,s4,a5
    6528:	5e048493          	addi	s1,s1,1504
    652c:	70080813          	addi	a6,a6,1792 # fffff700 <__freertos_irq_stack_top+0xfff95110>
            for (x = 0; x < 3; x++)
    6530:	00300e93          	li	t4,3
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    6534:	c7250513          	addi	a0,a0,-910 # 71c71c72 <__freertos_irq_stack_top+0x71c07682>
    6538:	40000e37          	lui	t3,0x40000
        dst[c] = sat8(qapply(acc, mult, shift) + ozp);
    653c:	07f00313          	li	t1,127
    6540:	010706b3          	add	a3,a4,a6
        int32_t acc = 0;
    6544:	00000793          	li	a5,0
{
    6548:	00068593          	mv	a1,a3
            for (x = 0; x < 3; x++)
    654c:	00000613          	li	a2,0
                acc += src[(y * 3 + x) * ic + c] - izp;
    6550:	00058f03          	lb	t5,0(a1)
            for (x = 0; x < 3; x++)
    6554:	00160613          	addi	a2,a2,1
    6558:	10058593          	addi	a1,a1,256
                acc += src[(y * 3 + x) * ic + c] - izp;
    655c:	080f0f13          	addi	t5,t5,128
    6560:	01e787b3          	add	a5,a5,t5
            for (x = 0; x < 3; x++)
    6564:	ffd616e3          	bne	a2,t4,6550 <pdti8_run+0x818>
    6568:	30068693          	addi	a3,a3,768 # 40000300 <__freertos_irq_stack_top+0x3ff95d10>
        for (y = 0; y < 3; y++)
    656c:	fcd71ee3          	bne	a4,a3,6548 <pdti8_run+0x810>
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    6570:	02a786b3          	mul	a3,a5,a0
        dst[c] = sat8(qapply(acc, mult, shift) + ozp);
    6574:	414705b3          	sub	a1,a4,s4
    6578:	010585b3          	add	a1,a1,a6
    657c:	00b485b3          	add	a1,s1,a1
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    6580:	02a79633          	mulh	a2,a5,a0
    6584:	01c687b3          	add	a5,a3,t3
    6588:	00d7b6b3          	sltu	a3,a5,a3
    int32_t h = (int32_t)(ab >> 31);
    658c:	01f7d793          	srli	a5,a5,0x1f
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    6590:	00c686b3          	add	a3,a3,a2
    int32_t h = (int32_t)(ab >> 31);
    6594:	00169693          	slli	a3,a3,0x1
    6598:	00f6e7b3          	or	a5,a3,a5
        return h >> (-shift);
    659c:	4037d793          	srai	a5,a5,0x3
        dst[c] = sat8(qapply(acc, mult, shift) + ozp);
    65a0:	f8078793          	addi	a5,a5,-128
    65a4:	00f35463          	bge	t1,a5,65ac <pdti8_run+0x874>
    65a8:	07f00793          	li	a5,127
    65ac:	00f58023          	sb	a5,0(a1)
    65b0:	00170713          	addi	a4,a4,1
    for (c = 0; c < ic; c++) {
    65b4:	f8e896e3          	bne	a7,a4,6540 <pdti8_run+0x808>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 1, 1, 256, 2, -128, -1, pd_w28, pd_b28, pd_m28, pd_s28);
    65b8:	81c18793          	addi	a5,gp,-2020 # 46bd4 <pd_s28>
    65bc:	00f12023          	sw	a5,0(sp)
    65c0:	0000c7b7          	lui	a5,0xc
    65c4:	cc078793          	addi	a5,a5,-832 # bcc0 <pd_w28>
    65c8:	82418893          	addi	a7,gp,-2012 # 46bdc <pd_m28>
    65cc:	82c18813          	addi	a6,gp,-2004 # 46be4 <pd_b28>
    65d0:	fff00713          	li	a4,-1
    65d4:	00200693          	li	a3,2
    65d8:	10000613          	li	a2,256
    65dc:	00100593          	li	a1,1
    65e0:	00100513          	li	a0,1
    65e4:	ad8ff0ef          	jal	ra,58bc <conv1x1.constprop.1>
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    *no_person = src[0];
    65e8:	5e040783          	lb	a5,1504(s0)
    65ec:	00f98023          	sb	a5,0(s3)
    *person = src[1];
    65f0:	001a0783          	lb	a5,1(s4) # 40000001 <__freertos_irq_stack_top+0x3ff95a11>
    65f4:	00f90023          	sb	a5,0(s2)
}
    65f8:	02c12083          	lw	ra,44(sp)
    65fc:	02812403          	lw	s0,40(sp)
    6600:	02412483          	lw	s1,36(sp)
    6604:	02012903          	lw	s2,32(sp)
    6608:	01c12983          	lw	s3,28(sp)
    660c:	01812a03          	lw	s4,24(sp)
    6610:	03010113          	addi	sp,sp,48
    6614:	00008067          	ret
