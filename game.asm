### CSDS314 Project
### Fabian Jimenez

# Snake
# Start with a length of 2 and collect the points around the map to increase length incrementally.
# Collisions with wall and snake body lead to game over.

# Movement WASD
## Using Keyboard MMIO Simualator 
# Bitmap Display
## Unit Width: 8px
## Unit Height: 8px
## Display Width: 512px
## Display Height: 256px
## Base Addr: static

#

.data

display: 	.space 	0x80000		# display equal to 512x256 pixels * 4
moveUp:	.word	0x00cd5c5c	# 00 up, next 6 bits color
moveDown:	.word	0x01cd5c5c	# 01 down, next 6 bits color
moveLeft:	.word	0x02cd5c5c	# 02 left, next 6 bits color
moveRight:	.word	0x03cd5c5c	# 03 right, next 6 bits color
moveX:		.word	0		# -1 move x-, 1 move x+ 
moveY:		.word	0		# -1 move y-, 1 move y+

keyboardInput:	.word 	0xffff0004	# MIPS keyboard controller register
headX:		.word	32		# initial x snake head
headY:		.word	27		# initial y snake head
tail:		.word	7552		# initial tail coord
pointX:		.word	32		# initial point x coord
pointY:		.word	8		# initial point y coord
bitmapX:	.word	64		# 64x32 to 512 x 256 adaptation for x
bitmapY:	.word	4		# 64x32 to 512 x 256 adaptation for y


.text
main:

### background
	
	
	la 	$t0, display	# display addr
	li 	$t1, 8192	# pixels display counter 64 * 32 * 4
	li 	$t3, 512	# counter for pixels per line
	li 	$t2, 0x0090ee90 # background color
	li 	$t5, 0x00a9a9a9	#

color:
	sw   	$t2, 0($t0)	# pixel color
	addi 	$t0, $t0, 4 	# next pixel
	addi 	$t1, $t1, -1	# pixel count--
	bnez 	$t1, color	# branch to dark grey if pixel counter != 0
	
#dgrey:
#	sw   	$t5, 0($t0)	# pixel color dark gre
#	addi 	$t0, $t0, 4 	# next pixel
#	addi 	$t1, $t1, -1	# pixel count--
#	bnez 	$t1, grey	# branch to dark grey if pixel counter != 0
	
### boundries

#top	
	la	$t0, display	# display addr
	addi	$t1, $zero, 64	# t1 = 64 length of row
	li 	$t2, 0x003b7600	# load green border color
topBoundry:
	sw	$t2, 0($t0)		
	addi	$t0, $t0, 4		
	addi	$t1, $t1, -1		
	bne	$t1, $0, topBoundry	
	
#bottom	
	la	$t0, display	
	addi	$t0, $t0, 7936		
	addi	$t1, $zero, 64		
bottomBoundry:
	sw	$t2, 0($t0)		
	addi	$t0, $t0, 4		
	addi	$t1, $t1, -1		
	bne	$t1, $0, bottomBoundry	
	
#left	
	la	$t0, display	
	addi	$t1, $zero, 256		
leftBoundry:
	sw	$t2, 0($t0)		
	addi	$t0, $t0, 256		
	addi	$t1, $t1, -1		
	bne	$t1, $0, leftBoundry	
	
#right	
	la	$t0, display		
	addi	$t0, $t0, 508		
	addi	$t1, $zero, 255		
rightBoundry:
	sw	$t2, 0($t0)
	addi	$t0, $t0, 256		
	addi	$t1, $t1, -1		
	bne	$t1, $0, rightBoundry	
	
	
### snake

	la	$t0, display		# display addr
	lw	$s2, tail		# s2 = tail of snake
	lw	$s3, moveUp		# s3 = direction of snake
	
	add	$t1, $s2, $t0		# t1 = tail start on bit map display
	sw	$s3, 0($t1)		# draw pixel where snake is
	addi	$t1, $t1, -256		# set t1 to pixel above
	sw	$s3, 0($t1)		# draw pixel where snake currently is
	
### point
	jal 	point


running:

	lw	$t0, 0xffff0004		# keyboard controller register
	
	addi	$v0, $zero, 32	
	addi	$a0, $zero, 80		# sleep, increase --> slow down game
	syscall
	beq	$t0, 0, pressW		
	beq	$t0, 119, pressW	# 'w'
	beq	$t0, 97, pressA		# 'a'
	beq	$t0, 100, pressD	# 'd'
	beq	$t0, 115, pressS	# 's'
	
	
pressW:
	lw	$s3, moveUp	# 
	add	$a0, $s3, $zero	# save snake moving up to a0
	jal	UpdateSnake
	jal 	moveSnakeHead
	j	backToRunning 	


	
pressA:
	lw	$s3, moveLeft	# s3 = direction of snake
	add	$a0, $s3, $zero	# a0 = direction of snake
	jal	UpdateSnake

	jal 	moveSnakeHead
	j	backToRunning
pressD:
	lw	$s3, moveRight	# 
	add	$a0, $s3, $zero	# save snake moving right to a0
	jal	UpdateSnake
	jal 	moveSnakeHead
	j	backToRunning
pressS:
	lw	$s3, moveDown	# 
	add	$a0, $s3, $zero	# save snake moving down to a0
	jal	UpdateSnake
	jal 	moveSnakeHead
	j	backToRunning
	
backToRunning:
	j 	running

UpdateSnake:
	addiu 	$sp, $sp, -24	# stack allocation
	sw 	$fp, 0($sp)
	sw 	$ra, 4($sp)	
	addiu 	$fp, $sp, 20	# setup UpdateSnake frame pointer
	
	lw	$t0, headX		# t0 = headX of snake
	lw	$t1, headY		# t1 = headY of snake
	lw	$t2, bitmapX		# t2 = 64
	mult	$t1, $t2		# headY * 64
	mflo	$t3			# t3 = headY * 64
	add	$t3, $t3, $t0		# t3 = headY * 64 + headX
	lw	$t2, bitmapY	# t2 = 4
	mult	$t3, $t2		# (headY * 64 + headX) * 4
	mflo	$t0			# t0 = (headY * 64 + headX) * 4
	
	la 	$t1, display	# load frame buffer address
	add	$t0, $t1, $t0		# t0 = (headY * 64 + headX) * 4 + frame address
	lw	$t4, 0($t0)		# save original val of pixel in t4
	sw	$a0, 0($t0)		# store direction plus color on the bitmap display
	
	lw	$t2, moveUp			# load word snake up = 0x0000ff00
	beq	$a0, $t2, contMovementUp		# if head direction and color == snake up branch to contMovementUp
	
	lw	$t2, moveDown			# load word snake up = 0x0100ff00
	beq	$a0, $t2, contMovementDown	# if head direction and color == snake down branch to contMovementUp
	
	lw	$t2, moveLeft			# load word snake up = 0x0200ff00
	beq	$a0, $t2, contMovementLeft	# if head direction and color == snake left branch to contMovementUp
	
	lw	$t2, moveRight			# load word snake up = 0x0300ff00
	beq	$a0, $t2, contMovementRight	# if head direction and color == snake right branch to contMovementUp
	
contMovementUp:
	addi	$t5, $zero, 0		# set x velocity to zero
	addi	$t6, $zero, -1	 	# set y velocity to -1
	sw	$t5, moveX		# backToRunning moveX in memory
	sw	$t6, moveY		# backToRunning moveY in memory
	j checkPointCollision
	
contMovementDown:
	addi	$t5, $zero, 0		# set x velocity to zero
	addi	$t6, $zero, 1 		# set y velocity to 1
	sw	$t5, moveX		# backToRunning moveX in memory
	sw	$t6, moveY		# backToRunning moveY in memory
	j checkPointCollision
	
contMovementLeft:
	addi	$t5, $zero, -1		# set x velocity to -1
	addi	$t6, $zero, 0 		# set y velocity to zero
	sw	$t5, moveX		# backToRunning moveX in memory
	sw	$t6, moveY		# backToRunning moveY in memory
	j checkPointCollision
	
contMovementRight:
	addi	$t5, $zero, 1		# set x velocity to 1
	addi	$t6, $zero, 0 		# set y velocity to zero
	sw	$t5, moveX		# backToRunning moveX in memory
	sw	$t6, moveY		# backToRunning moveY in memory
	j checkPointCollision	
	
checkPointCollision:
	
	li 	$t2, 0x00ffffff 			# load red color
	bne	$t2, $t4, checkCollision	# if head isnt on the point, check if head is on the playable background
	
	jal 	rdyNextPoint
	jal	point
	j	exitUpdateSnake
	
checkCollision:

	li	$t2, 0x0090ee90 	# light green background
	#li	$t3, 0x00a9a9a9
	beq	$t2, $t4, onPlayableArea # if on background branch
	#beq 	$t3, $t4, onDarkGrey	# if head location is dark grey
	j gameOver			# collision occured go to game over
	
	
gameOver:
	
	### Series of loads and writes of 64x32 coord black bits to b
	li	$t0, 23			# 
	li	$t1, 13			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 24			# 
	li	$t1, 13			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 25			# 
	li	$t1, 13			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 26			# 
	li	$t1, 13			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 23			# 
	li	$t1, 14			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 23			# 
	li	$t1, 15			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 24			# 
	li	$t1, 16			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 25			# 
	li	$t1, 16			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 23			# 
	li	$t1, 17			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 23			# 
	li	$t1, 18			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 23			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 24			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 25			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 26			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 29			# 
	li	$t1, 17			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 29			# 
	li	$t1, 18			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 29			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 30			# 
	li	$t1, 16			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 31			# 
	li	$t1, 16			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 32			# 
	li	$t1, 17			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 32			# 
	li	$t1, 18			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 32			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 35			# 
	li	$t1, 17			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 35			# 
	li	$t1, 18			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 35			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 36	 		# 
	li	$t1, 16			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 37			# 
	li	$t1, 16			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 36			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 37			# 
	li	$t1, 19			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 38			# 
	li	$t1, 13			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 38			# 
	li	$t1, 14			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 38			# 
	li	$t1, 15			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 38			# 
	li	$t1, 16			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 38			# 
	li	$t1, 17			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black
	
	li	$t0, 38			# 
	li	$t1, 18			#
	lw	$t2, bitmapX
	mult	$t1, $t2	
	mflo	$t3		
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0	
	la 	$t1, display
	add	$t0, $t1, $t0
	li	$t4, 0x0000000
	sw	$t4, 0($t0)		# paints pixel black

	addi 	$v0, $zero, 10			#END GAME
	syscall

onPlayableArea:

	# remove prev tail
	lw	$t0, tail		# tail
	la 	$t1, display		# display
	add	$t2, $t0, $t1		# tail pixel location
	li 	$t3, 0x0090ee90 		#
	lw	$t4, 0($t2)		# tail pixel location temp
	sw	$t3, 0($t2)		# tail moves on, background back to light green
	
	# set new tail
	lw	$t5, moveUp			# snake moving up
	beq	$t5, $t4, movingUp		# if true branch to movingUp
	
	lw	$t5, moveDown			# snake moving down
	beq	$t5, $t4, movingDown	# if true branch to movingDown
	
	lw	$t5, moveLeft			# snake moving left
	beq	$t5, $t4, movingLeft	# if true movingLeft
	
	lw	$t5, moveRight			# snake moving right
	beq	$t5, $t4, movingRight	# if true branch to movingRight
	
#onDarkGrey:
#
#	# remove prev tail
#	lw	$t0, tail		# tail
#	la 	$t1, display		# display
#	add	$t2, $t0, $t1		# tail pixel location
#	li 	$t3, 0x00a9a9a9		# dark grey
#	lw	$t4, 0($t2)		# tail pixel location temp
#	sw	$t3, 0($t2)		# tail moves on, background back to dark grey
#	
#	# set next tail
#	lw	$t5, moveUp			# snake moving up
#	beq	$t5, $t4, movingUp		# # if true branch to movingUp
#	
#	lw	$t5, moveDown			# snake moving down
#	beq	$t5, $t4, movingDown	# if true branch to movingDown
#	
#	lw	$t5, moveLeft			# snake moving left
#	beq	$t5, $t4, movingLeft	# if true movingLeft
#	
#	lw	$t5, moveRight			# snake moving right
#	beq	$t5, $t4, movingRight	# if true branch to movingRight
#
	
movingUp:
	addi	$t0, $t0, -256		# 
	sw	$t0, tail		# 1 bit up
	j exitUpdateSnake
	
movingDown:
	addi	$t0, $t0, 256		# 
	sw	$t0, tail		# 1 bit down
	j exitUpdateSnake
	
movingLeft:
	addi	$t0, $t0, -4		# 
	sw	$t0, tail		# 1 bit left
	j exitUpdateSnake
	
movingRight:
	addi	$t0, $t0, 4		# 
	sw	$t0, tail		# 1 bit right
	j exitUpdateSnake
	
exitUpdateSnake:
	
	lw 	$ra, 4($sp)	#deallocate
	lw 	$fp, 0($sp)	
	addiu 	$sp, $sp, 24	
	jr 	$ra		# return to caller's code
	
moveSnakeHead:
	addiu 	$sp, $sp, -24	# stack allocation
	sw 	$fp, 0($sp)	
	sw 	$ra, 4($sp)	
	addiu 	$fp, $sp, 20	# frame pointer	
	
	lw	$t3, moveX	# load moveX from memory
	lw	$t4, moveY	# load moveY from memory
	lw	$t5, headX	# load headX from memory
	lw	$t6, headY	# load headY from memory
	add	$t5, $t5, $t3	
	add	$t6, $t6, $t4	
	sw	$t5, headX	# store upated snakes head x
	sw	$t6, headY	# store updated snakes head y
	
	lw 	$ra, 4($sp)	# restore
	lw 	$fp, 0($sp)	
	addiu 	$sp, $sp, 24	
	jr 	$ra		

rdyNextPoint:
	addiu 	$sp, $sp, -24	# stack allocation
	sw 	$fp, 0($sp)	
	sw 	$ra, 4($sp)	
	addiu 	$fp, $sp, 20

point:
	addiu 	$sp, $sp, -24	# stack allocation
	sw 	$fp, 0($sp)	
	sw 	$ra, 4($sp)	
	addiu 	$fp, $sp, 20	
	
	lw	$t0, pointX		
	lw	$t1, pointY		
	lw	$t2, bitmapX	
	mult	$t1, $t2		
	mflo	$t3			
	add	$t3, $t3, $t0		
	lw	$t2, bitmapY	
	mult	$t3, $t2		
	mflo	$t0			
	
	la 	$t1, display	
	add	$t0, $t1, $t0		
	li	$t4, 0x00ffffff 
	sw	$t4, 0($t0)		
	
	lw 	$ra, 4($sp)	
	lw 	$fp, 0($sp)	
	addiu 	$sp, $sp, 24	
	jr 	$ra		
	
randNextPoint:		
	addi	$v0, $zero, 42	# random int 
	addi	$a1, $zero, 63	
	syscall
	add	$t1, $zero, $a0	# random pointX
	
	addi	$v0, $zero, 42	# random int 
	addi	$a1, $zero, 31	
	syscall
	add	$t2, $zero, $a0	# random pointY
	
	lw	$t3, bitmapX	
	mult	$t2, $t3		
	mflo	$t4			
	add	$t4, $t4, $t1		
	lw	$t3, bitmapY	
	mult	$t3, $t4	
	mflo	$t4			
	
	la 	$t0, display	
	add	$t0, $t4, $t0		
	lw	$t5, 0($t0)		
	
	li	$t6, 0x0090ee90 		
	beq	$t5, $t6, saveNextPoint	#next point in playable area, not on snake, save
	j randNextPoint

saveNextPoint:
	sw	$t1, pointX
	sw	$t2, pointY	

	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code

retry:
	j main
