#include <common.h>

extern void init_map();
extern void init_timer();
extern void init_serial();

void init_device() {
    init_map();
    IFDEF(CONFIG_HAS_TIMER, init_timer());
    IFDEF(CONFIG_HAS_SERIAL, init_serial());
}
