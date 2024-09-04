#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define NR_SIZE 1024

static int itoa(double val, char *buf, char type);

static int itoa_recur(double val, char *buf, char type, int align, int zero_pad, int width, int precision) {
  char *tmp_buf = buf;
  tmp_buf += itoa(val, buf, type);
  *tmp_buf++ = '\0';
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

static int itoa(double ival, char *buf, char type) {
  char *tmp_buf = buf;
  uint32_t uval = (uint32_t)ival;
  int32_t val = (int32_t)ival;
  // static bool is_prefix = false;
  if(val < 0 && (type = 'd' || type == 'i')) {
    *tmp_buf++ = '-';
    val = -val;
  }
  switch(type) {
    case 'd': {
      if(val/10 != 0) {
        tmp_buf += itoa(val/10, tmp_buf, 'd');
      }
      *tmp_buf++ = val%10 + '0';
      break;
    }
    case 'i': {
      if(val/10 != 0) {
        tmp_buf += itoa(val/10, tmp_buf, 'i');
      }
      *tmp_buf++ = val%10 + '0';
      break;
    }
    case 'x': {
      if(uval/16 != 0) {
        tmp_buf += itoa(uval/16, tmp_buf, 'x');
      }
      if(uval%16 <= 9) *tmp_buf++ = uval%16 + '0';
      else *tmp_buf++ = uval%16 - 10 + 'a';
      break;
    }
    case 'X': {
      if(uval/16 != 0) {
        tmp_buf += itoa(uval/16, tmp_buf, 'X');
      }
      if(uval%16 <= 9) *tmp_buf++ = uval%16 + '0';
      else *tmp_buf++ = uval%16 - 10 + 'A';
      break;
    }
    case 'o': {
      if(uval/8 != 0) {
        tmp_buf += itoa(uval/8, tmp_buf, 'o');
      }
      *tmp_buf++ = uval%8 + '0';
      break;
    }
    case 'f': {
      int32_t integ = (int32_t)ival;
      float decimal = ival - integ;
      while(decimal != (int32_t)decimal) decimal *= 10;
      int32_t decimal_to_integ = (int32_t)decimal;
      tmp_buf += itoa(ival, tmp_buf, 'i');
      *tmp_buf++ = '.';
      tmp_buf += itoa(decimal_to_integ, tmp_buf, 'i');
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
  // ioe_write(0, buf);
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
    int precision = -1; // 默认精度为 -1（表示不指定）

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
      while(*fmt >= '0' && *fmt <= '9') {
        precision = precision*10 + (*fmt - '0');
      }
    }

    switch(*fmt) {
      case 'd': {
        int val = va_arg(p_next, int);
        itoa_recur(val, tmp, 'd', align, zero_pad, width, precision); 
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      } 
      case 'i': {
        int val = va_arg(p_next, int);
        itoa_recur(val, tmp, 'i', align, zero_pad, width, precision); 
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      } 
      case 'o': {
        int val = va_arg(p_next, int);
        itoa_recur(val, tmp, 'o', align, zero_pad, width, precision); 
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      } 
      case 'x': {
        int val = va_arg(p_next, int);
        itoa_recur(val, tmp, 'x', align, zero_pad, width, precision);
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }
      case 'X': {
        int val = va_arg(p_next, int);
        itoa_recur(val, tmp, 'X', align, zero_pad, width, precision);
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

      case 'f': {
        float val = va_arg(p_next, double);
        itoa_recur(val, tmp, 'f', align, zero_pad, width, precision);
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
