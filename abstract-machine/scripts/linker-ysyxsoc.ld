ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

MEMORY
{
  /* MROM (rx) : ORIGIN = 0x20000000, LENGTH = 0x1000 */       /* 4K */
  SRAM (rwx) : ORIGIN = 0x0f000000, LENGTH = 0x2000            /* 8k */
  FLASH (rx) : ORIGIN = 0x30000000, LENGTH = 0x01000000        /* 2^24 = 16M */
  PSRAM (rwx) : ORIGIN = 0x80000000, LENGTH = 0x00400000       /* 4M */
  SDRAM (rwx) : ORIGIN = 0xa0000000, LENGTH = 0x02000000       /* 32M */
}

SECTIONS {
  _sram_base = ORIGIN(SRAM);
  _flash_base = ORIGIN(FLASH);
  _psram_base = ORIGIN(PSRAM);
  _sdram_base = ORIGIN(SDRAM);
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = ORIGIN(FLASH);

  .fsbl : {
    _fsbl_start = .;
    *(.fsbl*)
    . = ALIGN(4);
    _fsbl_end = .;
  } > FLASH AT> FLASH

  . = ALIGN(4);
  .ssbl : {
    _ssbl_start = .;
    *(.ssbl*)
    . = ALIGN(4);
    _ssbl_end = .;
  } > SRAM AT> FLASH
  _ssbl_load = LOADADDR(.ssbl);

  .text : {
    _text_start = .;
    *(entry)
    *(.text*)
    . = ALIGN(4);
    _text_end = .;
  } > SDRAM AT> FLASH : text
  _text_load = LOADADDR(.text);
  etext = .;
  _etext = .;

  .rodata : {
    *(.rodata*)
    *(.srodata*)
  } > SDRAM AT> FLASH

  .data : {
    _data_start = .;
    *(.data*)
    *(.sdata*)
    . = ALIGN(4);
    _data_end = .;
  } > SDRAM AT> FLASH : data
  _data_load = LOADADDR(.data);
  edata = .;
  _data = .;

  .bss : {
    _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = .;
    . = ALIGN(4);
  } > SDRAM

  end = .;
  _end = .;

  /* heap is in SDRAM*/
  /* . = ORIGIN(SDRAM) + SIZEOF(.data) + SIZEOF(.bss) + SIZEOF(.ssbl); */
  /* . = ORIGIN(SDRAM); */
  /* _heap_start = ALIGN(0x1000); */
  . = ORIGIN(SDRAM) + _end;
  _heap_start = ALIGN(0x1000);


  /* stack are in SRAM*/
  /* _stack_top = ORIGIN(SRAM); */
  /* _stack_top = .; */
  /* . = _stack_top + LENGTH(SRAM); */
  /* . = ORIGIN(SRAM) + LENGTH(SRAM); */
  /* _stack_pointer = .; */

  . = ORIGIN(SRAM);
  _stack_top = .;

  _stack_pointer = . + LENGTH(SRAM);
}
