


.text
.globl sys_read_sonar
sys_read_sonar:
        lsl r0, r0, #26
        add r0, r0, #0x40000000
        mov pc, lr
