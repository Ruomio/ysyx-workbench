#include <common.h>
#include <device/device.h>

#define VGA_WIDTH 640
#define VGA_HEIGHT 480

void init_vga() {
    int width = VGA_WIDTH;
    int height = VGA_HEIGHT;
    uint32_t size = (VGA_WIDTH << 16) | (VGA_HEIGHT & 0x0000ffff);
    *(uint32_t *)(uintptr_t *)(VGACTL_ADDR) = size;
}