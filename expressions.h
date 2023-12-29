#ifndef EXPRESSIONS_H
#define EXPRESSIONS_H

#include <string.h>

typedef struct expression {
    char *function;
    char *derivative;
} expression;

expression *new_expression(const char *func, const char *deriv);
expression *copy_expression(const expression *expr);
void delete_expression(expression *expr);
expression *differentiate_sum(const expression *f, const expression *g, int is_minus);
expression *differentiate_product(const expression *f, const expression *g);
expression *differentiate_quotient(const expression *f, const expression *g);
expression *differentiate_power(const expression *base, const expression *exponent);
expression *apply_chain_rule(const expression *outer, const expression *inner);

#endif // EXPRESSIONS_H
