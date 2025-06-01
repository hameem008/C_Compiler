#include <bits/stdc++.h>
using namespace std;
#define space "\t";

class SymbolInfo
{
private:
    string name;
    string type;
    string extratype;
    vector<SymbolInfo *> paramlist;
    int arraysize = 0;
    bool def;
    int offset = 0;

public:
    SymbolInfo *nextSymbol;
    SymbolInfo(string name, string type)
    {
        setName(name);
        setType(type);
        extratype = "";
        def = false;
        nextSymbol = nullptr;
    }
    void setName(string name)
    {
        this->name = name;
    }
    string getName()
    {
        return name;
    }
    void setType(string type)
    {
        this->type = type;
    }
    string getType()
    {
        return type;
    }
    void setExtraType(string extratype)
    {
        this->extratype = extratype;
    }
    string getExtraType()
    {
        return extratype;
    }
    void setParamList(vector<SymbolInfo *> paramlist)
    {
        this->paramlist = paramlist;
    }
    vector<SymbolInfo *> getParamList()
    {
        return paramlist;
    }
    void setArraySize(int arraysize)
    {
        this->arraysize = arraysize;
    }
    int getArraySize()
    {
        return arraysize;
    }
    void setDef()
    {
        def = true;
    }
    bool getDef()
    {
        return def;
    }
    void setOffset(int offset)
    {
        this->offset = offset;
    }
    int getOffset()
    {
        return offset;
    }
    ~SymbolInfo()
    {
    }
};

class ScopeTable
{
private:
    int size;
    string id;
    ScopeTable *parentScope;
    SymbolInfo **array;
    unsigned long long sdbm(string name)
    {
        unsigned long long hash = 0;
        for (auto ch : name)
        {
            hash = (int)ch + (hash << 6) + (hash << 16) - hash;
        }
        return hash % size;
    }

public:
    int childs;
    ScopeTable(int n, ScopeTable *parentScope, int &scopeTableVal)
    {
        scopeTableVal++;
        size = n;
        this->parentScope = parentScope;
        if (parentScope == nullptr)
        {
            id = "1";
        }
        else
        {
            id = "";
            for (auto x : to_string(scopeTableVal))
            {
                id.push_back(x);
            }
        }
        array = new SymbolInfo *[n];
        for (int i = 0; i < n; i++)
        {
            array[i] = nullptr;
        }
    }

    string getId()
    {
        return id;
    }
    ScopeTable *getParentScope()
    {
        return parentScope;
    }

    SymbolInfo *LookUp(string symbolName)
    {
        int pos = 1;
        int index = sdbm(symbolName);
        SymbolInfo *it = array[index];
        SymbolInfo *ret = nullptr;
        while (it != nullptr)
        {
            if (it->getName() == symbolName)
            {
                ret = it;
                return ret;
            }
            it = it->nextSymbol;
            pos++;
        }
        return ret;
    }
    SymbolInfo *FullLookUp(string symbolName)
    {
        ScopeTable *it = this;
        SymbolInfo *ret = nullptr;
        while (it != nullptr)
        {
            ret = it->LookUp(symbolName);
            if (ret != nullptr)
            {
                return ret;
            }
            it = it->getParentScope();
        }
        return ret;
    }

    bool Insert(string symbolName, string symbolType)
    {
        int pos = 1;
        int index = sdbm(symbolName);
        SymbolInfo *it, *save, *in;
        it = array[index];
        if (it == nullptr)
        {
            in = new SymbolInfo(symbolName, symbolType);
            array[index] = in;
        }
        else
        {
            while (it != nullptr)
            {
                if (it->getName() == symbolName)
                {
                    return false;
                }
                if (it->nextSymbol == nullptr)
                {
                    save = it;
                }
                it = it->nextSymbol;
                pos++;
            }
            in = new SymbolInfo(symbolName, symbolType);
            in->nextSymbol = save->nextSymbol;
            save->nextSymbol = in;
        }
        return true;
    }

    bool Insert(SymbolInfo *si)
    {
        int pos = 1;
        int index = sdbm(si->getName());
        SymbolInfo *it, *save, *in;
        it = array[index];
        if (it == nullptr)
        {
            in = si;
            array[index] = in;
        }
        else
        {
            while (it != nullptr)
            {
                if (it->getName() == si->getName())
                {
                    return false;
                }
                if (it->nextSymbol == nullptr)
                {
                    save = it;
                }
                it = it->nextSymbol;
                pos++;
            }
            in = si;
            in->nextSymbol = save->nextSymbol;
            save->nextSymbol = in;
        }
        return true;
    }

    bool Delete(string symbolName)
    {
        int pos = 1;
        int index = sdbm(symbolName);
        SymbolInfo *it, *save = nullptr;
        it = array[index];
        if (it == nullptr)
        {
            return false;
        }
        if (it->getName() == symbolName)
        {
            array[index] = it->nextSymbol;
            delete it;
            return true;
        }
        else
        {
            while (it != nullptr)
            {
                if (it->nextSymbol != nullptr && it->nextSymbol->getName() == symbolName)
                {
                    pos++;
                    save = it;
                    break;
                }
                it = it->nextSymbol;
                pos++;
            }
        }
        if (save == nullptr)
        {
            return false;
        }
        else
        {
            SymbolInfo *temp = save->nextSymbol;
            save->nextSymbol = temp->nextSymbol;
            delete temp;
            return true;
        }
    }

    void Print(ofstream &logout)
    {
        logout << space;
        logout << "ScopeTable# " << id << endl;
        for (int i = 0; i < size; i++)
        {
            SymbolInfo *it = array[i];
            if (it != nullptr)
            {
                logout << space;
                logout << i + 1;
                logout << "--> ";
                while (it != nullptr)
                {
                    logout << " ";
                    if (it->getType() == "FUNCTION")
                    {
                        logout << "<" << it->getName() << "," << it->getType() << "," << it->getExtraType() << ">";
                    }
                    else
                    {
                        logout << "<" << it->getName() << "," << it->getType() << ">";
                    }
                    it = it->nextSymbol;
                }
                logout << endl;
            }
        }
    }

    int getSize()
    {
        return size;
    }

    SymbolInfo **getArray()
    {
        return array;
    }

    // ~ScopeTable()
    // {
    //     if (size)
    //     {
    //         for (int i = 0; i < size; i++)
    //         {
    //             SymbolInfo *it = array[i];
    //             while (it != nullptr)
    //             {
    //                 SymbolInfo *temp = it->nextSymbol;
    //                 it->getParamList().clear();
    //                 delete it;
    //                 it = temp;
    //             }
    //             delete it;
    //         }
    //         delete[] array;
    //         size = 0;
    //     }
    // }
};

class tree
{
private:
    int startLine = 0;
    int endLine = 0;
    string grammar;
    vector<tree *> childs;
    int spaceCnt = 0;

    string data = "";
    string dataType = "";
    SymbolInfo *si = nullptr;
    ScopeTable *st = nullptr;

public:
    void setStartLine(int startLine)
    {
        this->startLine = startLine;
    }
    int getStartLine()
    {
        return startLine;
    }
    void setEndLine(int endLine)
    {
        this->endLine = endLine;
    }
    int getEndLine()
    {
        return endLine;
    }
    void setGrammar(string grammar)
    {
        this->grammar = grammar;
    }
    string getGrammar()
    {
        return grammar;
    }
    vector<tree *> getChilds()
    {
        return childs;
    }
    void add(vector<tree *> ch)
    {
        for (auto x : ch)
        {
            childs.push_back(x);
        }
    }
    void setSpaceCnt(int spaceCnt)
    {
        this->spaceCnt = spaceCnt;
    }
    int getSpaceCnt()
    {
        return spaceCnt;
    }
    void setData(string data)
    {
        this->data = data;
    }
    string getData()
    {
        return data;
    }
    void setDataType(string dataType)
    {
        this->dataType = dataType;
    }
    string getDataType()
    {
        return dataType;
    }
    void setSi(SymbolInfo *si)
    {
        this->si = si;
    }
    SymbolInfo *getSi()
    {
        return si;
    }
    void setSt(ScopeTable *st)
    {
        this->st = st;
    }
    ScopeTable *getSt()
    {
        return st;
    }
    void print(ofstream &out)
    {
        for (int i = 0; i < spaceCnt; i++)
        {
            out << " ";
        }
        if (childs.size())
            out << grammar << " \t<Line: " << startLine << "-" << endLine << ">\n";
        else
            out << grammar << "\t<Line: " << startLine << ">\n";
        for (auto x : childs)
        {
            x->setSpaceCnt(spaceCnt + 1);
            x->print(out);
        }
    }
    void updateLine()
    {
        if (childs.size())
        {
            if (startLine != 0 && endLine != 0)
                return;
            for (auto x : childs)
            {
                x->updateLine();
            }
            startLine = childs.front()->getStartLine();
            endLine = childs.back()->getEndLine();
        }
        else
            return;
    }
};

class SymbolTable
{
private:
    int scopeTableVal = 0;
    ScopeTable *currentScopeTable;
    int size;

public:
    SymbolTable(int size)
    {
        this->size = size;
        currentScopeTable = new ScopeTable(size, nullptr, scopeTableVal);
    }
    void EnterScope()
    {
        ScopeTable *temp = new ScopeTable(size, currentScopeTable, scopeTableVal);
        currentScopeTable = temp;
    }
    void ExitScope()
    {
        ScopeTable *temp = currentScopeTable;
        if (currentScopeTable->getParentScope() == nullptr)
        {
        }
        else
        {
            currentScopeTable = currentScopeTable->getParentScope();
            // delete temp;
        }
    }
    bool Insert(string symbolName, string symbolType)
    {
        return currentScopeTable->Insert(symbolName, symbolType);
    }
    bool Insert(SymbolInfo *si)
    {
        return currentScopeTable->Insert(si);
    }
    bool Remove(string symbolName)
    {
        return currentScopeTable->Delete(symbolName);
    }
    SymbolInfo *LookUp(string symbolName)
    {
        ScopeTable *it = currentScopeTable;
        SymbolInfo *ret = nullptr;
        while (it != nullptr)
        {
            ret = it->LookUp(symbolName);
            if (ret != nullptr)
            {
                return ret;
            }
            it = it->getParentScope();
        }
        return ret;
    }
    void PrintCurrentScopeTable(ofstream &logout)
    {
        currentScopeTable->Print(logout);
    }
    void PrintAllScopeTable(ofstream &logout)
    {
        ScopeTable *it = currentScopeTable;
        while (it != nullptr)
        {
            it->Print(logout);
            it = it->getParentScope();
        }
    }

    ScopeTable *getCurrentScopeTable()
    {
        return currentScopeTable;
    }

    // ~SymbolTable()
    // {
    //     ScopeTable *it = currentScopeTable;
    //     while (it != nullptr)
    //     {
    //         it = currentScopeTable->getParentScope();
    //         delete currentScopeTable;
    //         currentScopeTable = it;
    //     }
    // }
};