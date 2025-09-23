#include <cstdint>
#include <fstream>
#include <ios>
#include <iostream>
#include <ostream>
#include <regex>
#include <string>
#include <exception>
#include <cstdlib>
#include <cstring>
#include <cmath>

#include "branchsim.h"

BranchSim::BranchSim() {
    btb_way = 0;
    memset(btb_meta, 0, sizeof(btb_meta));

}

BranchSim::~BranchSim() {
    disasm_file.close();
    pc_stream_file.close();
}

void BranchSim::Init(std::string disasm_file_path, std::string pc_stream_file_path) {
    std::regex j_regex(R"((\S+):\s+\S+\s+(?:j|jal)\s+(\S+))");
    std::regex b_regex(R"((\S+):\s+\S+\s+b(?:eq|eqz|ne|lt|ge|ltu|geu)\s+\S+,\S+,(\S+))");

    disasm_file.open(disasm_file_path.c_str());
    if(!disasm_file.is_open()) {
        std::cout << "open file faile: " << disasm_file_path << std::endl;
        return;
    }
    pc_stream_file.open(pc_stream_file_path.c_str());
    if(!pc_stream_file.is_open()) {
        std::cout << "open file faile: " << pc_stream_file_path << std::endl;
        return;
    }

    std::string line;
    while(std::getline(disasm_file, line)) {
        std::smatch match;
        uint32_t pc, target;
        try {
            if (regex_search(line, match, b_regex) && match.size() == 3) {
                pc = stoul(match[1], nullptr, 16);
                target = stoul(match[2], nullptr, 16);
                branch_map[pc] = { true, target };
            }
            else if (regex_search(line, match, j_regex) && match.size() == 3) {
                pc = stoul(match[1], nullptr, 16);
                target = stoul(match[2], nullptr, 16);
                branch_map[pc] = { true, target };
                // std::cout << "b type: "<< std::hex << pc << std::endl;
            }
        }
        catch(const std::exception &e) {
            std::cerr << "Error parsing disassembly file: " << e.what() << " " << match[1] << " " << match[2] << std::endl;
        }
    }

    while (getline(pc_stream_file, line)) {
        if (line.find("0x") != std::string::npos) {
            size_t colon_pos = line.find(':');
            if (colon_pos != std::string::npos) line = line.substr(0, colon_pos);
            std::string hex = line.substr(2);
            pc_stream.push_back(stoul(hex, nullptr, 16));
        }
    }

}

void BranchSim::RunPredict(int flag) {
    int correct = 0;
    int total = 0;

    for (size_t i = 0; i < pc_stream.size() - 1; ++i) {
        uint32_t current_pc = pc_stream[i];
        uint32_t next_pc = pc_stream[i + 1];

        if(next_pc != current_pc + 0x4) total++;

        auto it = branch_map.find(current_pc);
        if (it != branch_map.end()) {
            switch(flag) {
                case(ALWAYS_TAKEN): {
                    uint32_t branch_target = it->second.target;

                    uint32_t predicted_next_pc =  branch_target;

                    if (predicted_next_pc == next_pc) ++correct;

                    break;
                }
                case(ALWAYS_NOT_TAKEN): {
                    uint32_t predicted_next_pc =  current_pc + 4;

                    if (predicted_next_pc == next_pc) ++correct;

                    break;
                }
                case(BTFN): {
                    uint32_t branch_target = it->second.target;
                    bool predicted_taken = (branch_target < current_pc); // BTFN: 后向跳转预测为 taken

                    uint32_t predicted_next_pc = predicted_taken ? branch_target : (current_pc + 4);

                    if (predicted_next_pc == next_pc) ++correct;

                    break;
                }
                default: {
                    // default BTFN
                    uint32_t branch_target = it->second.target;
                    bool predicted_taken = (branch_target < current_pc); // BTFN: 后向跳转预测为 taken

                    uint32_t predicted_next_pc = predicted_taken ? branch_target : (current_pc + 4);

                    if (predicted_next_pc == next_pc) ++correct;

                    break;
                }
            }
        }
        else {
            // not b or jal instruction
            // ++correct;
            // ++total;
        }
    }
    switch (flag) {
        case(ALWAYS_TAKEN):
            std::cout << "ALWAYS_TAKEN" << std::endl;
            std::cout << "Hit cnt:" << correct << std::endl;
            std::cout << "Total:" << total << std::endl;
            std::cout << "Accuracy: " << (double)correct*100 / total << "%" << std::endl;
            break;
        case(ALWAYS_NOT_TAKEN):
            std::cout << "ALWAYS_NOT_TAKEN" << std::endl;
            std::cout << "Hit cnt:" << correct << std::endl;
            std::cout << "Total:" << total << std::endl;
            std::cout << "Accuracy: " << (double)correct*100 / total << "%" << std::endl;
            break;
        case(BTFN):
            std::cout << "BTFN" << std::endl;
            std::cout << "Hit cnt:" << correct << std::endl;
            std::cout << "Total:" << total << std::endl;
            std::cout << "Accuracy: " << (double)correct*100 / total << "%" << std::endl;
            break;
        default:
            std::cout << "BTFN" << std::endl;
            std::cout << "Hit cnt:" << correct << std::endl;
            std::cout << "Total:" << total << std::endl;
            std::cout << "Accuracy: " << (double)correct*100 / total << "%" << std::endl;
            break;
    }
    std::cout << std::endl;
}


void BranchSim::RunPredictWithBTB(int flag) {
    int correct = 0;
    int total = 0;

    for (size_t i = 0; i < pc_stream.size() - 1; ++i) {
        uint32_t current_pc = pc_stream[i];
        uint32_t next_pc = pc_stream[i + 1];

        if(next_pc != current_pc + 0x4) total++;

        auto it = branch_map.find(current_pc);
        if(it != branch_map.end()) {
            // total++;

            uint32_t predict_pc = 0;

            int index = BITS(current_pc, branch_size_bits+branch_way_bits-1, branch_size_bits);

            bool btb_hit = false;

            BtbMeta tmp = btb_meta[index];

            for(auto &i : tmp.branch_tag) {
                if(i.valid && i.tag == current_pc) {
                    switch(flag) {
                        case ALWAYS_TAKEN: {
                            predict_pc = i.target_pc[current_pc%BRANCH_SIZE];
                            btb_hit = true;
                            break;
                        }
                        case ALWAYS_NOT_TAKEN: {
                            predict_pc = current_pc + 4;
                            btb_hit = true;
                            break;
                        }
                        case BTFN: {
                            uint32_t tmp_pc = i.target_pc[current_pc%BRANCH_SIZE];
                            predict_pc = tmp_pc < current_pc ? tmp_pc : current_pc + 4;
                            btb_hit = true;
                            break;
                        }
                        default: {
                            // default btfn
                            uint32_t tmp_pc = i.target_pc[current_pc%BRANCH_SIZE];
                            predict_pc = tmp_pc < current_pc ? tmp_pc : current_pc + 4;
                            btb_hit = true;
                            break;
                        }
                    }
                    break;
                }
            }

            if(btb_hit) {
                if(predict_pc != next_pc) {
                    // predict fail
                    // std::cout << "current_pc: " << std::hex << current_pc << ", next_pc: " << std::hex << next_pc << ", predict_pc: " << std::hex << predict_pc << std::endl;
                }
                else {
                    correct++;
                }
            }
            else {
                btb_meta[index].branch_tag[btb_way].valid = true;
                btb_meta[index].branch_tag[btb_way].tag = current_pc;
                btb_meta[index].branch_tag[btb_way].target_pc[0] = next_pc;

                btb_way = (btb_way + 1) % BRANCH_WAY;
            }
        }
    }

    switch (flag) {
        case(ALWAYS_TAKEN):
            std::cout << "ALWAYS_TAKEN" << std::endl;
            std::cout << "Hit cnt:" << correct << std::endl;
            std::cout << "Total:" << total << std::endl;
            std::cout << "Accuracy: " << (double)correct*100 / total << "%" << std::endl;
            break;
        case(ALWAYS_NOT_TAKEN):
            std::cout << "ALWAYS_NOT_TAKEN" << std::endl;
            std::cout << "Hit cnt:" << correct << std::endl;
            std::cout << "Total:" << total << std::endl;
            std::cout << "Accuracy: " << (double)correct*100 / total << "%" << std::endl;
            break;
        case(BTFN):
            std::cout << "BTFN" << std::endl;
            std::cout << "Hit cnt:" << correct << std::endl;
            std::cout << "Total:" << total << std::endl;
            std::cout << "Accuracy: " << (double)correct*100 / total << "%" << std::endl;
            break;
        default:
            std::cout << "BTFN" << std::endl;
            std::cout << "Hit cnt:" << correct << std::endl;
            std::cout << "Total:" << total << std::endl;
            std::cout << "Accuracy: " << (double)correct*100 / total << "%" << std::endl;
            break;
    }
    std::cout << std::endl;
}
