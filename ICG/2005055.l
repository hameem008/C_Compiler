%option noyywrap

%{
    #include <bits/stdc++.h>
    #include "2005055.h"
    #include "y.tab.h"
    using namespace std;

    extern ofstream logout;
    extern SymbolTable *st;
    extern vector<SymbolInfo *> param_list;

    int errorCount = 0, lineCount = 1;

    void printlogout(string ltype)
    {
        logout << "Line# " << lineCount <<": Token <"<< ltype <<"> Lexeme "<< yytext <<" found\n"; 
    }
%}

WHITESPACE  [ \t\f\r\v]
LETTER  [a-zA-Z_]
LETTERANDDIGIT  [A-Za-z0-9_]
DIGIT   [0-9]
NEWLINE \n
KEYWORDS    if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue|println
ADDOP "+"|"-"
MULOP "*"|"/"|"%"
INCOP "++"
DECOP "--"
RELOP "<"|"<="|">"|">="|"=="|"!="
ASSIGNOP "="
LOGICOP "&&"|"||"
NOT "!"
LPAREN "("
RPAREN ")"
LCURL "{"
RCURL "}"
LSQUARE "["
RSQUARE "]"
COMMA ","
SEMICOLON ";"


%%
{NEWLINE}   {
    lineCount++;
} 

{KEYWORDS}  {
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    string str = yytext;
    if (str == "if"){
        yylval.node->setGrammar("IF : if");
        yylval.node->setSi(new SymbolInfo("if","IF"));
        printlogout("IF");
        return IF;
    }
    else if (str == "else"){
        yylval.node->setGrammar("ELSE : else");
        yylval.node->setSi(new SymbolInfo("else","ELSE"));
        printlogout("ELSE");
        return ELSE;
    }
    else if (str == "for"){
        yylval.node->setGrammar("FOR : for");
        yylval.node->setSi(new SymbolInfo("for","FOR"));
        printlogout("FOR");
        return FOR;
    }
    else if (str == "while"){
        yylval.node->setGrammar("WHILE : while");
        yylval.node->setSi(new SymbolInfo("while","WHILE"));
        printlogout("WHILE");
        return WHILE;
    }
    else if (str == "int"){
        yylval.node->setGrammar("INT : int");
        yylval.node->setSi(new SymbolInfo("int","INT"));
        printlogout("INT");
        return INT;
    }
    else if (str == "float"){
        yylval.node->setGrammar("FLOAT : float");
        yylval.node->setSi(new SymbolInfo("float","FLOAT"));
        printlogout("FLOAT");
        return FLOAT;
    }
    else if( str == "void"){
        yylval.node->setGrammar("VOID : void");
        yylval.node->setSi(new SymbolInfo("void","VOID"));
        printlogout("VOID");
        return VOID;
    }
    else if( str == "return"){
        yylval.node->setGrammar("RETURN : return");
        yylval.node->setSi(new SymbolInfo("return","RETURN"));
        printlogout("RETURN");
        return RETURN;
    }
    else if( str == "println"){
        yylval.node->setGrammar("PRINTLN : println");
        yylval.node->setSi(new SymbolInfo("PRINTLN","PRINTLN"));
        printlogout("PRINTLN");
        return PRINTLN;
    }
}

{ADDOP} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("ADDOP : " + str);
    yylval.node->setSi(new SymbolInfo(str,"ADDOP"));
    printlogout("ADDOP");
    return ADDOP;
}

{MULOP} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("MULOP : " + str);
    yylval.node->setSi(new SymbolInfo(str,"MULOP"));
    printlogout("MULOP");
    return MULOP;
}

{INCOP} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("INCOP : " + str);
    yylval.node->setSi(new SymbolInfo(str,"INCOP"));
    printlogout("INCOP");
    return INCOP;
}

{DECOP} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("DECOP : " + str);
    yylval.node->setSi(new SymbolInfo(str,"DECOP"));
    printlogout("DECOP");
    return DECOP;
}

{RELOP} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("RELOP : " + str);
    yylval.node->setSi(new SymbolInfo(str,"RELOP"));
    printlogout("RELOP");
    return RELOP;
}

{LOGICOP}   {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("LOGICOP : " + str);
    yylval.node->setSi(new SymbolInfo(str,"LOGICOP"));
    printlogout("LOGICOP");
    return LOGICOP;
}

{ASSIGNOP}  {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("ASSIGNOP : " + str);
    yylval.node->setSi(new SymbolInfo(str,"ASSIGNOP"));
    printlogout("ASSIGNOP");
    return ASSIGNOP;
}

{NOT}   {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("NOT : " + str);
    yylval.node->setSi(new SymbolInfo(str,"NOT"));
    printlogout("NOT");
    return NOT;
}

{LPAREN}    {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("LPAREN : " + str);
    yylval.node->setSi(new SymbolInfo(str,"LPAREN"));
    printlogout("LPAREN");
    return LPAREN;
}

{RPAREN}    {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("RPAREN : " + str);
    yylval.node->setSi(new SymbolInfo(str,"RPAREN"));
    printlogout("RPAREN");
    return RPAREN;
}

{LCURL} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("LCURL : " + str);
    yylval.node->setSi(new SymbolInfo(str,"LCURL"));
    printlogout("LCURL");
    return LCURL;
}

{RCURL} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("RCURL : " + str);
    yylval.node->setSi(new SymbolInfo(str,"RCURL"));
    printlogout("RCURL");
    return RCURL;
}

{LSQUARE}   {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("LSQUARE : " + str);
    yylval.node->setSi(new SymbolInfo(str,"LSQUARE"));
    printlogout("LSQUARE");
    return LSQUARE;
}

{RSQUARE}   {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("RSQUARE : " + str);
    yylval.node->setSi(new SymbolInfo(str,"RSQUARE"));
    printlogout("RSQUARE");
    return RSQUARE;
}

{COMMA} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("COMMA : " + str);
    yylval.node->setSi(new SymbolInfo(str,"COMMA"));
    printlogout("COMMA");
    return COMMA;
}

{SEMICOLON} {
    string str = yytext;
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setGrammar("SEMICOLON : " + str);
    yylval.node->setSi(new SymbolInfo(str,"SEMICOLON"));
    printlogout("SEMICOLON");
    return SEMICOLON;
}

{DIGIT}+    {
    string str = yytext;
    SymbolInfo *si = new SymbolInfo(str,"CONST_INT");
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setSi(si);
    yylval.node->setDataType("INT");
    yylval.node->setGrammar("CONST_INT : " + str);
    printlogout("CONST_INT");
    return CONST_INT;
}

{DIGIT}*(\.?{DIGIT}+)(E[+-]?{DIGIT}+)?  {
    string str = yytext;
    SymbolInfo *si = new SymbolInfo(str,"CONST_FLOAT");
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setSi(si);
    yylval.node->setDataType("FLOAT");
    yylval.node->setGrammar("CONST_FLOAT : " + str);
    printlogout("CONST_FLOAT");
    return CONST_FLOAT;
}

{DIGIT}*(\.)({DIGIT}|(\.))+(E[+-]?{DIGIT}+)? {
    errorCount++;
}

{DIGIT}*(\.?{DIGIT}+)(E[+-]?({DIGIT}|(\.))+)    {
    errorCount++;
}

{LETTER}+({LETTERANDDIGIT}*)    {
    string str = yytext;
    SymbolInfo *si = new SymbolInfo(str,"ID");
    yylval.node = new tree();
    yylval.node->setStartLine(lineCount);
    yylval.node->setEndLine(lineCount);
    yylval.node->setSi(si);
    yylval.node->setGrammar("ID : " + str);
    printlogout("ID");
    return ID; 
}

{DIGIT}+{LETTER}+{LETTERANDDIGIT}*  {
    errorCount++;
}

<<EOF>> {
    return 0;
}

{WHITESPACE}   {
}

.   {
    errorCount++;
}

%%