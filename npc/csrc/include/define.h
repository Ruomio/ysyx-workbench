#ifndef __DEFINE_H__
#define __DEFINE_H__

#include <getopt.h>

#define MBASE 0x80000000
#define MSIZE 0x40000000     // 4G 2^31


#define no_argument		0
#define required_argument	1
#define optional_argument	2

extern int getopt_long (int ___argc, char *__getopt_argv_const *___argv, 
                const char *__shortopts, 
                const struct option *__longopts, int *__longind) 
                __THROW __nonnull ((2, 3));

extern int getopt_long_only (int ___argc, char *__getopt_argv_const *___argv, 
                const char *__shortopts, 
                const struct option *__longopts, int *__longind) 
                __THROW __nonnull ((2, 3));

#endif