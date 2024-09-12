#ifndef __DEFINE_H__
#define __DEFINE_H__

#include <getopt.h>
#include <stdint.h>

#define MBASE 0x80000000
#define MSIZE 0x40000000     // 4G 2^31

enum NPCSTATE{NPC_RUNNING, NPC_STOP, NPC_END, NPC_ABORT, NPC_QUIT};
typedef struct{
    int state;
    uint32_t pc;
    bool ret;
}npc_state;

extern npc_state u_npc_state;

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