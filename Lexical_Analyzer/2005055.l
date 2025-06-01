%option noyywrap

%x STRING
%x SCOMMENT 
%x MCOMMENT
%x CHARECTER

%{
    #include <iostream>
    #include <fstream>
    #include "2005055.h"
    using namespace std;
    #define space "\t";

    FILE *fout;
    ofstream tokenout;

    string strlogtext, strtokentext, strtext;
    bool isMultLineString, indVal = false;
    int strStartingLine, comStartingLine;
    int errorCount = 0, warningCount = 0, expTabCount = 0;

    string comtext, comlogtext;
    string chartext;
    SymbolTable *st = new SymbolTable(10);

    void indFunc()
    {
        if(indVal){
            return;
        }
        if(expTabCount != 0){
            warningCount++;
            cout << "Line# " << yylineno << ": warning, " << expTabCount << " of tabs needed but got " << 0 << " tabs.\n" ;
        }
        indVal = true;
    }
    string toUpper(char* text)
    {
        string str = text;
        for(int i = 0;i < str.size(); i++)
        {
            str[i] -= ('a' - 'A');
        }
        return str;
    }
    char getChar(string str)
    {
        char ret;
        if(str == "\'\\n\'")    {
            ret = '\n';
        }
        else if(str == "\'\\t\'")   {
            ret = '\t';
        } 
        else if(str == "\'\\\\\'")  {
            ret = '\\';
        }
        else if(str == "\'\\'\'")   {
            ret = '\'';
        }
        else if(str == "\'\\a\'")   {
            ret = '\a';
        }
        else if(str == "\'\\f\'")   {
            ret = '\f';
        }
        else if(str == "\'\\r\'")   {
            ret = '\r';
        }
        else if(str == "\'\\b\'")   {
            ret = '\b';
        }
        else if(str == "\'\\v\'")   {
            ret = '\v';
        }
        else if(str == "\'\\0\'")   {
            ret = '\0';
        }
        else if(str == "\'\\\"\'")  {
            ret = '\"';
        }
        return ret;
    }
    
%}

WHITESPACE  [ \t\f\r\v]
LETTER  [a-zA-Z_]
LETTERANDDIGIT  [A-Za-z0-9_]
DIGIT   [0-9]
NEWLINE \n
KEYWORDS    if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue
CHARECTERLITERALS   n|t|\\|\'|a|f|r|b|v|0|\"
SINGLEQUOTATION [\']
BACKSLASH [\\]
ADDOP "+"|"-"
MULOP "*"|"/"|"%"
INCOP "++"|"--"
RELOP "<"|"<="|">"|">="|"=="|"!="
ASSIGNOP "="
LOGICOP "&&"|"||"
BITOP "&"|"|"|"^"|"<<"|">>"
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
    yylineno++;
    indVal = false;
} 

{KEYWORDS}  {
    indFunc();
    tokenout << "<" << toUpper(yytext) << ", "<< yytext << ">\n";
    cout << "Line# "<< yylineno <<": Token <"<< toUpper(yytext) <<"> Lexeme "<< yytext <<" found\n";
}

{ADDOP} {
    indFunc();
    tokenout <<"<ADDOP, " << yytext <<">\n";
    cout << "Line# " << yylineno <<": Token <ADDOP> Lexeme "<< yytext <<" found\n";
}

{MULOP} {
    indFunc();
    tokenout << "<MULOP, " << yytext <<">\n";
    cout << "Line# " << yylineno <<": Token <MULOP> Lexeme "<< yytext <<" found\n";
}

{INCOP} {
    indFunc();
    tokenout << "<INCOP, " << yytext <<">\n";
    cout << "Line# " << yylineno <<": Token <INCOP> Lexeme "<< yytext <<" found\n";
}

{RELOP} {
    indFunc();
    tokenout << "<RELOP, " << yytext <<">\n";
    cout << "Line# " << yylineno <<": Token <RELOP> Lexeme "<< yytext <<" found\n";
}

{LOGICOP}   {
    indFunc();
    tokenout << "<LOGICOP, " << yytext <<">\n";
    cout << "Line# " << yylineno <<": Token <LOGICOP> Lexeme "<< yytext <<" found\n";
}

{ASSIGNOP}  {
    indFunc();
    tokenout << "<ASSIGNOP, " << yytext <<">\n";
    cout << "Line# " << yylineno <<": Token <ASSIGNOP> Lexeme "<< yytext <<" found\n";
}

{BITOP} {
    indFunc();
    tokenout << "<BITOP, " <<yytext <<">\n";
    cout << "Line# " << yylineno <<": Token <BITOP> Lexeme "<< yytext <<" found\n";
}

{NOT}   {
    indFunc();
    tokenout << "<NOT, " << yytext <<">\n";
    cout << "Line# " << yylineno <<": Token <NOT> Lexeme "<< yytext <<" found\n";
}

{LPAREN}    {
    indFunc();
    tokenout << "<LPAREN, "<<yytext<<">\n";
    cout << "Line# " << yylineno <<": Token <LPAREN> Lexeme "<< yytext <<" found\n";
}

{RPAREN}    {
    indFunc();
    tokenout << "<RPAREN, "<<yytext<<">\n";
    cout << "Line# " << yylineno <<": Token <RPAREN> Lexeme "<< yytext <<" found\n";
}

{LCURL} {
    indFunc();
    tokenout << "<LCURL, "<<yytext<<">\n";
    cout << "Line# " << yylineno <<": Token <LCURL> Lexeme "<< yytext <<" found\n";
    st->EnterScope();
    expTabCount++;
}

{RCURL} {
    if(expTabCount > 0)
        expTabCount--;
    indFunc();
    tokenout << "<RCURL, "<<yytext<<">\n";
    cout << "Line# " << yylineno <<": Token <RCURL> Lexeme "<< yytext <<" found\n";
    st->ExitScope();
}

{LSQUARE}   {
    indFunc();
    tokenout << "<LSQUARE, "<<yytext<<">\n";
    cout << "Line# " << yylineno <<": Token <LSQUARE> Lexeme "<< yytext <<" found\n";
}

{RSQUARE}   {
    indFunc();
    tokenout << "<RSQUARE, "<<yytext<<">\n";
    cout << "Line# " << yylineno <<": Token <RSQUARE> Lexeme "<< yytext <<" found\n";
}

{COMMA} {
    indFunc();
    tokenout << "<COMMA, "<<yytext<<">\n";
    cout << "Line# " << yylineno <<": Token <COMMA> Lexeme "<< yytext <<" found\n";
}

{SEMICOLON} {
    indFunc();
    tokenout<<"<SEMICOLON, "<<yytext<<">\n";
    cout << "Line# " << yylineno <<": Token <SEMICOLON> Lexeme "<< yytext <<" found\n";
}

{DIGIT}+    {
    indFunc();
    tokenout << "<CONST_INT, "<< yytext << ">\n";
    cout << "Line# " << yylineno <<": Token <CONST_INT> Lexeme "<< yytext <<" found\n";
}

{DIGIT}*(\.?{DIGIT}+)(E[+-]?{DIGIT}+)?  {
    indFunc();
    tokenout << "<CONST_FLOAT, " << yytext << ">\n";
    cout << "Line# " << yylineno <<": Token <CONST_FLOAT> Lexeme "<< yytext <<" found\n";
}

{DIGIT}*(\.)({DIGIT}|(\.))+(E[+-]?{DIGIT}+)? {
    indFunc();
    cout << "Error at line# " << yylineno <<": TOO_MANY_DECIMAL_POINTS " << yytext << "\n";
    errorCount++;
}

{DIGIT}*(\.?{DIGIT}+)(E[+-]?({DIGIT}|(\.))+)    {
    indFunc();
    cout << "Error at line# " << yylineno << ": ILLFORMED_NUMBER " << yytext << "\n";
    errorCount++;
}

{SINGLEQUOTATION}{BACKSLASH}{CHARECTERLITERALS}{SINGLEQUOTATION}    {
    indFunc();
    string str = yytext;
    tokenout <<"<CONST_CHAR, " << getChar(str) << ">\n";
    cout << "Line# " << yylineno <<": Token <CONST_CHAR> Lexeme "<< getChar(str) <<" found\n";
}

{SINGLEQUOTATION}{SINGLEQUOTATION}  {
    indFunc();
    cout << "Error at line# " << yylineno << ": EMPTY_CONST_CHAR " << yytext << "\n";
    errorCount++;
}

{SINGLEQUOTATION}{BACKSLASH}{SINGLEQUOTATION}  {
    indFunc();
    cout << "Error at line# " << yylineno << ": UNFINISHED_CONST_CHAR " << yytext << "\n";
    errorCount++;
}

{SINGLEQUOTATION}{BACKSLASH}(.){SINGLEQUOTATION}|'''    {
    indFunc();
    cout << "Error at line# " << yylineno << ": UNRECOGNIZED_CHAR " << yytext << "\n";
    errorCount++;
}

{SINGLEQUOTATION}(.){SINGLEQUOTATION}   {
    indFunc();
    string str = yytext;
    tokenout <<"<CONST_CHAR, " << str[1] << ">\n";
    cout << "Line# " << yylineno <<": Token <CONST_CHAR> Lexeme "<< str[1] <<" found\n";
}

{SINGLEQUOTATION}   {
    indFunc();
    chartext.clear();
    BEGIN (CHARECTER);
    string str = yytext;
    chartext += str;
}

<CHARECTER>[^\n\r\']  {
    string str = yytext;
    chartext += str;
}

<CHARECTER>[\r] {
    cout << "Error at line# " << yylineno << ": UNFINISHED_CONST_CHAR " << chartext <<"\n";
    errorCount++;
    BEGIN (INITIAL);
}

<CHARECTER>[\n] {
    yylineno++;
}

<CHARECTER>{SINGLEQUOTATION}    {
    string str = yytext;
    chartext += str;
    cout << "Error at line# " << yylineno << ": MULTICHAR_CONST_CHAR " << chartext <<"\n";
    errorCount++;
    BEGIN (INITIAL);
}

<CHARECTER><<EOF>> {
    cout << "Error at line# " << yylineno << ": UNFINISHED_CONST_CHAR " << chartext <<"\n";
    errorCount++;
    BEGIN (INITIAL);
}

"\""  {
    indFunc();
    strlogtext.clear();
    strtokentext.clear();
    strtext.clear();
    string str = yytext;
    strlogtext += str;
    strtext += str;
    strStartingLine = yylineno;
    isMultLineString = false;
    BEGIN (STRING);
}

<STRING>"\"" {
    string str = yytext;
    strlogtext += str;
    strtext += str;
    if(isMultLineString){
        tokenout << "<MULTI LINE STRING, " << strtokentext << ">\n";
        cout <<"Line# "<< strStartingLine <<": Token <MULTI LINE STRING> Lexeme " << strlogtext << " found\n";
    }
    else {
        tokenout << "<SINGLE LINE STRING, " << strtokentext << ">\n";
        cout <<"Line# "<< strStartingLine <<": Token <SINGLE LINE STRING> Lexeme " << strlogtext << " found\n";
    }
    BEGIN (INITIAL);
}

<STRING>"\\"  {
    string str = yytext;
    strtext += str;
    cout << "Error at line# " << yylineno <<": UNFINISHED_STRING " << strtext <<"\n";
    errorCount++;
    BEGIN (INITIAL);
}

<STRING>"\\\r"    {
    string str = yytext;
    strlogtext += str;
    strtext += str;
    isMultLineString = true;
}

<STRING>{BACKSLASH}{CHARECTERLITERALS} {
    string str = yytext;
    strlogtext += str;
    string str2;
    str2.push_back('\'');
    str2 += str;
    str2.push_back('\'');
    strtokentext.push_back(getChar(str2));
}

<STRING>[^\n\r]   {
    char *ch = yytext;
    string str = yytext;
    strtokentext.push_back(*ch);
    strlogtext += str;
    strtext += str;
}
<STRING>[\r]    {
    string str = yytext;
    strtext += str;
    cout << "Error at line# " << yylineno <<": UNFINISHED_STRING " << strtext <<"\n";
    errorCount++;
    BEGIN (INITIAL);
}

<STRING>[\n]    {
    yylineno++;
}

<STRING><<EOF>> {
    cout << "Error at line# " << yylineno <<": UNFINISHED_STRING " << strtext <<"\n";
    errorCount++;
    BEGIN (INITIAL);
}

"\/\/"  {
    indFunc();
    comtext.clear();
    string str = yytext;
    comtext += str;
    comStartingLine = yylineno;
    BEGIN(SCOMMENT);
}

<SCOMMENT>[^\n\r]    {
    string str = yytext;
    comtext += str;
}

<SCOMMENT>"\\\r" {
    string str = yytext;
    comtext += str;
} 

<SCOMMENT>[\r]  {
    cout << "Line# " << comStartingLine << ": Token <SINGLE LINE COMMENT> Lexeme " << comtext <<" found\n"; 
    BEGIN(INITIAL);
}

<SCOMMENT>[\n]   {
    yylineno++;
}

<SCOMMENT><<EOF>>   {
    string str = yytext;
    comtext += str;
    cout << "Line# " << comStartingLine << ": Token <SINGLE LINE COMMENT> Lexeme " << comtext <<" found\n"; 
    BEGIN (INITIAL);
}

"\/\*"  {
    indFunc();
    comtext.clear();
    comlogtext.clear();
    string str = yytext;
    comtext += str;
    comlogtext += str;
    comStartingLine = yylineno;
    BEGIN (MCOMMENT);
}

<MCOMMENT>[^\n\r]    {
    string str = yytext;
    comtext += str;
    comlogtext += str;
}

<MCOMMENT>[\r]  {
    string str = yytext;
    comtext += str;
    comlogtext += str;
}

<MCOMMENT>[\n]  {
    yylineno ++;
}

<MCOMMENT>"\*\/"  {
    string str = yytext;
    comtext += str;
    comlogtext += str;
    cout << "Line# " << comStartingLine <<": Token <MULTI LINE COMMENT> Lexeme "<< comlogtext <<" found\n";
    BEGIN (INITIAL);
}

<MCOMMENT><<EOF>>   {
    cout << "Error at line# " << yylineno <<": UNFINISHED_COMMENT " << comtext << "\n";
    errorCount++;
    BEGIN (INITIAL);
}

{LETTER}+({LETTERANDDIGIT}*)    {
    indFunc();
    tokenout <<"<ID, "<< yytext << ">\n";
    cout << "Line# " << yylineno << ": Token <ID> Lexeme " << yytext << " found\n";
    string str = yytext;
    bool res = st->Insert(str, "ID");
    if(res) {
        st->PrintAllScopeTable();
    }
    else {
        cout << space;
        cout << yytext << " already exists in the current ScopeTable\n";
    }
}

{DIGIT}+{LETTER}+{LETTERANDDIGIT}*  {
    indFunc();
    cout << "Error at line# " << yylineno << ": INVALID_ID_SUFFIX_NUM_PREFIX " << yytext << "\n";
    errorCount++;
}

<<EOF>> {
    st->PrintAllScopeTable();
    cout << "Total lines: " << yylineno << "\n";
    cout << "Total errors: " << errorCount << "\n";
    cout << "Total warnings: " << warningCount << "\n";
    return 0;
}

^[ \t]+ {
    int spaceCount = 0, tabCount = 0;
    string str = yytext;
    for(char x: str){
        if(x == '\t') tabCount++;
        else if (x == ' ') spaceCount++;
    }
    if(spaceCount != 0  ){
        cout << "Line# " << yylineno << ": Warning, tab requrired but got space.\n";
        warningCount++;
    }
    else if(tabCount != expTabCount){
        cout << "Line# " << yylineno << ": warning, " << expTabCount << " of tabs needed but got " << tabCount << " tabs.\n" ; 
        warningCount++;
    }
    indVal = true;
}

{WHITESPACE}   {
}

.   {
    cout << "Error at line# " << yylineno << ": UNRECOGNIZED_CHAR " << yytext << "\n";
    errorCount++;
}

%%

int main(int argc, char *argv[])    
{

    if( argc != 2)
    {
        cout << "Please provide input file name and try again\n";
		return 0;
    }

    FILE *fin = fopen(argv[1], "r");

    if(fin == NULL)
    {
        cout << "Cannot open specified file\n";
		return 0;
    } 

    tokenout.open("2005055_token.txt");
    fout = freopen("2005055_log.txt", "w", stdout);

    yyin = fin;
    yylineno = 1;
    yylex();
    fclose(yyin);
    tokenout.close();
    fclose(fout);
    return 0;
}