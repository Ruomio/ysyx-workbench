#ifndef __CACHESIM__
#define __CACHESIM__

#include <cstdint>
#include <vector>
#include <string>

#define CACHE_SIZE 4
#define CACHE_NUM 16


class CacheSim {
public:
    CacheSim(std::string path);
    ~CacheSim();
    void run_simulation();
    void print_results();

private:
    uint32_t cache_hit;
    uint32_t cache_miss;
    uint32_t inst_cnt;

    std::string inst_file_path;

    uint32_t cache_index;
    std::vector<bool> cache_valid;
    std::vector<uint32_t> cache_tag;
    std::vector<uint32_t> cache_data;

};

#endif