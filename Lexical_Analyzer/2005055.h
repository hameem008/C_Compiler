#include <iostream>
using namespace std;
#define space "\t";

class SymbolInfo
{
private:
    string name;
    string type;

public:
    SymbolInfo *nextSymbol;
    SymbolInfo(string name, string type)
    {
        setName(name);
        setType(type);
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
    ScopeTable(int n, ScopeTable *parentScope)
    {
        size = n;
        childs = 0;
        this->parentScope = parentScope;
        if (parentScope == nullptr)
        {
            id = "1";
        }
        else
        {
            id = parentScope->getId();
            id.push_back('.');
            for (auto x : to_string(parentScope->childs + 1))
            {
                id.push_back(x);
            }
            parentScope->childs++;
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

    void Print()
    {
        cout << space;
        cout << "ScopeTable# " << id << endl;
        for (int i = 0; i < size; i++)
        {
            SymbolInfo *it = array[i];
            cout << space;
            cout << i + 1;
            while (it != nullptr)
            {
                cout << " --> ";
                cout << "(" << it->getName() << "," << it->getType() << ")";
                it = it->nextSymbol;
            }
            cout << endl;
        }
    }

    ~ScopeTable()
    {
        if (size)
        {
            for (int i = 0; i < size; i++)
            {
                SymbolInfo *it = array[i];
                while (it != nullptr)
                {
                    SymbolInfo *temp = it->nextSymbol;
                    delete it;
                    it = temp;
                }
                delete it;
            }
            delete[] array;
            size = 0;
        }
    }
};

class SymbolTable
{
private:
    ScopeTable *currentScopeTable;
    int size;

public:
    SymbolTable(int size)
    {
        this->size = size;
        currentScopeTable = new ScopeTable(size, nullptr);
    }
    void EnterScope()
    {
        ScopeTable *temp = new ScopeTable(size, currentScopeTable);
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
            delete temp;
        }
    }
    bool Insert(string symbolName, string symbolType)
    {
        return currentScopeTable->Insert(symbolName, symbolType);
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
    void PrintCurrentScopeTable()
    {
        currentScopeTable->Print();
    }
    void PrintAllScopeTable()
    {
        ScopeTable *it = currentScopeTable;
        while (it != nullptr)
        {
            it->Print();
            it = it->getParentScope();
        }
    }
    ~SymbolTable()
    {
        ScopeTable *it = currentScopeTable;
        while (it != nullptr)
        {
            it = currentScopeTable->getParentScope();
            delete currentScopeTable;
            currentScopeTable = it;
        }
    }
};