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
    cacheway = CACHE_WAY;

    cache_tag = std::vector<std::vector<uint32_t>>(cachenum, std::vector<uint32_t>(cacheway, 0));
    cache_valid = std::vector<std::vector<bool>>(cachenum, std::vector<bool>(cacheway, false));
    cache_data = std::vector<std::vector<std::vector<uint32_t>>>(cachenum, std::vector<std::vector<uint32_t>>(cacheway, std::vector<uint32_t>(cachesize/4, 0)));
}

CacheSim::~CacheSim() {
    print_results();
}

int CacheSim::setCache_size_num(uint32_t size, uint32_t num, uint32_t way) {
    cachesize = size;
    cachenum = num;
    cacheway = way;
    cache_tag = std::vector<std::vector<uint32_t>>(cachenum, std::vector<uint32_t>(cacheway, 0));
    cache_valid = std::vector<std::vector<bool>>(cachenum, std::vector<bool>(cacheway, false));
    cache_data = std::vector<std::vector<std::vector<uint32_t>>>(cachenum, std::vector<std::vector<uint32_t>>(cacheway, std::vector<uint32_t>(cachesize/4, 0)));
    return 0;
}

void CacheSim::print_results() {
  double hit_rate = cache_hit*1.0/inst_cnt;
  double miss_rate = cache_miss*1.0/inst_cnt;
    std::cout << "Total_insts: " << inst_cnt << std::endl;
    assert(inst_cnt > 0);
    std::cout << "ICache_Hit: " << cache_hit << " Percentage:" << hit_rate * 100 << "%" << std::endl;
    std::cout << "ICacche_Miss: " << cache_miss << " Percentage:" << miss_rate * 100 << "%" << std::endl;
    std::cout << "ICache: " << "AMAT: " << HIT_CYCLES * hit_rate + MISS_CYCLES * miss_rate << " TMT: " << MISS_CYCLES * cache_miss << std::endl;
}

bool CacheSim::is_cachehit(uint32_t address) {
  // Calculate cache index and tag
  uint32_t index = (address / cachesize) % cachenum;
  uint32_t tag = address / cachesize / cachenum;
  uint32_t offset = (address % cachesize) / 4;

  bool valid = cache_valid[index][tag%cacheway];
  bool is_tag_same = false;
  for(uint32_t i=0; i<cacheway; i++) {
    if(this->cache_tag[index][i] == tag) {
      if(this->cache_data[index][i][offset] == address) {
        is_tag_same = true;
        break;
      }
      else {
        printf("error hit, not just only cache miss! should be:0x%x, but get: 0x%x\n", address, this->cache_data[index][i][offset]);
        assert(0);
        break;
      }
    }
  }
  return valid && is_tag_same;
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


        // Check if the cache line is valid and matches the tag
        if (is_cachehit(address)) {
            // Cache hit
            cache_hit++;
            // printf("cache hit addr: 0x%x\n", address);
        } else {
            address = address & ~(cachesize-1);
            uint32_t index = (address / cachesize) % cachenum;
            uint32_t tag = address / cachesize / cachenum;
            // Cache miss
            cache_miss++;
            // Update cache line
            cache_valid[index][tag%cacheway] = true;
            cache_tag[index][tag%cacheway] = tag;
            // Simulate storing data in the cache (for simplicity, just store the address)
            for(uint32_t i=0; i<cacheway; i++) {
              printf("save cache data: 0x%x\n", address);
              cache_data[index][tag%cacheway][i] = address;
              address += 0x4;
            }
            printf("access soc done\n");
        }
    }

    inst_file.close();
}
