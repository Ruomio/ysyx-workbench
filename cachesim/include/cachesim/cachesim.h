#ifndef __CACHESIM__
#define __CACHESIM__

#include <cstdint>
#include <vector>
#include <string>

#define CACHE_SIZE 4
#define CACHE_NUM 16
#define CACHE_WAY 4
#define MISS_CYCLES 2466
#define HIT_CYCLES 3



class CacheSim {
public:
    CacheSim(std::string path);
    ~CacheSim();
    void run_simulation();
    void print_results();
    bool is_cachehit(uint32_t address);

    int setCache_size_num(uint32_t size, uint32_t num, uint32_t way);

private:
    uint32_t cache_hit;
    uint32_t cache_miss;
    uint32_t inst_cnt;

    std::string inst_file_path;

    uint32_t cachesize;
    uint32_t cachenum;
    uint32_t cacheway;
    uint32_t cache_index;
    std::vector<std::vector<bool>> cache_valid;
    std::vector<std::vector<uint32_t>> cache_tag;
    std::vector<std::vector<std::vector<uint32_t>>> *cache_data = nullptr;
    uint32_t fifo_index;
};

#endif
