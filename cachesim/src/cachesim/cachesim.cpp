#include <cstdint>
#include <iostream>
#include <cassert>
#include <fstream>

#include "cachesim/cachesim.h"

CacheSim::CacheSim(std::string path) {
    inst_file_path = path;

    cache_hit = 0;
    cache_miss = 0;
    inst_cnt = 0;

    cache_valid = std::vector<bool>(CACHE_NUM, 0);
    cache_tag = std::vector<uint32_t>(CACHE_NUM, 0);
    cache_data = std::vector<uint32_t>(CACHE_NUM * CACHE_SIZE/4, 0);
}

CacheSim::~CacheSim() {
    print_results();
}

void CacheSim::print_results() {
    std::cout << "Total_insts: " << inst_cnt << std::endl;
    assert(inst_cnt > 0);
    std::cout << "Cache_Hit: " << cache_hit << " Percentage:" << cache_hit*100.0/inst_cnt << "%" << std::endl;
    std::cout << "Cacche_Miss: " << cache_miss << " Percentage:" << cache_miss*100.0/inst_cnt << "%" << std::endl;
}

void CacheSim::run_simulation() {
    std::ifstream inst_file(inst_file_path);
    if (!inst_file.is_open()) {
        std::cerr << "Error opening instruction file: " << inst_file_path << std::endl;
        return;
    }

    uint32_t address;
    std::string line;
    while (std::getline(inst_file, line)) {
        if(line.empty()) return;
        if(line.back() == ':') {
            line.pop_back();
        }
        address = static_cast<uint32_t>(std::stoul(line, nullptr, 16));

        inst_cnt++;

        // Calculate cache index and tag
        uint32_t index = (address / CACHE_SIZE) % CACHE_NUM; // Assuming each instruction is 4 bytes
        uint32_t tag = address / CACHE_SIZE / CACHE_NUM;

        // Check if the cache line is valid and matches the tag
        if (cache_valid[index] && cache_tag[index] == tag) {
            // Cache hit
            cache_hit++;
        } else {
            // Cache miss
            cache_miss++;
            // Update cache line
            cache_valid[index] = true;
            cache_tag[index] = tag;
            // Simulate storing data in the cache (for simplicity, just store the address)
            cache_data[index] = address; 
        }
    }

    inst_file.close();
}