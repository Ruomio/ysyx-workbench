#include <klib.h>
#include <klib-macros.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define NK (1)
#define BF_SIZE (NK * (1u << 8))

size_t strlen(const char *s) {
  size_t len = 0;
  while(s[len++] != '\0');
  len--;
  return len;
}

char *strcpy(char *dst, const char *src) {
  size_t len = strlen(src);

  memcpy(dst, src, len);

  // promise dst end as '\0'
  dst[len] = '\0'; 
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t dlen;
  dlen = strlen(src);

  memset((memcpy(dst, src, dlen) + dlen), 0, n-dlen);
  return dst;
}

char *strcat(char *dst, const char *src) {
  strcpy(dst + strlen(dst), src);
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  for(int i=0; s1[i] != '\0' || s2[i] != '\0' ; i++) {
    if(s1[i] == '\0') return s2[i];
    else if(s2[i] == '\0') return s1[1];
    else if(*((uint8_t *)s1 + i) != *((uint8_t *)s2 + i)) {
      return *((uint8_t *)s1 + i) - *((uint8_t *)s2 + i);
    }
  }
  return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  for(int i=0; (i < n) && (s1[i] != '\0' || s2[i] != '\0') ; i++) {
    if(s1[i] == '\0') return s2[i];
    else if(s2[i] == '\0') return s1[1];
    else if(*((uint8_t *)s1 + i) != *((uint8_t *)s2 + i)) {
      return *((uint8_t *)s1 + i) - *((uint8_t *)s2 + i);
    }
  }
  return 0;
}

void *memset(void *s, int c, size_t n) {
  uint8_t *tmp = (uint8_t *)s;
  uint8_t c_tmp = (uint8_t)c;
  for(int i=0; i<n; i++) {
    *tmp = c_tmp;
    tmp += 1;
  }

  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  // src and out is overlap
  size_t idx = 0;
  uint8_t buf[BF_SIZE] = {};
  while(idx < n) {
    // assert(idx < BF_SIZE);
    buf[idx] = *((char *)src + idx);
    idx++;
  }
  idx = 0;
  while(idx < n) {
    *((uint8_t *)dst + idx) = buf[idx];
    idx++;
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  // src and out not overlap
  size_t idx = 0;
  while(idx < n) {
    *((uint8_t*)out + idx) = *((uint8_t *)in + idx);
    idx++;
  }
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  for(int i=0; (i<n) && (*((uint8_t*)s1 + i) != '\0' || *((uint8_t*)s2 + i) != '\0') ; i++) {
    if(*((uint8_t*)s1 + i) == '\0') return -*((uint8_t*)s2 + i);
    else if(*((uint8_t*)s2 + i) == '\0') return *((uint8_t*)s1 + i);
    else if(*((uint8_t *)s1 + i) != *((uint8_t *)s2 + i)) {
      return *((uint8_t *)s1 + i) - *((uint8_t *)s2 + i);
    }
  }
  return 0;
}

#endif
