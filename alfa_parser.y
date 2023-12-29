%{
    #include "expressions.h"
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <ctype.h>
    
    extern FILE *yyin;

    void yyerror(const char *s);
    int yylex(void);
    expression *final_expression = NULL;

    void print_final_expression();
%}

%token VARIABLE SIN COS EXP LN PLUS MINUS MULT DIV POW EOL
%token <num> NUMBER

%union {
    expression *expr;
    double num;
}

%type <expr> expression term factor exponent
%left PLUS MINUS
%left MULT DIV
%right POW

%%

input
    : /* пусто */
    | input line
    ;

line
    : expression EOL { final_expression = $1; print_final_expression(); }
    ;

expression
    : term
    | expression PLUS term { $$ = differentiate_sum($1, $3, 0); }
    | expression MINUS term { $$ = differentiate_sum($1, $3, 1); }
    ;

term
    : factor
    | term MULT factor { $$ = differentiate_product($1, $3); }
    | term DIV factor { $$ = differentiate_quotient($1, $3); }
    ;

factor
    : NUMBER { 
        char num_str[64];
        snprintf(num_str, sizeof(num_str), "%g", $1);  // Используем $1 как double
        $$ = new_expression(num_str, "0");
    }
    | VARIABLE { $$ = new_expression("x", "1"); }
    | SIN '(' expression ')' { $$ = apply_chain_rule(new_expression("sin", "cos"), $3); }
    | COS '(' expression ')' { $$ = apply_chain_rule(new_expression("cos", "-sin"), $3); }
    | EXP '(' expression ')' { $$ = apply_chain_rule(new_expression("exp", "exp"), $3); }
    | LN '(' expression ')' { $$ = apply_chain_rule(new_expression("ln", "1/x"), $3); }
    | factor POW exponent { $$ = differentiate_power($1, $3); }
    | '(' expression ')' { $$ = copy_expression($2); }
    ;

exponent
    : expression
    ;

%%

expression *copy_expression(const expression *expr) {
    return new_expression(expr->function, expr->derivative);
}

expression *new_expression(const char *func, const char *deriv) {
    expression *expr = (expression *)malloc(sizeof(expression));

    if (isdigit(func[0]) || (func[0] == '-' && isdigit(func[1]))) {
        // Для чисел используем их строковое представление
        expr->function = strdup(func);
    } else {
        // Для всего остального используем как есть
        expr->function = strdup(func);
    }

    expr->derivative = strdup(deriv);
    return expr;
}

expression *differentiate_sum(const expression *f, const expression *g, int is_minus) {
    char *op = is_minus ? "-" : "+";
    char *function = (char *)malloc(strlen(f->function) + strlen(g->function) + 4);
    sprintf(function, "(%s %s %s)", f->function, op, g->function);

    char *derivative;
    if (strcmp(f->derivative, "0") == 0) {
        derivative = strdup(g->derivative);
    } else if (strcmp(g->derivative, "0") == 0) {
        derivative = strdup(f->derivative);
    } else {
        derivative = (char *)malloc(strlen(f->derivative) + strlen(g->derivative) + 4);
        sprintf(derivative, "(%s %s %s)", f->derivative, op, g->derivative);
    }

    return new_expression(function, derivative);
}

expression *differentiate_product(const expression *f, const expression *g) {
    char *function = (char *)malloc(strlen(f->function) + strlen(g->function) + 5);
    sprintf(function, "(%s * %s)", f->function, g->function);

    char *derivative = (char *)malloc(strlen(f->function) + strlen(f->derivative) + strlen(g->function) + strlen(g->derivative) + 20);
    sprintf(derivative, "((%s * %s) + (%s * %s))", f->derivative, g->function, f->function, g->derivative);

    return new_expression(function, derivative);
}

expression *differentiate_quotient(const expression *f, const expression *g) {
    char *function = (char *)malloc(strlen(f->function) + strlen(g->function) + 5);
    sprintf(function, "(%s / %s)", f->function, g->function);

    char *derivative;
    if (strcmp(f->derivative, "0") == 0) {
        derivative = strdup("0");
    } else if (strcmp(g->derivative, "0") == 0) {
        derivative = strdup(f->derivative);
    } else {
        derivative = (char *)malloc(strlen(f->function) + strlen(f->derivative) + strlen(g->function) + strlen(g->derivative) + 32);
        sprintf(derivative, "((%s * %s) - (%s * %s)) / pow(%s, 2)", f->derivative, g->function, f->function, g->derivative, g->function);
    }

    return new_expression(function, derivative);
}

expression *differentiate_power(const expression *base, const expression *exponent) {
    char *function = (char *)malloc(strlen(base->function) + strlen(exponent->function) + 10);
    sprintf(function, "pow(%s, %s)", base->function, exponent->function);

    char *derivative;
    if (strcmp(base->derivative, "0") == 0) {
        derivative = strdup("0");
    } else {
        derivative = (char *)malloc(strlen(base->function) + strlen(base->derivative) + strlen(exponent->function) + strlen(exponent->derivative) + 64);
        sprintf(derivative, "pow(%s, %s - 1) * (%s * %s + ln(%s) * %s * %s)", base->function, exponent->function, exponent->function, base->derivative, base->function, exponent->derivative, base->function);
    }

    return new_expression(function, derivative);
}

expression *apply_chain_rule(const expression *outer, const expression *inner) {
    char *function = (char *)malloc(strlen(outer->function) + strlen(inner->function) + 3);
    sprintf(function, "%s(%s)", outer->function, inner->function);

    char *derivative;
    if (strcmp(outer->function, "ln") == 0) {
        // Для ln(x), производная будет 1/внутреннее_выражение
        derivative = (char *)malloc(strlen(inner->function) + 6);
        sprintf(derivative, "1/(%s)", inner->function);
    } else {
        // Для других функций, используем обычное правило произведения
        derivative = (char *)malloc(strlen(outer->derivative) + strlen(inner->function) + strlen(inner->derivative) + 10);
        sprintf(derivative, "(%s(%s) * %s)", outer->derivative, inner->function, inner->derivative);
    }

    return new_expression(function, derivative);
}


void delete_expression(expression *expr) {
    free(expr->function);
    free(expr->derivative);
    free(expr);
}

void print_final_expression() {
    if (final_expression) {
        printf("Function: %s, Derivative: %s\n", final_expression->function, final_expression->derivative);
        delete_expression(final_expression);
        final_expression = NULL;
    }
}

void yyerror(const char *s) {
        fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        // Если аргумент командной строки предоставлен, открываем файл
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror(argv[1]); // Выводим ошибку, если файл не может быть открыт
            return 1;
        }
        yyin = file; // Устанавливаем yyin на файл для считывания
    } else {
        yyin = stdin; // В противном случае считываем из стандартного ввода
    }

    yyparse(); // Вызываем парсер

    if (argc > 1) {
        fclose(yyin); // Закрываем файл, если он был открыт
    }

    return 0;
}