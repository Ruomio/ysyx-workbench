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

    int setCache_size_num(uint32_t size, uint32_t num);

private:
    uint32_t cache_hit;
    uint32_t cache_miss;
    uint32_t inst_cnt;

    std::string inst_file_path;

    uint32_t cachesize;
    uint32_t cachenum;
    uint32_t cache_index;
    std::vector<std::vector<bool>> cache_valid;
    std::vector<std::vector<uint32_t>> cache_tag;
    std::vector<std::vector<uint32_t>> cache_data;

};

#endif