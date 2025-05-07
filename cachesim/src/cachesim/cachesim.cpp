#include <cstdint>
#include <iostream>
#include <cassert>
#include <fstream>
#include <vector>
#include <regex>

#include "cachesim.h"

CacheSim::CacheSim(std::string path) {
    inst_file_path = path;

    mode = 0;
    cache_hit = 0;
    cache_miss = 0;
    inst_cnt = 0;

    cachesize = CACHE_SIZE;
    cachenum = CACHE_NUM;
    cacheway = CACHE_WAY;


    fifo_index = std::vector<uint32_t>(cachenum, 0);
    cache_tag = new std::vector<std::vector<uint32_t>>(cachenum, std::vector<uint32_t>(cacheway, 0));
    cache_valid = new std::vector<std::vector<bool>>(cachenum, std::vector<bool>(cacheway, false));
    cache_data = new std::vector<std::vector<std::vector<uint32_t>>>(cachenum, std::vector<std::vector<uint32_t>>(cacheway, std::vector<uint32_t>(cachesize/4, 0)));
}

CacheSim::~CacheSim() {
    print_results();
    if(cache_tag) delete cache_tag;
    if(cache_valid) delete cache_valid;
    if(cache_data) delete cache_data;
}

int CacheSim::setMode(bool mode) {
  this->mode = mode;
  return 0;
}

int CacheSim::setCache_size_num(uint32_t size, uint32_t num, uint32_t way) {
    cachesize = size;
    cachenum = num;
    cacheway = way;
    if(cache_tag) delete cache_tag;
    if(cache_valid) delete cache_valid;
    if(cache_data) delete cache_data;
    cache_tag = new std::vector<std::vector<uint32_t>>(cachenum, std::vector<uint32_t>(cacheway, 0));
    cache_valid = new std::vector<std::vector<bool>>(cachenum, std::vector<bool>(cacheway, false));
    cache_data = new std::vector<std::vector<std::vector<uint32_t>>>(cachenum, std::vector<std::vector<uint32_t>>(cacheway, std::vector<uint32_t>(cachesize/4, 0)));
    return 0;
}

void CacheSim::print_results() {
  double hit_rate = cache_hit*1.0/inst_cnt;
  double miss_rate = cache_miss*1.0/inst_cnt;
    std::cout << "Total_insts: " << inst_cnt << std::endl;
    assert(inst_cnt > 0);
    if(!mode) {
      std::cout << "ICache_Hit: " << cache_hit << " Percentage:" << hit_rate * 100 << "%" << std::endl;
      std::cout << "ICache_Miss: " << cache_miss << " Percentage:" << miss_rate * 100 << "%" << std::endl;
      std::cout << "ICache: " << "AMAT: " << HIT_CYCLES * hit_rate + MISS_CYCLES * miss_rate << " TMT: " << MISS_CYCLES * cache_miss << std::endl;
    }
    else {
      std::cout << "DCache_Hit: " << cache_hit << " Percentage:" << hit_rate * 100 << "%" << std::endl;
      std::cout << "DCache_Miss: " << cache_miss << " Percentage:" << miss_rate * 100 << "%" << std::endl;
      std::cout << "DCache: " << "AMAT: " << HIT_CYCLES * hit_rate + MISS_CYCLES * miss_rate << " TMT: " << MISS_CYCLES * cache_miss << std::endl;
    }
}

bool CacheSim::is_cachehit(uint32_t address) {
  // Calculate cache index and tag
  uint32_t index = (address / cachesize) % cachenum;
  uint32_t tag = address / cachesize / cachenum;
  uint32_t offset = (address % cachesize) / 4;

  bool valid = false;
  bool is_tag_same = false;
  for(uint32_t i=0; i<cacheway; i++) {
    if((*(this->cache_tag))[index][i] == tag && (*(this->cache_valid))[index][i]) {
      if((*cache_data)[index][i][offset] == address) {
        // printf("cache hit addr: 0x%x\n", address);
        valid = true;
        is_tag_same = true;
        break;
      }
      else {
        // printf("error hit, not just only cache miss! should be:0x%x, but get: 0x%x\n", address, (cache_data)[index][i][offset]);
        assert(0);
        break;
      }
    }
    else {
      // printf("cache miss! address: 0x%x, fifo_index:%d \n",address, i);
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

    uint32_t address = 0;
    std::string line;
    std::regex addr_pattern("[x0-9a-z]+");
    std::regex r_pattern("r");
    std::smatch matches;

    bool rw_ = 0;

    while (std::getline(inst_file, line)) {
        if(line.empty()) return;
        printf("line: %s\n", line.c_str());
        if(std::regex_search(line, matches, addr_pattern)) {
            address = static_cast<uint32_t>(std::stoul(matches[0], nullptr, 16));
            printf("address: 0x%x\n", address);
        }
        if(std::regex_match(line, r_pattern)) {
            rw_ = 0;
        }
        else {
            rw_ = 1;
        }

        inst_cnt++;

        if(rw_ == 1 && mode == 1) {
            // write, need invalid cache block
            address = address & ~(cachesize-1);
            uint32_t index = (address / cachesize) % cachenum;
            uint32_t tag = address / cachesize / cachenum;

            for(int i=0; i<CACHE_WAY; i++) {
                if((*cache_tag)[index][i] == tag) {
                    (*cache_valid)[index][i] = false;
                    printf("set invalid addr: 0x%x\n", address);
                }
            }
        }


        // Check if the cache line is valid and matches the tag
        if (is_cachehit(address)) {
            // Cache hit
            cache_hit++;
            // printf("cache hit addr: 0x%x\n", address);
        } else {
            // Cache miss
            cache_miss++;
            // Update cache line
            address = address & ~(cachesize-1);
            uint32_t index = (address / cachesize) % cachenum;
            uint32_t tag = address / cachesize / cachenum;

            // Simulate storing data in the cache (for simplicity, just store the address)
            for(uint32_t i=0; i<cachesize/4; i++) {
                // printf("save cache data: 0x%x\n", address);
                (*cache_data)[index][fifo_index[index]][i] = address;
                address += 0x4;
            }
            (*cache_valid)[index][fifo_index[index]] = true;
            (*cache_tag)[index][fifo_index[index]] = tag;
            fifo_index[index] = (fifo_index[index]+1) % cacheway;
            // printf("fifo_index[%d]: %d\n", index, fifo_index[index]);
            // printf("access soc done\n");
        }
    }

    inst_file.close();
}
