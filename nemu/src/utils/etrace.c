/***************************************************************************************
* Copyright (c) 2024-2024 Peizhi Peng
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/
#include <common.h>

static bool is_init = false;
static FILE *fp = NULL;

void etrace_init() {
    fp = fopen("/home/papillon/Documents/All_codes/ysyx-workbench/nemu/build/etrace-log.txt", "w");

    is_init = true;
}
void etrace_write(word_t NO, vaddr_t epc) {
    if(!is_init) etrace_init();
    assert(fp);
    fseek(fp, 0, SEEK_END);

    char buf[128] = {};
    sprintf(buf, "[%s] at PC 0x%x, cause 0x%x\n", NO&0x80000000 ? "Interrupt" : "Exception", epc, NO);

    fprintf(fp, "%s", buf);

}

void etrace_close() {
    fclose(fp);
    fp = NULL;
}