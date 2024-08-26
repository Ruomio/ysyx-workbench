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
#include "memory/paddr.h"

#define TOKENS_SIZE 1024
#define TOKEN_STR_SIZE 32

enum {
  TK_NOTYPE = 256,

  /* TODO: Add more token types */
  TK_PLUS,
  TK_SUB,
  TK_MINUS,
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
  {"[a-zA-Z0-9]+->[a-zA-Z0-9]+", TK_ARROW},
  {"--", TK_DSUB},
  {"-", TK_SUB},
  // {"\\*[a-zA-Z]+[0-9]*[^->*]", TK_DEREFRENCE},
  {"&[a-zA-Z]+[0-9]*", TK_ADDRESSOF},
  {"[a-zA-Z0-9]+\\.[a-zA-Z0-9]+", TK_DOT},
  {"\\*",TK_MULTIP},
  {"/", TK_DIV},
  {"%", TK_COMPLE},
  {"\\(", TK_LBRACK},
  {"\\)", TK_RBRACK},
  {"\\[", TK_LMBRACK},
  {"\\]", TK_LMBRACK},
  {"\\$(\\$0|ra|sp|gp|tp|t[0-6]|s[0-9]{1,2}|a[0-7]|pc)", TK_REG},
  // {"\\$", TK_REG},
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
  char str[TOKEN_STR_SIZE];
} Token;

static Token tokens[TOKENS_SIZE] __attribute__((used)) = {};
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

        // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
        //     i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
          case TK_NOTYPE: break;
          default: {
            if(nr_token > TOKENS_SIZE-1) {
              printf("array tokens is already full.\n");
              return false;
            }
            if(substr_len > TOKEN_STR_SIZE-1) {
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

static uint32_t eval(Token *tokens, int s, int e);
static bool check_parentheses(Token *tokens, int s, int e);
static int get_op_pos(Token *tokens, int s, int e);
static int get_op_priority(Token *tokens, int index);
static void update_op_type();

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  // TODO();
  update_op_type();
  *success = true;
  uint32_t res= eval(tokens, 0, nr_token-1);

  memset(tokens, 0, sizeof(tokens));
  nr_token = 0;

  return res;
}

static uint32_t eval(Token *tokens, int s, int e) {
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
        bool flag = false;
        word_t ret = isa_reg_str2val(tokens[s].str+1, &flag);
        if(flag) res = ret;
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
    uint32_t val1=0, val2=0, ret=0;
    int op = get_op_pos(tokens, s, e );

    // special op code
    if(s == e-1) {
      switch(tokens[s].type) {
        case TK_MINUS: return -eval(tokens, s+1, e); break;
        case TK_DEREFRENCE: return paddr_read(eval(tokens, s+1, e), 1); break;
        case TK_REG: {

          break;
        }
        default: break;
      }
    }
    else {
      val1 = eval(tokens, s, op-1);
      val2 = eval(tokens, op+1, e);
    }

    switch(tokens[op].type) {
      case TK_PLUS: ret = val1 + val2; break;
      case TK_SUB: ret = val1 - val2; break;
      case TK_MULTIP: ret = val1 * val2; break;
      case TK_DIV: {
        if(val2 == 0) {
          // Assert(val2 != 0, "error: divisor could not be zero. divisor position is %d\n", op);
          printf("\033[0;31merror: divisor could not be zero. divisor position is %d\033[0m\n", op);
          ret = 0;
          break;
        }
        ret = val1 / val2;
        break;
      }
      case TK_EQ: ret = val1 == val2; break;
      case TK_NEQ: ret = val1 != val2; break;
      case TK_LSHIFT: ret = val1 << val2; break;
      case TK_RSHIFT: ret = val1 >> val2; break;
      case TK_BT: ret = val1 > val2; break;
      case TK_BEQ: ret = val1 >= val2; break;
      case TK_LT: ret = val1 < val2; break;
      case TK_LEQ: ret = val1 <= val2; break;
      case TK_AND: ret = val1 & val2;
      case TK_OR: ret = val1 | val2;
      case TK_XOR: ret = val1 ^ val2;
      case TK_LAND: ret = val1 && val2;
      case TK_LOR: ret = val1 || val2;
      default: {
        printf("\033[0;31moperater not support.\033[0m\n");
        // Assert(0, "operater not support.\n");
        ret = 0;
        break;
      }
    }
    return ret;
  }

} 

static bool check_parentheses(Token *tokens, int s, int e) {
  int top = 0;
  for(int i=s; i<=e; i++) {
    if(tokens[i].type == TK_LBRACK) {
      top++;
    }
    else if(tokens[i].type == TK_RBRACK) {
      top--;
      if(top < 0) return false;
      if(top == 0 && i != e) return false;
      else if(top == 0 && i == e) return true;
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

static int get_op_pos(Token *tokens, int s, int e) {
  int lowest_priority = -1;
  int index = -1;
  int paren_cnt = 0;
  int i = 0;
  for(i=s; i<e; i++) {
    int token_type = tokens[i].type;
    int priority = get_op_priority(tokens, i);
    if(token_type == TK_LBRACK) paren_cnt++;
    else if(token_type == TK_RBRACK) paren_cnt--;
    else if(paren_cnt ==0 && \
      priority >= lowest_priority)
    {
      lowest_priority = priority;
      index = i;
    }
  }

  Assert(index>=0, "index not update index = %d.\n", index);
  return index;
}

// the smaller value, the bigger priority
static int get_op_priority(Token *tokens, int index) {
  switch (tokens[index].type) {
    case TK_LMBRACK: return 1;        // [
    case TK_LBRACK: return 1;         // (
    case TK_DOT: return 1;         // .
    case TK_ARROW: return 1;         // ->
    case TK_REG: return 2;
    case TK_MINUS: return 2;
    case TK_DEREFRENCE: return 2;
    case TK_ADDRESSOF: return 2;
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


void test_expr() {
  FILE *fp = fopen("/home/papillon/Documents/All_codes/ysyx-workbench/nemu/tools/gen-expr/build/input", "r");
  if(!fp) {
    Log("can not open the input file.\n");
    return;
  }
  char str[1024] = {};
  int line = 1;
  bool success = false;
  while(fgets(str, 1024, fp) != NULL) {
    // remove '\n'
    str[strlen(str)-1] = '\0';
    if(strcmp(str, "") == 0) {
      printf("\033[0;32mtest skip: %d row is null line\033[0m\n", line);
      line++;
      continue;
    }
    char *res = strtok(str, " ");
    char *expr_str = str + strlen(res) + 1;

    word_t value = expr(expr_str, &success);

    if(value != atoi(res)) {
      printf("\033[0;31mtest error at line %d: It should be %lu, but be %u.\033[0m\n", line, strtoul(res, NULL, 10), value);
    }
    else {
      printf("\033[0;32mtest success at line %d.\033[0m\n", line);
    }

    line++;
  }

  fclose(fp);
}
static bool is_certain_type(int type) {
  bool ret = false;
  switch( type ) {
    case TK_PLUS: ret = true; break;
    case TK_SUB: ret = true; break;
    case TK_MULTIP: ret = true; break;
    case TK_DIV: ret = true; break;
    case TK_COMPLE: ret = true; break;
    case TK_LSHIFT: ret = true; break;
    case TK_RSHIFT: ret = true; break;
    case TK_BT: ret = true; break;
    case TK_BEQ: ret = true; break;
    case TK_LT: ret = true; break;
    case TK_LEQ: ret = true; break;
    case TK_EQ: ret = true; break;
    case TK_NEQ: ret = true; break;
    case TK_AND: ret = true; break;
    case TK_XOR: ret = true; break;
    case TK_OR: ret = true; break;
    case TK_LOR: ret = true; break;
    case TK_LAND: ret = true; break;
    
    default:
      ret = false;
  }
  return ret;
}

static void update_op_type() {
  for(int i=0; i < nr_token; i++) {
    if(i ==0 || is_certain_type(tokens[i-1].type)) {
      switch(tokens[i].type) {
        case TK_MULTIP: tokens[i].type = TK_DEREFRENCE; break;
        case TK_SUB: tokens[i].type = TK_MINUS; break;
        case TK_AND: tokens[i].type = TK_ADDRESSOF; break;
        default: break;
      }
    }
  }
}