#ifndef __BRANCHSIM_H__
#define __BRANCHSIM_H__

#include <map>
#include <fstream>
#include <cstdint>
#include <cmath>
#include <vector>

#include "macro.h"

#define BRANCH_INDEX 4
#define BRANCH_WAY 4
#define BRANCH_SIZE 4

struct BtbMeta{
    struct btb_tag_type{
        uint32_t tag;
        uint32_t target_pc[BRANCH_SIZE>>2];
        bool valid;
    };
    struct btb_tag_type branch_tag[BRANCH_WAY];
};

enum {
    ALWAYS_TAKEN = 0,
    ALWAYS_NOT_TAKEN,
    BTFN,
};

struct BranchInfo {
    bool is_branch;
    uint32_t target;
};

class BranchSim
{
public:
    BranchSim();
    ~BranchSim();
    void Init(std::string disasm_file, std::string pc_stream_file);
    void RunPredict(int flag);
    void RunPredictWithBTB(int flag);

private:
    std::ifstream disasm_file;
    std::ifstream pc_stream_file;
    std::vector<uint32_t> pc_stream;
    std::map<uint32_t, BranchInfo> branch_map;

    // BTB
    const uint8_t branch_size_bits = std::log2(BRANCH_SIZE);
    const uint8_t branch_way_bits = std::log2(BRANCH_WAY);
    const uint8_t branch_tag_bits = 32 - branch_way_bits - branch_size_bits;

    uint8_t btb_way;
    BtbMeta btb_meta[BRANCH_INDEX];
};

#endif
