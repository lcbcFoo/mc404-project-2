/* Lucas de Camargo Barros de Castro
 * RA: 172678
 *
 * This file implements the control logic sublayer for the round module
 */

#include "api_robot2.h"
#define turning_deltaT 4
#define turning_speed 20
#define going_ahead_speed 30


void go_ahead();
void delay();
void turn();
void avoid_collision();


motor_cfg_t m0;             // Motor 0
motor_cfg_t m1;             // Motor 1
int time_unit = 1;          // Time unit to form the spiral
int flag = 0;               // Control variable for avoiding collisions


void main(){

    /* Sets both motors id */
    m0.id = 0;
    m1.id = 1;

    /* Registers callbacks to avoid collision and start walking */
    register_proximity_callback(3, 800, avoid_collision);
    register_proximity_callback(4, 800, avoid_collision);

    go_ahead();
    while(1){
        /* Starts new patroll */
        if(time_unit == 50){
            set_time(0);
            time_unit = 1;
        }
    }
}

/* Turns the robot around for about 90 degrees */
void turn(){
    int i;
    get_time(&i);

    /* Checks if the robot can turn right in that position */
    if(read_sonar(7) > 500){
        m0.speed = 0;
        m1.speed = turning_speed;
        set_motors_speed(&m0, &m1);
        add_alarm(go_ahead, i + turning_deltaT);
    }

    /* If not, waits 1 more cycle of the system time moving foward */
    else
        add_alarm(go_ahead,  i + 1);
}

/* Turns the robot to avoid a collision. After avoiding a wall, the robot
 * continues the round from where it was without reajusting the original
 * orientation or the timing for the next turnings */
void avoid_collision(){
    if(flag)
        return;

    flag = 1;

    m0.speed = 0;
    m1.speed = turning_speed;
    set_motors_speed(&m0, &m1);

    int i;
    get_time(&i);
    add_alarm(delay, i + 1);
}

/* Moves the robot foward and sets next turning to form the spiral */
void go_ahead(){

    int i;
    get_time(&i);

    m0.speed = going_ahead_speed;
    m1.speed = going_ahead_speed;
    set_motors_speed(&m0, &m1);

    flag = 0;
    time_unit++;

    add_alarm(turn, i + time_unit);
}

/* Used by 'avoid_collision' to keep turning while there is a wall in the
 * front. After that, sets an alarm to continue the round */
void delay(){
    while(read_sonar(3) < 1200 && read_sonar(4) < 1200);

    int i;
    get_time(&i);
    add_alarm(go_ahead, i + 1);
}
