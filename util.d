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


/// Runs destructor and frees memory.
auto delete_(Object obj) @system
{
	destroy(obj);
	.delete_(cast(void*)obj);
}

/// ditto
auto delete_(T)(T* ptr) @system
{
	static if (is(T == struct))
		destroy(*ptr);
	import core.memory;
	GC.free(ptr);
}

///
@system unittest
{
	int j;
	class C
	{
		~this(){j = 3;}
	}
	delete_(new C);
	assert(j == 3);
	
	struct S
	{
		~this(){j = 7;}
	}
	delete_(new S);
	assert(j == 7);
}

// TODO: frameArray, Set, staticArray
