/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
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

#include "sdb.h"

#define NR_WP 32
#define NR_BA 32
#define STR_SIZE 64

extern uint32_t g_pc;

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  int type;
  char str[STR_SIZE];
} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;
static word_t last[NR_WP] = {0};


void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    memset(wp_pool[i].str, 0, STR_SIZE);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
WP *new_wp(char *s, int type) {
  if(!free_) { 
    printf("\033[0;31mfree_ is already empty.\033[0m\n");
    return NULL; 
  }

  if(strlen(s) < STR_SIZE) {
    WP *new_node = free_;
    free_ = free_->next;
    new_node->next = NULL;
    strcpy(new_node->str, s);
    new_node->type = type;
    bool success = false;
    word_t ret = expr(s, &success);
    last[new_node->NO] = ret;


    if(!head) head = new_node;
    else {
      new_node->next = head;
      head = new_node;
    }

    return new_node;
  }
  else {
    printf("\033[0;31mexpr str is too long, over WP->str size\033[0m\n");
    return NULL;
  }

}

bool new_wp_interface(char *s, int type) {
  WP *ret = new_wp(s, type);
  if(ret) {
    return true;
  }
  return false;
}

void free_wp(WP *wp) {
  if(!wp) {
    printf("\033[0;31mcan not free NULL.\033[0m\n");
    return;
  }

  if(!head) {
    // impossible
    assert(0);
  }
  else if(head == wp) {
    memset(head->str, 0, STR_SIZE);
    head = head->next;
  }
  else {
    WP *p = head, *q = head->next;
    while(q) {
      if(q == wp) {
        memset(q->str, 0, STR_SIZE);
        p->next = q->next;
        break;
      }
      p = p->next;
      q = q->next;
    } 
  }

  if(!free_) {
    free_ = wp;
  }
  else {
    wp->next = free_;
    free_ = wp;
  }
}


bool free_wp_by_no_interface(int no) {
  for(WP *p = head; p != NULL; p = p->next) {
    if(p->NO == no) {
      free_wp(p);
      return true;
    }
  }
  return false;
}


void scan_watchpoint(bool *is_change, bool *is_break) {
  for(WP *p = head; p != NULL; p = p->next) {
    bool success = false;
    word_t ret = expr(p->str, &success);
    if(!success) {
      printf("\033[0;31mexpr fail.\033[0m\n");
      return;
    }
    if(ret == g_pc && p->type == BA_TYPE) {
      *is_break = true;
      printf("break point at 0x%x\n", ret);
      return;
    }
    if(ret != last[p->NO] && p->type == WP_TYPE ) {
      *is_change = true;
      printf("watch point %d: %s\n", p->NO, p->str);
      printf("Old value = 0x%x\n", last[p->NO]);
      printf("New value = 0x%x\n", ret);

    }
    last[p->NO] = ret;
  }
}

void print_watchpoint() {
  for(WP *p = head; p != NULL; p = p->next) {
    bool success = false;
    word_t ret = expr(p->str, &success);
    if(!success) {
      printf("\033[0;31mexpr fail.\033[0m\n");
      return;
    }
    printf("watch point %d: %s\t\t0x%x\n", p->NO, p->str, ret);
  }
}