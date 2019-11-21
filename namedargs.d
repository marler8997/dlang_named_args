#!/usr/bin/env rund
import std.stdio;
import std.traits : Parameters, ParameterIdentifierTuple, fullyQualifiedName, isCallable;
import std.typecons : tuple;
import std.meta : AliasSeq;

void noargs() { }
void foo(bool log)
{
    writefln("called foo: log=%s", log);
}
void foo2(bool log1, bool log2)
{
    writefln("called foo2: log1=%s log2=%s", log1, log2);
}

template FunctionArgInfoHelper(string funcName, string name, uint index, alias Names, Types...)
{
    static if (Names.length == 0)
        static assert(0, "function '" ~ funcName ~ "' does not have an argument named: " ~ name);
    else static if (Names[0] == name)
        alias FunctionArgInfoHelper = AliasSeq!(Types[0], index);
    else
        alias FunctionArgInfoHelper = FunctionArgInfoHelper!(funcName, name, index + 1, tuple(Names[1..$]), Types[1..$]);
}
template FunctionArgInfo(alias Func, string name)
{
    enum FuncName = fullyQualifiedName!Func;
    static if(isCallable!Func)
    {
        alias FunctionArgInfo = FunctionArgInfoHelper!(FuncName, name, 0,
            tuple(ParameterIdentifierTuple!Func), Parameters!Func);
    } else static assert(0, "alias '" ~ FuncName ~ "' is not a function");
}

static struct NamedArgCall(alias Func)
{
    Parameters!Func args;
    auto ref opDispatch(string name)(FunctionArgInfo!(Func, name)[0] arg)
    {
        pragma(inline, true);
        args[FunctionArgInfo!(Func, name)[1]] = arg;
        return this;
    }
}

auto narg(alias Func)()
{
    return NamedArgCall!Func();
}

auto narg2(alias Func, alias callBuilder)()
{
    NamedArgCall!Func call;
    callBuilder(&call);
    return Func(call.args);
}

void main()
{
    foo(false);
    foo(true);
    //foo.na.log(true);
    writefln("%s", typeid(FunctionArgInfo!(foo, "log")[0]));
    writefln("%s", typeid(FunctionArgInfo!(foo2, "log1")[0]));
    writefln("%s", typeid(FunctionArgInfo!(foo2, "log2")[0]));
    //writefln("%s", typeid(FunctionArgInfo!(foo, "log2")[0]));
    //int x;
    //FunctionArgInfo!(x, "log");
    narg!foo.log(true);
    narg!foo.log(false);
    narg2!(foo, c => c.log(true));
}
