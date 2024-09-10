#ifndef __DEFINE_H__
#define __DEFINE_H__

#define MSIZE 0x40000000     // 4G 2^31

struct option
{
  const char *name;
  /* has_arg can't be an enum because some compilers complain about
     type mismatches in all the code that assumes it is an int.  */
  int has_arg;
  int *flag;
  int val;
};

#define no_argument		0
#define required_argument	1
#define optional_argument	2

extern int getopt_long (int ___argc, char *__getopt_argv_const *___argv, const char *__shortopts, const struct option *__longopts, int *__longind) __THROW __nonnull ((2, 3));
extern int getopt_long_only (int ___argc, char *__getopt_argv_const *___argv, const char *__shortopts, const struct option *__longopts, int *__longind) __THROW __nonnull ((2, 3));

#endif