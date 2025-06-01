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
        cout << space;
        cout << "ScopeTable# " << id << " created" << endl;
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
                cout << space;
                cout << "'" << symbolName << "' found at position <" << index + 1 << ", " << pos << "> of ScopeTable# " << id << endl;
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
                    cout << space;
                    cout << "'" << symbolName << "' already exists in the current ScopeTable# " << id << endl;
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
        cout << space;
        cout << "Inserted  at position <" << index + 1 << ", " << pos << "> of ScopeTable# " << id << endl;
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
            cout << space;
            cout << "Not found in the current ScopeTable# " << id << endl;
            return false;
        }
        if (it->getName() == symbolName)
        {
            array[index] = it->nextSymbol;
            delete it;
            cout << space;
            cout << "Deleted '" << symbolName << "' from position <" << index + 1 << ", " << pos << "> of ScopeTable# " << id << endl;
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
            cout << space;
            cout << "Not found in the current ScopeTable# " << id << endl;
            return false;
        }
        else
        {
            SymbolInfo *temp = save->nextSymbol;
            save->nextSymbol = temp->nextSymbol;
            delete temp;
            cout << space;
            cout << "Deleted '" << symbolName << "' from position <" << index + 1 << ", " << pos << "> of ScopeTable# " << id << endl;
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
            cout << space;
            cout << "ScopeTable# " << id << " deleted" << endl;
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
            cout << space;
            cout << "ScopeTable# 1 cannot be deleted" << endl;
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
        cout << space;
        cout << "'" << symbolName << "' not found in any of the ScopeTables" << endl;
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

int main()
{
    FILE *fin;
    FILE *fout;
    // ofstream str = freopen("in.txt", "w", fin);
    fin = freopen("input.txt", "r", stdin);
    fout = freopen("output.txt", "w", stdout);
    string str;
    getline(cin, str);
    int size = stoi(str), cmd = 1;
    SymbolTable *st = new SymbolTable(size);
    while (!feof(fin))
    {
        str.clear();
        getline(cin, str);
        int cnt = 0;
        for (auto x : str)
        {
            if (x == ' ')
            {
                cnt++;
            }
        }
        cnt++;
        string arr[cnt];
        int it = 0;
        string dum;
        for (auto x : str)
        {
            if (x == ' ')
            {
                arr[it] = dum;
                dum.clear();
                it++;
            }
            else
            {
                dum.push_back(x);
            }
        }
        arr[it] = dum;
        cout << "Cmd " << cmd << ": " << str << endl;
        cmd++;
        if (arr[0] == "I")
        {
            if (cnt == 3)
            {
                st->Insert(arr[1], arr[2]);
            }
            else
            {
                cout << space;
                cout << "Wrong number of arugments for the command I" << endl;
            }
        }
        else if (arr[0] == "L")
        {
            if (cnt == 2)
            {
                st->LookUp(arr[1]);
            }
            else
            {
                cout << space;
                cout << "Wrong number of arugments for the command L" << endl;
            }
        }
        else if (arr[0] == "D")
        {
            if (cnt == 2)
            {
                st->Remove(arr[1]);
            }
            else
            {
                cout << space;
                cout << "Wrong number of arugments for the command D" << endl;
            }
        }
        else if (arr[0] == "P")
        {
            if (cnt == 2)
            {
                if (arr[1] == "A")
                {
                    st->PrintAllScopeTable();
                }
                else if (arr[1] == "C")
                {
                    st->PrintCurrentScopeTable();
                }
                else
                {
                    cout << space;
                    cout << "Invalid argument for the command P" << endl;
                }
            }
            else
            {
                cout << space;
                cout << "Wrong number of arugments for the command P" << endl;
            }
        }
        else if (arr[0] == "S")
        {
            if (cnt == 1)
            {
                st->EnterScope();
            }
            else
            {
                cout << space;
                cout << "Wrong number of arugments for the command S" << endl;
            }
        }
        else if (arr[0] == "E")
        {
            if (cnt == 1)
            {
                st->ExitScope();
            }
            else
            {
                cout << space;
                cout << "Wrong number of arugments for the command E" << endl;
            }
        }
        else if (arr[0] == "Q")
        {
            if (cnt == 1)
            {
                delete st;
                return 0;
            }
            else
            {
                cout << space;
                cout << "Wrong number of arugments for the command Q" << endl;
            }
        }
    }
    return 0;
}