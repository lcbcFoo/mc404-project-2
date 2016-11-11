@ Lucas de Camargo Barros de Castro
@ RA: 172678
@
@ This file implements all functions from api_robot2 related to the robot motors


@ Parameter:
@ Sets motor speed.
@   r0: mem addr of motor_cfg_t struct containing motor id and motor speed
@ Returns:
@   void
set_motor_speed:

        ldrb r1, [r0, #1]           @ Loads the speed
        ldrb r0, [r0]               @ Loads motor id
        stmfd sp!, {r0, r1}         @ Stacks parameters for syscall

        mov r7, #18                 
        svc 0x0

        add sp, sp, #8              @ Removes parameters from stack and returns
        mov pc, lr


@ Sets both motors speed.
@ Parameters:
@   r0: mem addr of a motor_cfg_t struct containing motor id and motor speed
@   r1: mem addr of a motor_cfg_t struct containing motor id and motor speed
@ Returns:
@   void
set_motors_speed:
        ldrb r2, [r0]               @ Loads motors id
        ldrb r3, [r1]

        cmp r2, r3                  @ Checks if r0 contains the motor0 address
        blt endif
        mov r2, r0                  @ if not, swaps r0 and r1
        mov r0, r1,
        mov r1, r2

endif:

        ldrb r0, [r0, #1]           @ Loads motor0 speed
        ldrb r1. [r1, #1]           @ Loads motor1 speed
        stmfd sp!, {r0, r1}         @ Stacks parameters for syscall

        mov r7, #19                 @ Sets motor speed with syscall
        svc 0x0

        add sp, sp, #8              @ Removes parameters from stack and returns
        mov pc, lr
