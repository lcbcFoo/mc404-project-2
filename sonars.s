@ Lucas de Camargo Barros de Castro
@ RA: 172678
@
@ This file implements all functions related to the robot sonars from api_robot2.h


@ Reads one of the sonars.
@ Parameter:
@   r0: the sonar id (ranges from 0 to 15).
@ Returns:
@   r0: distance of the selected sonar
read_sonar:
        stmfd sp!, {r0}         @ Stacks r0 for syscall

        mov r7, #16
        svc 0x0

        add sp, #4              @ Remove parameter from stack
        mov pc, lr


@ Reads all sonars at once.
@ Parameters:
@   r0: start - reading goes from this integer and
@   r1: end - reading goes until this integer (a range of sonars to be read)
@   r2: distances - mem addr of the int array that must receive the distances.
@ Returns:
@   void
read_sonars:
        stmfd sp!, {lr}         @ Stores the return link in the stack
        mov r3, r0              @ Stores the start sonar in r3

loop:
        bl read_sonar           @ Read sonar for current sonar id
        str r0, [r2], #4        @ Stores distance in the array

        add r3, r3, #1          @ Increments r3 and checks if the loop is done
        mov r0, r3
        cmp r0, r1
        blt loop
