#include "api_robot2.h"

void turn_right();
void go_ahead();
void stop();

motor_cfg_t m0;
motor_cfg_t m1;

void main(){

    m0.id = 0;
    m1.id = 1;

    add_alarm(go_ahead, 5);
    add_alarm(turn_right, 10);
    add_alarm(stop, 15);
    add_alarm(go_ahead, 25);

    while(1){
        read_sonar(2);
    }
}

void turn_right(){
    m0.speed = 0;
    m1.speed = 10;

    set_motors_speed(&m0, &m1);
    return;
}

void go_ahead(){
    m0.speed = 30;
    m1.speed = 30;

    set_motors_speed(&m0, &m1);
    return;
}

void stop(){
    m0.speed = 0;
    m1.speed = 0;

    set_motors_speed(&m0, &m1);
    return;
}
