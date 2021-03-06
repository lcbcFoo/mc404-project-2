@ Lucas de Camargo Barros de Castro
@ RA: 172678
@
@ This file implements the SOUL layer, responsable for configuring the hardware
@ and providing the syscalls used by the api_robot2.h

.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
        b RESET_HANDLER
.org 0x08
        b SYSCALL_HANDLER
.org 0x18
        b IRQ_HANDLER


.org 0x100
.text
RESET_HANDLER:

        @ Initializates system control variables
        bl sys_init

        @ Set interrupt table base address on coprocessor 15.
        ldr r0, =interrupt_vector
        mcr p15, 0, r0, c12, c0, 0

SET_GPT:
        @ set GPT registers addresses
        .set GPT_CR_ADDR, 0x53FA0000
        .set GPT_PR_ADDR, 0x53FA0004
        .set GPT_OCR1_ADDR, 0x53FA0010
        .set GPT_IR_ADDR, 0x53FA000C

        @ Configure GPT hardware
        @ GPT_CR <= 0x00000041
        mov r1, #0x41
        ldr r0, =GPT_CR_ADDR
        str r1, [r0]

        @ GPT_PR <= #0
        mov r1, #0
        ldr r0, =GPT_PR_ADDR
        str r1, [r0]

        @ GPT_OCR1 <= TIME_SZ
        .set TIME_SZ, 100
        ldr r1, =TIME_SZ
        ldr r0, =GPT_OCR1_ADDR
        str r1, [r0]

        @ GPT_IR <= #1 (true)
        mov r1, #1
        ldr r0, =GPT_IR_ADDR
        str r1, [r0]

SET_TZIC:
        @ Sets TZIC registers adressess
        .set TZIC_BASE, 0x0FFFC000
        .set TZIC_INTCTRL, 0x0
        .set TZIC_INTSEC1, 0x84
        .set TZIC_ENSET1, 0x104
        .set TZIC_PRIOMASK, 0xC
        .set TZIC_PRIORITY9, 0x424

        @ Starts interruption handler
        ldr	r1, =TZIC_BASE

        @ Configures interruption 39 from GPT as non safe
        mov	r0, #(1 << 7)
        str	r0, [r1, #TZIC_INTSEC1]

        @ Enables interruption 39 (GPT)
        @ reg1 bit 7 (gpt)

        mov	r0, #(1 << 7)
        str	r0, [r1, #TZIC_ENSET1]

        @ Configures interrupt 39 priority as 1
        @ reg9, byte 3

        ldr r0, [r1, #TZIC_PRIORITY9]
        bic r0, r0, #0xFF000000
        mov r2, #1
        orr r0, r0, r2, lsl #24
        str r0, [r1, #TZIC_PRIORITY9]

        @ Configures PRIOMASK as 0
        eor r0, r0, r0
        str r0, [r1, #TZIC_PRIOMASK]

        @ Enables the interruptions controller
        mov	r0, #1
        str	r0, [r1, #TZIC_INTCTRL]


CONFIGURE_STACKS:

        @  Set stack pointer for supervisor mode
        msr cpsr_c, #0x13
        ldr sp, =SVC_STACK

        @ Set stack pointer for IRQ mode
        msr cpsr_c, #0x12
        ldr sp, =IRQ_STACK

        @ Set stack pointer for system/user mode
        msr cpsr_c, #0x1F
        ldr sp, =SYS_USER_STACK


SET_GPIO:
        @ Configure FDIR mask
        .set GDIR_MASK, 0xFFFC003E
        .set BASE_GPIO, 0x53F84000
        ldr r0, =GDIR_MASK
        ldr r1, =BASE_GPIO
        str r0, [r1, #4]
        mov r0, #0
        ldr r0, [r1, #4]

        @ Change to user mode and changes control to user program
        msr cpsr_c, #0x10

        .set USER_MAIN, 0x77802000
        ldr pc, =USER_MAIN



@ SYSCALL_HANDLER: Executes a software interruption
SYSCALL_HANDLER:
        @ Syscall made to recover IRQ mode
        cmp r7, #2
        moveq pc, lr

	    msr cpsr_c, #0xD3

        @ Saves registers on SVC_STACK
        stmfd sp!, {r1-r12}

        @ Determines which syscall qas made and treat it
        stmfd sp!, {lr}
        cmp r7, #16
        bleq sys_read_sonar
        cmp r7, #17
        bleq sys_reg_prox_callback
        cmp r7, #18
        bleq sys_motor_speed
        cmp r7, #19
        bleq sys_motors_speed
        cmp r7, #20
        bleq sys_get_time
        cmp r7, #21
        bleq sys_set_time
        cmp r7, #22
        bleq sys_set_alarm

        ldmfd sp!, {lr}

        @ Recovers registers from SVC_STACK (r0 contains the return of the syscall)
        ldmfd sp!, {r1-r12}
        movs pc, lr


@ Handles hardware interruption (called after GPT completed TIME_SZ cycles)
IRQ_HANDLER:
        stmfd sp!, {r0-r8}

        @ GPT_SR <= #1
        .set GPT_SR_ADDR, 0x53FA0008
        mov r1, #1
        ldr r0, =GPT_SR_ADDR
        str r1, [r0]

        msr cpsr_c, #0xD2

        @ Updates system time
        stmfd sp!, {lr}
        bl update_sys_time
        bl check_callbacks
        bl check_alarms
        ldmfd sp!, {lr}

        @ Enables new interruptions and return
        sub lr, lr, #4
        ldmfd sp!, {r0-r8}
        movs pc, lr


@ Data
.data

@ Defines the stacks for IRQ mode, system/user mode and supervisor mode
.skip 512
IRQ_STACK: .skip 512
SVC_STACK: .skip 512
SYS_USER_STACK:
