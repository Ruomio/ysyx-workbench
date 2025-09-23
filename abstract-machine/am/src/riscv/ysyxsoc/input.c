#include <am.h>
#include <amdev.h>
#include "ysyxsoc.h"


// scancode to am key code
typedef struct KEYCODE{
  int amcode;
  int scancode;
}KEYCODE_T;

#define SCANCODE_AMCODE(_) \
  _(ESCAPE, 0x76) _(F1, 0x05) _(F2, 0x06) _(F3, 0x04) _(F4, 0x0C) _(F5, 0x03) _(F6, 0x0B) _(F7, 0x83) _(F8, 0x0A) _(F9, 0x01) _(F10, 0x09) _(F11, 0x78) _(F12, 0x07) \
  _(GRAVE, 0x0E) _(1, 0x16) _(2, 0x1E) _(3, 0x26) _(4, 0x25) _(5, 0x2E) _(6, 0x36) _(7, 0x3D) _(8, 0x3E) _(9, 0x46) _(0, 0x45) _(MINUS, 0x4E) _(EQUALS, 0x55) _(BACKSPACE, 0x66) \
  _(TAB, 0x0D) _(Q, 0x15) _(W, 0x1D) _(E, 0x24) _(R, 0x2D) _(T, 0x2C) _(Y, 0x35) _(U, 0x3C) _(I, 0x43) _(O, 0x44) _(P, 0x4D) _(LEFTBRACKET, 0x54) _(RIGHTBRACKET, 0x5B) _(BACKSLASH, 0x5D) \
  _(CAPSLOCK, 0x58) _(A, 0x1C) _(S, 0x1B) _(D, 0x23) _(F, 0x2B) _(G, 0x34) _(H, 0x33) _(J, 0x3B) _(K, 0x42) _(L, 0x4B) _(SEMICOLON, 0x4C) _(APOSTROPHE, 0x52) _(RETURN, 0x5A) \
  _(LSHIFT, 0x12) _(Z, 0x1A) _(X, 0x22) _(C, 0x21) _(V, 0x2A) _(B, 0x32) _(N, 0x31) _(M, 0x3A) _(COMMA, 0x41) _(PERIOD, 0x49) _(SLASH, 0x4A) _(RSHIFT, 0x59) \
  _(LCTRL, 0x14) _(APPLICATION, 0x11D) _(LALT, 0x11) _(SPACE, 0x29) _(RALT, 0xE01C) _(RCTRL, 0xE014) \
  _(UP, 0xE075) _(DOWN, 0xE072) _(LEFT, 0xE06B) _(RIGHT, 0xE074) _(INSERT, 0xE070) _(DELETE, 0xE071) _(HOME, 0xE06C) _(END, 0xE069) _(PAGEUP, 0xE07D) _(PAGEDOWN, 0xE07A)


#define AM_KEY_VARIABLE(amcode, scancode) {AM_KEY_##amcode, scancode}, 

KEYCODE_T keycodes[] = {
  {AM_KEY_NONE, 0},
  SCANCODE_AMCODE(AM_KEY_VARIABLE)
};

int get_keycode(int scancode) {
  for(int i = 0; i < sizeof(keycodes) / sizeof(KEYCODE_T); i++) {
    if(keycodes[i].scancode == scancode) {
      return keycodes[i].amcode;
    }
  }
  return AM_KEY_NONE;
}

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  // get scancode from soc
  uint8_t ret_1 = inb(KBD_ADDR);
  if(ret_1 != 0) {
    if(ret_1 == 0xE0) {
      uint8_t ret_2 = inb(KBD_ADDR);
      if(ret_2 != 0xF0) {
        kbd->keycode = get_keycode(0xE000 | ret_2);
        kbd->keydown = 1;
      }
      else {
        uint8_t ret_3 = inb(KBD_ADDR);
        kbd->keycode = get_keycode(0xE000 | ret_3);
        kbd->keydown = 0;
      }
    } 
    else if(ret_1 == 0xF0) {
      kbd->keydown = 0;
      uint8_t ret_3 = inb(KBD_ADDR);
      kbd->keycode = get_keycode(ret_3);
    }
    else {
      kbd->keycode = get_keycode(ret_1);
      kbd->keydown = 1;
    }
  }
  else {
    kbd->keydown = 0;
    kbd->keycode = AM_KEY_NONE;
  }
}
