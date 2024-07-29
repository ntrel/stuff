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

/// See_Also: std.exception.assumeUnique for array version.
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


import core.stdc.stdlib : alloca;

/** Dynamically allocates array memory on the caller's stack frame.
 * Warning: Memory is uninitialized. */
T[] frameArray(T, alias size)(return void* ptr = alloca(T.sizeof * size)) @system
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
    import core.memory;
    ()@trusted {__delete(p);}();
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


/// Enforce a dynamic cast, disallowing const cast removal
D derived(D, B : Object)(B base)
if (is(D : B) && !__traits(compiles, base.opCast!D))
{
    // TODO disallow extern(C++) class
    return cast(D)base;
}

static assert(!__traits(compiles, derived!Exception(new const Object)));

///
unittest
{
    alias E = Exception;
    Object o = new E("hi");
    E e = o.derived!E;
    assert(e.msg == "hi");
}

// TODO: Set
