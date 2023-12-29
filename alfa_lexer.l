%{
    #include "expressions.h"
    #include "alfa_parser.tab.h"  // Подключаем заголовочный файл Bison

    void yyerror(const char *s);
%}

%%

[0-9]+(\.[0-9]+)?   {
    yylval.num = atof(yytext);  // Заполняем yylval.num
    return NUMBER;
}



"x"                 { return VARIABLE; }
"sin"               { return SIN; }
"cos"               { return COS; }
"exp"               { return EXP; }
"ln"                { return LN; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return MULT; }
"/"                 { return DIV; }
"^"                 { return POW; }
"("                 { return '('; }
")"                 { return ')'; }
"\n"                { return EOL; }  // Обработка символа конца строки
[ \t]+              { /* Игнорируем пробелы и табуляции */ }
.                   { printf("Неизвестный символ: %s\n", yytext); return yytext[0]; }

%%

int yywrap() {
    return 1;
}
