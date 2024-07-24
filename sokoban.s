# Enhancement 1 (Option 1):
# Increase difficulty by increasing the number of boxes and targets.

# Enhancement 2 (Option 1):
# Improve the random number generator by implementing a formal pseudo-random generation function.
# The pseudo-random generator uses LCG algorithm.

.data
character:  .word 0,0
successCounter: .word 0
board: .byte 6, 6, 6, 6, 6, 6, 6, 6  # top row
       .byte 6, 0, 0, 0, 0, 0, 0, 6
       .byte 6, 0, 0, 0, 0, 0, 0, 6
       .byte 6, 0, 0, 0, 0, 0, 0, 6
       .byte 6, 0, 0, 0, 0, 0, 0, 6
       .byte 6, 0, 0, 0, 0, 0, 0, 6
       .byte 6, 0, 0, 0, 0, 0, 0, 6 
       .byte 6, 6, 6, 6, 6, 6, 6, 6  # bottom row

a: .word 1703515645
c: .word 12346 
m: .word 3147483647     
X_n: .word 0 


konamiCode:    .byte 0, 0, 1, 1, 2, 3, 2, 3
konamiPosition: .byte 0

collisionPrompt: .string "\nYou cannot move in this direction because it's blocked.\n"
successPrompt: .string "\nYou have successfully win the game!\n"

inputPrompt: .string "Enter a number for the number of boxes:\n"
invalidPrompt: .string "The number should be from 1 to 15 inclusive, please enter a different number for the number of boxes.\n"

.globl main
.text

main:
    # TODO: Before we deal with the LEDs, generate random locations for
    # the character, box, and target. static locations have been provided
    # for the (x,y) coordinates for each of these elements within the 8x8
    # grid. 
    # There is a rand function, but note that it isn't very good! You 
    # should at least make sure that none of the items are on top of each
    # other.
    
    # reset the success count
    la a1, successCounter
    sw zero, (0)a1

    # Set the LED to black
    li a0, 0x000000
    li a1, 0
    li a2, 0
    
    sw zero, 0(t5)
    sw zero, 0(t6)

    li s7, LED_MATRIX_0_WIDTH
    li s8, LED_MATRIX_0_HEIGHT
    loopBlack:
        beq a2, s8, loopBlackDone
        jal setLED
        
        addi a1, a1, 1
        bne a1, s7, loopBlack
        
        li a1, 0
        addi a2, a2, 1
        jal loopBlack
    loopBlackDone:
        
    li a7, 4
    la a0, inputPrompt
    ecall
    
    call readInt
    mv s0, a0
    
    li a7, 1
    blt s0, a7, invalidInput
    li a7, 15
    bgt s0, a7, invalidInput

    # get the address of character
    la t4, character # character 
    
    slli s0, s0, 3    # calculate the offset to align with the stack per line (8 bytes)
    sub sp, sp, s0
    mv t5, sp         # box
    sub sp, sp, s0
    mv t6, sp         # target
    
    srli s0, s0, 3    # comvert s0 back to input value
 
    setRandomPos:
        # loop through the board
        li s11, 1  # counter1
        li a1, 7   # upper bound
        li t1, 0
        li t2, 0
        li t3, 0
    
        traverseRowB:
            bge s11, a1, resetBoardDone
            li a2, 1  # Column counter

        traverseColB:
            bge a2, a1, nextRowB
            # calculate the coorect index in board
            slli a3, s11, 3
            add a3, a3, a2
            la t0, board
            add a3, t0, a3
            sb zero, 0(a3)
        
        nextColB:
            addi a2, a2, 1
            j traverseColB

        nextRowB:
            addi s11, s11, 1
            j traverseRowB
        
        resetBoardDone:
            # set the position of character
            jal getTime
            la t0, X_n
            sw a0, 0(t0)
            jal rand
            sw a0, 0(t4)
        
            jal rand
            sw a0, 4(t4)
        
            # update the board
            lw s1, 0(t4)
            lw s2, 4(t4)
        
            la t0, board
            slli t1, s2, 3
            add t1, s1, t1
            add t1, t0, t1
            
            li t3, 1
            sb t3, 0(t1)
 
        # start to assign positions to box and targets
        li s11, 0   # counter
        mv a5, t5   # save the base address of box
        mv a6, t6   # save the base address of target
        
        assignPos:
            # set the position of box
            jal rand
            sw a0, 0(a5)
        
            jal rand
            sw a0, 4(a5)
            
            # update the board
            lw s1, 0(a5)
            lw s2, 4(a5)
            
            jal checkBoxXCorner
            
            la t0, board
            slli t1, s2, 3
            add t1, s1, t1
            add t1, t0, t1
            
            li t3, 2
            lb s3, 0(t1)
            bne s3, zero, setRandomPos
            
            sb t3, 0(t1)
            
            # increment the box addr
            addi a5, a5, 8
            
        
            # set the position of target   
            jal rand
            sw a0, 0(a6)
  
            jal rand
            sw a0, 4(a6)
            
            # update the board array
            lw s1, 0(a6)
            lw s2, 4(a6)
            
            la t0, board
            slli t1, s2, 3
            add t1, s1, t1
            add t1, t0, t1
            
            li t3, 3
            lb s3, 0(t1)
            bne s3, zero, setRandomPos
            sb t3, 0(t1)
        
            # increment the target addr
            addi a6, a6, 8
                
            # incremenr the counter         
            addi s11, s11, 1
            
            bge s11, s0, assignEnd
            j assignPos
            
    assignEnd:
   
    mv a5, t5  # a5 = box base addr
    mv a6, t6  # a6 = target base addr
    

    li s11, 0
    li a1, 2
    mv a5, t5  # a5 = box base addr
    mv a6, t6  # a6 = target base addr  
        
    # check each box to avoid any box positions at the corner
    li s1, 1
    li s2, 1
    la t0, board
    slli t1, s2, 3
    add t1, s1, t1
    add t1, t0, t1
    lw t2, 0(t0)
    
    li a1, 1
    beq t2, a1, setRandomPos
    
    li s1, 1
    li s2, 6
    la t0, board
    slli t1, s2, 3
    add t1, s1, t1
    add t1, t0, t1
    lw t2, 0(t0)
    
    li a1, 1
    beq t2, a1, setRandomPos
    
    li s1, 6
    li s2, 6
    la t0, board
    slli t1, s2, 3
    add t1, s1, t1
    add t1, t0, t1
    lw t2, 0(t0)
    
    li a1, 1
    beq t2, a1, setRandomPos
    
    li s1, 6
    li s2, 1
    la t0, board
    slli t1, s2, 3
    add t1, s1, t1
    add t1, t0, t1
    lw t2, 0(t0)
    
    li a1, 1
    beq t2, a1, setRandomPos
  
        
    checkBoxNotInCornerDone:
    li s11, 0
    mv a5, t5 
    mv a6, t6
    li t2, 1
    li t3, 6
    li a1, 0
        
    beq s0, t2, boxesOnWallCheckDone   # no need to check if there are boxes together on the wall if n = 1
    
    li t2, 3
    ble s0, t2, checkBoxesOnWallTogether
    
    li s11, 1
    li a1, 1
    
    li t3, 6

    checkSquareLoop:    
        bge s11, t3, checkSquareLoopDone
        li a1, 1  # Column counter
        li t4, 6  # Bottommost row to check

        checkSquareInnerLoop:
            bge a1, t4, nextRowCheckSquare

            slli t1, s11, 3
            add t1, t1, a1
            la t0, board
            add t1, t0, t1

            lb t2, 0(t1)
            li a3, 2
            bne t2, a3, nextColumnCheckSquare

            # Check adjacent cells for boxes
            addi a2, t1, 1    # Right cell
            lb a2, 0(a2)
            bne a2, a3, nextColumnCheckSquare

            addi a2, t1, 8    # Below cell
            lb a2, 0(a2)
            bne a2, a3, nextColumnCheckSquare

            addi a2, t1, 9    # Diagonal cell
            lb a2, 0(a2)
            bne a2, a3, nextColumnCheckSquare

            j setRandomPos

        nextColumnCheckSquare:
            addi a1, a1, 1
            j checkSquareInnerLoop

        nextRowCheckSquare:
            addi s11, s11, 1
            j checkSquareLoop
        
    checkSquareLoopDone:
        li s11, 0
        mv a5, t5 
        mv a6, t6
        li t2, 1
        li t3, 6
        li a1, 0

    # check if there is any boxes on the wall with adjacent positions 
    checkBoxesOnWallTogether:
        bge s11, s0, boxesOnWallCheckDone
        lw s3, 0(a5)    # s3 = b.x
        lw s4, 4(a5)    # s4 = b.y

        # check if the box is on any wall
        beq s3, t2, checkBoxOnVerticalWall
        beq s3, t3, checkBoxOnVerticalWall
        beq s4, t2, checkBoxOnHorizontalWall
        beq s4, t3, checkBoxOnHorizontalWall
        j incrementBoxIndex

    # check the vertical wall
    checkBoxOnVerticalWall:
        li a1, 0 
        addi s4, s4, 1
        
        verticalWallLoop:
            bge a1, s0, incrementBoxIndex
            beq a1, s11, skipV   # skip itself

            slli s1, a1, 3    # offset
            add s1, t5, s1
            lw s5, 0(s1)   # x
            lw s6, 4(s1)   # y

            # Check if the other box is directly below the current one
            beq s3, s5, checkBoxOnVerticalWallY
            addi a1, a1, 1
            j verticalWallLoop
            
        checkBoxOnVerticalWallY:
            beq s4, s6, setRandomPos
            addi a1, a1, 1
            j verticalWallLoop
        
        skipV:
            addi a1, a1, 1
            j verticalWallLoop
            
    # check the horizontal wall
    checkBoxOnHorizontalWall:
        li a1, 0 
        addi s3, s3, 1
        
        horizontalWallLoop:
            bge a1, s0, incrementBoxIndex
            beq a1, s11, skipH   # skip itself

            slli s1, a1, 3    # offset
            add s1, t5, s1
            lw s5, 0(s1)   # x
            lw s6, 4(s1)   # y

            # Check if the other box is directly below the current one
            beq s3, s5, checkBoxOnHorizontalWallY
            addi a1, a1, 1
            j horizontalWallLoop
            
        checkBoxOnHorizontalWallY:
            beq s4, s6, setRandomPos
            addi a1, a1, 1
            j horizontalWallLoop
    
        skipH:
            addi a1, a1, 1
            j horizontalWallLoop
 
    incrementBoxIndex:       
        addi s11, s11, 1
        addi a5, a5, 8
        j checkBoxesOnWallTogether
        
    boxesOnWallCheckDone:
        li s11, 9    # loop counter
        li s2, 0     # box counter
        li s3, 0     # target counter
        li s4, 0     # total box counter
        li s5, 0     # total target counter
        li a3, 15
        li a4, 2     # box checker
        li a5, 3     # target checker
        mv a5, t5 
        mv a6, t6
        
    # check if any targets are on the wall, make sure they can be reached by the boxes
    # check upper wall
    la t0, board
    loopUpperWallCheck:
        bge s11, a3, loopUpperWallCheckDone 
        add s1, s11, t0
        lb a7, 0(s1)
        beq a4, a7, incBoxUpper
        beq a5, a7, incTargetUpper
        
        addi s11, s11, 1
        j loopUpperWallCheck
        
    incBoxUpper:
        addi s2, s2, 1
        addi s4, s4, 1
        addi s11, s11, 1
        j loopUpperWallCheck
        
    incTargetUpper:
        addi s3, s3, 1
        addi s5, s5, 1
        addi s11, s11, 1
        j loopUpperWallCheck
        
    loopUpperWallCheckDone:
        bgt s2, s3, setRandomPos
        
        la t0, board
        li s2, 0
        li s3, 0
        
        li s11, 49    # loop counter
        li a3, 55
        li a1, 1
        
    loopLowerWallCheck:
        bge s11, a3, loopLowerWallCheckDone
        add s1, s11, a1
        add s1, s1, t0
        lb a7, 0(s1)
        beq a4, a7, incBoxLower
        beq a5, a7, incTargetLower
        
        addi s11, s11, 1
        j loopLowerWallCheck
        
    incBoxLower:
        addi s2, s2, 1
        addi s4, s4, 1
        addi s11, s11, 1
        j loopLowerWallCheck
        
    incTargetLower:
        addi s3, s3, 1
        addi s5, s5, 1
        addi s11, s11, 1
        j loopLowerWallCheck
        
    loopLowerWallCheckDone:
        bgt s2, s3, setRandomPos
        
        la t0, board
        li s2, 0
        li s3, 0
        
        li s11, 1    # loop counter
        li a3, 7
        li a1, 1
        
    loopSecondColumnCheck:
        bge s11, a3, loopSecondColumnCheckDone
        slli t1, s11, 3
        add t2, t1, a1
        add t2, t0, t2
        lb a7, 0(t2)
        beq a4, a7, incBoxSecond
        beq a5, a7, incTargetSecond

        addi s11, s11, 1   # Move to the next row
        j loopSecondColumnCheck
        
    incBoxSecond:
        addi s2, s2, 1
        addi s4, s4, 1
        addi s11, s11, 1
        j loopSecondColumnCheck
        
    incTargetSecond:
        addi s3, s3, 1
        addi s5, s5, 1
        addi s11, s11, 1
        j loopSecondColumnCheck
        
    loopSecondColumnCheckDone:
        bgt s2, s3, setRandomPos
        
        li s2, 0
        li s3, 0
        
        li s11, 1
        li a3, 7
        li a1, 6
        
    loopSecondLastColumnCheck:
        bge s11, a3, loopSecondLastColumnCheckDone
        slli t1, s11, 3
        add t2, t1, a1 
        add t2, t0, t2
        lb a7, 0(t2)
        beq a4, a7, incBoxSecondLast
        beq a5, a7, incTargetSecondLast

        addi s11, s11, 1   # Move to the next row
        j loopSecondLastColumnCheck
        
    incBoxSecondLast:
        addi s2, s2, 1
        addi s4, s4, 1
        addi s11, s11, 1
        j loopSecondLastColumnCheck
        
    incTargetSecondLast:
        addi s3, s3, 1
        addi s5, s5, 1
        addi s11, s11, 1
        j loopSecondLastColumnCheck 

    loopSecondLastColumnCheckDone:
        bgt s2, s3, setRandomPos

    # check corner duplicate count for box and target
    OmitCorner:
        # upper left corner
        li s1, 1
        li s2, 1
        la t0, board
        slli t1, s2, 3
        add t1, s1, t1
        add t1, t0, t1
        lw t2, 0(t0)
        
        jal OmitCornerHelper
        
        li s1, 1
        li s2, 6
        la t0, board
        slli t1, s2, 3
        add t1, s1, t1
        add t1, t0, t1
        lw t2, 0(t0)
    
        jal OmitCornerHelper
        
        li s1, 6
        li s2, 6
        la t0, board
        slli t1, s2, 3
        add t1, s1, t1
        add t1, t0, t1
        lw t2, 0(t0)
        
        jal OmitCornerHelper
    
        li s1, 6
        li s2, 1
        la t0, board
        slli t1, s2, 3
        add t1, s1, t1
        add t1, t0, t1
        lw t2, 0(t0)
    
        jal OmitCornerHelper
        
    bgt s4, s5, setRandomPos

 
    # set up the wall
    # set top side
    li a1, 0     
    li a2, 0
    li s7, LED_MATRIX_0_WIDTH
    li s8, LED_MATRIX_0_HEIGHT
    topSide:
        li a0, 0xA52A2A
        jal setLED
        addi a1, a1, 1
        bne a1, s7, topSide

    # set bottom side
    li a1, 0     
    li a2, 7
    bottomSide:
        li a0, 0xA52A2A
        jal setLED
        addi a1, a1, 1
        bne a1, s7, bottomSide
    
    # set left side
    li a1, 0
    li a2, 1
    leftSide:
        li a0, 0xA52A2A
        jal setLED
        addi a2, a2, 1
        bne a2, s8, leftSide

    # set right side
    li a1, 7
    li a2, 1
    rightSide:
        li a0, 0xA52A2A
        jal setLED
        addi a2, a2, 1
        bne a2, s8, rightSide
        
    # calculate the positions in LED

    # character
    li a0, 0xFE0016 # red
    lw a1, 0(t4)
    lw a2, 4(t4) 
    jal setLED
    
    li a0, 0
    mv a5, t5 
    mv a6, t6
    lightUp:
        bge s11, s0, lightUpDone
        
        # box
        li a0, 0xFFFF00 # yellow
        lw a1, 0(a5)
        lw a2, 4(a5) 
        jal setLED
    
        # target
        li a0, 0x0028FE # blue
        lw a1, 0(a6)
        lw a2, 4(a6) 
        jal setLED
        
        addi s11, s11, 1
        addi a5, a5, 8
        addi, a6, a6, 8
        
        j lightUp

    lightUpDone:
        mv a5, t5 
        mv a6, t6
        li s11, 0
        li t0, 0
   
    # TODO: Enter a loop and wait for user input. Whenever user input is
    # received, update the grid with the new location of the player (and) 
    # if applicable, box and (target). You will also need to restart the
    # game if the user requests it and indicate when the box is located
    # in the same position as the target.

    gameLoop:
        la a1, successCounter
        sw zero, (0)a1
    
        # draw objects
        li s11, 0
        
        # save base addr of box of target
        mv a5, t5
        mv a6, t6
        
        loopDrawBoxes:
            bge s11, s0, loopDrawBoxesDone
            li a0, 0xFFFF00 # yellow
            lw a1, 0(a5)
            lw a2, 4(a5)
            jal setLED
        
            addi s11, s11, 1
            addi a5, a5, 8
            j loopDrawBoxes
            
        loopDrawBoxesDone:    
            mv a5, t5 
            li s11, 0
            
            li t2, 0 # counter
        
        loopDrawTargets:
            bge t2, s0, drawCharacter
            lw s5, 0(a6)  # s5 = t.x
            lw s6, 4(a6)  # s6 = t.y

            li s11, 0
            mv a5, t5

            li a0, 0x0028FE  # blue

        # loop to check if any box is on the current target
        loopBoxes:
            bge s11, s0, drawTarget  # draw the target blue if no box is on it
            lw s3, 0(a5)  # s3 = b.x
            lw s4, 4(a5)  # s4 = b.y
        
            beq s3, s5, boxOnTargetY
            addi s11, s11, 1
            addi a5, a5, 8
            j loopBoxes

        # the box and the target have the same x, check y
        boxOnTargetY:
            beq s4, s6, makeTargetGreen
            addi s11, s11, 1
            addi a5, a5, 8
            j loopBoxes

        makeTargetGreen:
            li a0, 0x00FF00  # change color to green

        drawTargetG:
            mv a1, s5  # Target x
            mv a2, s6  # Target y
            jal setLED
            
            la a1, successCounter
            lw, a2, 0(a1)
            addi a2, a2, 1
            sw a2, 0(a1)
         
            addi t2, t2, 1
            addi a6, a6, 8
            j loopDrawTargets
            
        drawTarget:
            mv a1, s5  # Target x
            mv a2, s6  # Target y
            jal setLED
    
            addi t2, t2, 1
            addi a6, a6, 8
            j loopDrawTargets

        drawCharacter:
            li a0, 0xFE0016 # red
            lw a1, 0(t4) # Load character x
            lw a2, 4(t4) # Load character y
            jal setLED        
        
        # take input from the user
        li s7, 0    # Up
        li s8, 1    # Down
        li s9, 2    # Left
        li s10, 3    # Right
    
        jal pollDpad
        mv s11, a0
        
        jal checkKonamiCode
     
        beq s11, s7, getTempUp        
        beq s11, s8, getTempDown
        beq s11, s9, getTempLeft
        beq s11, s10, getTempRight
        j gameLoop
            
        # calculate temp coordinates of the character
        # s1 = c.x
        # s2 = c.y
        getTempUp:
            lw s1, 0(t4)
            lw s2, 4(t4)
            addi s2, s2, -1
            j checkWall
        
        getTempDown:  
            lw s1, 0(t4)
            lw s2, 4(t4)
            addi s2, s2, 1
            j checkWall
        
        getTempLeft:
            lw s1, 0(t4)
            lw s2, 4(t4)
            addi s1, s1, -1
            j checkWall
    
        getTempRight:
            lw s1, 0(t4)
            lw s2, 4(t4)
            addi s1, s1, 1
        
        # check if the character would hit the wall
        checkWall:
            li a4, 0
            li a5, 7
            beq s1, a4, collision
            beq s1, a5, collision
            beq s2, a4, collision
            beq s2, a5, collision
            
        # check if the character would hit any box  
        checkAnyBox:
            li s11, 0  # counter
            mv a5, t5
        
        loopCheckBox:
            bge s11, s0, moveCharOnly
            lw s3, 0(a5)  # s3 = b.x
            lw s4, 4(a5)  # s4 = b.y

            beq s1, s3, checkBoxY   # Check if the x-coordinates match
            addi s11, s11, 1
            addi a5, a5, 8
            j loopCheckBox

        # character and cuurent box have the same x, check y
        checkBoxY:
            beq s2, s4, checkBoxHitWall

            addi s11, s11, 1
            addi a5, a5, 8
            j loopCheckBox
                
    
        moveCharOnly:
            # set old character to black
            lw a6, 0(t4)
            lw a7, 4(t4)
        
            li a0, 0x000000 # black
            mv a1, a6
            mv a2, a7
            jal setLED
        
            sw s1, 0(t4)    # save new character.x
            sw s2, 4(t4)    # save new character.y
        
            # set new character to red
            li a0, 0xFE0016 # red
            lw a1, 0(t4)
            lw a2, 4(t4) 
            jal setLED    
                    
            j gameLoop
        
        collision:
            li a7, 4
            la a0, collisionPrompt
            ecall
        
            j gameLoop
        
        checkBoxHitWall:
            # calculate difference between new x - old x and new y - old y
            # find difference
            
            # old c: s7 = c.x, s8 = c.y
            lw s7, 0(t4)
            sub a6, s1, s7
            lw s8, 4(t4)
            sub a7, s2, s8

            add a6, s3, a6
            add a7, s4, a7

            li a4, 0
            li a1, 7
            beq a6, a4, collision
            beq a6, a1, collision
            beq a7, a4, collision
            beq a7, a1, collision
            
        mv a2, t5
            
        checkboxWithBox:
            bge a4, s0, loopCheckTargetStart   
            
            lw s5, 0(a2)
            lw s6, 4(a2) 
            
            beq s5, a6, checkBoxWithBoxY2
            
            addi a4, a4, 1
            addi a2, a2, 8
            j checkboxWithBox
    
        checkBoxWithBoxY2:
            beq s6, a7, collision
            
            addi a4, a4, 1
            addi a2, a2, 8
            j checkboxWithBox
        
        loopCheckTargetStart:
            li a4, 0
            mv a3, t6
            
        # check if any target gets hit      
        loopCheckTarget:
            bge a4, s0, moveCharAndBox
            lw s5, 0(a3)  # s5 = t.x
            lw s6, 4(a3)  # s6 = t.y

            beq a6, s5, checkTargetY   # check if the x match
            addi a4, a4, 1
            addi a3, a3, 8
            j loopCheckTarget

        checkTargetY:
            beq a7, s6, success
            addi a4, a4, 1
            addi a3, a3, 8
            j loopCheckTarget
            
        moveCharAndBox:
            # set old character to black
            lw a1, 0(t4)
            lw a2, 4(t4)  
            li a0, 0x000000 # black
        
            jal setLED

            sw s1, 0(t4)    # save new character.x
            sw s2, 4(t4)    # save new character.y
        
            # set new character to red
            li a0, 0xFE0016 # red
            lw a1, 0(t4)
            lw a2, 4(t4) 
            jal setLED
        
            # box
            li a0, 0xFFFF00 # yellow
            
            mv a1, a6
            mv a2, a7
            jal setLED
            
            sw a6, 0(a5)    # save new box.x
            sw a7, 4(a5)    # save new box.y
    
            j gameLoop
        
        success:
            # set old character to black
            lw a1, 0(t4)
            lw a2, 4(t4)  
            li a0, 0x000000 # black
        
            jal setLED

            sw s1, 0(t4)    # save new character.x
            sw s2, 4(t4)    # save new character.y
        
            # set new character to red
            li a0, 0xFE0016 # red
            lw a1, 0(t4)
            lw a2, 4(t4) 
            jal setLED
        
            sw a6, 0(a5)    # save new box.x
            sw a7, 4(a5)    # save new box.y
            
            # target
            li a0, 0x35FD00 # green
            mv a1, a6
            mv a2, a7
            jal setLED
        
            la a1, successCounter
            lw a2, 0(a1)
            addi a2, a2, 1
            sw a2, 0(a1)
            
            beq a2, s0, successPt

            j gameLoop
            
        successPt:
            li a7, 4
            la a0, successPrompt
            ecall
            
            j gameLoop
         
        
        checkKonamiCode:
            la a4, konamiPosition    # a4 = konamiPosition base addr
            lbu a5, 0(a4)            # current index of Konami position
            la a6, konamiCode
            add a6, a6, a5
            lbu a6, 0(a6)

            bne a6, s11, resetKonamiPosition 

            addi a5, a5, 1 
            sb a5, 0(a4) 

            li a7, 8
            beq a5, a7, restartGame  # if the full code has been entered, restart the game

            jalr ra, ra, 0
        
        resetKonamiPosition:
            la a4, konamiPosition
            sb zero, 0(a4)
            jalr ra, ra, 0

        restartGame:
            la a4, konamiPosition
            sb zero, 0(a4)
        
            slli s0, s0, 3
            add sp, sp, s0  # deallocate space for targets
            add sp, sp, s0  # deallocate space for boxes
        
            j main

    
    invalidInput:
        li a7, 4
        la a0, invalidPrompt
        ecall
        
        j loopBlackDone
        
 
exit:
    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---
# Feel free to use (or modify) them however you see fit
OmitCornerHelper:
    li a1, 2
    beq t2, a1, decBoxUL
    li a1, 3
    beq t2, a1, decTargetUL
    
    jalr ra, ra, 0
    
decBoxUL:
    addi s4, s4, -1
    jalr ra, ra, 0
    
decTargetUL:
    addi s5, s5, -1
    jalr ra, ra, 0
    
checkBoxXCorner:
    li t1, 1
    li t2, 6
         
    beq s1, t1, checkBoxYCorner  # box.x = 1
    beq s2, t2, checkBoxYCorner  # box.x = 6
    beq s1, t1, checkBoxXCorner  # box.y = 1
    beq s2, t2, checkBoxXCorner  # box.y = 6
    jalr ra, ra, 0
    
checkBoxYCorner:
    beq s1, t2, setRandomPos 
    beq s2, t1, setRandomPos
    jalr ra, ra, 0

     
# Takes in a number in a0, and returns a (sort of) (okay no really) random 
# number from 0 to this number (exclusive)
getTime:
    li a7, 30
    li a0, 0 
    ecall 

    jalr ra, ra, 0
    
rand: 
    # citation: https://rosettacode.org/wiki/Linear_congruential_generator
    la t0, X_n
    lw a0, 0(t0) 
    lw t1, a
    lw t2, c
    lw t3, m

    # X_n = (a * X_n + c) mod m
    mul a0, t1, a0
    add a0, a0, t2        # a0 = a * X_n + c
    rem a0, a0, t3 
    
    sw a0, 0(t0)
    
    li t3, 6
    rem a0, a0, t3 
    addi a0, a0, 1
    
    # case0: a0 >= 1
    li t3, 1
    bge a0, t3, end
    
    # case1: a0 is a multiple of 6
    beq a0, zero, addOne
    
    # case2: a0 <= -7
    li t3, -7
    ble a0, t3, loopUntilGreaterThanZero
    
    # case3: a0 <= -1
    addi a0, a0, 6
    jalr ra, ra, 0
    
end:
    jalr ra, ra, 0
    
addOne:
    addi a0, a0, 1
    jalr ra, ra, 0
    
loopUntilGreaterThanZero:
    addi a0, a0, 76
    blt a0, zero, loopUntilGreaterThanZero
    jalr ra, ra, 0
    
readInt:
    addi sp, sp, -12
    li a0, 0
    mv a1, sp
    li a2, 12
    li a7, 63
    ecall
    li a1, 1
    add a2, sp, a0
    addi a2, a2, -2
    mv a0, zero
parse:
    blt a2, sp, parseEnd
    lb a7, 0(a2)
    addi a7, a7, -48
    li a3, 9
    bltu a3, a7, error
    mul a7, a7, a1
    add a0, a0, a7
    li a3, 10
    mul a1, a1, a3
    addi a2, a2, -1
    j parse
parseEnd:
    addi sp, sp, 12
    ret
error:
    j invalidInput

# Takes in an RGB color in a0, an x-coordinate in a1, and a y-coordinate
# in a2. Then it sets the led at (x, y) to the given color.
setLED:
    li t1, LED_MATRIX_0_WIDTH
    mul t0, a2, t1
    add t0, t0, a1
    li t1, 4
    mul t0, t0, t1
    li t1, LED_MATRIX_0_BASE
    add t0, t1, t0
    sw a0, (0)t0
    jr ra
    
# Polls the d-pad input until a button is pressed, then returns a number
# representing the button that was pressed in a0.
# The possible return values are:
# 0: UP
# 1: DOWN
# 2: LEFT
# 3: RIGHT
pollDpad:
    mv a0, zero
    li t1, 4
pollLoop:
    bge a0, t1, pollLoopEnd
    li t2, D_PAD_0_BASE
    slli t3, a0, 2
    add t2, t2, t3
    lw t3, (0)t2
    bnez t3, pollRelease
    addi a0, a0, 1
    j pollLoop
pollLoopEnd:
    j pollDpad
pollRelease:
    lw t3, (0)t2
    bnez t3, pollRelease
pollExit:
    jr ra
    

