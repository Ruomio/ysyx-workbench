#include <cstdint>
#include <iostream>
#include <cassert>
#include <fstream>
#include <vector>

#include "cachesim.h"

CacheSim::CacheSim(std::string path) {
    inst_file_path = path;

    cache_hit = 0;
    cache_miss = 0;
    inst_cnt = 0;

    cachesize = CACHE_SIZE;
    cachenum = CACHE_NUM;

    cache_tag.resize(cachenum, 0);
    cache_valid = std::vector<std::vector<bool>>(cachenum, std::vector<bool>(cachesize/4, false));
    cache_data = std::vector<std::vector<uint32_t>>(cachenum * cachesize/4, std::vector<uint32_t>(cachesize/4, 0));
}

CacheSim::~CacheSim() {
    print_results();
}

int CacheSim::setCachesize(uint32_t size) {
    cachesize = size;
    cache_data = std::vector<std::vector<uint32_t>>(cachenum * cachesize/4, std::vector<uint32_t>(cachesize/4, 0));
    return 0;
}

int CacheSim::setCachenum(uint32_t num) {
    cachenum = num;
    cache_tag.resize(cachenum, 0);
    cache_valid = std::vector<std::vector<bool>>(cachenum, std::vector<bool>(cachesize/4, false));
    cache_data = std::vector<std::vector<uint32_t>>(cachenum * cachesize/4, std::vector<uint32_t>(cachesize/4, 0));
    return 0;
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
        uint32_t index = (address / cachesize) % cachenum; // Assuming each instruction is 4 bytes
        uint32_t tag = address / cachesize;
        uint32_t offset = (address % cachesize) / 4;

        // Check if the cache line is valid and matches the tag
        if (cache_valid[index][offset] && cache_tag[index] == tag) {
            // Cache hit
            cache_hit++;
        } else {
            // Cache miss
            cache_miss++;
            // Update cache line
            cache_valid[index][offset] = true;
            cache_tag[index] = tag;
            // Simulate storing data in the cache (for simplicity, just store the address)
            cache_data[index][offset] = address; 
        }
    }

    inst_file.close();
}