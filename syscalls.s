@ Lucas de Camargo Barros de Castro
@ RA: 172678
@
@ This file implements the syscalls used by the api_robot_2.h and other routines
@ used by SOUL to keep system time and the alarms treatment working

.globl sys_read_sonar
.globl sys_reg_prox_callback
.globl sys_motor_speed
.globl sys_motors_speed
.globl sys_get_time
.globl sys_set_time
.globl sys_set_alarm
.globl update_sys_time
.globl check_alarms
.globl sys_init


@ Defines max number of alarms and callbacks
.set MAX_ALARMS,     8
.set MAX_CALLBACKS,  8

@ Defines masks used to communicate with GPIO
.set BASE_GPIO,             0x53F84000
.set WRITE_MOTOR0_SPEED,    0x00003F80
.set WRITE_MOTOR1_SPEED,    0x0000007F

.text
@ Read a sonar
sys_read_sonar:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0}
        msr cpsr_c, #0x13

        @ Checks if sonar id is valid
        cmp r0, #16
        blt endif2
        mov r0, #-1
        mov pc, lr

    endif2:
        @ r0 <= sonar id ready to be written
        lsl r0, r0, #2
        add r0, r0, #2

        @ r2 <= GDIR ready to be written
        ldr r1, =BASE_GPIO
        ldr r2, [r1]
        .set write_mask, 0x3FFFF
        ldr r3, =write_mask
        bic r2, r2, r3

        @ r0 <= new GDIR to b sent to GPIO
        orr r0, r0, r2

        @ Writes with TRIGGER = 1
        str r0, [r1]

        @ Waits to zero TRIGGER
        mov r2, #0
    loop0:
        add r2, r2, #1
        cmp r2, #1000
        bne loop0

        @ Writes with trigger = 0
        sub r0, r0, #2
        str r0, [r1]

        @ Waits FLAG = 1
    loop1:
        ldr r0, [r1]
        and r2, r0, #1
        cmp r2, #1
        bne loop1

        lsr r0, r0, #6
        ldr r1, =0xFFF
        and r0, r0, r1

        mov pc, lr

@ Register a callback
sys_reg_prox_callback:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0-r2}
        msr cpsr_c, #0x13

@ Set a single motor speed
sys_motor_speed:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0, r1}
        msr cpsr_c, #0x13

        @ Checks if motor id is ok
        cmp r0, #2
        blt endif3
        mov r0, #-1
        mov pc, lr

    endif3:
        @ Checks if speed is valid
        cmp r1, #64
        blt endif4
        mov r0, #-2
        mov pc, lr

    endif4:
        lsl r1, r1, #1
        cmp r0, #0
        bne motor1

        lsl r0, r1, #18
        ldr r2, =BASE_GPIO
        ldr r1, [r2]

        bic r1, r1, #0x01FC0000
        orr r0, r0, r1
        str r0, [r2]

        b end1

    motor1:
        lsl r0, r1, #25
        ldr r2, =BASE_GPIO
        ldr r1, [r2]

        bic r1, r1, #0xFE000000
        orr r0, r0, r1
        str r0, [r2]

    end1:
        @ Done
        mov r0, #0
        mov pc, lr


@ Set both motors speed
sys_motors_speed:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0, r1}
        msr cpsr_c, #0x13

        @ Cheks motor 0 speed
        cmp r0, #64
        blt endif5
        mov r0, #-1
        mov pc, lr

        @ Checks motor1 speed
    endif5:
        cmp r1, #64
        blt endif6
        mov r0, #-2
        mov pc, lr

        @ Writes motors speeds
    endif6:
        lsl r0, r0, #19
        lsl r1, r1, #26

        orr r0, r0, r1
        ldr r1, =BASE_GPIO
        ldr r2, [r1]

        .set bic_mask, 0xFFFC0000
        ldr r3, =bic_mask
        bic r2, r2, r3
        orr r0, r0, r2
        str r0, [r1]

        @ Done
        mov r0, #0
        mov pc, lr


@ Gets current system time
sys_get_time:
        ldr r0, =SYSTEM_TIME
        ldr r0, [r0]
        mov pc, lr

@ Set new system time
sys_set_time:
        msr cpsr_c, #0x1F
        ldmfd sp, {r1}
        msr cpsr_c, #0x13
        ldr r0, =SYSTEM_TIME
        str r1, [r0]
        mov pc, lr

@ Init counters
sys_init:
        @ SYSTEM_TIME <= 0
        ldr r0, =SYSTEM_TIME
        mov r1, #0
        str r1, [r0]

        ldr r0, =NUM_ALARMS
        mov r1, #0
        str r1, [r0]

        ldr r0, =NUM_CALLBACKS
        mov r1, #0
        str r1, [r0]

        ldr r0, =ALARMS_ARRAY
        mov r1, #0
        ldr r3, =MAX_ALARMS
    loop4:
        mov r2, #0
        str r2, [r0, r1]
        add r1, r1, #1
        cmp r1, r3
        bne loop4

        ldr r0, =ALARMS_FUNCTIONS
        mov r1, #0
    loop2:
        mov r2, #0
        str r2, [r0, r1]
        add r1, r1, #1
        cmp r1, r3
        bne loop2

        mov pc, lr

@ Register alarm
sys_set_alarm:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0, r1}
        msr cpsr_c, #0x13

        mov r6, r0
        mov r7, r1

        @ Checks if MAX_ALARMS is not reached
        ldr r0, =NUM_ALARMS
        ldr r1, =MAX_ALARMS
        ldr r0, [r0]

        cmp r0, r1
        blo endif1
        mov r0, #-1
        mov pc, lr

    endif1:
        ldr r5, =SYSTEM_TIME
        ldr r5, [r5]

        @ Check if time is valid
        cmp r5, r7
        bls endif8
        mov r0, #-2
        mov pc, lr

    endif8:
        @ Stores new alarm and respective function at last position
        ldr r0, =NUM_ALARMS
        ldr r0, [r0]
        ldr r1, =ALARMS_ARRAY
        str r7, [r1, r0, lsl#2]
        ldr r5, =ALARMS_FUNCTIONS
        str r6, [r5, r0, lsl#2]

        @ NUM_ALARMS++
        ldr r0, =NUM_ALARMS
        ldr r1, [r0]
        add r1, r1, #1
        str r1, [r0]
        mov pc, lr


@ Updates system time after GPT interruption
update_sys_time:
        ldr r0, =SYSTEM_TIME
        ldr r1, [r0]
        add r1, r1, #1
        str r1, [r0]
        mov pc, lr

@ Check alarms
check_alarms:
        ldr r0, =ALARMS_ARRAY           @ r0 <= array base
        mov r1, #0                      @ r1 <= counter\

    loop5:
        ldr r6, =NUM_ALARMS
        ldr r5, [r6]
        ldr r3, =SYSTEM_TIME
        ldr r3, [r3]
        cmp r1, #MAX_ALARMS
        beq end
        cmp r1, r5
        beq end
        ldr r2, [r0, r1, lsl#2]
        add r1, r1, #1
        cmp r2, r3
        bne loop5

        @ r1 ==  alarm to be executed
        sub r1, r1, #1

        @ Stores last element into the new empty position
        sub r5, r5, #1
        str r5, [r6]
        ldr r2, [r0, r5, lsl#2]         @ r2 <= alarm
        str r2, [r0, r1, lsl#2]

        @ Store last function into empty position
        ldr r0, =ALARMS_FUNCTIONS
        ldr r4, [r0, r1, lsl#2]
        ldr r3, [r0, r5, lsl#2]         @ r3 <= function
        str r3, [r0, r1, lsl#2]


        @ Change to user mode and call user function
        stmfd sp!, {r0-r12, lr}
        msr cpsr_c, #0x10
        stmfd sp!, {lr}
        blx r4
        ldmfd sp!, {lr}

        @ Syscalls to recover mode
        mov r7, #2
        svc 0x0
        msr cpsr_c, #0x12
        ldmfd sp!, {r0-r12, lr}

        @ Checks if other functions need to be called
        ldr r0, =ALARMS_ARRAY
        b loop5

    end:
        movs pc, lr


.data
SYSTEM_TIME: .skip 4                 @ System time, updated after TIME_SZ cycles
NUM_ALARMS: .skip 4
NUM_CALLBACKS: .skip 4
ALARMS_ARRAY: .skip 32
ALARMS_FUNCTIONS: .skip 32
