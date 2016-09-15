/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/** Useful small utilities, mostly one-liners.
 *
 * Functions:
 * $(LREF apply)
 * $(LREF assumeUnique)
 * $(LREF delete_)
 * $(LREF deref)
 * $(LREF frameArray)
 * $(LREF staticArray)
 * $(LREF staticEx)
 *
 * Types:
 * $(LREF StaticArray)
 *
 * Templates:
 * $(LREF Apply)
 * $(LREF isVersion)
 *
 * Macros:
 * LREF=<a href="#$1">$1</a>
 */
module util;

@safe:

/// See_Also: std.exception.assumeUnique.
immutable(T)* assumeUnique(T)(T* ptr) @system
{
    return cast(typeof(return))ptr;
}

@system unittest
{
    char[] arr = "hi".dup;
    immutable(char)* s = arr.ptr.assumeUnique;
    assert(s[0..2] == arr);
}


/** Checks if a particular version is defined globally.
 * Author: Tomek Sowiński
 */
enum bool isVersion(string ver) = !is(typeof({
          mixin("version(" ~ ver ~ ") static assert(0);");
    }));

///
unittest
{
    static assert(isVersion!"assert");
    static assert(!isVersion!"Broken");

    import std.meta;
    alias allVersions = ApplyLeft!(allSatisfy, isVersion);
    static assert(allVersions!("assert", "unittest"));

    alias anyVersions = ApplyLeft!(anySatisfy, isVersion);
    static assert(!anyVersions!("Broken", "Unsafe"));
}


// See: undocumented std.meta.Instantiate;
/**
 * Instantiates the given template with the supplied list of arguments.
 *
 * Used to work around syntactic limitations of D with regard to instantiating
 * a template from an alias sequence (e.g. `Seq[0]!(Args)` is not valid) or a template
 * returning another template (e.g. `Foo!(Bar)!(Args)` is not allowed).
 */
alias Apply(alias Template, Args...) = Template!Args;

///
unittest
{
    import std.meta : Alias, AliasSeq;
    enum size(T) = T.sizeof;

    alias Seq = AliasSeq!size;
    // enum s1 = Seq[0]!byte; // error: semicolon expected, not '!'
    enum s1 = Apply!(Seq[0], byte);
    static assert(s1 == 1);

    // enum s2 = Alias!size!byte; // error: multiple ! arguments not allowed
    enum s2 = Apply!(Alias!size, wchar);
    static assert(s2 == 2);
}


/** Calls `fun`.
 * Useful in UFCS chains when a function result should be used more than once,
 * or as a function argument other than the first.
 */
alias apply(alias fun) = fun;

///
unittest
{
    import std.range;

    auto str = "hem".dropBackOne.apply!(s => s ~ s);
    assert(str == "hehe");

    str = "Jon".dropOne.apply!(s => "go" ~ s);
    assert(str == "goon");
}


/** Runs destructor and frees memory.
 * Sets argument to null for safety.
 */
auto delete_(C:Object)(ref C obj) @system
{
    destroy(obj);
    import core.memory;
    GC.free(cast(void*)obj);
    obj = null;
}

/// ditto
auto delete_(T)(ref T* ptr) @system
{
    import std.traits;
    static if (hasElaborateDestructor!T)
        destroy(*ptr);
    import core.memory;
    GC.free(ptr);
    ptr = null;
}

///
unittest
{
    int j;
    class C
    {
        ~this(){j = 3;}
    }
    auto c = new C;
    ()@trusted {delete_(c);}();
    assert(j == 3);
    assert(c is null);

    struct S
    {
        ~this(){j++;}
    }
    auto s = new S;
    ()@trusted {delete_(s);}();
    assert(j == 4);
    assert(s is null);

    auto sa = new StaticArray!(S, 3);
    ()@trusted {delete_(sa);}();
    assert(sa is null);
    assert(j == 7);
}


/// Dereferences ptr. Helps to avoid bracket nesting.
ref deref(T)(T* ptr){
    return *ptr;
}

///
@system unittest
{
    int i;
    auto p = &i;
    ++*p;
    assert(i == 1);
    p.deref *= 2;   // post op without brackets
    assert(i == 2);

    import std.stdio;
    p.deref.writeln;    // use in UFCS chains

    i = deref([0, 3].ptr + 1);  // less syntax noise for more complicated expressions
    assert(i == 3);
}


import core.stdc.stdlib : alloca;

/** Dynamically allocates array memory on the caller's stack frame.
 * Warning: Memory is uninitialized. */
T[] frameArray(T, alias size)(void* ptr = alloca(T.sizeof * size)) @system
{
    auto pa = cast(T*)ptr;
    return pa[0..size];
}

///
@system unittest
{
    auto size = 1;
    size++;
    auto s = frameArray!(int, size);
    s[] = [3, 4];
    assert(s == [3, 4]);
}


/**
 * Interprets an array literal as a static array.
 *
 * Params:
 *      arr = Array literal.
 *
 * Returns: A static array of size `arr.length`.
 *
 * Warning:
 * Do not initialize a dynamic array with a static array literal.
 * The dynamic array slice would point to stack memory no longer in use.
 * Instead define the static array first using type inference (or `int[4]`).
 * ---
 * int[] invalid = [1,2,3,4].staticArray; // Wrong
 * ---
 * The compiler $(I should) prevent this in `@safe` code once
 * $(LINK2 http://issues.dlang.org/show_bug.cgi?id=12625, Issue 12625)
 * is implemented.
 * Author: Ryan Roden-Corrent (rcorre)
 */
pragma(inline, true)
@nogc T[n] staticArray(T, size_t n)(T[n] arr)
{
    return arr;
}

/// Array size and type can be inferred:
@safe @nogc pure nothrow unittest
{
    auto arr = [1,2,3,4].staticArray;
    static assert(is(typeof(arr) == int[4])); // arr is a static array
    assert(arr == [1,2,3,4]);
}

// dmd doesn't support inference of n, but not T for staticArray!immutable
// http://issues.dlang.org/show_bug.cgi?id=15890
/// The element type can also be supplied:
@safe @nogc pure nothrow unittest
{
    auto arr = [1,2].staticArray!(immutable int, 2);
    static assert(is(typeof(arr) == immutable(int)[2]));
    assert(arr == [1,2].staticArray);
}


/// Allows construction of a static array with `new`.
struct StaticArray(T, size_t n)
{
    private T[n] data;
    alias data this;
}

///
unittest
{
    // Can't use new to make a static array
    static assert(is(typeof(new int[2]) == int[]));

    auto p = new StaticArray!(int, 2);
    // ref sa = *p;
    ref sa() @property return {return *p;}
    sa[1] = 6;
    sa[0] = sa[1];
    assert(sa[0] == 6);
    ()@trusted {delete_(p);}();
}


/// Statically construct `Throwable(args, file, line)`.
template staticEx(T:Throwable, args...)
{
    ///
    // Note: scoped not @nogc
    const(T) staticEx(string file = __FILE__, size_t line = __LINE__)() @trusted //@nogc
    {
        import std.typecons : scoped;
        alias SE = typeof(scoped!T(args));
        // Note: druntime may modify exceptions in flight so don't use immutable storage
        static se = SE.init;
        se = scoped!T(args, file, line);
        return se;
    }
}

/// ditto
alias staticEx(string msg, string file = __FILE__, size_t line = __LINE__) =
    Apply!(.staticEx!(Exception, msg), file, line);

///
//@nogc
@safe unittest
{
    import std.exception;
    assert(collectExceptionMsg({throw staticEx!"hi";}()) == "hi");
}

///
//@nogc (assertThrown)
@safe unittest
{
    import std.conv, std.exception;
    assertThrown!ConvException({throw staticEx!(ConvException, "");}());
}


// TODO: frameArray, Set
