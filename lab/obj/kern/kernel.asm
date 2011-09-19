
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 00 11 00 	lgdtl  0x110018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 60 00 00 00       	call   f010009d <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>
	...

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 c0 19 10 f0 	movl   $0xf01019c0,(%esp)
f0100055:	e8 d0 08 00 00       	call   f010092a <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 05 07 00 00       	call   f010078c <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 19 10 f0 	movl   $0xf01019dc,(%esp)
f0100092:	e8 93 08 00 00       	call   f010092a <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 80 09 11 f0       	mov    $0xf0110980,%eax
f01000a8:	2d 20 03 11 f0       	sub    $0xf0110320,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 20 03 11 f0 	movl   $0xf0110320,(%esp)
f01000c0:	e8 2c 14 00 00       	call   f01014f1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 98 04 00 00       	call   f0100562 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 19 10 f0 	movl   $0xf01019f7,(%esp)
f01000d9:	e8 4c 08 00 00       	call   f010092a <cprintf>




	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 a0 06 00 00       	call   f0100796 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f01000fe:	83 3d 20 03 11 f0 00 	cmpl   $0x0,0xf0110320
f0100105:	75 40                	jne    f0100147 <_panic+0x4f>
		goto dead;
	panicstr = fmt;
f0100107:	8b 45 10             	mov    0x10(%ebp),%eax
f010010a:	a3 20 03 11 f0       	mov    %eax,0xf0110320

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f010010f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100112:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100116:	8b 45 08             	mov    0x8(%ebp),%eax
f0100119:	89 44 24 04          	mov    %eax,0x4(%esp)
f010011d:	c7 04 24 12 1a 10 f0 	movl   $0xf0101a12,(%esp)
f0100124:	e8 01 08 00 00       	call   f010092a <cprintf>

	if (panicstr)
		goto dead;
	panicstr = fmt;

	va_start(ap, fmt);
f0100129:	8d 45 14             	lea    0x14(%ebp),%eax
	cprintf("kernel panic at %s:%d: ", file, line);
	vcprintf(fmt, ap);
f010012c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100130:	8b 45 10             	mov    0x10(%ebp),%eax
f0100133:	89 04 24             	mov    %eax,(%esp)
f0100136:	e8 bc 07 00 00       	call   f01008f7 <vcprintf>
	cprintf("\n");
f010013b:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100142:	e8 e3 07 00 00       	call   f010092a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100147:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010014e:	e8 43 06 00 00       	call   f0100796 <monitor>
f0100153:	eb f2                	jmp    f0100147 <_panic+0x4f>

f0100155 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100155:	55                   	push   %ebp
f0100156:	89 e5                	mov    %esp,%ebp
f0100158:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f010015b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010015e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100162:	8b 45 08             	mov    0x8(%ebp),%eax
f0100165:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100169:	c7 04 24 2a 1a 10 f0 	movl   $0xf0101a2a,(%esp)
f0100170:	e8 b5 07 00 00       	call   f010092a <cprintf>
void
_warn(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	va_start(ap, fmt);
f0100175:	8d 45 14             	lea    0x14(%ebp),%eax
	cprintf("kernel warning at %s:%d: ", file, line);
	vcprintf(fmt, ap);
f0100178:	89 44 24 04          	mov    %eax,0x4(%esp)
f010017c:	8b 45 10             	mov    0x10(%ebp),%eax
f010017f:	89 04 24             	mov    %eax,(%esp)
f0100182:	e8 70 07 00 00       	call   f01008f7 <vcprintf>
	cprintf("\n");
f0100187:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f010018e:	e8 97 07 00 00       	call   f010092a <cprintf>
	va_end(ap);
}
f0100193:	c9                   	leave  
f0100194:	c3                   	ret    
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
f01001b7:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001be:	f6 c2 01             	test   $0x1,%dl
f01001c1:	74 09                	je     f01001cc <serial_proc_data+0x1e>
f01001c3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001c8:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c9:	0f b6 c0             	movzbl %al,%eax
}
f01001cc:	5d                   	pop    %ebp
f01001cd:	c3                   	ret    

f01001ce <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ce:	55                   	push   %ebp
f01001cf:	89 e5                	mov    %esp,%ebp
f01001d1:	53                   	push   %ebx
f01001d2:	83 ec 04             	sub    $0x4,%esp
f01001d5:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d7:	eb 25                	jmp    f01001fe <cons_intr+0x30>
		if (c == 0)
f01001d9:	85 c0                	test   %eax,%eax
f01001db:	74 21                	je     f01001fe <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001dd:	8b 15 64 05 11 f0    	mov    0xf0110564,%edx
f01001e3:	88 82 60 03 11 f0    	mov    %al,-0xfeefca0(%edx)
f01001e9:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001ec:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001f1:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f6:	0f 44 c2             	cmove  %edx,%eax
f01001f9:	a3 64 05 11 f0       	mov    %eax,0xf0110564
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fe:	ff d3                	call   *%ebx
f0100200:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100203:	75 d4                	jne    f01001d9 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100205:	83 c4 04             	add    $0x4,%esp
f0100208:	5b                   	pop    %ebx
f0100209:	5d                   	pop    %ebp
f010020a:	c3                   	ret    

f010020b <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020b:	55                   	push   %ebp
f010020c:	89 e5                	mov    %esp,%ebp
f010020e:	57                   	push   %edi
f010020f:	56                   	push   %esi
f0100210:	53                   	push   %ebx
f0100211:	83 ec 2c             	sub    $0x2c,%esp
f0100214:	89 c7                	mov    %eax,%edi
f0100216:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010021b:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010021c:	a8 20                	test   $0x20,%al
f010021e:	75 1b                	jne    f010023b <cons_putc+0x30>
f0100220:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100225:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f010022a:	e8 71 ff ff ff       	call   f01001a0 <delay>
f010022f:	89 f2                	mov    %esi,%edx
f0100231:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100232:	a8 20                	test   $0x20,%al
f0100234:	75 05                	jne    f010023b <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100236:	83 eb 01             	sub    $0x1,%ebx
f0100239:	75 ef                	jne    f010022a <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010023b:	89 fa                	mov    %edi,%edx
f010023d:	89 f8                	mov    %edi,%eax
f010023f:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100242:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100247:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100248:	b2 79                	mov    $0x79,%dl
f010024a:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024b:	84 c0                	test   %al,%al
f010024d:	78 21                	js     f0100270 <cons_putc+0x65>
f010024f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100254:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100259:	e8 42 ff ff ff       	call   f01001a0 <delay>
f010025e:	89 f2                	mov    %esi,%edx
f0100260:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100261:	84 c0                	test   %al,%al
f0100263:	78 0b                	js     f0100270 <cons_putc+0x65>
f0100265:	83 c3 01             	add    $0x1,%ebx
f0100268:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f010026e:	75 e9                	jne    f0100259 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100270:	ba 78 03 00 00       	mov    $0x378,%edx
f0100275:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100279:	ee                   	out    %al,(%dx)
f010027a:	b2 7a                	mov    $0x7a,%dl
f010027c:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100281:	ee                   	out    %al,(%dx)
f0100282:	b8 08 00 00 00       	mov    $0x8,%eax
f0100287:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100288:	89 fa                	mov    %edi,%edx
f010028a:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100290:	89 f8                	mov    %edi,%eax
f0100292:	80 cc 07             	or     $0x7,%ah
f0100295:	85 d2                	test   %edx,%edx
f0100297:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010029a:	89 f8                	mov    %edi,%eax
f010029c:	25 ff 00 00 00       	and    $0xff,%eax
f01002a1:	83 f8 09             	cmp    $0x9,%eax
f01002a4:	74 78                	je     f010031e <cons_putc+0x113>
f01002a6:	83 f8 09             	cmp    $0x9,%eax
f01002a9:	7f 0b                	jg     f01002b6 <cons_putc+0xab>
f01002ab:	83 f8 08             	cmp    $0x8,%eax
f01002ae:	0f 85 9e 00 00 00    	jne    f0100352 <cons_putc+0x147>
f01002b4:	eb 12                	jmp    f01002c8 <cons_putc+0xbd>
f01002b6:	83 f8 0a             	cmp    $0xa,%eax
f01002b9:	74 3d                	je     f01002f8 <cons_putc+0xed>
f01002bb:	83 f8 0d             	cmp    $0xd,%eax
f01002be:	66 90                	xchg   %ax,%ax
f01002c0:	0f 85 8c 00 00 00    	jne    f0100352 <cons_putc+0x147>
f01002c6:	eb 38                	jmp    f0100300 <cons_putc+0xf5>
	case '\b':
		if (crt_pos > 0) {
f01002c8:	0f b7 05 40 03 11 f0 	movzwl 0xf0110340,%eax
f01002cf:	66 85 c0             	test   %ax,%ax
f01002d2:	0f 84 e4 00 00 00    	je     f01003bc <cons_putc+0x1b1>
			crt_pos--;
f01002d8:	83 e8 01             	sub    $0x1,%eax
f01002db:	66 a3 40 03 11 f0    	mov    %ax,0xf0110340
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002e1:	0f b7 c0             	movzwl %ax,%eax
f01002e4:	66 81 e7 00 ff       	and    $0xff00,%di
f01002e9:	83 cf 20             	or     $0x20,%edi
f01002ec:	8b 15 44 03 11 f0    	mov    0xf0110344,%edx
f01002f2:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f6:	eb 77                	jmp    f010036f <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f8:	66 83 05 40 03 11 f0 	addw   $0x50,0xf0110340
f01002ff:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100300:	0f b7 05 40 03 11 f0 	movzwl 0xf0110340,%eax
f0100307:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010030d:	c1 e8 16             	shr    $0x16,%eax
f0100310:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100313:	c1 e0 04             	shl    $0x4,%eax
f0100316:	66 a3 40 03 11 f0    	mov    %ax,0xf0110340
f010031c:	eb 51                	jmp    f010036f <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f010031e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100323:	e8 e3 fe ff ff       	call   f010020b <cons_putc>
		cons_putc(' ');
f0100328:	b8 20 00 00 00       	mov    $0x20,%eax
f010032d:	e8 d9 fe ff ff       	call   f010020b <cons_putc>
		cons_putc(' ');
f0100332:	b8 20 00 00 00       	mov    $0x20,%eax
f0100337:	e8 cf fe ff ff       	call   f010020b <cons_putc>
		cons_putc(' ');
f010033c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100341:	e8 c5 fe ff ff       	call   f010020b <cons_putc>
		cons_putc(' ');
f0100346:	b8 20 00 00 00       	mov    $0x20,%eax
f010034b:	e8 bb fe ff ff       	call   f010020b <cons_putc>
f0100350:	eb 1d                	jmp    f010036f <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100352:	0f b7 05 40 03 11 f0 	movzwl 0xf0110340,%eax
f0100359:	0f b7 c8             	movzwl %ax,%ecx
f010035c:	8b 15 44 03 11 f0    	mov    0xf0110344,%edx
f0100362:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100366:	83 c0 01             	add    $0x1,%eax
f0100369:	66 a3 40 03 11 f0    	mov    %ax,0xf0110340
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010036f:	66 81 3d 40 03 11 f0 	cmpw   $0x7cf,0xf0110340
f0100376:	cf 07 
f0100378:	76 42                	jbe    f01003bc <cons_putc+0x1b1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010037a:	a1 44 03 11 f0       	mov    0xf0110344,%eax
f010037f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100386:	00 
f0100387:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010038d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100391:	89 04 24             	mov    %eax,(%esp)
f0100394:	e8 b7 11 00 00       	call   f0101550 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100399:	8b 15 44 03 11 f0    	mov    0xf0110344,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010039f:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01003a4:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003aa:	83 c0 01             	add    $0x1,%eax
f01003ad:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003b2:	75 f0                	jne    f01003a4 <cons_putc+0x199>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003b4:	66 83 2d 40 03 11 f0 	subw   $0x50,0xf0110340
f01003bb:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003bc:	8b 0d 48 03 11 f0    	mov    0xf0110348,%ecx
f01003c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c7:	89 ca                	mov    %ecx,%edx
f01003c9:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003ca:	0f b7 35 40 03 11 f0 	movzwl 0xf0110340,%esi
f01003d1:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003d4:	89 f0                	mov    %esi,%eax
f01003d6:	66 c1 e8 08          	shr    $0x8,%ax
f01003da:	89 da                	mov    %ebx,%edx
f01003dc:	ee                   	out    %al,(%dx)
f01003dd:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003e2:	89 ca                	mov    %ecx,%edx
f01003e4:	ee                   	out    %al,(%dx)
f01003e5:	89 f0                	mov    %esi,%eax
f01003e7:	89 da                	mov    %ebx,%edx
f01003e9:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003ea:	83 c4 2c             	add    $0x2c,%esp
f01003ed:	5b                   	pop    %ebx
f01003ee:	5e                   	pop    %esi
f01003ef:	5f                   	pop    %edi
f01003f0:	5d                   	pop    %ebp
f01003f1:	c3                   	ret    

f01003f2 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003f2:	55                   	push   %ebp
f01003f3:	89 e5                	mov    %esp,%ebp
f01003f5:	53                   	push   %ebx
f01003f6:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f9:	ba 64 00 00 00       	mov    $0x64,%edx
f01003fe:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003ff:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100404:	a8 01                	test   $0x1,%al
f0100406:	0f 84 de 00 00 00    	je     f01004ea <kbd_proc_data+0xf8>
f010040c:	b2 60                	mov    $0x60,%dl
f010040e:	ec                   	in     (%dx),%al
f010040f:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100411:	3c e0                	cmp    $0xe0,%al
f0100413:	75 11                	jne    f0100426 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f0100415:	83 0d 68 05 11 f0 40 	orl    $0x40,0xf0110568
		return 0;
f010041c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100421:	e9 c4 00 00 00       	jmp    f01004ea <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f0100426:	84 c0                	test   %al,%al
f0100428:	79 37                	jns    f0100461 <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010042a:	8b 0d 68 05 11 f0    	mov    0xf0110568,%ecx
f0100430:	89 cb                	mov    %ecx,%ebx
f0100432:	83 e3 40             	and    $0x40,%ebx
f0100435:	83 e0 7f             	and    $0x7f,%eax
f0100438:	85 db                	test   %ebx,%ebx
f010043a:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010043d:	0f b6 d2             	movzbl %dl,%edx
f0100440:	0f b6 82 80 1a 10 f0 	movzbl -0xfefe580(%edx),%eax
f0100447:	83 c8 40             	or     $0x40,%eax
f010044a:	0f b6 c0             	movzbl %al,%eax
f010044d:	f7 d0                	not    %eax
f010044f:	21 c1                	and    %eax,%ecx
f0100451:	89 0d 68 05 11 f0    	mov    %ecx,0xf0110568
		return 0;
f0100457:	bb 00 00 00 00       	mov    $0x0,%ebx
f010045c:	e9 89 00 00 00       	jmp    f01004ea <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f0100461:	8b 0d 68 05 11 f0    	mov    0xf0110568,%ecx
f0100467:	f6 c1 40             	test   $0x40,%cl
f010046a:	74 0e                	je     f010047a <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010046c:	89 c2                	mov    %eax,%edx
f010046e:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100471:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100474:	89 0d 68 05 11 f0    	mov    %ecx,0xf0110568
	}

	shift |= shiftcode[data];
f010047a:	0f b6 d2             	movzbl %dl,%edx
f010047d:	0f b6 82 80 1a 10 f0 	movzbl -0xfefe580(%edx),%eax
f0100484:	0b 05 68 05 11 f0    	or     0xf0110568,%eax
	shift ^= togglecode[data];
f010048a:	0f b6 8a 80 1b 10 f0 	movzbl -0xfefe480(%edx),%ecx
f0100491:	31 c8                	xor    %ecx,%eax
f0100493:	a3 68 05 11 f0       	mov    %eax,0xf0110568

	c = charcode[shift & (CTL | SHIFT)][data];
f0100498:	89 c1                	mov    %eax,%ecx
f010049a:	83 e1 03             	and    $0x3,%ecx
f010049d:	8b 0c 8d 80 1c 10 f0 	mov    -0xfefe380(,%ecx,4),%ecx
f01004a4:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f01004a8:	a8 08                	test   $0x8,%al
f01004aa:	74 19                	je     f01004c5 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004ac:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004af:	83 fa 19             	cmp    $0x19,%edx
f01004b2:	77 05                	ja     f01004b9 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004b4:	83 eb 20             	sub    $0x20,%ebx
f01004b7:	eb 0c                	jmp    f01004c5 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004b9:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004bc:	8d 53 20             	lea    0x20(%ebx),%edx
f01004bf:	83 f9 19             	cmp    $0x19,%ecx
f01004c2:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004c5:	f7 d0                	not    %eax
f01004c7:	a8 06                	test   $0x6,%al
f01004c9:	75 1f                	jne    f01004ea <kbd_proc_data+0xf8>
f01004cb:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004d1:	75 17                	jne    f01004ea <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004d3:	c7 04 24 44 1a 10 f0 	movl   $0xf0101a44,(%esp)
f01004da:	e8 4b 04 00 00       	call   f010092a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004df:	ba 92 00 00 00       	mov    $0x92,%edx
f01004e4:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e9:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	83 c4 14             	add    $0x14,%esp
f01004ef:	5b                   	pop    %ebx
f01004f0:	5d                   	pop    %ebp
f01004f1:	c3                   	ret    

f01004f2 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f2:	55                   	push   %ebp
f01004f3:	89 e5                	mov    %esp,%ebp
f01004f5:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004f8:	83 3d 4c 03 11 f0 00 	cmpl   $0x0,0xf011034c
f01004ff:	74 0a                	je     f010050b <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100501:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100506:	e8 c3 fc ff ff       	call   f01001ce <cons_intr>
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100513:	b8 f2 03 10 f0       	mov    $0xf01003f2,%eax
f0100518:	e8 b1 fc ff ff       	call   f01001ce <cons_intr>
}
f010051d:	c9                   	leave  
f010051e:	c3                   	ret    

f010051f <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010051f:	55                   	push   %ebp
f0100520:	89 e5                	mov    %esp,%ebp
f0100522:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100525:	e8 c8 ff ff ff       	call   f01004f2 <serial_intr>
	kbd_intr();
f010052a:	e8 de ff ff ff       	call   f010050d <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010052f:	8b 15 60 05 11 f0    	mov    0xf0110560,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100535:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010053a:	3b 15 64 05 11 f0    	cmp    0xf0110564,%edx
f0100540:	74 1e                	je     f0100560 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f0100542:	0f b6 82 60 03 11 f0 	movzbl -0xfeefca0(%edx),%eax
f0100549:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f010054c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100552:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100557:	0f 44 d1             	cmove  %ecx,%edx
f010055a:	89 15 60 05 11 f0    	mov    %edx,0xf0110560
		return c;
	}
	return 0;
}
f0100560:	c9                   	leave  
f0100561:	c3                   	ret    

f0100562 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100562:	55                   	push   %ebp
f0100563:	89 e5                	mov    %esp,%ebp
f0100565:	57                   	push   %edi
f0100566:	56                   	push   %esi
f0100567:	53                   	push   %ebx
f0100568:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010056b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100572:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100579:	5a a5 
	if (*cp != 0xA55A) {
f010057b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100582:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100586:	74 11                	je     f0100599 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100588:	c7 05 48 03 11 f0 b4 	movl   $0x3b4,0xf0110348
f010058f:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100592:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100597:	eb 16                	jmp    f01005af <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100599:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a0:	c7 05 48 03 11 f0 d4 	movl   $0x3d4,0xf0110348
f01005a7:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005aa:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005af:	8b 0d 48 03 11 f0    	mov    0xf0110348,%ecx
f01005b5:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ba:	89 ca                	mov    %ecx,%edx
f01005bc:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005bd:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c0:	89 da                	mov    %ebx,%edx
f01005c2:	ec                   	in     (%dx),%al
f01005c3:	0f b6 f8             	movzbl %al,%edi
f01005c6:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c9:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005ce:	89 ca                	mov    %ecx,%edx
f01005d0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d1:	89 da                	mov    %ebx,%edx
f01005d3:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d4:	89 35 44 03 11 f0    	mov    %esi,0xf0110344
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005da:	0f b6 d8             	movzbl %al,%ebx
f01005dd:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005df:	66 89 3d 40 03 11 f0 	mov    %di,0xf0110340
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e6:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f0:	89 da                	mov    %ebx,%edx
f01005f2:	ee                   	out    %al,(%dx)
f01005f3:	b2 fb                	mov    $0xfb,%dl
f01005f5:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100600:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100605:	89 ca                	mov    %ecx,%edx
f0100607:	ee                   	out    %al,(%dx)
f0100608:	b2 f9                	mov    $0xf9,%dl
f010060a:	b8 00 00 00 00       	mov    $0x0,%eax
f010060f:	ee                   	out    %al,(%dx)
f0100610:	b2 fb                	mov    $0xfb,%dl
f0100612:	b8 03 00 00 00       	mov    $0x3,%eax
f0100617:	ee                   	out    %al,(%dx)
f0100618:	b2 fc                	mov    $0xfc,%dl
f010061a:	b8 00 00 00 00       	mov    $0x0,%eax
f010061f:	ee                   	out    %al,(%dx)
f0100620:	b2 f9                	mov    $0xf9,%dl
f0100622:	b8 01 00 00 00       	mov    $0x1,%eax
f0100627:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100628:	b2 fd                	mov    $0xfd,%dl
f010062a:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062b:	3c ff                	cmp    $0xff,%al
f010062d:	0f 95 c0             	setne  %al
f0100630:	0f b6 c0             	movzbl %al,%eax
f0100633:	89 c6                	mov    %eax,%esi
f0100635:	a3 4c 03 11 f0       	mov    %eax,0xf011034c
f010063a:	89 da                	mov    %ebx,%edx
f010063c:	ec                   	in     (%dx),%al
f010063d:	89 ca                	mov    %ecx,%edx
f010063f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100640:	85 f6                	test   %esi,%esi
f0100642:	75 0c                	jne    f0100650 <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f0100644:	c7 04 24 50 1a 10 f0 	movl   $0xf0101a50,(%esp)
f010064b:	e8 da 02 00 00       	call   f010092a <cprintf>
}
f0100650:	83 c4 1c             	add    $0x1c,%esp
f0100653:	5b                   	pop    %ebx
f0100654:	5e                   	pop    %esi
f0100655:	5f                   	pop    %edi
f0100656:	5d                   	pop    %ebp
f0100657:	c3                   	ret    

f0100658 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100658:	55                   	push   %ebp
f0100659:	89 e5                	mov    %esp,%ebp
f010065b:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010065e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100661:	e8 a5 fb ff ff       	call   f010020b <cons_putc>
}
f0100666:	c9                   	leave  
f0100667:	c3                   	ret    

f0100668 <getchar>:

int
getchar(void)
{
f0100668:	55                   	push   %ebp
f0100669:	89 e5                	mov    %esp,%ebp
f010066b:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010066e:	e8 ac fe ff ff       	call   f010051f <cons_getc>
f0100673:	85 c0                	test   %eax,%eax
f0100675:	74 f7                	je     f010066e <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100677:	c9                   	leave  
f0100678:	c3                   	ret    

f0100679 <iscons>:

int
iscons(int fdnum)
{
f0100679:	55                   	push   %ebp
f010067a:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100681:	5d                   	pop    %ebp
f0100682:	c3                   	ret    
	...

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 90 1c 10 f0 	movl   $0xf0101c90,(%esp)
f010069d:	e8 88 02 00 00       	call   f010092a <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01006a2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006a9:	00 
f01006aa:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 1c 1d 10 f0 	movl   $0xf0101d1c,(%esp)
f01006b9:	e8 6c 02 00 00       	call   f010092a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006be:	c7 44 24 08 a5 19 10 	movl   $0x1019a5,0x8(%esp)
f01006c5:	00 
f01006c6:	c7 44 24 04 a5 19 10 	movl   $0xf01019a5,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 40 1d 10 f0 	movl   $0xf0101d40,(%esp)
f01006d5:	e8 50 02 00 00       	call   f010092a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006da:	c7 44 24 08 20 03 11 	movl   $0x110320,0x8(%esp)
f01006e1:	00 
f01006e2:	c7 44 24 04 20 03 11 	movl   $0xf0110320,0x4(%esp)
f01006e9:	f0 
f01006ea:	c7 04 24 64 1d 10 f0 	movl   $0xf0101d64,(%esp)
f01006f1:	e8 34 02 00 00       	call   f010092a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	c7 44 24 08 80 09 11 	movl   $0x110980,0x8(%esp)
f01006fd:	00 
f01006fe:	c7 44 24 04 80 09 11 	movl   $0xf0110980,0x4(%esp)
f0100705:	f0 
f0100706:	c7 04 24 88 1d 10 f0 	movl   $0xf0101d88,(%esp)
f010070d:	e8 18 02 00 00       	call   f010092a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
f0100712:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f0100717:	f7 d8                	neg    %eax
	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100719:	8d 90 7e 11 11 f0    	lea    -0xfeeee82(%eax),%edx
		(end-_start+1023)/1024);
f010071f:	05 7f 0d 11 f0       	add    $0xf0110d7f,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100724:	85 c0                	test   %eax,%eax
f0100726:	0f 48 c2             	cmovs  %edx,%eax
f0100729:	c1 f8 0a             	sar    $0xa,%eax
f010072c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100730:	c7 04 24 ac 1d 10 f0 	movl   $0xf0101dac,(%esp)
f0100737:	e8 ee 01 00 00       	call   f010092a <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f010073c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100741:	c9                   	leave  
f0100742:	c3                   	ret    

f0100743 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100743:	55                   	push   %ebp
f0100744:	89 e5                	mov    %esp,%ebp
f0100746:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100749:	a1 50 1e 10 f0       	mov    0xf0101e50,%eax
f010074e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100752:	a1 4c 1e 10 f0       	mov    0xf0101e4c,%eax
f0100757:	89 44 24 04          	mov    %eax,0x4(%esp)
f010075b:	c7 04 24 a9 1c 10 f0 	movl   $0xf0101ca9,(%esp)
f0100762:	e8 c3 01 00 00       	call   f010092a <cprintf>
f0100767:	a1 5c 1e 10 f0       	mov    0xf0101e5c,%eax
f010076c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100770:	a1 58 1e 10 f0       	mov    0xf0101e58,%eax
f0100775:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100779:	c7 04 24 a9 1c 10 f0 	movl   $0xf0101ca9,(%esp)
f0100780:	e8 a5 01 00 00       	call   f010092a <cprintf>
	return 0;
}
f0100785:	b8 00 00 00 00       	mov    $0x0,%eax
f010078a:	c9                   	leave  
f010078b:	c3                   	ret    

f010078c <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010078c:	55                   	push   %ebp
f010078d:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010078f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100794:	5d                   	pop    %ebp
f0100795:	c3                   	ret    

f0100796 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100796:	55                   	push   %ebp
f0100797:	89 e5                	mov    %esp,%ebp
f0100799:	57                   	push   %edi
f010079a:	56                   	push   %esi
f010079b:	53                   	push   %ebx
f010079c:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010079f:	c7 04 24 d8 1d 10 f0 	movl   $0xf0101dd8,(%esp)
f01007a6:	e8 7f 01 00 00       	call   f010092a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007ab:	c7 04 24 fc 1d 10 f0 	movl   $0xf0101dfc,(%esp)
f01007b2:	e8 73 01 00 00       	call   f010092a <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f01007b7:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007ba:	c7 04 24 b2 1c 10 f0 	movl   $0xf0101cb2,(%esp)
f01007c1:	e8 ba 0a 00 00       	call   f0101280 <readline>
f01007c6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	74 ee                	je     f01007ba <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007cc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007d3:	be 00 00 00 00       	mov    $0x0,%esi
f01007d8:	eb 06                	jmp    f01007e0 <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007da:	c6 03 00             	movb   $0x0,(%ebx)
f01007dd:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007e0:	0f b6 03             	movzbl (%ebx),%eax
f01007e3:	84 c0                	test   %al,%al
f01007e5:	74 6a                	je     f0100851 <monitor+0xbb>
f01007e7:	0f be c0             	movsbl %al,%eax
f01007ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ee:	c7 04 24 b6 1c 10 f0 	movl   $0xf0101cb6,(%esp)
f01007f5:	e8 9c 0c 00 00       	call   f0101496 <strchr>
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	75 dc                	jne    f01007da <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f01007fe:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100801:	74 4e                	je     f0100851 <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100803:	83 fe 0f             	cmp    $0xf,%esi
f0100806:	75 16                	jne    f010081e <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100808:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010080f:	00 
f0100810:	c7 04 24 bb 1c 10 f0 	movl   $0xf0101cbb,(%esp)
f0100817:	e8 0e 01 00 00       	call   f010092a <cprintf>
f010081c:	eb 9c                	jmp    f01007ba <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f010081e:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100822:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100825:	0f b6 03             	movzbl (%ebx),%eax
f0100828:	84 c0                	test   %al,%al
f010082a:	75 0c                	jne    f0100838 <monitor+0xa2>
f010082c:	eb b2                	jmp    f01007e0 <monitor+0x4a>
			buf++;
f010082e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100831:	0f b6 03             	movzbl (%ebx),%eax
f0100834:	84 c0                	test   %al,%al
f0100836:	74 a8                	je     f01007e0 <monitor+0x4a>
f0100838:	0f be c0             	movsbl %al,%eax
f010083b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083f:	c7 04 24 b6 1c 10 f0 	movl   $0xf0101cb6,(%esp)
f0100846:	e8 4b 0c 00 00       	call   f0101496 <strchr>
f010084b:	85 c0                	test   %eax,%eax
f010084d:	74 df                	je     f010082e <monitor+0x98>
f010084f:	eb 8f                	jmp    f01007e0 <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f0100851:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100858:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100859:	85 f6                	test   %esi,%esi
f010085b:	0f 84 59 ff ff ff    	je     f01007ba <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100861:	a1 4c 1e 10 f0       	mov    0xf0101e4c,%eax
f0100866:	89 44 24 04          	mov    %eax,0x4(%esp)
f010086a:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010086d:	89 04 24             	mov    %eax,(%esp)
f0100870:	e8 a7 0b 00 00       	call   f010141c <strcmp>
f0100875:	ba 00 00 00 00       	mov    $0x0,%edx
f010087a:	85 c0                	test   %eax,%eax
f010087c:	74 1d                	je     f010089b <monitor+0x105>
f010087e:	a1 58 1e 10 f0       	mov    0xf0101e58,%eax
f0100883:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100887:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010088a:	89 04 24             	mov    %eax,(%esp)
f010088d:	e8 8a 0b 00 00       	call   f010141c <strcmp>
f0100892:	85 c0                	test   %eax,%eax
f0100894:	75 25                	jne    f01008bb <monitor+0x125>
f0100896:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f010089b:	6b d2 0c             	imul   $0xc,%edx,%edx
f010089e:	8b 45 08             	mov    0x8(%ebp),%eax
f01008a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008a9:	89 34 24             	mov    %esi,(%esp)
f01008ac:	ff 92 54 1e 10 f0    	call   *-0xfefe1ac(%edx)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b2:	85 c0                	test   %eax,%eax
f01008b4:	78 1d                	js     f01008d3 <monitor+0x13d>
f01008b6:	e9 ff fe ff ff       	jmp    f01007ba <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008bb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c2:	c7 04 24 d8 1c 10 f0 	movl   $0xf0101cd8,(%esp)
f01008c9:	e8 5c 00 00 00       	call   f010092a <cprintf>
f01008ce:	e9 e7 fe ff ff       	jmp    f01007ba <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008d3:	83 c4 5c             	add    $0x5c,%esp
f01008d6:	5b                   	pop    %ebx
f01008d7:	5e                   	pop    %esi
f01008d8:	5f                   	pop    %edi
f01008d9:	5d                   	pop    %ebp
f01008da:	c3                   	ret    

f01008db <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01008db:	55                   	push   %ebp
f01008dc:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008de:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008e1:	5d                   	pop    %ebp
f01008e2:	c3                   	ret    
	...

f01008e4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008e4:	55                   	push   %ebp
f01008e5:	89 e5                	mov    %esp,%ebp
f01008e7:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 63 fd ff ff       	call   f0100658 <cputchar>
	*cnt++;
}
f01008f5:	c9                   	leave  
f01008f6:	c3                   	ret    

f01008f7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008f7:	55                   	push   %ebp
f01008f8:	89 e5                	mov    %esp,%ebp
f01008fa:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100904:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100907:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010090b:	8b 45 08             	mov    0x8(%ebp),%eax
f010090e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100912:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100915:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100919:	c7 04 24 e4 08 10 f0 	movl   $0xf01008e4,(%esp)
f0100920:	e8 b5 04 00 00       	call   f0100dda <vprintfmt>
	return cnt;
}
f0100925:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100928:	c9                   	leave  
f0100929:	c3                   	ret    

f010092a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010092a:	55                   	push   %ebp
f010092b:	89 e5                	mov    %esp,%ebp
f010092d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100930:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100933:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100937:	8b 45 08             	mov    0x8(%ebp),%eax
f010093a:	89 04 24             	mov    %eax,(%esp)
f010093d:	e8 b5 ff ff ff       	call   f01008f7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100942:	c9                   	leave  
f0100943:	c3                   	ret    
	...

f0100950 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
f0100953:	57                   	push   %edi
f0100954:	56                   	push   %esi
f0100955:	53                   	push   %ebx
f0100956:	83 ec 14             	sub    $0x14,%esp
f0100959:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010095c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010095f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100962:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100965:	8b 1a                	mov    (%edx),%ebx
f0100967:	8b 01                	mov    (%ecx),%eax
f0100969:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f010096c:	39 c3                	cmp    %eax,%ebx
f010096e:	0f 8f 9c 00 00 00    	jg     f0100a10 <stab_binsearch+0xc0>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0100974:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f010097b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010097e:	01 d8                	add    %ebx,%eax
f0100980:	89 c7                	mov    %eax,%edi
f0100982:	c1 ef 1f             	shr    $0x1f,%edi
f0100985:	01 c7                	add    %eax,%edi
f0100987:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100989:	39 df                	cmp    %ebx,%edi
f010098b:	7c 33                	jl     f01009c0 <stab_binsearch+0x70>
f010098d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100990:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100993:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0100998:	39 f0                	cmp    %esi,%eax
f010099a:	0f 84 bc 00 00 00    	je     f0100a5c <stab_binsearch+0x10c>
f01009a0:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01009a4:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f01009a8:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01009aa:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ad:	39 d8                	cmp    %ebx,%eax
f01009af:	7c 0f                	jl     f01009c0 <stab_binsearch+0x70>
f01009b1:	0f b6 0a             	movzbl (%edx),%ecx
f01009b4:	83 ea 0c             	sub    $0xc,%edx
f01009b7:	39 f1                	cmp    %esi,%ecx
f01009b9:	75 ef                	jne    f01009aa <stab_binsearch+0x5a>
f01009bb:	e9 9e 00 00 00       	jmp    f0100a5e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009c0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01009c3:	eb 3c                	jmp    f0100a01 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009c5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01009c8:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f01009ca:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009cd:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01009d4:	eb 2b                	jmp    f0100a01 <stab_binsearch+0xb1>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009d6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009d9:	76 14                	jbe    f01009ef <stab_binsearch+0x9f>
			*region_right = m - 1;
f01009db:	83 e8 01             	sub    $0x1,%eax
f01009de:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009e1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01009e4:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009e6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01009ed:	eb 12                	jmp    f0100a01 <stab_binsearch+0xb1>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009ef:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01009f2:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f01009f4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01009f8:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009fa:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a01:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100a04:	0f 8d 71 ff ff ff    	jge    f010097b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a0a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100a0e:	75 0f                	jne    f0100a1f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100a10:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a13:	8b 03                	mov    (%ebx),%eax
f0100a15:	83 e8 01             	sub    $0x1,%eax
f0100a18:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100a1b:	89 02                	mov    %eax,(%edx)
f0100a1d:	eb 57                	jmp    f0100a76 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a1f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100a22:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a24:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a27:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a29:	39 c1                	cmp    %eax,%ecx
f0100a2b:	7d 28                	jge    f0100a55 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100a2d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a30:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100a33:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100a38:	39 f2                	cmp    %esi,%edx
f0100a3a:	74 19                	je     f0100a55 <stab_binsearch+0x105>
f0100a3c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a40:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a44:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a47:	39 c1                	cmp    %eax,%ecx
f0100a49:	7d 0a                	jge    f0100a55 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100a4b:	0f b6 1a             	movzbl (%edx),%ebx
f0100a4e:	83 ea 0c             	sub    $0xc,%edx
f0100a51:	39 f3                	cmp    %esi,%ebx
f0100a53:	75 ef                	jne    f0100a44 <stab_binsearch+0xf4>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a55:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a58:	89 02                	mov    %eax,(%edx)
f0100a5a:	eb 1a                	jmp    f0100a76 <stab_binsearch+0x126>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0100a5c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a5e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a61:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100a64:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a68:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a6b:	0f 82 54 ff ff ff    	jb     f01009c5 <stab_binsearch+0x75>
f0100a71:	e9 60 ff ff ff       	jmp    f01009d6 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100a76:	83 c4 14             	add    $0x14,%esp
f0100a79:	5b                   	pop    %ebx
f0100a7a:	5e                   	pop    %esi
f0100a7b:	5f                   	pop    %edi
f0100a7c:	5d                   	pop    %ebp
f0100a7d:	c3                   	ret    

f0100a7e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a7e:	55                   	push   %ebp
f0100a7f:	89 e5                	mov    %esp,%ebp
f0100a81:	83 ec 38             	sub    $0x38,%esp
f0100a84:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100a87:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100a8a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100a8d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a90:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a93:	c7 03 64 1e 10 f0    	movl   $0xf0101e64,(%ebx)
	info->eip_line = 0;
f0100a99:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aa0:	c7 43 08 64 1e 10 f0 	movl   $0xf0101e64,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100aa7:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aae:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ab1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ab8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100abe:	76 12                	jbe    f0100ad2 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ac0:	b8 d7 72 10 f0       	mov    $0xf01072d7,%eax
f0100ac5:	3d 2d 5a 10 f0       	cmp    $0xf0105a2d,%eax
f0100aca:	0f 86 65 01 00 00    	jbe    f0100c35 <debuginfo_eip+0x1b7>
f0100ad0:	eb 1c                	jmp    f0100aee <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ad2:	c7 44 24 08 6e 1e 10 	movl   $0xf0101e6e,0x8(%esp)
f0100ad9:	f0 
f0100ada:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100ae1:	00 
f0100ae2:	c7 04 24 7b 1e 10 f0 	movl   $0xf0101e7b,(%esp)
f0100ae9:	e8 0a f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100aee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100af3:	80 3d d6 72 10 f0 00 	cmpb   $0x0,0xf01072d6
f0100afa:	0f 85 41 01 00 00    	jne    f0100c41 <debuginfo_eip+0x1c3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b00:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b07:	b8 2c 5a 10 f0       	mov    $0xf0105a2c,%eax
f0100b0c:	2d 9c 20 10 f0       	sub    $0xf010209c,%eax
f0100b11:	c1 f8 02             	sar    $0x2,%eax
f0100b14:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b1a:	83 e8 01             	sub    $0x1,%eax
f0100b1d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b20:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b24:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b2b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b2e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b31:	b8 9c 20 10 f0       	mov    $0xf010209c,%eax
f0100b36:	e8 15 fe ff ff       	call   f0100950 <stab_binsearch>
	if (lfile == 0)
f0100b3b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100b43:	85 d2                	test   %edx,%edx
f0100b45:	0f 84 f6 00 00 00    	je     f0100c41 <debuginfo_eip+0x1c3>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b4b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100b4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b51:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b54:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b58:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b5f:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b62:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b65:	b8 9c 20 10 f0       	mov    $0xf010209c,%eax
f0100b6a:	e8 e1 fd ff ff       	call   f0100950 <stab_binsearch>

	if (lfun <= rfun) {
f0100b6f:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b72:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b75:	7f 30                	jg     f0100ba7 <debuginfo_eip+0x129>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b77:	89 fa                	mov    %edi,%edx
f0100b79:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b7c:	8b 80 9c 20 10 f0    	mov    -0xfefdf64(%eax),%eax
f0100b82:	b9 d7 72 10 f0       	mov    $0xf01072d7,%ecx
f0100b87:	81 e9 2d 5a 10 f0    	sub    $0xf0105a2d,%ecx
f0100b8d:	39 c8                	cmp    %ecx,%eax
f0100b8f:	73 08                	jae    f0100b99 <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b91:	05 2d 5a 10 f0       	add    $0xf0105a2d,%eax
f0100b96:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b99:	6b c2 0c             	imul   $0xc,%edx,%eax
f0100b9c:	8b 80 a4 20 10 f0    	mov    -0xfefdf5c(%eax),%eax
f0100ba2:	89 43 10             	mov    %eax,0x10(%ebx)
f0100ba5:	eb 06                	jmp    f0100bad <debuginfo_eip+0x12f>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ba7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100baa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bad:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bb4:	00 
f0100bb5:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bb8:	89 04 24             	mov    %eax,(%esp)
f0100bbb:	e8 0a 09 00 00       	call   f01014ca <strfind>
f0100bc0:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bc3:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bc6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100bc9:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bcc:	05 a4 20 10 f0       	add    $0xf01020a4,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bd1:	eb 06                	jmp    f0100bd9 <debuginfo_eip+0x15b>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100bd3:	83 ef 01             	sub    $0x1,%edi
f0100bd6:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bd9:	39 cf                	cmp    %ecx,%edi
f0100bdb:	7c 1c                	jl     f0100bf9 <debuginfo_eip+0x17b>
	       && stabs[lline].n_type != N_SOL
f0100bdd:	0f b6 50 fc          	movzbl -0x4(%eax),%edx
f0100be1:	80 fa 84             	cmp    $0x84,%dl
f0100be4:	74 68                	je     f0100c4e <debuginfo_eip+0x1d0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100be6:	80 fa 64             	cmp    $0x64,%dl
f0100be9:	75 e8                	jne    f0100bd3 <debuginfo_eip+0x155>
f0100beb:	83 38 00             	cmpl   $0x0,(%eax)
f0100bee:	74 e3                	je     f0100bd3 <debuginfo_eip+0x155>
f0100bf0:	eb 5c                	jmp    f0100c4e <debuginfo_eip+0x1d0>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bf2:	05 2d 5a 10 f0       	add    $0xf0105a2d,%eax
f0100bf7:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bf9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bfc:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100bff:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c04:	39 fa                	cmp    %edi,%edx
f0100c06:	7d 39                	jge    f0100c41 <debuginfo_eip+0x1c3>
		for (lline = lfun + 1;
f0100c08:	8d 42 01             	lea    0x1(%edx),%eax
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100c0b:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c0e:	81 c2 a0 20 10 f0    	add    $0xf01020a0,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c14:	eb 07                	jmp    f0100c1d <debuginfo_eip+0x19f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c16:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c1a:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c1d:	39 f8                	cmp    %edi,%eax
f0100c1f:	7d 1b                	jge    f0100c3c <debuginfo_eip+0x1be>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c21:	0f b6 32             	movzbl (%edx),%esi
f0100c24:	83 c2 0c             	add    $0xc,%edx
f0100c27:	89 f1                	mov    %esi,%ecx
f0100c29:	80 f9 a0             	cmp    $0xa0,%cl
f0100c2c:	74 e8                	je     f0100c16 <debuginfo_eip+0x198>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c33:	eb 0c                	jmp    f0100c41 <debuginfo_eip+0x1c3>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c3a:	eb 05                	jmp    f0100c41 <debuginfo_eip+0x1c3>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c3c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c41:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100c44:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100c47:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100c4a:	89 ec                	mov    %ebp,%esp
f0100c4c:	5d                   	pop    %ebp
f0100c4d:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c4e:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c51:	8b 87 9c 20 10 f0    	mov    -0xfefdf64(%edi),%eax
f0100c57:	ba d7 72 10 f0       	mov    $0xf01072d7,%edx
f0100c5c:	81 ea 2d 5a 10 f0    	sub    $0xf0105a2d,%edx
f0100c62:	39 d0                	cmp    %edx,%eax
f0100c64:	72 8c                	jb     f0100bf2 <debuginfo_eip+0x174>
f0100c66:	eb 91                	jmp    f0100bf9 <debuginfo_eip+0x17b>
	...

f0100c70 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c70:	55                   	push   %ebp
f0100c71:	89 e5                	mov    %esp,%ebp
f0100c73:	57                   	push   %edi
f0100c74:	56                   	push   %esi
f0100c75:	53                   	push   %ebx
f0100c76:	83 ec 4c             	sub    $0x4c,%esp
f0100c79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c7c:	89 d6                	mov    %edx,%esi
f0100c7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c81:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c84:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c87:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c8a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100c8d:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c95:	39 d0                	cmp    %edx,%eax
f0100c97:	72 11                	jb     f0100caa <printnum+0x3a>
f0100c99:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c9c:	39 4d 10             	cmp    %ecx,0x10(%ebp)
f0100c9f:	76 09                	jbe    f0100caa <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ca1:	83 eb 01             	sub    $0x1,%ebx
f0100ca4:	85 db                	test   %ebx,%ebx
f0100ca6:	7f 5d                	jg     f0100d05 <printnum+0x95>
f0100ca8:	eb 6c                	jmp    f0100d16 <printnum+0xa6>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100caa:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100cae:	83 eb 01             	sub    $0x1,%ebx
f0100cb1:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100cb5:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100cb8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100cbc:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100cc0:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100cc4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100cc7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100cca:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100cd1:	00 
f0100cd2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cd5:	89 14 24             	mov    %edx,(%esp)
f0100cd8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100cdb:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100cdf:	e8 6c 0a 00 00       	call   f0101750 <__udivdi3>
f0100ce4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100ce7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cea:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cee:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100cf2:	89 04 24             	mov    %eax,(%esp)
f0100cf5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100cf9:	89 f2                	mov    %esi,%edx
f0100cfb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cfe:	e8 6d ff ff ff       	call   f0100c70 <printnum>
f0100d03:	eb 11                	jmp    f0100d16 <printnum+0xa6>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d05:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d09:	89 3c 24             	mov    %edi,(%esp)
f0100d0c:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d0f:	83 eb 01             	sub    $0x1,%ebx
f0100d12:	85 db                	test   %ebx,%ebx
f0100d14:	7f ef                	jg     f0100d05 <printnum+0x95>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d16:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d1a:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100d1e:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d25:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d2c:	00 
f0100d2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d30:	89 14 24             	mov    %edx,(%esp)
f0100d33:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100d36:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100d3a:	e8 21 0b 00 00       	call   f0101860 <__umoddi3>
f0100d3f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d43:	0f be 80 89 1e 10 f0 	movsbl -0xfefe177(%eax),%eax
f0100d4a:	89 04 24             	mov    %eax,(%esp)
f0100d4d:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100d50:	83 c4 4c             	add    $0x4c,%esp
f0100d53:	5b                   	pop    %ebx
f0100d54:	5e                   	pop    %esi
f0100d55:	5f                   	pop    %edi
f0100d56:	5d                   	pop    %ebp
f0100d57:	c3                   	ret    

f0100d58 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d58:	55                   	push   %ebp
f0100d59:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d5b:	83 fa 01             	cmp    $0x1,%edx
f0100d5e:	7e 0f                	jle    f0100d6f <getuint+0x17>
		return va_arg(*ap, unsigned long long);
f0100d60:	8b 10                	mov    (%eax),%edx
f0100d62:	83 c2 08             	add    $0x8,%edx
f0100d65:	89 10                	mov    %edx,(%eax)
f0100d67:	8b 42 f8             	mov    -0x8(%edx),%eax
f0100d6a:	8b 52 fc             	mov    -0x4(%edx),%edx
f0100d6d:	eb 24                	jmp    f0100d93 <getuint+0x3b>
	else if (lflag)
f0100d6f:	85 d2                	test   %edx,%edx
f0100d71:	74 11                	je     f0100d84 <getuint+0x2c>
		return va_arg(*ap, unsigned long);
f0100d73:	8b 10                	mov    (%eax),%edx
f0100d75:	83 c2 04             	add    $0x4,%edx
f0100d78:	89 10                	mov    %edx,(%eax)
f0100d7a:	8b 42 fc             	mov    -0x4(%edx),%eax
f0100d7d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d82:	eb 0f                	jmp    f0100d93 <getuint+0x3b>
	else
		return va_arg(*ap, unsigned int);
f0100d84:	8b 10                	mov    (%eax),%edx
f0100d86:	83 c2 04             	add    $0x4,%edx
f0100d89:	89 10                	mov    %edx,(%eax)
f0100d8b:	8b 42 fc             	mov    -0x4(%edx),%eax
f0100d8e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d93:	5d                   	pop    %ebp
f0100d94:	c3                   	ret    

f0100d95 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d95:	55                   	push   %ebp
f0100d96:	89 e5                	mov    %esp,%ebp
f0100d98:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d9b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d9f:	8b 10                	mov    (%eax),%edx
f0100da1:	3b 50 04             	cmp    0x4(%eax),%edx
f0100da4:	73 0a                	jae    f0100db0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100da6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100da9:	88 0a                	mov    %cl,(%edx)
f0100dab:	83 c2 01             	add    $0x1,%edx
f0100dae:	89 10                	mov    %edx,(%eax)
}
f0100db0:	5d                   	pop    %ebp
f0100db1:	c3                   	ret    

f0100db2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100db2:	55                   	push   %ebp
f0100db3:	89 e5                	mov    %esp,%ebp
f0100db5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100db8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dbb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dbf:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dc2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dc6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dc9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dcd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dd0:	89 04 24             	mov    %eax,(%esp)
f0100dd3:	e8 02 00 00 00       	call   f0100dda <vprintfmt>
	va_end(ap);
}
f0100dd8:	c9                   	leave  
f0100dd9:	c3                   	ret    

f0100dda <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dda:	55                   	push   %ebp
f0100ddb:	89 e5                	mov    %esp,%ebp
f0100ddd:	57                   	push   %edi
f0100dde:	56                   	push   %esi
f0100ddf:	53                   	push   %ebx
f0100de0:	83 ec 4c             	sub    $0x4c,%esp
f0100de3:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100de6:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100de9:	eb 12                	jmp    f0100dfd <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100deb:	85 c0                	test   %eax,%eax
f0100ded:	0f 84 fa 03 00 00    	je     f01011ed <vprintfmt+0x413>
				return;
			putch(ch, putdat);
f0100df3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100df7:	89 04 24             	mov    %eax,(%esp)
f0100dfa:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dfd:	0f b6 03             	movzbl (%ebx),%eax
f0100e00:	83 c3 01             	add    $0x1,%ebx
f0100e03:	83 f8 25             	cmp    $0x25,%eax
f0100e06:	75 e3                	jne    f0100deb <vprintfmt+0x11>
f0100e08:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100e0c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100e13:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100e18:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100e1f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e24:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100e27:	eb 2b                	jmp    f0100e54 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e29:	8b 5d e0             	mov    -0x20(%ebp),%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e2c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100e30:	eb 22                	jmp    f0100e54 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e32:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e35:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100e39:	eb 19                	jmp    f0100e54 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100e3e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100e45:	eb 0d                	jmp    f0100e54 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e47:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e4a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e4d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e54:	0f b6 03             	movzbl (%ebx),%eax
f0100e57:	0f b6 d0             	movzbl %al,%edx
f0100e5a:	8d 73 01             	lea    0x1(%ebx),%esi
f0100e5d:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0100e60:	83 e8 23             	sub    $0x23,%eax
f0100e63:	3c 55                	cmp    $0x55,%al
f0100e65:	0f 87 62 03 00 00    	ja     f01011cd <vprintfmt+0x3f3>
f0100e6b:	0f b6 c0             	movzbl %al,%eax
f0100e6e:	ff 24 85 18 1f 10 f0 	jmp    *-0xfefe0e8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e75:	83 ea 30             	sub    $0x30,%edx
f0100e78:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0100e7b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e7e:	0f be 02             	movsbl (%edx),%eax
				if (ch < '0' || ch > '9')
f0100e81:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e84:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100e87:	83 fa 09             	cmp    $0x9,%edx
f0100e8a:	77 4f                	ja     f0100edb <vprintfmt+0x101>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e8c:	8b 75 d4             	mov    -0x2c(%ebp),%esi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e8f:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0100e92:	8d 14 b6             	lea    (%esi,%esi,4),%edx
f0100e95:	8d 74 50 d0          	lea    -0x30(%eax,%edx,2),%esi
				ch = *fmt;
f0100e99:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
f0100e9c:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100e9f:	83 fa 09             	cmp    $0x9,%edx
f0100ea2:	76 eb                	jbe    f0100e8f <vprintfmt+0xb5>
f0100ea4:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100ea7:	eb 32                	jmp    f0100edb <vprintfmt+0x101>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ea9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eac:	83 c0 04             	add    $0x4,%eax
f0100eaf:	89 45 14             	mov    %eax,0x14(%ebp)
f0100eb2:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100eb5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ebb:	eb 1e                	jmp    f0100edb <vprintfmt+0x101>

		case '.':
			if (width < 0)
f0100ebd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100ec1:	0f 88 74 ff ff ff    	js     f0100e3b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100eca:	eb 88                	jmp    f0100e54 <vprintfmt+0x7a>
f0100ecc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ecf:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100ed6:	e9 79 ff ff ff       	jmp    f0100e54 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0100edb:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100edf:	0f 89 6f ff ff ff    	jns    f0100e54 <vprintfmt+0x7a>
f0100ee5:	e9 5d ff ff ff       	jmp    f0100e47 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eea:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eed:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ef0:	e9 5f ff ff ff       	jmp    f0100e54 <vprintfmt+0x7a>
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ef5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ef8:	83 c0 04             	add    $0x4,%eax
f0100efb:	89 45 14             	mov    %eax,0x14(%ebp)
f0100efe:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f02:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100f05:	89 04 24             	mov    %eax,(%esp)
f0100f08:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f0b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f0e:	e9 ea fe ff ff       	jmp    f0100dfd <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f13:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f16:	83 c0 04             	add    $0x4,%eax
f0100f19:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f1c:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100f1f:	89 c2                	mov    %eax,%edx
f0100f21:	c1 fa 1f             	sar    $0x1f,%edx
f0100f24:	31 d0                	xor    %edx,%eax
f0100f26:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0100f28:	83 f8 06             	cmp    $0x6,%eax
f0100f2b:	7f 0b                	jg     f0100f38 <vprintfmt+0x15e>
f0100f2d:	8b 14 85 70 20 10 f0 	mov    -0xfefdf90(,%eax,4),%edx
f0100f34:	85 d2                	test   %edx,%edx
f0100f36:	75 23                	jne    f0100f5b <vprintfmt+0x181>
				printfmt(putch, putdat, "error %d", err);
f0100f38:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f3c:	c7 44 24 08 a1 1e 10 	movl   $0xf0101ea1,0x8(%esp)
f0100f43:	f0 
f0100f44:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f48:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f4b:	89 34 24             	mov    %esi,(%esp)
f0100f4e:	e8 5f fe ff ff       	call   f0100db2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f53:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f56:	e9 a2 fe ff ff       	jmp    f0100dfd <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0100f5b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f5f:	c7 44 24 08 aa 1e 10 	movl   $0xf0101eaa,0x8(%esp)
f0100f66:	f0 
f0100f67:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f6e:	89 04 24             	mov    %eax,(%esp)
f0100f71:	e8 3c fe ff ff       	call   f0100db2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f76:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f79:	e9 7f fe ff ff       	jmp    f0100dfd <vprintfmt+0x23>
f0100f7e:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100f81:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f87:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f8d:	83 c0 04             	add    $0x4,%eax
f0100f90:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f93:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100f96:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				p = "(null)";
f0100f99:	85 c0                	test   %eax,%eax
f0100f9b:	b8 9a 1e 10 f0       	mov    $0xf0101e9a,%eax
f0100fa0:	0f 45 45 d4          	cmovne -0x2c(%ebp),%eax
f0100fa4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
			if (width > 0 && padc != '-')
f0100fa7:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100fab:	7e 06                	jle    f0100fb3 <vprintfmt+0x1d9>
f0100fad:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100fb1:	75 19                	jne    f0100fcc <vprintfmt+0x1f2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fb3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100fb6:	0f be 02             	movsbl (%edx),%eax
f0100fb9:	83 c2 01             	add    $0x1,%edx
f0100fbc:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0100fbf:	85 c0                	test   %eax,%eax
f0100fc1:	0f 85 97 00 00 00    	jne    f010105e <vprintfmt+0x284>
f0100fc7:	e9 84 00 00 00       	jmp    f0101050 <vprintfmt+0x276>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fcc:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100fd0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fd3:	89 04 24             	mov    %eax,(%esp)
f0100fd6:	e8 90 03 00 00       	call   f010136b <strnlen>
f0100fdb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100fde:	29 c2                	sub    %eax,%edx
f0100fe0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100fe3:	85 d2                	test   %edx,%edx
f0100fe5:	7e cc                	jle    f0100fb3 <vprintfmt+0x1d9>
					putch(padc, putdat);
f0100fe7:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100feb:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0100fee:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0100ff1:	89 d3                	mov    %edx,%ebx
f0100ff3:	89 c6                	mov    %eax,%esi
f0100ff5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ff9:	89 34 24             	mov    %esi,(%esp)
f0100ffc:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fff:	83 eb 01             	sub    $0x1,%ebx
f0101002:	85 db                	test   %ebx,%ebx
f0101004:	7f ef                	jg     f0100ff5 <vprintfmt+0x21b>
f0101006:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101009:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f010100c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0101013:	eb 9e                	jmp    f0100fb3 <vprintfmt+0x1d9>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101015:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101019:	74 18                	je     f0101033 <vprintfmt+0x259>
f010101b:	8d 50 e0             	lea    -0x20(%eax),%edx
f010101e:	83 fa 5e             	cmp    $0x5e,%edx
f0101021:	76 10                	jbe    f0101033 <vprintfmt+0x259>
					putch('?', putdat);
f0101023:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101027:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010102e:	ff 55 08             	call   *0x8(%ebp)
f0101031:	eb 0a                	jmp    f010103d <vprintfmt+0x263>
				else
					putch(ch, putdat);
f0101033:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101037:	89 04 24             	mov    %eax,(%esp)
f010103a:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010103d:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0101041:	0f be 03             	movsbl (%ebx),%eax
f0101044:	85 c0                	test   %eax,%eax
f0101046:	74 05                	je     f010104d <vprintfmt+0x273>
f0101048:	83 c3 01             	add    $0x1,%ebx
f010104b:	eb 17                	jmp    f0101064 <vprintfmt+0x28a>
f010104d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101050:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101054:	7f 1c                	jg     f0101072 <vprintfmt+0x298>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101056:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101059:	e9 9f fd ff ff       	jmp    f0100dfd <vprintfmt+0x23>
f010105e:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0101061:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101064:	85 f6                	test   %esi,%esi
f0101066:	78 ad                	js     f0101015 <vprintfmt+0x23b>
f0101068:	83 ee 01             	sub    $0x1,%esi
f010106b:	79 a8                	jns    f0101015 <vprintfmt+0x23b>
f010106d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101070:	eb de                	jmp    f0101050 <vprintfmt+0x276>
f0101072:	8b 75 08             	mov    0x8(%ebp),%esi
f0101075:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0101078:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010107b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010107f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101086:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101088:	83 eb 01             	sub    $0x1,%ebx
f010108b:	85 db                	test   %ebx,%ebx
f010108d:	7f ec                	jg     f010107b <vprintfmt+0x2a1>
f010108f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101092:	e9 66 fd ff ff       	jmp    f0100dfd <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101097:	83 f9 01             	cmp    $0x1,%ecx
f010109a:	7e 11                	jle    f01010ad <vprintfmt+0x2d3>
		return va_arg(*ap, long long);
f010109c:	8b 45 14             	mov    0x14(%ebp),%eax
f010109f:	83 c0 08             	add    $0x8,%eax
f01010a2:	89 45 14             	mov    %eax,0x14(%ebp)
f01010a5:	8b 58 f8             	mov    -0x8(%eax),%ebx
f01010a8:	8b 70 fc             	mov    -0x4(%eax),%esi
f01010ab:	eb 28                	jmp    f01010d5 <vprintfmt+0x2fb>
	else if (lflag)
f01010ad:	85 c9                	test   %ecx,%ecx
f01010af:	74 13                	je     f01010c4 <vprintfmt+0x2ea>
		return va_arg(*ap, long);
f01010b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b4:	83 c0 04             	add    $0x4,%eax
f01010b7:	89 45 14             	mov    %eax,0x14(%ebp)
f01010ba:	8b 58 fc             	mov    -0x4(%eax),%ebx
f01010bd:	89 de                	mov    %ebx,%esi
f01010bf:	c1 fe 1f             	sar    $0x1f,%esi
f01010c2:	eb 11                	jmp    f01010d5 <vprintfmt+0x2fb>
	else
		return va_arg(*ap, int);
f01010c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c7:	83 c0 04             	add    $0x4,%eax
f01010ca:	89 45 14             	mov    %eax,0x14(%ebp)
f01010cd:	8b 58 fc             	mov    -0x4(%eax),%ebx
f01010d0:	89 de                	mov    %ebx,%esi
f01010d2:	c1 fe 1f             	sar    $0x1f,%esi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010d5:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010da:	85 f6                	test   %esi,%esi
f01010dc:	0f 89 ad 00 00 00    	jns    f010118f <vprintfmt+0x3b5>
				putch('-', putdat);
f01010e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010e6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010ed:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01010f0:	f7 db                	neg    %ebx
f01010f2:	83 d6 00             	adc    $0x0,%esi
f01010f5:	f7 de                	neg    %esi
			}
			base = 10;
f01010f7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010fc:	e9 8e 00 00 00       	jmp    f010118f <vprintfmt+0x3b5>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101101:	89 ca                	mov    %ecx,%edx
f0101103:	8d 45 14             	lea    0x14(%ebp),%eax
f0101106:	e8 4d fc ff ff       	call   f0100d58 <getuint>
f010110b:	89 c3                	mov    %eax,%ebx
f010110d:	89 d6                	mov    %edx,%esi
			base = 10;
f010110f:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0101114:	eb 79                	jmp    f010118f <vprintfmt+0x3b5>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101116:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010111a:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101121:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0101124:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101128:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010112f:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0101132:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101136:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010113d:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101140:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101143:	e9 b5 fc ff ff       	jmp    f0100dfd <vprintfmt+0x23>

		// pointer
		case 'p':
			putch('0', putdat);
f0101148:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010114c:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101153:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101156:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010115a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101161:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101164:	8b 45 14             	mov    0x14(%ebp),%eax
f0101167:	83 c0 04             	add    $0x4,%eax
f010116a:	89 45 14             	mov    %eax,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010116d:	8b 58 fc             	mov    -0x4(%eax),%ebx
f0101170:	be 00 00 00 00       	mov    $0x0,%esi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101175:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010117a:	eb 13                	jmp    f010118f <vprintfmt+0x3b5>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010117c:	89 ca                	mov    %ecx,%edx
f010117e:	8d 45 14             	lea    0x14(%ebp),%eax
f0101181:	e8 d2 fb ff ff       	call   f0100d58 <getuint>
f0101186:	89 c3                	mov    %eax,%ebx
f0101188:	89 d6                	mov    %edx,%esi
			base = 16;
f010118a:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010118f:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0101193:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101197:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010119a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010119e:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011a2:	89 1c 24             	mov    %ebx,(%esp)
f01011a5:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011a9:	89 fa                	mov    %edi,%edx
f01011ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ae:	e8 bd fa ff ff       	call   f0100c70 <printnum>
			break;
f01011b3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01011b6:	e9 42 fc ff ff       	jmp    f0100dfd <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011bf:	89 14 24             	mov    %edx,(%esp)
f01011c2:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011c5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011c8:	e9 30 fc ff ff       	jmp    f0100dfd <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011cd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d1:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01011d8:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011db:	eb 02                	jmp    f01011df <vprintfmt+0x405>
f01011dd:	89 c3                	mov    %eax,%ebx
f01011df:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01011e2:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01011e6:	75 f5                	jne    f01011dd <vprintfmt+0x403>
f01011e8:	e9 10 fc ff ff       	jmp    f0100dfd <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01011ed:	83 c4 4c             	add    $0x4c,%esp
f01011f0:	5b                   	pop    %ebx
f01011f1:	5e                   	pop    %esi
f01011f2:	5f                   	pop    %edi
f01011f3:	5d                   	pop    %ebp
f01011f4:	c3                   	ret    

f01011f5 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011f5:	55                   	push   %ebp
f01011f6:	89 e5                	mov    %esp,%ebp
f01011f8:	83 ec 28             	sub    $0x28,%esp
f01011fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01011fe:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101201:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101204:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101208:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010120b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101212:	85 c0                	test   %eax,%eax
f0101214:	74 30                	je     f0101246 <vsnprintf+0x51>
f0101216:	85 d2                	test   %edx,%edx
f0101218:	7e 2c                	jle    f0101246 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010121a:	8b 45 14             	mov    0x14(%ebp),%eax
f010121d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101221:	8b 45 10             	mov    0x10(%ebp),%eax
f0101224:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101228:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010122b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010122f:	c7 04 24 95 0d 10 f0 	movl   $0xf0100d95,(%esp)
f0101236:	e8 9f fb ff ff       	call   f0100dda <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010123b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010123e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101241:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101244:	eb 05                	jmp    f010124b <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101246:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010124b:	c9                   	leave  
f010124c:	c3                   	ret    

f010124d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010124d:	55                   	push   %ebp
f010124e:	89 e5                	mov    %esp,%ebp
f0101250:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101253:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101256:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010125a:	8b 45 10             	mov    0x10(%ebp),%eax
f010125d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101261:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101264:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101268:	8b 45 08             	mov    0x8(%ebp),%eax
f010126b:	89 04 24             	mov    %eax,(%esp)
f010126e:	e8 82 ff ff ff       	call   f01011f5 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101273:	c9                   	leave  
f0101274:	c3                   	ret    
	...

f0101280 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101280:	55                   	push   %ebp
f0101281:	89 e5                	mov    %esp,%ebp
f0101283:	57                   	push   %edi
f0101284:	56                   	push   %esi
f0101285:	53                   	push   %ebx
f0101286:	83 ec 1c             	sub    $0x1c,%esp
f0101289:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010128c:	85 c0                	test   %eax,%eax
f010128e:	74 10                	je     f01012a0 <readline+0x20>
		cprintf("%s", prompt);
f0101290:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101294:	c7 04 24 aa 1e 10 f0 	movl   $0xf0101eaa,(%esp)
f010129b:	e8 8a f6 ff ff       	call   f010092a <cprintf>

	i = 0;
	echoing = iscons(0);
f01012a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012a7:	e8 cd f3 ff ff       	call   f0100679 <iscons>
f01012ac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012ae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01012b3:	e8 b0 f3 ff ff       	call   f0100668 <getchar>
f01012b8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012ba:	85 c0                	test   %eax,%eax
f01012bc:	79 17                	jns    f01012d5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c2:	c7 04 24 8c 20 10 f0 	movl   $0xf010208c,(%esp)
f01012c9:	e8 5c f6 ff ff       	call   f010092a <cprintf>
			return NULL;
f01012ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01012d3:	eb 6d                	jmp    f0101342 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012d5:	83 f8 08             	cmp    $0x8,%eax
f01012d8:	74 05                	je     f01012df <readline+0x5f>
f01012da:	83 f8 7f             	cmp    $0x7f,%eax
f01012dd:	75 19                	jne    f01012f8 <readline+0x78>
f01012df:	85 f6                	test   %esi,%esi
f01012e1:	7e 15                	jle    f01012f8 <readline+0x78>
			if (echoing)
f01012e3:	85 ff                	test   %edi,%edi
f01012e5:	74 0c                	je     f01012f3 <readline+0x73>
				cputchar('\b');
f01012e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01012ee:	e8 65 f3 ff ff       	call   f0100658 <cputchar>
			i--;
f01012f3:	83 ee 01             	sub    $0x1,%esi
f01012f6:	eb bb                	jmp    f01012b3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012f8:	83 fb 1f             	cmp    $0x1f,%ebx
f01012fb:	7e 1f                	jle    f010131c <readline+0x9c>
f01012fd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101303:	7f 17                	jg     f010131c <readline+0x9c>
			if (echoing)
f0101305:	85 ff                	test   %edi,%edi
f0101307:	74 08                	je     f0101311 <readline+0x91>
				cputchar(c);
f0101309:	89 1c 24             	mov    %ebx,(%esp)
f010130c:	e8 47 f3 ff ff       	call   f0100658 <cputchar>
			buf[i++] = c;
f0101311:	88 9e 80 05 11 f0    	mov    %bl,-0xfeefa80(%esi)
f0101317:	83 c6 01             	add    $0x1,%esi
f010131a:	eb 97                	jmp    f01012b3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010131c:	83 fb 0a             	cmp    $0xa,%ebx
f010131f:	74 05                	je     f0101326 <readline+0xa6>
f0101321:	83 fb 0d             	cmp    $0xd,%ebx
f0101324:	75 8d                	jne    f01012b3 <readline+0x33>
			if (echoing)
f0101326:	85 ff                	test   %edi,%edi
f0101328:	74 0c                	je     f0101336 <readline+0xb6>
				cputchar('\n');
f010132a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101331:	e8 22 f3 ff ff       	call   f0100658 <cputchar>
			buf[i] = 0;
f0101336:	c6 86 80 05 11 f0 00 	movb   $0x0,-0xfeefa80(%esi)
			return buf;
f010133d:	b8 80 05 11 f0       	mov    $0xf0110580,%eax
		}
	}
}
f0101342:	83 c4 1c             	add    $0x1c,%esp
f0101345:	5b                   	pop    %ebx
f0101346:	5e                   	pop    %esi
f0101347:	5f                   	pop    %edi
f0101348:	5d                   	pop    %ebp
f0101349:	c3                   	ret    
f010134a:	00 00                	add    %al,(%eax)
f010134c:	00 00                	add    %al,(%eax)
	...

f0101350 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101350:	55                   	push   %ebp
f0101351:	89 e5                	mov    %esp,%ebp
f0101353:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101356:	b8 00 00 00 00       	mov    $0x0,%eax
f010135b:	80 3a 00             	cmpb   $0x0,(%edx)
f010135e:	74 09                	je     f0101369 <strlen+0x19>
		n++;
f0101360:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101363:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101367:	75 f7                	jne    f0101360 <strlen+0x10>
		n++;
	return n;
}
f0101369:	5d                   	pop    %ebp
f010136a:	c3                   	ret    

f010136b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010136b:	55                   	push   %ebp
f010136c:	89 e5                	mov    %esp,%ebp
f010136e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101371:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101374:	b8 00 00 00 00       	mov    $0x0,%eax
f0101379:	85 d2                	test   %edx,%edx
f010137b:	74 12                	je     f010138f <strnlen+0x24>
f010137d:	80 39 00             	cmpb   $0x0,(%ecx)
f0101380:	74 0d                	je     f010138f <strnlen+0x24>
		n++;
f0101382:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101385:	39 d0                	cmp    %edx,%eax
f0101387:	74 06                	je     f010138f <strnlen+0x24>
f0101389:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010138d:	75 f3                	jne    f0101382 <strnlen+0x17>
		n++;
	return n;
}
f010138f:	5d                   	pop    %ebp
f0101390:	c3                   	ret    

f0101391 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101391:	55                   	push   %ebp
f0101392:	89 e5                	mov    %esp,%ebp
f0101394:	53                   	push   %ebx
f0101395:	8b 45 08             	mov    0x8(%ebp),%eax
f0101398:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010139b:	ba 00 00 00 00       	mov    $0x0,%edx
f01013a0:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01013a4:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01013a7:	83 c2 01             	add    $0x1,%edx
f01013aa:	84 c9                	test   %cl,%cl
f01013ac:	75 f2                	jne    f01013a0 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01013ae:	5b                   	pop    %ebx
f01013af:	5d                   	pop    %ebp
f01013b0:	c3                   	ret    

f01013b1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013b1:	55                   	push   %ebp
f01013b2:	89 e5                	mov    %esp,%ebp
f01013b4:	56                   	push   %esi
f01013b5:	53                   	push   %ebx
f01013b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013bc:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013bf:	85 f6                	test   %esi,%esi
f01013c1:	74 18                	je     f01013db <strncpy+0x2a>
f01013c3:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01013c8:	0f b6 1a             	movzbl (%edx),%ebx
f01013cb:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013ce:	80 3a 01             	cmpb   $0x1,(%edx)
f01013d1:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013d4:	83 c1 01             	add    $0x1,%ecx
f01013d7:	39 ce                	cmp    %ecx,%esi
f01013d9:	77 ed                	ja     f01013c8 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013db:	5b                   	pop    %ebx
f01013dc:	5e                   	pop    %esi
f01013dd:	5d                   	pop    %ebp
f01013de:	c3                   	ret    

f01013df <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013df:	55                   	push   %ebp
f01013e0:	89 e5                	mov    %esp,%ebp
f01013e2:	56                   	push   %esi
f01013e3:	53                   	push   %ebx
f01013e4:	8b 75 08             	mov    0x8(%ebp),%esi
f01013e7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013ea:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013ed:	89 f0                	mov    %esi,%eax
f01013ef:	85 c9                	test   %ecx,%ecx
f01013f1:	74 23                	je     f0101416 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
f01013f3:	83 e9 01             	sub    $0x1,%ecx
f01013f6:	74 1b                	je     f0101413 <strlcpy+0x34>
f01013f8:	0f b6 1a             	movzbl (%edx),%ebx
f01013fb:	84 db                	test   %bl,%bl
f01013fd:	74 14                	je     f0101413 <strlcpy+0x34>
			*dst++ = *src++;
f01013ff:	88 18                	mov    %bl,(%eax)
f0101401:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101404:	83 e9 01             	sub    $0x1,%ecx
f0101407:	74 0a                	je     f0101413 <strlcpy+0x34>
			*dst++ = *src++;
f0101409:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010140c:	0f b6 1a             	movzbl (%edx),%ebx
f010140f:	84 db                	test   %bl,%bl
f0101411:	75 ec                	jne    f01013ff <strlcpy+0x20>
			*dst++ = *src++;
		*dst = '\0';
f0101413:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101416:	29 f0                	sub    %esi,%eax
}
f0101418:	5b                   	pop    %ebx
f0101419:	5e                   	pop    %esi
f010141a:	5d                   	pop    %ebp
f010141b:	c3                   	ret    

f010141c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010141c:	55                   	push   %ebp
f010141d:	89 e5                	mov    %esp,%ebp
f010141f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101422:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101425:	0f b6 01             	movzbl (%ecx),%eax
f0101428:	84 c0                	test   %al,%al
f010142a:	74 15                	je     f0101441 <strcmp+0x25>
f010142c:	3a 02                	cmp    (%edx),%al
f010142e:	75 11                	jne    f0101441 <strcmp+0x25>
		p++, q++;
f0101430:	83 c1 01             	add    $0x1,%ecx
f0101433:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101436:	0f b6 01             	movzbl (%ecx),%eax
f0101439:	84 c0                	test   %al,%al
f010143b:	74 04                	je     f0101441 <strcmp+0x25>
f010143d:	3a 02                	cmp    (%edx),%al
f010143f:	74 ef                	je     f0101430 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101441:	0f b6 c0             	movzbl %al,%eax
f0101444:	0f b6 12             	movzbl (%edx),%edx
f0101447:	29 d0                	sub    %edx,%eax
}
f0101449:	5d                   	pop    %ebp
f010144a:	c3                   	ret    

f010144b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010144b:	55                   	push   %ebp
f010144c:	89 e5                	mov    %esp,%ebp
f010144e:	53                   	push   %ebx
f010144f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101452:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101455:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101458:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010145d:	85 d2                	test   %edx,%edx
f010145f:	74 28                	je     f0101489 <strncmp+0x3e>
f0101461:	0f b6 01             	movzbl (%ecx),%eax
f0101464:	84 c0                	test   %al,%al
f0101466:	74 24                	je     f010148c <strncmp+0x41>
f0101468:	3a 03                	cmp    (%ebx),%al
f010146a:	75 20                	jne    f010148c <strncmp+0x41>
f010146c:	83 ea 01             	sub    $0x1,%edx
f010146f:	74 13                	je     f0101484 <strncmp+0x39>
		n--, p++, q++;
f0101471:	83 c1 01             	add    $0x1,%ecx
f0101474:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101477:	0f b6 01             	movzbl (%ecx),%eax
f010147a:	84 c0                	test   %al,%al
f010147c:	74 0e                	je     f010148c <strncmp+0x41>
f010147e:	3a 03                	cmp    (%ebx),%al
f0101480:	74 ea                	je     f010146c <strncmp+0x21>
f0101482:	eb 08                	jmp    f010148c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101484:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101489:	5b                   	pop    %ebx
f010148a:	5d                   	pop    %ebp
f010148b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010148c:	0f b6 01             	movzbl (%ecx),%eax
f010148f:	0f b6 13             	movzbl (%ebx),%edx
f0101492:	29 d0                	sub    %edx,%eax
f0101494:	eb f3                	jmp    f0101489 <strncmp+0x3e>

f0101496 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101496:	55                   	push   %ebp
f0101497:	89 e5                	mov    %esp,%ebp
f0101499:	8b 45 08             	mov    0x8(%ebp),%eax
f010149c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014a0:	0f b6 10             	movzbl (%eax),%edx
f01014a3:	84 d2                	test   %dl,%dl
f01014a5:	74 1c                	je     f01014c3 <strchr+0x2d>
		if (*s == c)
f01014a7:	38 ca                	cmp    %cl,%dl
f01014a9:	75 07                	jne    f01014b2 <strchr+0x1c>
f01014ab:	eb 1b                	jmp    f01014c8 <strchr+0x32>
f01014ad:	38 ca                	cmp    %cl,%dl
f01014af:	90                   	nop
f01014b0:	74 16                	je     f01014c8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014b2:	83 c0 01             	add    $0x1,%eax
f01014b5:	0f b6 10             	movzbl (%eax),%edx
f01014b8:	84 d2                	test   %dl,%dl
f01014ba:	75 f1                	jne    f01014ad <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01014bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01014c1:	eb 05                	jmp    f01014c8 <strchr+0x32>
f01014c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014c8:	5d                   	pop    %ebp
f01014c9:	c3                   	ret    

f01014ca <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014ca:	55                   	push   %ebp
f01014cb:	89 e5                	mov    %esp,%ebp
f01014cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014d4:	0f b6 10             	movzbl (%eax),%edx
f01014d7:	84 d2                	test   %dl,%dl
f01014d9:	74 14                	je     f01014ef <strfind+0x25>
		if (*s == c)
f01014db:	38 ca                	cmp    %cl,%dl
f01014dd:	75 06                	jne    f01014e5 <strfind+0x1b>
f01014df:	eb 0e                	jmp    f01014ef <strfind+0x25>
f01014e1:	38 ca                	cmp    %cl,%dl
f01014e3:	74 0a                	je     f01014ef <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01014e5:	83 c0 01             	add    $0x1,%eax
f01014e8:	0f b6 10             	movzbl (%eax),%edx
f01014eb:	84 d2                	test   %dl,%dl
f01014ed:	75 f2                	jne    f01014e1 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01014ef:	5d                   	pop    %ebp
f01014f0:	c3                   	ret    

f01014f1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014f1:	55                   	push   %ebp
f01014f2:	89 e5                	mov    %esp,%ebp
f01014f4:	83 ec 0c             	sub    $0xc,%esp
f01014f7:	89 1c 24             	mov    %ebx,(%esp)
f01014fa:	89 74 24 04          	mov    %esi,0x4(%esp)
f01014fe:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101502:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101505:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101508:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010150b:	85 c9                	test   %ecx,%ecx
f010150d:	74 30                	je     f010153f <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010150f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101515:	75 25                	jne    f010153c <memset+0x4b>
f0101517:	f6 c1 03             	test   $0x3,%cl
f010151a:	75 20                	jne    f010153c <memset+0x4b>
		c &= 0xFF;
f010151c:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010151f:	89 d3                	mov    %edx,%ebx
f0101521:	c1 e3 08             	shl    $0x8,%ebx
f0101524:	89 d6                	mov    %edx,%esi
f0101526:	c1 e6 18             	shl    $0x18,%esi
f0101529:	89 d0                	mov    %edx,%eax
f010152b:	c1 e0 10             	shl    $0x10,%eax
f010152e:	09 f0                	or     %esi,%eax
f0101530:	09 d0                	or     %edx,%eax
f0101532:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101534:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101537:	fc                   	cld    
f0101538:	f3 ab                	rep stos %eax,%es:(%edi)
f010153a:	eb 03                	jmp    f010153f <memset+0x4e>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010153c:	fc                   	cld    
f010153d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010153f:	89 f8                	mov    %edi,%eax
f0101541:	8b 1c 24             	mov    (%esp),%ebx
f0101544:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101548:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010154c:	89 ec                	mov    %ebp,%esp
f010154e:	5d                   	pop    %ebp
f010154f:	c3                   	ret    

f0101550 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101550:	55                   	push   %ebp
f0101551:	89 e5                	mov    %esp,%ebp
f0101553:	83 ec 08             	sub    $0x8,%esp
f0101556:	89 34 24             	mov    %esi,(%esp)
f0101559:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010155d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101560:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101563:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101566:	39 c6                	cmp    %eax,%esi
f0101568:	73 36                	jae    f01015a0 <memmove+0x50>
f010156a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010156d:	39 d0                	cmp    %edx,%eax
f010156f:	73 2f                	jae    f01015a0 <memmove+0x50>
		s += n;
		d += n;
f0101571:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101574:	f6 c2 03             	test   $0x3,%dl
f0101577:	75 1b                	jne    f0101594 <memmove+0x44>
f0101579:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010157f:	75 13                	jne    f0101594 <memmove+0x44>
f0101581:	f6 c1 03             	test   $0x3,%cl
f0101584:	75 0e                	jne    f0101594 <memmove+0x44>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101586:	83 ef 04             	sub    $0x4,%edi
f0101589:	8d 72 fc             	lea    -0x4(%edx),%esi
f010158c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010158f:	fd                   	std    
f0101590:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101592:	eb 09                	jmp    f010159d <memmove+0x4d>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101594:	83 ef 01             	sub    $0x1,%edi
f0101597:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010159a:	fd                   	std    
f010159b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010159d:	fc                   	cld    
f010159e:	eb 20                	jmp    f01015c0 <memmove+0x70>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015a0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015a6:	75 13                	jne    f01015bb <memmove+0x6b>
f01015a8:	a8 03                	test   $0x3,%al
f01015aa:	75 0f                	jne    f01015bb <memmove+0x6b>
f01015ac:	f6 c1 03             	test   $0x3,%cl
f01015af:	75 0a                	jne    f01015bb <memmove+0x6b>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015b1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015b4:	89 c7                	mov    %eax,%edi
f01015b6:	fc                   	cld    
f01015b7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015b9:	eb 05                	jmp    f01015c0 <memmove+0x70>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015bb:	89 c7                	mov    %eax,%edi
f01015bd:	fc                   	cld    
f01015be:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015c0:	8b 34 24             	mov    (%esp),%esi
f01015c3:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01015c7:	89 ec                	mov    %ebp,%esp
f01015c9:	5d                   	pop    %ebp
f01015ca:	c3                   	ret    

f01015cb <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01015cb:	55                   	push   %ebp
f01015cc:	89 e5                	mov    %esp,%ebp
f01015ce:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015d1:	8b 45 10             	mov    0x10(%ebp),%eax
f01015d4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015df:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e2:	89 04 24             	mov    %eax,(%esp)
f01015e5:	e8 66 ff ff ff       	call   f0101550 <memmove>
}
f01015ea:	c9                   	leave  
f01015eb:	c3                   	ret    

f01015ec <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015ec:	55                   	push   %ebp
f01015ed:	89 e5                	mov    %esp,%ebp
f01015ef:	57                   	push   %edi
f01015f0:	56                   	push   %esi
f01015f1:	53                   	push   %ebx
f01015f2:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01015f5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015f8:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015fb:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101600:	85 ff                	test   %edi,%edi
f0101602:	74 38                	je     f010163c <memcmp+0x50>
		if (*s1 != *s2)
f0101604:	0f b6 03             	movzbl (%ebx),%eax
f0101607:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010160a:	83 ef 01             	sub    $0x1,%edi
f010160d:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0101612:	38 c8                	cmp    %cl,%al
f0101614:	74 1d                	je     f0101633 <memcmp+0x47>
f0101616:	eb 11                	jmp    f0101629 <memcmp+0x3d>
f0101618:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010161d:	0f b6 4c 16 01       	movzbl 0x1(%esi,%edx,1),%ecx
f0101622:	83 c2 01             	add    $0x1,%edx
f0101625:	38 c8                	cmp    %cl,%al
f0101627:	74 0a                	je     f0101633 <memcmp+0x47>
			return (int) *s1 - (int) *s2;
f0101629:	0f b6 c0             	movzbl %al,%eax
f010162c:	0f b6 c9             	movzbl %cl,%ecx
f010162f:	29 c8                	sub    %ecx,%eax
f0101631:	eb 09                	jmp    f010163c <memcmp+0x50>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101633:	39 fa                	cmp    %edi,%edx
f0101635:	75 e1                	jne    f0101618 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101637:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010163c:	5b                   	pop    %ebx
f010163d:	5e                   	pop    %esi
f010163e:	5f                   	pop    %edi
f010163f:	5d                   	pop    %ebp
f0101640:	c3                   	ret    

f0101641 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101641:	55                   	push   %ebp
f0101642:	89 e5                	mov    %esp,%ebp
f0101644:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101647:	89 c2                	mov    %eax,%edx
f0101649:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010164c:	39 d0                	cmp    %edx,%eax
f010164e:	73 15                	jae    f0101665 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101650:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101654:	38 08                	cmp    %cl,(%eax)
f0101656:	75 06                	jne    f010165e <memfind+0x1d>
f0101658:	eb 0b                	jmp    f0101665 <memfind+0x24>
f010165a:	38 08                	cmp    %cl,(%eax)
f010165c:	74 07                	je     f0101665 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010165e:	83 c0 01             	add    $0x1,%eax
f0101661:	39 c2                	cmp    %eax,%edx
f0101663:	77 f5                	ja     f010165a <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101665:	5d                   	pop    %ebp
f0101666:	c3                   	ret    

f0101667 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101667:	55                   	push   %ebp
f0101668:	89 e5                	mov    %esp,%ebp
f010166a:	57                   	push   %edi
f010166b:	56                   	push   %esi
f010166c:	53                   	push   %ebx
f010166d:	8b 55 08             	mov    0x8(%ebp),%edx
f0101670:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101673:	0f b6 02             	movzbl (%edx),%eax
f0101676:	3c 20                	cmp    $0x20,%al
f0101678:	74 04                	je     f010167e <strtol+0x17>
f010167a:	3c 09                	cmp    $0x9,%al
f010167c:	75 0e                	jne    f010168c <strtol+0x25>
		s++;
f010167e:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101681:	0f b6 02             	movzbl (%edx),%eax
f0101684:	3c 20                	cmp    $0x20,%al
f0101686:	74 f6                	je     f010167e <strtol+0x17>
f0101688:	3c 09                	cmp    $0x9,%al
f010168a:	74 f2                	je     f010167e <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f010168c:	3c 2b                	cmp    $0x2b,%al
f010168e:	75 0a                	jne    f010169a <strtol+0x33>
		s++;
f0101690:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101693:	bf 00 00 00 00       	mov    $0x0,%edi
f0101698:	eb 10                	jmp    f01016aa <strtol+0x43>
f010169a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010169f:	3c 2d                	cmp    $0x2d,%al
f01016a1:	75 07                	jne    f01016aa <strtol+0x43>
		s++, neg = 1;
f01016a3:	83 c2 01             	add    $0x1,%edx
f01016a6:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016aa:	85 db                	test   %ebx,%ebx
f01016ac:	0f 94 c0             	sete   %al
f01016af:	74 05                	je     f01016b6 <strtol+0x4f>
f01016b1:	83 fb 10             	cmp    $0x10,%ebx
f01016b4:	75 15                	jne    f01016cb <strtol+0x64>
f01016b6:	80 3a 30             	cmpb   $0x30,(%edx)
f01016b9:	75 10                	jne    f01016cb <strtol+0x64>
f01016bb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016bf:	75 0a                	jne    f01016cb <strtol+0x64>
		s += 2, base = 16;
f01016c1:	83 c2 02             	add    $0x2,%edx
f01016c4:	bb 10 00 00 00       	mov    $0x10,%ebx
f01016c9:	eb 13                	jmp    f01016de <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f01016cb:	84 c0                	test   %al,%al
f01016cd:	74 0f                	je     f01016de <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016cf:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016d4:	80 3a 30             	cmpb   $0x30,(%edx)
f01016d7:	75 05                	jne    f01016de <strtol+0x77>
		s++, base = 8;
f01016d9:	83 c2 01             	add    $0x1,%edx
f01016dc:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01016de:	b8 00 00 00 00       	mov    $0x0,%eax
f01016e3:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016e5:	0f b6 0a             	movzbl (%edx),%ecx
f01016e8:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01016eb:	80 fb 09             	cmp    $0x9,%bl
f01016ee:	77 08                	ja     f01016f8 <strtol+0x91>
			dig = *s - '0';
f01016f0:	0f be c9             	movsbl %cl,%ecx
f01016f3:	83 e9 30             	sub    $0x30,%ecx
f01016f6:	eb 1e                	jmp    f0101716 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01016f8:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01016fb:	80 fb 19             	cmp    $0x19,%bl
f01016fe:	77 08                	ja     f0101708 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0101700:	0f be c9             	movsbl %cl,%ecx
f0101703:	83 e9 57             	sub    $0x57,%ecx
f0101706:	eb 0e                	jmp    f0101716 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101708:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f010170b:	80 fb 19             	cmp    $0x19,%bl
f010170e:	77 15                	ja     f0101725 <strtol+0xbe>
			dig = *s - 'A' + 10;
f0101710:	0f be c9             	movsbl %cl,%ecx
f0101713:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101716:	39 f1                	cmp    %esi,%ecx
f0101718:	7d 0f                	jge    f0101729 <strtol+0xc2>
			break;
		s++, val = (val * base) + dig;
f010171a:	83 c2 01             	add    $0x1,%edx
f010171d:	0f af c6             	imul   %esi,%eax
f0101720:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101723:	eb c0                	jmp    f01016e5 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101725:	89 c1                	mov    %eax,%ecx
f0101727:	eb 02                	jmp    f010172b <strtol+0xc4>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101729:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f010172b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010172f:	74 05                	je     f0101736 <strtol+0xcf>
		*endptr = (char *) s;
f0101731:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101734:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101736:	89 ca                	mov    %ecx,%edx
f0101738:	f7 da                	neg    %edx
f010173a:	85 ff                	test   %edi,%edi
f010173c:	0f 45 c2             	cmovne %edx,%eax
}
f010173f:	5b                   	pop    %ebx
f0101740:	5e                   	pop    %esi
f0101741:	5f                   	pop    %edi
f0101742:	5d                   	pop    %ebp
f0101743:	c3                   	ret    
	...

f0101750 <__udivdi3>:
f0101750:	55                   	push   %ebp
f0101751:	89 e5                	mov    %esp,%ebp
f0101753:	57                   	push   %edi
f0101754:	56                   	push   %esi
f0101755:	83 ec 20             	sub    $0x20,%esp
f0101758:	8b 45 14             	mov    0x14(%ebp),%eax
f010175b:	8b 75 08             	mov    0x8(%ebp),%esi
f010175e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101761:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101764:	85 c0                	test   %eax,%eax
f0101766:	89 75 e8             	mov    %esi,-0x18(%ebp)
f0101769:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010176c:	75 3a                	jne    f01017a8 <__udivdi3+0x58>
f010176e:	39 f9                	cmp    %edi,%ecx
f0101770:	77 66                	ja     f01017d8 <__udivdi3+0x88>
f0101772:	85 c9                	test   %ecx,%ecx
f0101774:	75 0b                	jne    f0101781 <__udivdi3+0x31>
f0101776:	b8 01 00 00 00       	mov    $0x1,%eax
f010177b:	31 d2                	xor    %edx,%edx
f010177d:	f7 f1                	div    %ecx
f010177f:	89 c1                	mov    %eax,%ecx
f0101781:	89 f8                	mov    %edi,%eax
f0101783:	31 d2                	xor    %edx,%edx
f0101785:	f7 f1                	div    %ecx
f0101787:	89 c7                	mov    %eax,%edi
f0101789:	89 f0                	mov    %esi,%eax
f010178b:	f7 f1                	div    %ecx
f010178d:	89 fa                	mov    %edi,%edx
f010178f:	89 c6                	mov    %eax,%esi
f0101791:	89 75 f0             	mov    %esi,-0x10(%ebp)
f0101794:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101797:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010179a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010179d:	83 c4 20             	add    $0x20,%esp
f01017a0:	5e                   	pop    %esi
f01017a1:	5f                   	pop    %edi
f01017a2:	5d                   	pop    %ebp
f01017a3:	c3                   	ret    
f01017a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	31 d2                	xor    %edx,%edx
f01017aa:	31 f6                	xor    %esi,%esi
f01017ac:	39 f8                	cmp    %edi,%eax
f01017ae:	77 e1                	ja     f0101791 <__udivdi3+0x41>
f01017b0:	0f bd d0             	bsr    %eax,%edx
f01017b3:	83 f2 1f             	xor    $0x1f,%edx
f01017b6:	89 55 ec             	mov    %edx,-0x14(%ebp)
f01017b9:	75 2d                	jne    f01017e8 <__udivdi3+0x98>
f01017bb:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01017be:	39 4d f0             	cmp    %ecx,-0x10(%ebp)
f01017c1:	76 06                	jbe    f01017c9 <__udivdi3+0x79>
f01017c3:	39 f8                	cmp    %edi,%eax
f01017c5:	89 f2                	mov    %esi,%edx
f01017c7:	73 c8                	jae    f0101791 <__udivdi3+0x41>
f01017c9:	31 d2                	xor    %edx,%edx
f01017cb:	be 01 00 00 00       	mov    $0x1,%esi
f01017d0:	eb bf                	jmp    f0101791 <__udivdi3+0x41>
f01017d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017d8:	89 f0                	mov    %esi,%eax
f01017da:	89 fa                	mov    %edi,%edx
f01017dc:	f7 f1                	div    %ecx
f01017de:	31 d2                	xor    %edx,%edx
f01017e0:	89 c6                	mov    %eax,%esi
f01017e2:	eb ad                	jmp    f0101791 <__udivdi3+0x41>
f01017e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017e8:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01017ec:	89 c2                	mov    %eax,%edx
f01017ee:	b8 20 00 00 00       	mov    $0x20,%eax
f01017f3:	8b 75 f0             	mov    -0x10(%ebp),%esi
f01017f6:	2b 45 ec             	sub    -0x14(%ebp),%eax
f01017f9:	d3 e2                	shl    %cl,%edx
f01017fb:	89 c1                	mov    %eax,%ecx
f01017fd:	d3 ee                	shr    %cl,%esi
f01017ff:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101803:	09 d6                	or     %edx,%esi
f0101805:	89 fa                	mov    %edi,%edx
f0101807:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010180a:	8b 75 f0             	mov    -0x10(%ebp),%esi
f010180d:	d3 e6                	shl    %cl,%esi
f010180f:	89 c1                	mov    %eax,%ecx
f0101811:	d3 ea                	shr    %cl,%edx
f0101813:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101817:	89 75 f0             	mov    %esi,-0x10(%ebp)
f010181a:	8b 75 e8             	mov    -0x18(%ebp),%esi
f010181d:	d3 e7                	shl    %cl,%edi
f010181f:	89 c1                	mov    %eax,%ecx
f0101821:	d3 ee                	shr    %cl,%esi
f0101823:	09 fe                	or     %edi,%esi
f0101825:	89 f0                	mov    %esi,%eax
f0101827:	f7 75 e4             	divl   -0x1c(%ebp)
f010182a:	89 d7                	mov    %edx,%edi
f010182c:	89 c6                	mov    %eax,%esi
f010182e:	f7 65 f0             	mull   -0x10(%ebp)
f0101831:	39 d7                	cmp    %edx,%edi
f0101833:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101836:	72 12                	jb     f010184a <__udivdi3+0xfa>
f0101838:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010183b:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f010183f:	d3 e2                	shl    %cl,%edx
f0101841:	39 c2                	cmp    %eax,%edx
f0101843:	73 08                	jae    f010184d <__udivdi3+0xfd>
f0101845:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0101848:	75 03                	jne    f010184d <__udivdi3+0xfd>
f010184a:	83 ee 01             	sub    $0x1,%esi
f010184d:	31 d2                	xor    %edx,%edx
f010184f:	e9 3d ff ff ff       	jmp    f0101791 <__udivdi3+0x41>
	...

f0101860 <__umoddi3>:
f0101860:	55                   	push   %ebp
f0101861:	89 e5                	mov    %esp,%ebp
f0101863:	57                   	push   %edi
f0101864:	56                   	push   %esi
f0101865:	83 ec 20             	sub    $0x20,%esp
f0101868:	8b 7d 14             	mov    0x14(%ebp),%edi
f010186b:	8b 45 08             	mov    0x8(%ebp),%eax
f010186e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101871:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101874:	85 ff                	test   %edi,%edi
f0101876:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0101879:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f010187c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010187f:	89 f2                	mov    %esi,%edx
f0101881:	75 15                	jne    f0101898 <__umoddi3+0x38>
f0101883:	39 f1                	cmp    %esi,%ecx
f0101885:	76 41                	jbe    f01018c8 <__umoddi3+0x68>
f0101887:	f7 f1                	div    %ecx
f0101889:	89 d0                	mov    %edx,%eax
f010188b:	31 d2                	xor    %edx,%edx
f010188d:	83 c4 20             	add    $0x20,%esp
f0101890:	5e                   	pop    %esi
f0101891:	5f                   	pop    %edi
f0101892:	5d                   	pop    %ebp
f0101893:	c3                   	ret    
f0101894:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101898:	39 f7                	cmp    %esi,%edi
f010189a:	77 4c                	ja     f01018e8 <__umoddi3+0x88>
f010189c:	0f bd c7             	bsr    %edi,%eax
f010189f:	83 f0 1f             	xor    $0x1f,%eax
f01018a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01018a5:	75 51                	jne    f01018f8 <__umoddi3+0x98>
f01018a7:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f01018aa:	0f 87 e8 00 00 00    	ja     f0101998 <__umoddi3+0x138>
f01018b0:	89 f2                	mov    %esi,%edx
f01018b2:	8b 75 f0             	mov    -0x10(%ebp),%esi
f01018b5:	29 ce                	sub    %ecx,%esi
f01018b7:	19 fa                	sbb    %edi,%edx
f01018b9:	89 75 f0             	mov    %esi,-0x10(%ebp)
f01018bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018bf:	83 c4 20             	add    $0x20,%esp
f01018c2:	5e                   	pop    %esi
f01018c3:	5f                   	pop    %edi
f01018c4:	5d                   	pop    %ebp
f01018c5:	c3                   	ret    
f01018c6:	66 90                	xchg   %ax,%ax
f01018c8:	85 c9                	test   %ecx,%ecx
f01018ca:	75 0b                	jne    f01018d7 <__umoddi3+0x77>
f01018cc:	b8 01 00 00 00       	mov    $0x1,%eax
f01018d1:	31 d2                	xor    %edx,%edx
f01018d3:	f7 f1                	div    %ecx
f01018d5:	89 c1                	mov    %eax,%ecx
f01018d7:	89 f0                	mov    %esi,%eax
f01018d9:	31 d2                	xor    %edx,%edx
f01018db:	f7 f1                	div    %ecx
f01018dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018e0:	eb a5                	jmp    f0101887 <__umoddi3+0x27>
f01018e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018e8:	89 f2                	mov    %esi,%edx
f01018ea:	83 c4 20             	add    $0x20,%esp
f01018ed:	5e                   	pop    %esi
f01018ee:	5f                   	pop    %edi
f01018ef:	5d                   	pop    %ebp
f01018f0:	c3                   	ret    
f01018f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01018f8:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01018fc:	89 f2                	mov    %esi,%edx
f01018fe:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101901:	c7 45 f0 20 00 00 00 	movl   $0x20,-0x10(%ebp)
f0101908:	29 45 f0             	sub    %eax,-0x10(%ebp)
f010190b:	d3 e7                	shl    %cl,%edi
f010190d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101910:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101914:	d3 e8                	shr    %cl,%eax
f0101916:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f010191a:	09 f8                	or     %edi,%eax
f010191c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010191f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101922:	d3 e0                	shl    %cl,%eax
f0101924:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101928:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010192b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010192e:	d3 ea                	shr    %cl,%edx
f0101930:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101934:	d3 e6                	shl    %cl,%esi
f0101936:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f010193a:	d3 e8                	shr    %cl,%eax
f010193c:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101940:	09 f0                	or     %esi,%eax
f0101942:	8b 75 e8             	mov    -0x18(%ebp),%esi
f0101945:	f7 75 e4             	divl   -0x1c(%ebp)
f0101948:	d3 e6                	shl    %cl,%esi
f010194a:	89 75 e8             	mov    %esi,-0x18(%ebp)
f010194d:	89 d6                	mov    %edx,%esi
f010194f:	f7 65 f4             	mull   -0xc(%ebp)
f0101952:	89 d7                	mov    %edx,%edi
f0101954:	89 c2                	mov    %eax,%edx
f0101956:	39 fe                	cmp    %edi,%esi
f0101958:	89 f9                	mov    %edi,%ecx
f010195a:	72 30                	jb     f010198c <__umoddi3+0x12c>
f010195c:	39 45 e8             	cmp    %eax,-0x18(%ebp)
f010195f:	72 27                	jb     f0101988 <__umoddi3+0x128>
f0101961:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101964:	29 d0                	sub    %edx,%eax
f0101966:	19 ce                	sbb    %ecx,%esi
f0101968:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f010196c:	89 f2                	mov    %esi,%edx
f010196e:	d3 e8                	shr    %cl,%eax
f0101970:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101974:	d3 e2                	shl    %cl,%edx
f0101976:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f010197a:	09 d0                	or     %edx,%eax
f010197c:	89 f2                	mov    %esi,%edx
f010197e:	d3 ea                	shr    %cl,%edx
f0101980:	83 c4 20             	add    $0x20,%esp
f0101983:	5e                   	pop    %esi
f0101984:	5f                   	pop    %edi
f0101985:	5d                   	pop    %ebp
f0101986:	c3                   	ret    
f0101987:	90                   	nop
f0101988:	39 fe                	cmp    %edi,%esi
f010198a:	75 d5                	jne    f0101961 <__umoddi3+0x101>
f010198c:	89 f9                	mov    %edi,%ecx
f010198e:	89 c2                	mov    %eax,%edx
f0101990:	2b 55 f4             	sub    -0xc(%ebp),%edx
f0101993:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0101996:	eb c9                	jmp    f0101961 <__umoddi3+0x101>
f0101998:	39 f7                	cmp    %esi,%edi
f010199a:	0f 82 10 ff ff ff    	jb     f01018b0 <__umoddi3+0x50>
f01019a0:	e9 17 ff ff ff       	jmp    f01018bc <__umoddi3+0x5c>
