#include "api_robot2.h"

void turn_right();
void go_ahead();
void stop();
void turn();
void remove_flag();

motor_cfg_t m0;
motor_cfg_t m1;
int flag = 0;
int counter = 1;

void main(){

    m0.id = 0;
    m1.id = 1;

    go_ahead();
    register_proximity_callback(3, 800, turn);


    int i = 0;

    while(1){
        if(i > 5000);
    }
}

void remove_flag(){
    flag = 0;
}

void turn_right(){
    m0.speed = 0;
    m1.speed = 14;

    int i;
    get_time(&i);


    set_motors_speed(&m0, &m1);
    add_alarm(go_ahead, i + 10);

    return;
}

void turn(){
    flag = 1;
    int i;
    get_time(&i);
    add_alarm(turn_right, i + 1);
}

void go_ahead(){

    int i;
    get_time(&i);
    if(flag == 0){
        m0.speed = 30;
        m1.speed = 30;

        set_motors_speed(&m0, &m1);
        add_alarm(turn_right, i + counter);
        counter += 4;
    }
    else{
        flag = 0;
        add_alarm(turn_right, i + counter);

    }

    return;
}

void stop(){
    m0.speed = 0;
    m1.speed = 0;

    int i;
    get_time(&i);
    set_motors_speed(&m0, &m1);
    add_alarm(turn_right, i + counter - 1);
    flag = 0;

    return;
}
