#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define NR_SIZE 128
static int itoa(void *val, char *buf, char type);

static int itoa_recur(void *val, char *buf, char type, int align, int zero_pad, int width, int precision) {
  char *tmp_buf = buf;
  tmp_buf += itoa(val, buf, type);
  *tmp_buf++ = '\0';
  // precision
  #if defined(__ISA_RISCV32__) || defined (__ISA_RISCV32E__) // rv32im do not support float
  #else
  if(type == 'f') {
    double dval = *(double *)val;
    int cnt = 0;
    int integ = dval;
    float  decimal = dval - integ;
    while(decimal != (int32_t)decimal) { decimal *= 10; cnt++; }
    if(cnt < precision) {
      memset(tmp_buf-1, '0', precision - cnt);
      tmp_buf += strlen(tmp_buf);
      *tmp_buf++ = '\0';
    }
  }
  #endif


  // width
  if(tmp_buf - buf -1 < width) {
    if(align == 0) { // right align default
      int len = strlen(buf);
      memmove((buf+width-len), buf, len+1);
      if(zero_pad) memset(buf, '0', width-len);
      else memset(buf, ' ', width-len);
    }
    else {  // left align, zero_pad is invalid
      int len = strlen(buf);
      memset(buf+len, ' ', width - len + 1);
      buf[width] = '\0';
    }
  }
  return tmp_buf - buf;
}

static int itoa(void *ival, char *buf, char type) {
  char *tmp_buf = buf;

  switch(type) {
    case 'd': {
      int64_t val = *(int32_t *)ival;
      if(val < 0) {
        *tmp_buf++ = '-';
        val = -val;
      }
      if(val/10 != 0) {
        int64_t val_new = val/10;
        tmp_buf += itoa( &val_new, tmp_buf, 'd');
      }
      *tmp_buf++ = val%10 + '0';
      break;
    }
    case 'i': {
      int64_t val = *(int32_t *)ival;
      if(val < 0) {
        *tmp_buf++ = '-';
        val = -val;
      }
      if(val/10 != 0) {
        int64_t val_new = val/10;
        tmp_buf += itoa(&val_new, tmp_buf, 'i');
      }
      *tmp_buf++ = val%10 + '0';
      break;
    }
    case 'x': {
      uint32_t uval = *(uint32_t *)ival;
      if(uval/16 != 0) {
        uint32_t uval_new = uval/16;
        tmp_buf += itoa(&uval_new, tmp_buf, 'x');
      }
      if(uval%16 <= 9) *tmp_buf++ = uval%16 + '0';
      else *tmp_buf++ = uval%16 - 10 + 'a';
      break;
    }
    case 'X': {
      uint32_t uval = *(uint32_t *)ival;
      if(uval/16 != 0) {
        uint32_t uval_new = uval/16;
        tmp_buf += itoa(&uval_new, tmp_buf, 'X');
      }
      if(uval%16 <= 9) *tmp_buf++ = uval%16 + '0';
      else *tmp_buf++ = uval%16 - 10 + 'A';
      break;
    }
    case 'o': {
      uint32_t uval = *(uint32_t *)ival;
      if(uval/8 != 0) {
        uint32_t uval_new = uval/8;
        tmp_buf += itoa(&uval_new, tmp_buf, 'o');
      }
      *tmp_buf++ = uval%8 + '0';
      break;
    }
    #if defined(__ISA_RISCV32__) || defined (__ISA_RISCV32E__) // rv32im do not support float
    #else
    case 'f': {
      double dval = *(double *)ival;
      int32_t integ = (int32_t)dval;
      float decimal = dval - integ;
      while(decimal != (int32_t)decimal) decimal *= 10;
      int32_t decimal_to_integ = (int32_t)decimal;
      tmp_buf += itoa(&integ, tmp_buf, 'd');
      *tmp_buf++ = '.';
      tmp_buf += itoa(&decimal_to_integ, tmp_buf, 'd');
      break;
    }
    #endif
    case 'p': {
      *tmp_buf++ = '0';
      *tmp_buf++ = 'x';
      #if defined (__ISA_RISCV32__) || defined (__ISA_MIPS32__) || defined (__ISA_X86__)|| defined (__ISA_LONNGARCH32R__) || defined (__ISA_RISCV32E__)
        uint32_t vall = *(uint32_t *)ival;
        tmp_buf += itoa(&vall, tmp_buf, 'x');
      #else
        uint64_t val = *(uint64_t *)ival;
        uint32_t valh = val >> 32;
        uint32_t vall = (uint32_t)val;
        tmp_buf += itoa(&valh, tmp_buf, 'x');
        tmp_buf += itoa(&vall, tmp_buf, 'x');
      #endif
      break;
    }


    default: {
      #define MSG "Unknown format.\n"
      strcpy(tmp_buf, MSG);
      tmp_buf += strlen(MSG);
      break;
    }
  }

  return tmp_buf - buf;
}

int printf(const char *fmt, ...) {
  int i = 0;
  va_list arg;
  char buf[NR_SIZE] = {0};
  va_start(arg, fmt);
  i = vsprintf(buf, fmt, arg);
  va_end(arg);
  for(int j=0; j<i; j++) {
    putch(*(buf+j));
  }
  return i;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  char *p = NULL;
  char tmp[NR_SIZE] = {};
  va_list p_next;
  va_copy(p_next, ap);

  for(p = out; *fmt != '\0'; fmt++) {
    if(*fmt != '%') {
      *p++ = *fmt;
      continue;
    }

    fmt++;
    // 初始化标志和格式参数
    int align = 0;
    int zero_pad = 0;
    int width = 0;
    int precision = 6; // 默认精度为 6（表示不指定）

    if(*fmt == '-') {
      align = 1;
    }
    if(*fmt == '0') {
      zero_pad = 1;
    }
    while(*fmt>= '0' && *fmt <= '9') {
      width = width*10 + (*fmt-'0');
      fmt++;
    }

    if(*fmt == '.') {
      fmt++;
      precision = 0;
      while(*fmt >= '0' && *fmt <= '9') {
        precision = precision*10 + (*fmt - '0');
        fmt++;
      }
    }

    switch(*fmt) {
      case 'd': {
        int val = va_arg(p_next, int);
        itoa_recur(&val, tmp, 'd', align, zero_pad, width, precision);
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }
      case 'i': {
        int val = va_arg(p_next, int);
        itoa_recur(&val, tmp, 'i', align, zero_pad, width, precision);
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }
      case 'o': {
        uint32_t val = va_arg(p_next, int);
        itoa_recur(&val, tmp, 'o', align, zero_pad, width, precision);
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }
      case 'x': {
        uint32_t val = va_arg(p_next, int);
        itoa_recur(&val, tmp, 'x', align, zero_pad, width, precision);
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }
      case 'X': {
        uint32_t val = va_arg(p_next, int);
        itoa_recur(&val, tmp, 'X', align, zero_pad, width, precision);
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }
      case 'c': {
        char val = (char)va_arg(p_next, int);
        *p++ = val;
        break;
      }
      case 's': {
        char *s = va_arg(p_next, char *);
        strcpy(p, s);
        p += strlen(s);
        break;
      }
      #if defined(__ISA_RISCV32__) || defined (__ISA_RISCV32E__) // rv32im do not support float
      #else
      case 'f': {
        double val = va_arg(p_next, double);
        itoa_recur(&val, tmp, 'f', align, zero_pad, width, precision);
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }
      #endif
      case 'p': {
        #if defined (__ISA_RISCV32__) || defined (__ISA_MIPS32__) || defined (__ISA_X86__)|| defined (__ISA_LONNGARCH32R__) || defined (__ISA_RISCV32E__)
        uint32_t val = va_arg(p_next, uint32_t);
        #else /* 64 bit */
        uint64_t val = va_arg(p_next, uint64_t);
        #endif

        itoa_recur(&val, tmp, 'p', align, zero_pad, width, precision);
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }

      default: {
        // unknown format
        *p++ = '%';
        *p++ = *fmt;
        break;
      }
    }

    // clear tmp
    memset(tmp, 0, NR_SIZE);
  }
  *p++ = '\0';

  return p - out;
}

int sprintf(char *out, const char *fmt, ...) {
  int i = 0;
  va_list arg;
  va_start(arg, fmt);
  i = vsprintf(out, fmt, arg);
  va_end(arg);
  return i;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
