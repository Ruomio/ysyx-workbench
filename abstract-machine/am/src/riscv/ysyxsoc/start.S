.section entry, "ax"
.globl _start
.type _start, @function

_start:
  // initial in fsbl
  // mv s0, zero
  // la sp, _stack_pointer
  call _trm_init
