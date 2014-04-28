/* Written in the D programming language.
 * Copyright: 2012 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/


import std.stdio;

template Flag(string name) {
    enum Flag : bool
    {
        no = false,
        yes = true
    }
}

struct FlagValue(string name)
{
    alias Flag!name.yes this;
    //~ Flag!name opCast()
    //~ {
        //~ return Flag!name.yes;
    //~ }
    //~ enum bool opCast = Flag!name.yes;
    
    /* opCast!bool can only return a bool, not a Flag, so instead
     * we use the bitwise complement operator. */
    template opUnary(string op: "~")
    {
        enum opUnary = Flag!name.no;
    }
}

struct FlagName
{
    template opDispatch(string name)
    {
        enum opDispatch = FlagValue!name();
    }
}

FlagName flag;

void main(string[] args)
{
    void test(Flag!"fill" fill = flag.fill)
    {
        writeln(fill ? true : false);
        //~ writeln(fill == true ? true : false); // not allowed
    }
    test();
    test(flag.fill);
    //~ test(true); // error
    //~ test(!flag.fill); // not allowed
    //~ test(~flag.fill);
        
    //~ void ct(Flag!"expand" e = flag.expand)()
    //~ {
        //~ writeln(cast(bool)e);
    //~ }
    //~ writeln();
    //~ ct!()();
    //~ ct!(flag.expand)();
    //~ ct!(~flag.expand)();
    //~ ct!false();

    // no conflict with global flag
    int flag = 7;
    writeln(flag);
}

