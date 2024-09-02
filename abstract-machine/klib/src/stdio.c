#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define NR_SIZE 1024

static int itoa(int val, char *buf, char type);

static int itoa_recur(int val, char *buf, char type) {
  char *tmp_buf = buf;
  tmp_buf += itoa(val, buf, type);
  *tmp_buf++ = '\0';
  return tmp_buf - buf;
}

static int itoa(int val, char *buf, char type) {
  char *tmp_buf = buf;
  // static bool is_prefix = false;
  if(val < 0) {
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
    case 'x': {
      if(val/16 != 0) {
        tmp_buf += itoa(val/16, tmp_buf, 'x');
      }
      if(val%16 <= 9) *tmp_buf++ = val%16 + '0';
      else *tmp_buf++ = val%16 - 10 + 'a';
      break;
    }
    case 'X': {
      if(val/16 != 0) {
        tmp_buf += itoa(val/16, tmp_buf, 'X');
      }
      if(val%16 <= 9) *tmp_buf++ = val%16 + '0';
      else *tmp_buf++ = val%16 - 10 + 'A';
      break;
    }
    case 'o': {
      if(val/8 != 0) {
        tmp_buf += itoa(val/8, tmp_buf, 'o');
      }
      *tmp_buf++ = val%8 + '0';
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
  va_list p_next = ap;

  for(p = out; *fmt != '\0'; fmt++) {
    if(*fmt != '%') {
      *p++ = *fmt;
      continue;
    }

    fmt++;

    switch(*fmt) {
      case 'd': {
        int val = va_arg(p_next, int);
        itoa_recur(val, tmp, 'd'); 
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      } 
      case 'x': {
        int val = va_arg(p_next, int);
        itoa_recur(val, tmp, 'x');
        strcpy(p, tmp);
        p += strlen(tmp);
        break;
      }
      case 'X': {
        int val = va_arg(p_next, int);
        itoa_recur(val, tmp, 'X');
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
