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

#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include "common.h"

enum {
  TK_NOTYPE = 256,

  /* TODO: Add more token types */
  TK_PLUS,
  TK_SUB,
  TK_MULTIP,
  TK_DIV,
  TK_COMPLE,        // %
  TK_LBRACK,
  TK_RBRACK,
  TK_LMBRACK,       // [
  TK_RMBRACK,       // ]
  TK_DECNUM,
  TK_HEXNUM,
  TK_BINNUM,
  TK_REG,
  TK_DOT,           // .
  TK_ARROW,         // ->
  TK_DPLUS,         // ++
  TK_DSUB,         // --
  TK_LSHIFT,         // <<
  TK_RSHIFT,         // >>
  TK_BT,         // >
  TK_BEQ,         // >=
  TK_LT,         // <
  TK_LEQ,         // <=
  TK_EQ,         // ==
  TK_NEQ,        // !=
  TK_AND,
  TK_OR,
  TK_XOR,
  TK_COUNT,     // ~
  TK_NOT,     // ~
  TK_LAND,      // &&
  TK_LOR,       // ||
  TK_CONDI,       // ?:
  TK_ASSIGN,       // =
  TK_PLUS_ASSIGN,       // +=
  TK_SUB_ASSIGN,       // -=
  TK_MULTIP_ASSIGN,       // *=
  TK_DIV_ASSIGN,       // /=
  TK_COMPLE_ASSIGN,       // %=
  TK_LSHIFT_ASSIGN,       // <<=
  TK_RSHIFT_ASSIGN,       // >>=
  TK_AND_ASSIGN,       // &=
  TK_OR_ASSIGN,       // |=
  TK_XOR_ASSIGN,       // ^=
  TK_COMMA,       // ,
  TK_DEREFRENCE,    // *p_param
  TK_ADDRESSOF,    // &param
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", TK_PLUS},         // plus
  {"\\+\\+", TK_DPLUS},         // double plus
  {"==", TK_EQ},        // equal
  {"!=", TK_NEQ},        // equal
  {"-", TK_SUB},
  {"--", TK_DSUB},
  {"\\*[a-zA-Z]+[0-9]*", TK_DEREFRENCE},
  {"&[a-zA-Z]+[0-9]*", TK_ADDRESSOF},
  {"[a-zA-Z0-9]+\\.[a-zA-Z0-9]+", TK_DOT},
  {"[a-zA-Z0-9]+->[a-zA-Z0-9]+", TK_ARROW},
  {"\\*",TK_MULTIP},
  {"/", TK_DIV},
  {"%", TK_COMPLE},
  {"\\(", TK_LBRACK},
  {"\\)", TK_RBRACK},
  {"\\[", TK_LMBRACK},
  {"\\]", TK_LMBRACK},
  {"\\$(\\$0|ra|sp|gp|tp|t[0-6]|s[0-9]{1,2}|a[0-7])", TK_REG},
  {"0x[0-9a-fA-F]+", TK_HEXNUM},
  {"0b[0-1]+", TK_BINNUM},
  {"[0-9]+", TK_DECNUM},
  {"~", TK_COUNT},
  {"&", TK_AND},
  {"|", TK_OR},
  {"^", TK_XOR},
  {"!", TK_NOT},
  {"&&", TK_LAND},
  {"||", TK_LOR},
  {"<<", TK_LSHIFT},
  {">>", TK_LSHIFT},
  {">", TK_BT},
  {">=", TK_BEQ},
  {"<", TK_LT},
  {"<=", TK_LEQ},
  {"\\?", TK_CONDI},
  {"=", TK_ASSIGN},
  {"\\+=", TK_PLUS_ASSIGN},
  {"-=", TK_SUB_ASSIGN},
  {"\\*=", TK_MULTIP_ASSIGN},
  {"/=", TK_DIV_ASSIGN},
  {"%=", TK_COMPLE_ASSIGN},
  {"<<=", TK_LSHIFT_ASSIGN},
  {">>=", TK_RSHIFT_ASSIGN},
  {"&=", TK_AND_ASSIGN},
  {"|=", TK_OR_ASSIGN},
  {"^=", TK_XOR_ASSIGN},
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
          case TK_NOTYPE: break;
          default: {
            if(nr_token > 31) {
              printf("array tokens is already full.\n");
              return false;
            }
            if(substr_len>32) {
              printf("substr is too long, over 32 byte.\n");
              return false;
            }

            tokens[nr_token].type = rules[i].token_type;
            strncpy(tokens[nr_token].str, substr_start, substr_len);

            nr_token++;
          };
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

static uint32_t eval(Token *tokens, uint8_t s, uint8_t e);
static bool check_parentheses(Token *tokens, uint8_t s, uint8_t e);
static int get_op_pos(Token *tokens, uint8_t s, uint8_t e);
static int get_op_priority(int token_type);

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  // TODO();
  *success = true;
  int res= eval(tokens, 0, nr_token-1);
  nr_token = 0;

  return res;
}

static uint32_t eval(Token *tokens, uint8_t s, uint8_t e) {
  if(s > e) {
    panic("bad expression\n");
  }
  else if(s == e) {
    uint32_t res=0;
    switch(tokens[s].type) {
      case TK_DECNUM: { sscanf(tokens[s].str, "%d", &res); break; }
      case TK_HEXNUM: { sscanf(tokens[s].str, "0x%x", &res); break; }
      case TK_BINNUM: { res = strtoul(tokens[s].str+2, NULL, 2); break; }
      case TK_REG: {
        // reg save mem address 
        break; 
      }
      default: break;
    }
    return res;
  }
  else if( check_parentheses(tokens, s, e) ) {
    return eval(tokens, s+1, e-1);
  }
  else {
    int op = get_op_pos(tokens, s, e );
    uint32_t val1 = eval(tokens, s, op-1);
    uint32_t val2 = eval(tokens, op+1, e);

    switch(tokens[op].type) {
      case TK_PLUS: return val1 + val2;
      case TK_SUB: return val1 - val2;
      case TK_MULTIP: return val1 * val2;
      case TK_DIV: {
        Assert(val2 != 0, "error: divisor could not be zero.\n");
      }
      case TK_EQ: return val1 == val2;
      default: {
        // printf("operater not support.\n");
        Assert(0, "operater not support.\n");
        return 0;
      }
    }
  }

} 

static bool check_parentheses(Token *tokens, uint8_t s, uint8_t e) {
  int top = 0;
  for(int i=s; i<=e; i++) {
    if(tokens[i].str[0] == '(') {
      top++;
    }
    else if(tokens[i].str[0] == ')') {
      top--;
      if(top < 0) return false;
    }
  }
  if(tokens[s].str[0] == '(' && \
    tokens[e].str[0] == ')' && \
    top == 0 ) 
  {
    return true;
  }
  return false;
}

static int get_op_pos(Token *tokens, uint8_t s, uint8_t e) {
  int lowest_priority = -1;
  int index = -1;
  int paren_cnt = 0;
  int i = 0;
  for(i=s; i<e; i++) {
    int token_type = tokens[i].type;
    int priority = get_op_priority(token_type);
    if(token_type == TK_LBRACK) paren_cnt++;
    else if(token_type == TK_RBRACK) paren_cnt--;
    else if(paren_cnt ==0 && \
      priority > lowest_priority)
    {
      lowest_priority = priority;
      index = i;
    }
  }

  Assert(index>=0, "index not update index = %d.\n", index);
  return index;
}

// the smaller value, the bigger priority
static int get_op_priority(int token_type) {
  switch (token_type) {
    case TK_LMBRACK: return 1;        // [
    case TK_LBRACK: return 1;         // (
    case TK_DOT: return 1;         // .
    case TK_ARROW: return 1;         // ->
    case TK_NOT: return 2;
    case TK_DPLUS: return 2;
    case TK_DSUB: return 2;
    case TK_MULTIP: return 3;
    case TK_DIV: return 3;
    case TK_COMPLE: return 3;
    case TK_PLUS: return 4;
    case TK_SUB: return 4;
    case TK_LSHIFT: return 5;
    case TK_RSHIFT: return 5;
    case TK_BT: return 6;
    case TK_BEQ: return 6;
    case TK_LT: return 6;
    case TK_LEQ: return 6;
    case TK_EQ: return 7;
    case TK_NEQ: return 7;

    case TK_AND: return 8;
    case TK_XOR: return 9;
    case TK_OR: return 10;
    case TK_LAND: return 11;
    case TK_LOR: return 12;
    case TK_CONDI: return 13;

    case TK_ASSIGN: return 14;
    case TK_PLUS_ASSIGN: return 14;
    case TK_SUB_ASSIGN: return 14;
    case TK_MULTIP_ASSIGN: return 14;
    case TK_DIV_ASSIGN: return 14;
    case TK_COMPLE_ASSIGN: return 14;
    case TK_LSHIFT_ASSIGN: return 14;
    case TK_RSHIFT_ASSIGN: return 14;
    case TK_AND_ASSIGN: return 14;
    case TK_OR_ASSIGN: return 14;
    case TK_XOR_ASSIGN: return 14;

    case TK_COMMA: return 15;
    default: return -1;
  }
}