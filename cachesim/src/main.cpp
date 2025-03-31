#include <iostream>

#include "cachesim/cachesim.h"


int main(int argc, char **argv) {
    if(argc < 2) {
        std::cout << "Cachesim Need a file path" << std::endl;
        return -1;
    }
    CacheSim cachesim(argv[1]);

    cachesim.run_simulation();
}