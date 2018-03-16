# mc404-project-2
MC404 project 2, 2016 secon semester. The main objectve was to implement all software layers to set, control the hardware and program the behaviour of the robot Ultrasonic Ranging Module HC - SR04.
##  Software layers and their components
The project implements three layers:
* The user layer. Where the robot's behaviour logic is implemented. Composed by `ronda.c`
* Control library. Implements the functions resposible for controlling the robot, for example change it's speed or check it's sonars. This library offers an API for the user layer. Composed by `api_robot2.h`, `sonars.s`, `timer.s` and `motors.s`
* Operating System: Implements a minimal OS resposible for initizaling and setting up the hardware. Also implements the syscalls used by control library. Composed by `soul.s` and `syscalls.s`

