#include <device.h>

void init_device() {
#ifdef CONFIG_HAS_VGA
  init_vga();
#endif
}