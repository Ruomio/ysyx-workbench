#include <iostream>

#include "cachesim.h"


int main(int argc, char **argv) {
    if(argc < 2) {
        std::cout << "Cachesim Need a file path" << std::endl;
        return -1;
    }
    CacheSim cachesim(argv[1]);

    if(argv[2] && argv[3]) {
        cachesim.setCachesize(atoi(argv[2]));
        cachesim.setCachenum(atoi(argv[3]));
    }
    else {
        std::cout << "sim as default size:4 and num:16" << std::endl;
    }

    cachesim.run_simulation();
}