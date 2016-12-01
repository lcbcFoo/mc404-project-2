@ Lucas de Camargo Barros de Castro
@ RA: 172678
@
@ This file implements the syscalls used by the api_robot_2.h and other routines
@ used by SOUL to keep system time and the alarms treatment working

.text
.globl sys_read_sonar
.globl sys_reg_prox_callback
.globl sys_motor_speed
.globl sys_motors_speed
.globl sys_get_time
.globl sys_set_time
.globl sys_set_alarm
.globl update_sys_time
.globl check_alarms

@ Defines max number of alarms and callbacks
.set MAX_ALARMS,     8
.set MAX_CALLBACKS,  8

@ Defines masks used to communicate with GPIO
.set BASE_GPIO,             0x53F84000
.set WRITE_MOTOR0_SPEED,    0x00003F80
.set WRITE_MOTOR1_SPEED,    0x0000007F

sys_read_sonar:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0}
        msr cpsr_c, #0x13

        lsl r0, r0, #2
        add r0, r0, #2

        ldr r1, =BASE_GPIO
        str r0, [r1]

        mov r2, #1
    loop1:
        add r2, r2, #1
        cmp r2, #4000
        bne loop1

        ldr r0, [r1]
        lsr r0, r0, #6
        ldr r1, =0xFFF
        and r0, r0, r1

        mov pc, lr

sys_reg_prox_callback:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0-r2}
        msr cpsr_c, #0x13

sys_motor_speed:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0, r1}
        msr cpsr_c, #0x13

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
        mov pc, lr


sys_motors_speed:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0, r1}
        msr cpsr_c, #0x13

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

sys_set_alarm:
        msr cpsr_c, #0x1F
        ldmfd sp, {r0, r1}

        msr cpsr_c, #0x13


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
        ldr r3, =SYSTEM_TIME
        ldr r3, [r3]

    loop:
        cmp r1, #MAX_ALARMS
        beq end
        ldr r2, [r0, r1]
        add r1, r1, #1
        cmp r2, r3
        bne loop


    end:
        mov pc, lr

.data
SYSTEM_TIME: .word 0              @ System time, updated after TIME_SZ cycles
NUM_ALARMS: .word 0
NUM_CALLBACKS: .word 0
ALARMS_ARRAY: .fill  MAX_ALARMS, 4, 0
FUNCTIONS_POINTER_VET: .fill MAX_ALARMS, 4, 0x0
