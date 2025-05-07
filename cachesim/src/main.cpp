#include <iostream>
#include <string.h>

#include "cachesim.h"


int main(int argc, char **argv) {
    if(argc < 2) {
        std::cout << "Cachesim Need a file path" << std::endl;
        return -1;
    }
    CacheSim cachesim(argv[1]);

    if(argv[2] && argv[3] && argv[4]) {
        cachesim.setCache_size_num(atoi(argv[2]), atoi(argv[3]), atoi(argv[4]));
    }
    else {
        std::cout << "sim as default size: "<< CACHE_SIZE << " num:" << CACHE_NUM << " and way:" << CACHE_WAY << std::endl;
    }

    // decide icache or decache
    if(argv[5]) {
        if( strcmp(argv[5], "ICACHE") == 0) {
            cachesim.setMode(0);
            printf("ICache Sim.\n");
        }
        else {
            printf("%s\n", argv[5]);
            cachesim.setMode(1);
            printf("DCache Sim.\n");
        }
    }
    else {
        printf("ICache Sim.\n");
    }

    cachesim.run_simulation();
}
