%{
#include <bits/stdc++.h>
#include "2005055.h"
using namespace std; 

SymbolTable *st = new SymbolTable(11);

extern int errorCount, lineCount;
extern FILE *yyin;

ofstream logout, parsetreeout, errorout, asmb;
vector<SymbolInfo *> declare_list, param_list;
vector<string> arg_list;
tree *root = nullptr;
bool globalValDone = false;
ScopeTable *currentScope = st->getCurrentScopeTable();
int currentOffset = 0;
int currentNegOffset = -2;
int level = 1;
int fend = 1;

void yyerror(const char *s){
    cout << "Not Ok "<< lineCount << endl;
}

void errfun(int line, string err)
{
        errorCount++;
        errorout << "Line# " << line << ": " << err << "\n";
}

bool funcmp(SymbolInfo *a, SymbolInfo *b)
{
        bool ret = true;
        if(a->getParamList().size() != b->getParamList().size())
        {
                ret = false;
        }
        else if(a->getExtraType() != b->getExtraType())
        {
                ret = false;
        }
        else 
        {
                vector<SymbolInfo*> va = a->getParamList(), vb = b->getParamList();
                for(int i=0;va.size();i++)
                {
                        if(va[i]->getType() != vb[i]->getType())
                        {
                                ret = false;
                        }
                }         
        }
        return ret;
}

// ICG

void assemblyGenerationForGlobalVariable()
{
        ScopeTable *gs = st->getCurrentScopeTable();
        int size = gs->getSize();
        SymbolInfo **array = gs->getArray();
        for(int i = 0; i< size; i++)
        {
                SymbolInfo *it = array[i];
                while(it != nullptr)
                {
                        if(it->getType() == "INT")
                        {
                                asmb << "\t" << it->getName() << " DW 1 DUP (0000H)\n";
                        }
                        else if(it->getType() == "ARRAY")
                        {
                                asmb << "\t" << it->getName() << " DW " << it->getArraySize() << " DUP (0000H)\n";
                        }
                        it = it->nextSymbol;
                }
        }       
}

string manVar(string var)
{
        ScopeTable *it = currentScope;
        SymbolInfo *ret = nullptr;
        while (it != nullptr)
        {
            ret = it->LookUp(var);
            if (ret != nullptr)
            {
                break;
            }
            it = it->getParentScope();
        }
        string retStr;
        if(ret->getType() == "INT")
        {
                if(ret->getOffset() == 0)
                {
                        retStr += ret->getName();
                }
                else 
                {
                        retStr = "[BP-" + to_string(ret->getOffset()) + "]";
                }
        }
        else if(ret->getType() == "ARRAY")
        {
                if(ret->getOffset() == 0)
                {
                        retStr = ret->getName() + "[SI]";
                }
                else 
                {
                        retStr = "[BP-" + to_string(ret->getOffset()) + "-SI]";
                }       
        }
        return retStr;
}

void dfs(tree *node){
        vector<tree*> childs = node->getChilds();
        // function definition
        if(node->getGrammar() == "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" || node->getGrammar() == "func_definition : type_specifier ID LPAREN RPAREN compound_statement")
        {
                int oldNegOffset = currentNegOffset;
                for(auto x : childs[1]->getSi()->getParamList())
                {
                        currentNegOffset -= 2;
                        x->setOffset(currentNegOffset);
                }     
                vector<tree*> childs = node->getChilds();
                asmb << childs[1]->getSi()->getName() << " PROC\n";
                if(childs.size() == 6)
                {
                        asmb << "\tPUSH BP\n";
                        asmb << "\tMOV BP, SP\n";
                        dfs(childs[5]);
                }
                else if(childs.size() == 5)
                {
                        if(childs[1]->getSi()->getName() == "main")
                        {
                                asmb << "\tMOV AX, @DATA\n";
                                asmb << "\tMOV DS, AX\n";
                                asmb << "\tPUSH BP\n";
                                asmb << "\tMOV BP, SP\n";
                        }
                        else 
                        {
                                asmb << "\tPUSH BP\n";
                                asmb << "\tMOV BP, SP\n";       
                        }
                        dfs(childs[4]);
                }
                asmb << "L" << level++ <<":\n";
                if(childs[1]->getSi()->getName() == "main")
                {
                        asmb << "\tPOP BP\n";
                        asmb << "\tMOV AX, 4CH\n";
                        asmb << "\tINT 21H\n";
                }
                else 
                {
                        asmb << "\tPOP BP\n";
                        asmb << "\tRET "<< childs[1]->getSi()->getParamList().size() * 2 << "\n";
                }
                asmb << childs[1]->getSi()->getName() << " ENDP\n"; 
                currentNegOffset = oldNegOffset;
                return;     
        }
        // var declaretion
        else if(node->getGrammar() == "declaration_list : declaration_list COMMA ID")
        {
                if(currentScope->getParentScope() != nullptr)
                {
                        dfs(childs[0]);
                        currentOffset += 2;
                        currentScope->LookUp(childs[2]->getSi()->getName())->setOffset(currentOffset);
                        asmb << "\tSUB SP, 2\n";
                }
                return;
        }
        else if(node->getGrammar() == "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE")
        {
                if(currentScope->getParentScope() != nullptr)
                {
                        int arraySize = stoi(childs[4]->getSi()->getName());
                        if(arraySize > 0)
                        {
                                currentOffset += 2;
                                currentScope->LookUp(childs[2]->getSi()->getName())->setOffset(currentOffset);
                                currentOffset += 2 * arraySize - 2;
                                asmb << "\tSUB SP, " << 2 * arraySize << "\n";
                        }
                }
                return;
        }
        else if(node->getGrammar() == "declaration_list : ID")
        {
                if(currentScope->getParentScope() != nullptr)
                {
                        currentOffset += 2;
                        currentScope->LookUp(childs[0]->getSi()->getName())->setOffset(currentOffset);
                        asmb << "\tSUB SP, 2\n";
                }
                return;       
        }
        else if(node->getGrammar() == "declaration_list : ID LSQUARE CONST_INT RSQUARE")
        {
                if(currentScope->getParentScope() != nullptr)
                {
                        int arraySize = stoi(childs[2]->getSi()->getName());
                        if(arraySize > 0)
                        {
                                currentOffset += 2;
                                currentScope->LookUp(childs[0]->getSi()->getName())->setOffset(currentOffset);
                                currentOffset += 2 * arraySize - 2;
                                asmb << "\tSUB SP, " << 2 * arraySize << "\n";
                        }
                }
                return;
        }
        // statement
        else if(node->getGrammar() == "statement : PRINTLN LPAREN ID RPAREN SEMICOLON")
        {
                string var = manVar(childs[2]->getSi()->getName());
                asmb << "\t; Line " << node->getStartLine() << "\n";       
                asmb << "\tMOV AX, " << var << "\n";
                asmb << "\tCALL print_output\n";
                asmb << "\tCALL new_line\n";
                return; 
        }
        else if(node->getGrammar() == "statement : IF LPAREN expression RPAREN statement")
        {
                int lv = level;
                level++;
                asmb << "\t; Line " << node->getStartLine() << "\n";
                dfs(childs[2]);
                asmb << "\tCMP AX, 0\n";
                asmb << "\tJE L" << lv << "\n";
                dfs(childs[4]); 
                asmb << "L" << lv << ":\n";
                return;
        }
        else if(node->getGrammar() == "statement : IF LPAREN expression RPAREN statement ELSE statement")
        {
                int lv = level;
                level += 2;
                asmb << "\t; Line " << node->getStartLine() << "\n";
                dfs(childs[2]);
                asmb << "\tCMP AX, 0\n";
                asmb << "\tJE L" << lv << "\n";
                dfs(childs[4]);
                asmb << "\tJMP L" << lv + 1 << "\n";
                asmb << "L" << lv << ":\n";
                dfs(childs[6]);
                asmb << "L" << lv + 1 <<":\n";
                return;
        }
        else if(node->getGrammar() == "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement")
        {
                int lv = level;
                level += 2;
                asmb << "\t; Line " << node->getStartLine() << "\n";       
                dfs(childs[2]);
                asmb << "L" << lv << ":\n";
                dfs(childs[3]);
                asmb << "\tCMP AX, 0\n";
                asmb << "\tJE L" << lv + 1 <<"\n";
                dfs(childs[6]);
                dfs(childs[4]);
                asmb << "\tJMP L" << lv << "\n";
                asmb << "L" << lv + 1 << ":\n";
                return;     
        }
        else if(node->getGrammar() == "statement : WHILE LPAREN expression RPAREN statement")
        {
                int lv = level;
                level += 2;
                asmb << "\t; Line " << node->getStartLine() << "\n";
                asmb << "L" << lv << ":\n";
                dfs(childs[2]);
                asmb << "\tCMP AX, 0\n";
                asmb << "\tJE L" << lv + 1 <<"\n";
                dfs(childs[4]);
                asmb << "\tJMP L" << lv << "\n";
                asmb << "L" << lv + 1 << ":\n";
                return;
        }
        else if(node->getGrammar() == "statement : RETURN expression SEMICOLON")
        {
                dfs(childs[1]);
                asmb << "\tJMP FEND" << fend << "\n";
                return;
        }
        // compound statement
        else if(node->getGrammar() == "compound_statement : LCURL statements RCURL")
        {
                int oldOffset = currentOffset;
                currentScope = node->getSt();
                dfs(childs[1]);
                currentScope = currentScope->getParentScope();
                int newOffset = currentOffset;
                if(currentScope->getParentScope() == nullptr)
                {
                        asmb << "FEND" << fend++ << ":\n";
                }
                asmb << "L" << level++ << ":\n";
                asmb << "\tADD SP, " << newOffset - oldOffset << "\n";
                currentOffset = oldOffset;   
                return;    
        }
        // variable
        else if(node->getGrammar() == "variable : ID LSQUARE expression RSQUARE")
        {
                string var = manVar(childs[0]->getSi()->getName());
                dfs(childs[2]);
                asmb << "\tMOV BX, 2\n";
                asmb << "\tMUL BX\n";
                asmb << "\tMOV SI, AX\n";
                asmb << "\tMOV AX, " << var << "\n";
                return;
        }
        else if(node->getGrammar() == "variable : ID")
        {
                string var = manVar(childs[0]->getSi()->getName());
                asmb << "\tMOV AX, " << var << "\n";
                return;
        }
        // expression
        else if(node->getGrammar() == "expression_statement : expression SEMICOLON")
        {
                asmb << "L" << level++ <<":\n";
                asmb << "\t; Line " << node->getStartLine() << "\n";
                dfs(childs[0]);
                return;
        }
        else if(node->getGrammar() == "expression : logic_expression")
        {
                dfs(childs[0]);
                return;
        }
        else if(node->getGrammar() == "expression : variable ASSIGNOP logic_expression")
        {
                string var = manVar(childs[0]->getChilds().front()->getSi()->getName());
                dfs(childs[2]);
                asmb << "\tMOV " << var <<", AX\n";
                return;
        }
        else if(node->getGrammar() == "logic_expression : rel_expression")
        {
                dfs(childs[0]);
                return;
        }
        else if(node->getGrammar() == "logic_expression : rel_expression LOGICOP rel_expression")
        {
                if(childs[1]->getSi()->getName() == "||")
                {
                        dfs(childs[0]);
                        asmb << "\tCMP AX, 0\n";
                        asmb << "\tJNE L" << level + 1 << "\n";
                        asmb << "\tJMP L" << level << "\n";
                        asmb << "L" << level++ <<":\n"; 
                        dfs(childs[2]);
                        asmb << "\tCMP AX, 0\n";
                        asmb << "\tJNE L" << level << "\n";
                        asmb << "\tJMP L" << level + 1 << "\n";
                        asmb << "L" << level++ <<":\n";
                        asmb << "\tMOV AX, 1\n";
                        asmb << "\tJMP L" << level + 1 << "\n";
                        asmb << "L" << level++ <<":\n";
                        asmb << "\tMOV AX, 0\n";
                        asmb << "L" << level++ <<":\n";
                }
                else if(childs[1]->getSi()->getName() == "&&")
                {
                        dfs(childs[0]);
                        asmb << "\tCMP AX, 0\n";
                        asmb << "\tJNE L" << level << "\n";
                        asmb << "\tJMP L" << level + 2 << "\n";
                        asmb << "L" << level++ <<":\n"; 
                        dfs(childs[2]);
                        asmb << "\tCMP AX, 0\n";
                        asmb << "\tJNE L" << level << "\n";
                        asmb << "\tJMP L" << level + 1 << "\n";
                        asmb << "L" << level++ <<":\n";
                        asmb << "\tMOV AX, 1\n";
                        asmb << "\tJMP L" << level + 1 << "\n";
                        asmb << "L" << level++ <<":\n";
                        asmb << "\tMOV AX, 0\n";
                        asmb << "L" << level++ <<":\n";
                }
                return;
        }
        else if(node->getGrammar() == "rel_expression : simple_expression")
        {
                dfs(childs[0]);
                return;
        }
        else if(node->getGrammar() == "rel_expression : simple_expression RELOP simple_expression")
        {
                string op = childs[1]->getSi()->getName();
                dfs(childs[2]);
                asmb << "\tPUSH AX\n";
                dfs(childs[0]);
                asmb << "\tPOP CX\n";
                asmb << "\tCMP AX, CX\n";
                if(op == "<")
                {
                        asmb << "\tJL L" << level << "\n";
                }
                else if(op == "<=")
                {
                        asmb << "\tJLE L" << level << "\n";
                }
                else if(op == ">")
                {
                        asmb << "\tJG L" << level << "\n";
                }
                else if(op == ">=")
                {
                        asmb << "\tJGE L" << level << "\n";
                }
                else if(op == "==")
                {
                        asmb << "\tJE L" << level << "\n";
                }
                else if(op == "!=")
                {
                        asmb << "\tJNE L" << level << "\n";
                }
                asmb << "\tJMP L" << level + 1 << "\n";
                asmb << "L" << level++ <<":\n";
                asmb << "\tMOV AX, 1\n";
                asmb << "\tJMP L" << level + 1 << "\n";
                asmb << "L" << level++ << ":\n";
                asmb << "\tMOV AX, 0\n";
                asmb << "L" << level++ << ":\n";
                return;
        }
        else if(node->getGrammar() == "simple_expression : term")
        {
                dfs(childs[0]);
                return;
        }
        else if(node->getGrammar() == "simple_expression : simple_expression ADDOP term")
        {
                dfs(childs[0]);
                asmb << "\tMOV DX, AX\n";
                asmb << "\tPUSH DX\n";
                dfs(childs[2]);
                asmb << "\tPOP DX\n";
                if(childs[1]->getSi()->getName() == "-")
                {
                        asmb << "\tNEG AX\n";
                }
                asmb << "\tADD AX, DX\n";
                return;
        }
        else if(node->getGrammar() == "term : unary_expression")
        {
                dfs(childs[0]);
                return;
        }
        else if(node->getGrammar() == "term : term MULOP unary_expression")
        {
                if(childs[1]->getSi()->getName() == "*")
                {
                        dfs(childs[0]);
                        asmb << "\tMOV CX, AX\n";
                        asmb << "\tPUSH CX\n";
                        dfs(childs[2]);
                        asmb << "\tPOP CX\n";
                        asmb << "\tCWD\n";
                        asmb << "\tMUL CX\n";
                }
                else if(childs[1]->getSi()->getName() == "/")
                {
                        dfs(childs[0]);
                        asmb << "\tMOV CX, AX\n";
                        asmb << "\tPUSH CX\n";
                        dfs(childs[2]);
                        asmb << "\tPOP CX\n";
                        asmb << "\tXCHG AX, CX\n";
                        asmb << "\tCWD\n";
                        asmb << "\tDIV CX\n";
                }
                else if(childs[1]->getSi()->getName() == "%")
                {
                        dfs(childs[0]);
                        asmb << "\tMOV CX, AX\n";
                        asmb << "\tPUSH CX\n";
                        dfs(childs[2]);
                        asmb << "\tPOP CX\n";
                        asmb << "\tXCHG AX, CX\n";
                        asmb << "\tCWD\n";
                        asmb << "\tDIV CX\n";
                        asmb << "\tMOV AX, DX\n";
                }
                return;
        }
        else if(node->getGrammar() == "unary_expression : ADDOP unary_expression")
        {
                dfs(childs[1]);
                if(childs[0]->getSi()->getName() == "-")
                {
                        asmb << "\tNEG AX\n";
                }
                return;
        }
        else if(node->getGrammar() == "unary_expression : NOT unary_expression")
        {
                dfs(childs[1]);
                return;
        }
        else if(node->getGrammar() == "unary_expression : factor")
        {
                dfs(childs[0]);
                return;
        }
        // factor
        else if(node->getGrammar() == "factor : variable")
        {
                dfs(childs[0]);
                return;
        }
        else if(node->getGrammar() == "factor : ID LPAREN argument_list RPAREN")
        {
                dfs(childs[2]);
                asmb << "\tCALL " << childs[0]->getSi()->getName() << "\n";
                return;
        }
        else if(node->getGrammar() == "factor : LPAREN expression RPAREN")
        {
                dfs(childs[1]);
                return;
        }
        else if(node->getGrammar() == "factor : CONST_INT")
        {
                asmb << "\tMOV AX, " << childs[0]->getSi()->getName() << "\n";
                return;
        }
        else if(node->getGrammar() == "factor : variable INCOP")
        {
                dfs(childs[0]);
                asmb << "\tPUSH AX\n";
                asmb << "\tINC AX\n";
                asmb << "\tMOV " << manVar(childs[0]->getChilds().front()->getSi()->getName()) <<", AX\n";
                asmb << "\tPOP AX\n";
                return;
        }
        else if(node->getGrammar() == "factor : variable DECOP")
        {
                dfs(childs[0]);
                asmb << "\tPUSH AX\n";
                asmb << "\tDEC AX\n";
                asmb << "\tMOV " << manVar(childs[0]->getChilds().front()->getSi()->getName()) <<", AX\n";
                asmb << "\tPOP AX\n";
                return;
        }
        else if(node->getGrammar() == "factor : ID LPAREN argument_list RPAREN")
        {

                dfs(childs[2]);
                asmb << "\tCALL " << childs[0]->getSi()->getName() << "\n";
                return;
        }
        else if(node->getGrammar() == "arguments : arguments COMMA logic_expression")
        {
                dfs(childs[2]);
                asmb << "\tPUSH AX\n";
                dfs(childs[0]);
                return;
        }
        else if(node->getGrammar() == "arguments : logic_expression")
        {
                dfs(childs[0]);
                asmb << "\tPUSH AX\n";
                return;
        }
        for(auto x : childs)
        {
                dfs(x);
        }
}

void iniAssembly(){
        asmb << ".MODEL SMALL\n";
        asmb << ".STACK 1000H\n";
        asmb << ".DATA\n";
        asmb << "\tnumber DB \"00000$\"\n";
        assemblyGenerationForGlobalVariable();
        asmb << ".CODE\n";
        dfs(root);
        asmb << "new_line proc\n\tpush ax\n\tpush dx\n\tmov ah,2\n\tmov dl,0Dh\n\tint 21h\n\tmov ah,2\n\tmov dl,0Ah\n\tint 21h\n\tpop dx\n\tpop ax\n\tret\n\tnew_line endp\n";
        asmb << "print_output proc\n\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n\tpush si\n\tlea si,number\n\tmov bx,10\n\tadd si,4\n\tcmp ax,0\n\tjnge negate\n\tprint:\n\txor dx,dx\n\tdiv bx\n\tmov [si],dl\n\tadd [si],'0'\n\tdec si\n\tcmp ax,0\n\tjne print\n\tinc si\n\tlea dx,si\n\tmov ah,9\n\tint 21h\n\tpop si\n\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\tret\n\tnegate:\n\tpush ax\n\tmov ah,2\n\tmov dl,'-'\n\tint 21h\n\tpop ax\n\tneg ax\n\tjmp print\n\tprint_output endp\n";
        asmb << "END main";
}

int yylex(void);
int yyparse(void);

%}

%union{
    tree *node;
}

%token <node> IF ELSE FOR WHILE INT FLOAT VOID RETURN ADDOP MULOP INCOP RELOP LOGICOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE COMMA SEMICOLON PRINTLN DECOP
%token <node> CONST_INT CONST_FLOAT ID
%type <node>  start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments 

%left RELOP ADDOP
%left ID
%left LPAREN RPAREN 
%nonassoc ELSE

%%
start   :   program     {
        logout << "start\t: program\n"; 
        logout << "Total Lines: " << lineCount << "\n";
        logout << "Total Errors: " << errorCount << "\n";
        $$ = new tree();
        $$->setGrammar("start : program");
        $$->add({$1});
        $$->updateLine();
        $$->print(parsetreeout);
        
        // ICG starts from here
        root = $$;
        iniAssembly();
}
        ;
program :   program unit        {
        logout << "program\t: program unit\n";
        $$ = new tree();
        $$->setGrammar("program : program unit");
        $$->add({$1,$2});
}
        |   unit        {
        logout << "program\t: unit\n";
        $$ = new tree();
        $$->setGrammar("program : unit");
        $$->add({$1});
}
        ;
unit    :   var_declaration     {
        logout << "unit\t: var_declaration\n";
        $$ = new tree(); 
        $$->setGrammar("unit : var_declaration");
        $$->add({$1});
}
        |   func_declaration    {
        logout << "unit\t: func_declaration\n";
        $$ = new tree(); 
        $$->setGrammar("unit : func_declaration");
        $$->add({$1});
}
        |   func_definition     {
        logout << "unit\t: func_definition\n";
        $$ = new tree(); 
        $$->setGrammar("unit : func_definition");
        $$->add({$1});
}
        ;
func_declaration    :   type_specifier ID LPAREN parameter_list RPAREN SEMICOLON    {
        logout << "func_declaration\t: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n"; 
        $2->getSi()->setType("FUNCTION"); 
        $2->getSi()->setExtraType($1->getData()); 
        $2->getSi()->setParamList(param_list); 
        bool flag = st->Insert($2->getSi()); 
        multiset<string> ms;
        for(auto x:param_list)
        {
                ms.insert(x->getName());
        }
        set<string> s(ms.begin(),ms.end());
        for(auto x: s)
        {
                if(ms.count(x)>1)
                {
                        errfun($2->getStartLine(),"Redefinition of parameter of '"+x+"'");
                }
        }
        param_list.clear();
        if(!flag)
        {
                SymbolInfo *si = st->LookUp($2->getSi()->getName());
                if(si->getType() == "FUNCTION")
                {
                        errfun($2->getStartLine(),"Redeclaretion of function '"+si->getName()+"'");
                }
                else
                {
                        errfun($2->getStartLine(),"'"+si->getName()+"' redeclared as different kind of symbol");
                }
        }
        $$ = new tree(); 
        $$->setGrammar("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
        $$->add({$1,$2,$3,$4,$5,$6});
}
        |   type_specifier ID LPAREN RPAREN SEMICOLON   {
        logout << "func_declaration\t: type_specifier ID LPAREN RPAREN SEMICOLON\n"; 
        $2->getSi()->setType("FUNCTION"); 
        $2->getSi()->setExtraType($1->getData()); 
        bool flag = st->Insert($2->getSi()); 
        param_list.clear();
        if(!flag)
        {
                SymbolInfo *si = st->LookUp($2->getSi()->getName());
                if(si->getType() == "FUNCTION")
                {
                        errfun($2->getStartLine(),"Redeclaretion of function '"+si->getName()+"'");
                }
                else
                {
                        errfun($2->getStartLine(),"'"+si->getName()+"' redeclared as different kind of symbol");
                }
        }
        $$ = new tree(); 
        $$->setGrammar("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
        $$->add({$1,$2,$3,$4,$5});
}
        ;
func_definition     :   type_specifier ID LPAREN parameter_list RPAREN compound_statement       {
        logout << "func_definition\t: type_specifier ID LPAREN parameter_list RPAREN compound_statement\n";
        $2->getSi()->setType("FUNCTION");
        $2->getSi()->setExtraType($1->getData());
        $2->getSi()->setParamList(param_list);
        $2->getSi()->setDef();
        bool flag = st->Insert($2->getSi());
        if(!flag)
        {
                SymbolInfo *si = st->LookUp($2->getSi()->getName());
                if(si->getType() != "FUNCTION")
                {
                        errfun($2->getStartLine(),"'"+si->getName()+"' redeclared as different kind of symbol");
                }
                else
                {
                        if(si->getDef())
                        {
                                errfun($2->getStartLine(),"Redefinition of funciton '"+si->getName()+"'");
                        }
                        else 
                        {
                                if(funcmp(si,$2->getSi()))
                                {
                                        $2->getSi()->setDef();
                                }
                                else 
                                {
                                        errfun($2->getStartLine(),"Conflicting Types for '"+si->getName()+"'");
                                }
                        }
                }
        }
        else 
        {
                $2->getSi()->setDef();
                multiset<string> ms;
                for(auto x:param_list)
                {
                        ms.insert(x->getName());
                }
                set<string> s(ms.begin(),ms.end());
                for(auto x: s)
                {
                        if(ms.count(x)>1)
                        {
                                errfun($2->getStartLine(),"Redefinition of parameter of '"+x+"'");
                        }
                }
        }
        param_list.clear();
        $$ = new tree(); 
        $$->setGrammar("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
        $$->add({$1,$2,$3,$4,$5,$6});
        // ICG
        $$->setSt($6->getSt());
}
        |   type_specifier ID LPAREN RPAREN compound_statement                              {
        logout << "func_definition\t: type_specifier ID LPAREN RPAREN compound_statement\n";
        $2->getSi()->setType("FUNCTION");
        $2->getSi()->setExtraType($1->getData());
        bool flag = st->Insert($2->getSi());
        if(!flag)
        {
                SymbolInfo *si = st->LookUp($2->getSi()->getName());
                if(si->getType() != "FUNCTION")
                {
                        errfun($2->getStartLine(),"'"+si->getName()+"' redeclared as different kind of symbol");
                }
                else
                {
                        if(si->getDef())
                        {
                                errfun($2->getStartLine(),"Redefinition of funciton '"+si->getName()+"'");
                        }
                        else 
                        {
                                if(funcmp(si,$2->getSi()))
                                {
                                        $2->getSi()->setDef();
                                }
                                else 
                                {
                                        errfun($2->getStartLine(),"Conflicting Types for '"+si->getName()+"'");
                                }
                        }
                }
        }
        else 
        {
                $2->getSi()->setDef();
                multiset<string> ms;
                for(auto x:param_list)
                {
                        ms.insert(x->getName());
                }
                set<string> s(ms.begin(),ms.end());
                for(auto x: s)
                {
                        if(ms.count(x)>1)
                        {
                                errfun($2->getStartLine(),"Redefinition of parameter of '"+x+"'");
                        }
                }
        }
        $$ = new tree(); 
        $$->setGrammar("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
        $$->add({$1,$2,$3,$4,$5});
        // ICG 
        $$->setSt($5->getSt());
}
        ;
parameter_list      :   parameter_list COMMA type_specifier ID  {
        logout << "parameter_list\t: parameter_list COMMA type_specifier ID\n"; 
        $4->getSi()->setType($3->getData()); 
        param_list.push_back($4->getSi());
        $$ = new tree(); 
        $$->setGrammar("parameter_list : parameter_list COMMA type_specifier ID");
        $$->add({$1,$2,$3,$4});
}
        |   parameter_list COMMA type_specifier {
        logout << "parameter_list\t: parameter_list COMMA type_specifier\n"; 
        SymbolInfo *si = new SymbolInfo("",$3->getData()); 
        param_list.push_back(si);
        $$ = new tree(); 
        $$->setGrammar("parameter_list : parameter_list COMMA type_specifier");
        $$->add({$1,$2,$3});
}
        |   type_specifier ID   {
        logout << "parameter_list\t: type_specifier ID\n"; 
        $2->getSi()->setType($1->getData()); 
        param_list.push_back($2->getSi());
        $$ = new tree(); 
        $$->setGrammar("parameter_list : type_specifier ID");
        $$->add({$1,$2});
}
        |   type_specifier      {
        logout << "parameter_list\t: type_specifier\n";
        SymbolInfo *si = new SymbolInfo("",$1->getData()); 
        param_list.push_back(si);
        $$ = new tree(); 
        $$->setGrammar("parameter_list : type_specifier");
        $$->add({$1});
}
        ;
compound_statement  :   LCURL {st->EnterScope(); for(auto x: param_list){st->Insert(x);}} statements RCURL  {
        logout << "compound_statement\t: LCURL statements RCURL\n"; 
        st->PrintAllScopeTable(logout); 
        // ICG
        ScopeTable *currScope = st->getCurrentScopeTable();
        
        st->ExitScope();
        $$ = new tree(); 
        $$->setGrammar("compound_statement : LCURL statements RCURL");
        $$->add({$1,$3,$4});
        // ICG
        $$->setSt(currScope);
}
        |   LCURL {st->EnterScope();} RCURL {
        logout << "compound_statement\t: LCURL RCURL\n"; 
        st->PrintAllScopeTable(logout);
        // ICG
        ScopeTable *currScope = st->getCurrentScopeTable();

        st->ExitScope();
        $$ = new tree(); 
        $$->setGrammar("compound_statement : LCURL RCURL");
        $$->add({$1,$3});
        // ICG
        $$->setSt(currScope);
}
        ;
var_declaration     :   type_specifier declaration_list SEMICOLON       {
        logout << "var_declaration\t: type_specifier declaration_list SEMICOLON\n"; 
        string str = $1->getData(); 
        if(str == "VOID")
        {      
                for(auto &x: declare_list)
                {
                        errfun($3->getStartLine(),"Variable or field '"+x->getName()+"' declared void");
                }
        } 
        else 
        {
                for(auto &x: declare_list)
                {
                        if(x->getType() == "ID")
                        {
                                x->setType(str);
                        } 
                        else if(x->getType() == "ARRAY")
                        {
                                x->setExtraType(str);
                        }
                } 
                $1->updateLine();
                for(auto x: declare_list)
                {
                        bool flag = st->Insert(x); 
                        if(!flag)
                        {
                                SymbolInfo *si = st->LookUp(x->getName());
                                if(si->getType() == str)
                                {
                                        errfun($1->getStartLine(),"Redeclaretion for '"+si->getName()+"'");
                                }
                                else 
                                {
                                        errfun($1->getStartLine(),"Conflicting types for '"+si->getName()+"'");
                                }
                        }
                }
        }
        declare_list.clear();
        $$ = new tree(); 
        $$->setGrammar("var_declaration : type_specifier declaration_list SEMICOLON");
        $$->add({$1,$2,$3});
}
        ;
type_specifier      :   INT     {
        logout << "type_specifier\t: INT\n";
        $$ = new tree();
        $$->setData("INT");
        $$->setGrammar("type_specifier : INT");
        $$->add({$1});
}
        |   FLOAT       {
        logout << "type_specifier\t: FLOAT\n"; 
        $$ = new tree();
        $$->setData("FLOAT");
        $$->setGrammar("type_specifier : FLOAT");
        $$->add({$1});
}
        |   VOID        {
        logout << "type_specifier\t: VOID\n"; 
        $$ = new tree(); 
        $$->setData("VOID");
        $$->setGrammar("type_specifier : VOID");
        $$->add({$1});
}
        ;
declaration_list    :   declaration_list COMMA ID       {
        logout << "declaration_list\t: declaration_list COMMA ID\n"; 
        declare_list.push_back($3->getSi());
        $$ = new tree(); 
        $$->setGrammar("declaration_list : declaration_list COMMA ID");
        $$->add({$1,$2,$3});
}
        |   declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {
        logout << "declaration_list\t: declaration_list COMMA ID LSQUARE CONST_INT RSQUARE\n"; 
        $3->getSi()->setType("ARRAY"); 
        $3->getSi()->setArraySize(stoi($5->getSi()->getName()));
        declare_list.push_back($3->getSi());
        $$ = new tree(); 
        $$->setGrammar("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE");
        $$->add({$1,$2,$3,$4,$5,$6});
}
        |   ID  {
        logout << "declaration_list\t: ID\n"; 
        declare_list.push_back($1->getSi());
        $$ = new tree(); 
        $$->setGrammar("declaration_list : ID");
        $$->add({$1});
}
        |   ID LSQUARE CONST_INT RSQUARE        {
        logout << "declaration_list\t: ID LSQUARE CONST_INT RSQUARE\n"; 
        $1->getSi()->setType("ARRAY"); 
        $1->getSi()->setArraySize(stoi($3->getSi()->getName()));
        declare_list.push_back($1->getSi());
        $$ = new tree(); 
        $$->setGrammar("declaration_list : ID LSQUARE CONST_INT RSQUARE");
        $$->add({$1,$2,$3,$4}); 
}
        ;
statements          :   statement       {
        logout << "statements\t: statement\n";
        $$ = new tree(); 
        $$->setGrammar("statements : statement");
        $$->add({$1});
}
        |   statements statement        {
        logout << "statements\t: statements statement\n";
        $$ = new tree(); 
        $$->setGrammar("statements : statements statement");
        $$->add({$1,$2});
}
        ;
statement           :   var_declaration {
        logout << "statement\t: var_declaration\n";
        $$ = new tree(); 
        $$->setGrammar("statement : var_declaration");
        $$->add({$1});
}
        |   expression_statement        {
        logout << "statement\t: expression_statement\n";
        $$ = new tree(); 
        $$->setGrammar("statement : expression_statement");
        $$->add({$1});
}
        |   compound_statement  {
        logout << "statement\t: compound_statement\n";
        $$ = new tree(); 
        $$->setGrammar("statement : compound_statement");
        $$->add({$1});
}
        |   FOR LPAREN expression_statement expression_statement expression RPAREN statement    {
        logout << "statement\t: FOR LPAREN expression statement expression statement expression RPAREN statement\n";
        $$ = new tree(); 
        $$->setGrammar("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
        $$->add({$1,$2,$3,$4,$5,$6,$7}); 
}
        |   IF LPAREN expression RPAREN statement       {
        logout << "statement\t: IF LPAREN expression RPAREN statement\n";
        $$ = new tree(); 
        $$->setGrammar("statement : IF LPAREN expression RPAREN statement");
        $$->add({$1,$2,$3,$4,$5});
}
        |   IF LPAREN expression RPAREN statement ELSE statement        {
        logout << "statement\t: IF LPAREN expression RPAREN statement ELSE statement\n";
        $$ = new tree(); 
        $$->setGrammar("statement : IF LPAREN expression RPAREN statement ELSE statement");
        $$->add({$1,$2,$3,$4,$5,$6,$7});
}
        |   WHILE LPAREN expression RPAREN statement    {
        logout << "statement\t: WHILE LPAREN expression RPAREN statement\n";
        $$ = new tree(); 
        $$->setGrammar("statement : WHILE LPAREN expression RPAREN statement");
        $$->add({$1,$2,$3,$4,$5});
}
        |   PRINTLN LPAREN ID RPAREN SEMICOLON  {
        logout << "statement\t: PRINTLN LPAREN ID RPAREN SEMICOLON\n";
        $$ = new tree(); 
        $$->setGrammar("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
        $$->add({$1,$2,$3,$4,$5});
}
        |   RETURN expression SEMICOLON {
        logout << "statement\t: RETURN expression SEMICOLON\n";
        $$ = new tree(); 
        $$->setGrammar("statement : RETURN expression SEMICOLON");
        $$->add({$1,$2,$3});
}
        ;
expression_statement :  SEMICOLON       {
        logout << "expression_statement\t: SEMICOLON\n";
        $$ = new tree(); 
        $$->setGrammar("expression_statement : SEMICOLON");
        $$->add({$1});
}
        |   expression SEMICOLON            {
        logout << "expression_statement\t: expression SEMICOLON\n";
        $$ = new tree(); 
        $$->setGrammar("expression_statement : expression SEMICOLON");
        $$->add({$1,$2});
}
        ;
variable :  ID  {
        logout << "variable\t: ID\n";
        $$ = new tree(); 
        $$->setGrammar("variable : ID");
        $$->add({$1});
        SymbolInfo *si = st->LookUp($1->getSi()->getName());
        if(si == nullptr)
        {
                errfun($1->getStartLine(),"Undeclared variable '" + $1->getSi()->getName() + "'"); 
        }
        else 
        {
                if(si->getType() == "ARRAY")
                {
                        errfun($1->getStartLine(),"Array '"+si->getName()+"' used without indexing");
                }
                else 
                {
                        $$->setDataType(si->getType());
                }
        }
}
        |   ID LSQUARE expression RSQUARE       {
        logout << "variable\t: ID LSQUARE expression RSQUARE\n";
        $$ = new tree(); 
        $$->setGrammar("variable : ID LSQUARE expression RSQUARE");
        $$->add({$1,$2,$3,$4});
        SymbolInfo *si = st->LookUp($1->getSi()->getName());
        if(si == nullptr)
        {
                errfun($1->getStartLine(),"Undeclared variable '" + $1->getSi()->getName() + "'");
        }
        else 
        {
                if(si->getType() != "ARRAY")
                {
                        errfun($1->getStartLine(),"'"+si->getName()+"' is not an array");
                }
                else
                {
                        $$->setDataType(si->getExtraType());
                }
        }
        if($3->getDataType() != "INT") 
        {
                $3->updateLine();
                errfun($3->getStartLine(),"Array subscript is not an integer");
        }
}
        ;
expression          :   logic_expression        {
        logout << "expression\t: logic_expression\n";
        $$ = new tree(); 
        $$->setGrammar("expression : logic_expression");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        |   variable ASSIGNOP logic_expression      {
        logout << "expression\t: variable ASSIGNOP logic_expression\n";
        $$ = new tree(); 
        $$->setGrammar("expression : variable ASSIGNOP logic_expression");
        $$->add({$1,$2,$3});
        if($1->getDataType() != "" && $3->getDataType() != "")
        {
                if($1->getDataType() == "VOID" || $3->getDataType() == "VOID")
                {
                        errfun($2->getStartLine(),"Void cannot be used in expression");
                }
                else  if($1->getDataType() == "INT" && $3->getDataType() == "FLOAT")
                {
                        errfun($2->getStartLine(),"Warning: possible loss of data in assignment of FLOAT to INT");
                        $$->setDataType("INT");
                }
                else if($1->getDataType() == "FLOAT" || $3->getDataType() == "FLOAT")
                {
                        $$->setDataType("FLOAT");
                }
                else
                {
                        $$->setDataType("INT");
                }
        }
}
        ;
logic_expression    :   rel_expression  {
        logout << "logic_expression\t: rel_expression\n";
        $$ = new tree(); 
        $$->setGrammar("logic_expression : rel_expression");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        |   rel_expression LOGICOP rel_expression       {
        logout << "logic_expression\t: rel_expression LOGICOP rel_expression\n";
        $$ = new tree(); 
        $$->setGrammar("logic_expression : rel_expression LOGICOP rel_expression");
        $$->add({$1,$2,$3});
        if($1->getDataType() != "" && $3->getDataType() != "")
        {
                if($1->getDataType() != "INT" || $3->getDataType() != "INT")
                {
                        errfun($2->getStartLine(),"Operands must be integer");
                }
                else 
                {
                        $$->setDataType("INT");
                }
        }
}
        ;
rel_expression      :   simple_expression       {
        logout << "rel_expression\t: simple_expression\n";
        $$ = new tree(); 
        $$->setGrammar("rel_expression : simple_expression");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        |   simple_expression RELOP simple_expression       {
        logout << "rel_expression\t: simple_expression RELOP simple_expression\n";
        $$ = new tree(); 
        $$->setGrammar("rel_expression : simple_expression RELOP simple_expression");
        $$->add({$1,$2,$3});
        if($1->getDataType() != "" && $3->getDataType() != "")
        {
                if($1->getDataType() == "VOID" || $3->getDataType() == "VOID")
                {
                        errfun($2->getStartLine(),"Void cannot be used in expression");
                }
                else 
                {
                        $$->setDataType("INT");
                }
        }
}
        ;
simple_expression   :   term    {
        logout << "simple_expression\t: term\n";
        $$ = new tree(); 
        $$->setGrammar("simple_expression : term");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        |   simple_expression ADDOP term    {
        logout << "simple_expression\t: simple_expression ADDOP term\n";
        $$ = new tree(); 
        $$->setGrammar("simple_expression : simple_expression ADDOP term");
        $$->add({$1,$2,$3});
        if($1->getDataType() != "" && $3->getDataType() != "")
        {
                if($1->getDataType() == "VOID" || $3->getDataType() == "VOID")
                {
                        errfun($2->getStartLine(),"Void cannot be used in expression");
                }
                else if($1->getDataType() == "FLOAT" || $3->getDataType() == "FLOAT")
                {
                        $$->setDataType("FLOAT");
                }
                else
                {
                        $$->setDataType("INT");
                }
        }
}
        ;
term    :   unary_expression    {
        logout << "term\t: unary_expression\n";
        $$ = new tree(); 
        $$->setGrammar("term : unary_expression");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        |   term MULOP unary_expression     {
        logout << "term\t: term MULOP unary_expression\n";
        $$ = new tree(); 
        $$->setGrammar("term : term MULOP unary_expression");
        $$->add({$1,$2,$3});
        if($1->getDataType() != "" && $3->getDataType() != "")
        {
                if($2->getSi()->getName() == "%" || $2->getSi()->getName() == "/")
                {       
                        if($2->getSi()->getName() == "%")
                        {
                                if($1->getDataType() != "INT" || $3->getDataType() != "INT")
                                {
                                        errfun($2->getStartLine(),"Operands of modulus must be integers");
                                }
                                else
                                {
                                        $$->setDataType("INT");
                                }
                        }
                        else if($2->getSi()->getName() == "/")
                        {
                                if($1->getDataType() == "VOID" || $3->getDataType() == "VOID")
                                {       
                                        errfun($2->getStartLine(),"Void cannot be used in expression");
                                }
                                if($1->getDataType() == "FLOAT" || $3->getDataType() == "FLOAT")
                                {
                                        $$->setDataType("FLOAT");
                                }
                                else 
                                {
                                        $$->setDataType("INT");
                                }
                        }
                        tree *it = $3;
                        while(it->getChilds().size() > 0)
                        {
                                if(it->getChilds().size() == 1)
                                {
                                        it = it->getChilds().front();
                                }
                                else 
                                {
                                        break;
                                }
                        }
                        if(it->getChilds().size() == 0 && (it->getSi()->getType() == "CONST_INT" || it->getSi()->getType() == "CONST_FLOAT"))
                        {
                                float zero = stof(it->getSi()->getName());
                                if(zero == 0)
                                {
                                        errfun($2->getStartLine(),"Warning: division by zero");
                                }
                        }
                }
                else if($2->getSi()->getName() == "*")
                {
                        if($1->getDataType() == "VOID" || $3->getDataType() == "VOID")
                        {       
                                errfun($2->getStartLine(),"Void cannot be used in expression");
                        }
                        else if($1->getDataType() == "FLOAT" || $3->getDataType() == "FLOAT")
                        {
                                $$->setDataType("FLOAT");
                        }
                        else 
                        {
                                $$->setDataType("INT");
                        }
                }
        }
}
        ;
unary_expression    :   ADDOP unary_expression  {
        logout << "unary_expression\t: ADDOP unary_expression\n";
        $$ = new tree(); 
        $$->setGrammar("unary_expression : ADDOP unary_expression");
        $$->add({$1,$2});
        if($2->getDataType() != "")
        {
                if($2->getDataType() == "VOID")
                {
                        errfun($1->getStartLine(),"Void cannot be used in expression");
                }
                else
                {
                        $$->setDataType($2->getDataType());
                }
        }
}
        |   NOT unary_expression        {
        logout << "unary_expression\t: NOT unary_expression\n";
        $$ = new tree(); 
        $$->setGrammar("unary_expression : NOT unary_expression");
        $$->add({$1,$2});
        if($2->getDataType() != "")
        {
                if($2->getDataType() == "VOID")
                {
                        errfun($1->getStartLine(),"Void cannot be used in expression");
                }
                else
                {
                        $$->setDataType("INT");
                }
        }
}
        |   factor      {
        logout << "unary_expression\t: factor\n";
        $$ = new tree(); 
        $$->setGrammar("unary_expression : factor");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        ;
factor  :   variable {
        logout << "factor\t: variable\n";
        $$ = new tree(); 
        $$->setGrammar("factor : variable");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        |   ID LPAREN argument_list RPAREN      {
        logout << "factor\t: ID LPAREN argument_list RPAREN\n";
        $$ = new tree(); 
        $$->setGrammar("factor : ID LPAREN argument_list RPAREN");
        $$->add({$1,$2,$3,$4});
        SymbolInfo *si = st->LookUp($1->getSi()->getName());
        if(si == nullptr)
        {
                errfun($1->getStartLine(),"Undeclared function '"+$1->getSi()->getName()+"'");
        }
        else 
        {
                if(si->getType() != "FUNCTION")
                {
                        errfun($1->getStartLine(),"'"+si->getName()+"' is not a function");
                }
                else 
                {
                        $$->setDataType(si->getExtraType());
                        vector<SymbolInfo*>v = si->getParamList();
                        if(arg_list.size()>v.size())
                        {
                                errfun($1->getStartLine(),"Too many arguments to function '"+si->getName()+"'");
                        }
                        else if(arg_list.size()<v.size())
                        {
                                errfun($1->getStartLine(),"Too few arguments to function '"+si->getName()+"'");
                        }
                        else 
                        {
                                for(int i = 0; i<arg_list.size(); i++)
                                {
                                        if(arg_list[i] != v[i]->getType())
                                        {
                                                errfun($1->getStartLine(),"Type mismatch for argument "+to_string(i+1)+" of '"+si->getName()+"'");
                                        }
                                }
                        }
                }
        }
        arg_list.clear();
}
        |   LPAREN expression RPAREN    {
        logout << "factor\t: LPAREN expression RPAREN\n";
        $$ = new tree(); 
        $$->setGrammar("factor : LPAREN expression RPAREN");
        $$->add({$1,$2,$3});
        $$->setDataType($2->getDataType());
}
        |   CONST_INT   {
        logout << "factor\t: CONST_INT\n";
        $$ = new tree();
        $$->setGrammar("factor : CONST_INT");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        |   CONST_FLOAT {
        logout << "factor\t: CONST_FLOAT\n";
        $$ = new tree(); 
        $$->setGrammar("factor : CONST_FLOAT");
        $$->add({$1});
        $$->setDataType($1->getDataType());
}
        |   variable INCOP      {
        logout << "factor\t: variable INCOP\n";
        $$ = new tree(); 
        $$->setGrammar("factor : variable INCOP");
        $$->add({$1,$2});
        $$->setDataType($1->getDataType());
}
        |   variable DECOP      {
        logout << "factor\t: variable DECOP\n";
        $$ = new tree(); 
        $$->setGrammar("factor : variable DECOP");
        $$->add({$1,$2});
        $$->setDataType($1->getDataType());
}
        ;
argument_list       :   arguments       {
        logout << "argument_list\t: arguments\n";
        $$ = new tree(); 
        $$->setGrammar("argument_list : arguments");
        $$->add({$1});
}
        |       {
        logout << "argument_list\t: \n";
        $$ = new tree(); 
        $$->setGrammar("argument_list : ");
}
        ;
arguments           :   arguments COMMA logic_expression        {
        logout << "arguments\t: arguments COMMA logic_expression\n";
        $$ = new tree(); 
        $$->setGrammar("arguments : arguments COMMA logic_expression");
        $$->add({$1,$2,$3});
        arg_list.push_back($3->getDataType());
}
        |   logic_expression    {
        logout << "arguments\t: logic_expression\n";
        $$ = new tree(); 
        $$->setGrammar("arguments : logic_expression");
        $$->add({$1});
        arg_list.push_back($1->getDataType());
}
        ;
%%

int main(int argc, char *argv[])
{
        if(argc != 2)
        {
                cout << "Input a valid file name.\n";
                return 0;
        }
        yyin = fopen(argv[1], "r"); 
        if(yyin == nullptr)
        {
                cout << "Can't open specified file.\n";
                return 0;
        }
        cout << "Opened successfully.\n";
        logout.open("log.txt",ios::out);
        parsetreeout.open("parsetree.txt",ios::out);
        errorout.open("error.txt",ios::out);
        asmb.open("code.asm",ios::out);
        yyparse();
        fclose(yyin);
        exit(0);
}