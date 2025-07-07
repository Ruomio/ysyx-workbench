#include <iostream>
#include <memory>

#include "branchsim.h"

int main(int argc, char *argv[]) {
    if(argc < 3) {
        std::cout << "Usage: " << argv[0] << "  disasm_file  pc_stream_file" << std::endl;
        return -1;
    }
    auto bs = std::make_shared<BranchSim>();
    bs->Init(argv[1], argv[2]);

    // bs->RunPredict(ALWAYS_TAKEN);
    // bs->RunPredict(ALWAYS_NOT_TAKEN);
    // bs->RunPredict(BTFN);

    bs->RunPredictWithBTB(ALWAYS_TAKEN);
    bs->RunPredictWithBTB(ALWAYS_NOT_TAKEN);
    bs->RunPredictWithBTB(BTFN);

    return 0;
}
