#ifndef __BRANCHSIM_H__
#define __BRANCHSIM_H__

#include <map>
#include <fstream>
#include <cstdint>
#include <vector>

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

private:
    std::ifstream disasm_file;
    std::ifstream pc_stream_file;
    std::vector<uint32_t> pc_stream;
    std::map<uint32_t, BranchInfo> branch_map;
};

#endif
