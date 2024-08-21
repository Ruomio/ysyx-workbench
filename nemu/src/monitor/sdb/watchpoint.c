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



static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
WP *new_wp(bool *success) {
  if(!free_) { 
    printf("\033[0;31mfree_ is already empty.\033[0m\n");
    *success = false;
    return NULL; 
  }

  WP *new = free_;
  free_ = free_->next;
  new->next = NULL;

  if(!head) head = new;
  else {
    new->next = head;
    head = new;
  }

  *success = true;
  return new;
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
    head = head->next;
  }
  else {
    WP *p = head, *q = head->next;
    while(q) {
      if(q == wp) {
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

