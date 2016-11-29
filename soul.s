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

        @ Starts SYSTEM_TIME as 0
        ldr r0, =SYSTEM_TIME
        mov r1, #0
        str r1, [r0]

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
        .set TZIC_BASE,             0x0FFFC000
        .set TZIC_INTCTRL,          0x0
        .set TZIC_INTSEC1,          0x84
        .set TZIC_ENSET1,           0x104
        .set TZIC_PRIOMASK,         0xC
        .set TZIC_PRIORITY9,        0x424

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
        .set mask, 0x1f

        @  Set stack pointer for supervisor mode
        mrs r0, cpsr
        bic r0, r0, #mask
        orr r0, r0, #0x13
        msr cpsr, r0
        ldr sp, =SVC_STACK

        @ Set stack pointer for IRQ mode
        bic r0, r0, #mask
        orr r0, r0, #0x12
        msr cpsr, r0
        ldr sp, =IRQ_STACK

        @ Set stack pointer for system/user mode
        bic r0, r0, #mask
        orr r0, r0, #0x1F
        msr cpsr, r0
        ldr sp, =SYS_USER_STACK


SET_GPIO:
        .set BASE_GPIO, 0x53F84000

        @ TERMINAAAR---------


        @ Waits for interruption
        b waiting_interruption


SYSCALL_HANDLER:
        @ Saves registers on SVC_STACK
        stmfd sp!, {r1-r12}

        @ Changes to system mode so sp is the same from user
        mrs r1, cpsr
        bic r1, r1, #mask
        orr r1, r1, #0x1F
        msr cpsr, r1

        @ TREAT THE SYSCALL (FAZER)

        @ Return to SVC mode
        mrs r1, cpsr
        bic r1, r1, #mask
        orr r1, r1, #0x13
        msr cpsr, r1

        @ Recovers registers from SVC_STACK (r0 contains the return of the syscall)
        ldmfd sp!, {r1-r12}
        sub lr, lr, #4
        movs pc, lr


@ Handles hardware interruption (called after GPT completed TIME_SZ cycles)
IRQ_HANDLER:
        stmfd sp!, {r0-r1}

        @ GPT_SR <= #1
        .set GPT_SR_ADDR, 0x53FA0008
        mov r1, #0
        ldr r0, =GPT_SR_ADDR
        str r1, [r0]

        @ Updates system time
        ldr r0, =SYSTEM_TIME
        ldr r1, [r0]
        add r1, r1, #1
        str r1, [r0]

        @ Returns
        sub lr, lr, #4

        ldmfd sp!, {r0-r1}
        movs pc, lr


waiting_interruption:
        b waiting_interruption



@ Data
.data
SYSTEM_TIME:                    @ System time, updated after TIME_SZ cycles


@ Defines the stacks for IRQ mode, system/user mode and supervisor mode
.org 0x77808000
IRQ_STACK: .skip 400
SVC_STACK: .skip 12000
SYS_USER_STACK: .skip 12000
