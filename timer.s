@ Lucas de Camargo Barros de Castro
@ RA: 172678
@
@ This file implements all functions from api_robot2.h related to system time

.global add_alarm
.global get_time
.global set_time

@ Adds an alarm to the system.
@ Parameter:
@   f: function to be called when the alarm triggers.
@   time: the time to invoke the alarm function.
@ Returns:
@   void
add_alarm:
        stmfd sp!, {r0, r1}
        mov r7, #22
        svc 0x0

        ldmfd sp!, {r0, r1}
        mov pc, lr

@ Reads the system time.
@ Parameter:
@   r0: address of the variable that will receive the system time.
@ Returns:
@   void
get_time:
        stmfd sp!, {r0, r1}
        mov r1, r0
        mov r7, #20
        svc 0x0

        str r0, [r1]
        ldmfd sp!, {r0, r1}
        mov pc, lr

@ Sets the system time.
@ Parameter:
@   r0: the new system time.
@ Returns:
@   void
set_time:
        stmfd sp!, {r0}
        mov r7, #21
        svc 0x0

        ldmfd sp!, {r0}
        mov pc, lr
