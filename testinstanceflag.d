/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <"%s@%s.org".format("nick", "geany")>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

// from std.meta
private template isSame(ab...)
    if (ab.length == 2)
{
    static if (__traits(compiles, expectType!(ab[0]),
                                  expectType!(ab[1])))
    {
        enum isSame = is(ab[0] == ab[1]);
    }
    else static if (!__traits(compiles, expectType!(ab[0])) &&
                    !__traits(compiles, expectType!(ab[1])) &&
                     __traits(compiles, expectBool!(ab[0] == ab[1])))
    {
        static if (!__traits(compiles, &ab[0]) ||
                   !__traits(compiles, &ab[1]))
            enum isSame = (ab[0] == ab[1]);
        else
            enum isSame = __traits(isSame, ab[0], ab[1]);
    }
    else
    {
        enum isSame = __traits(isSame, ab[0], ab[1]);
    }
}
private template expectType(T) {}
private template expectBool(bool b) {}

///
template testInstanceFlag(alias Template, Args...)
{
	import std.traits : TemplateArgsOf;
	import util : isVersion;
	
	private enum testInstanceFlag =
		isVersion!"unittest" && isSame!(TemplateArgsOf!Template, Args);
	
	static if (!testInstanceFlag)
	unittest {
		// Ensure instantiation with specific test arguments
		alias TestInstance = Template!Args;
	}
}

///
@safe unittest 
{
	///
	struct S(T)
	{
		private enum ut = testInstanceFlag!(S, int);
		
		///
		static myDocumentedSymbol(){}
		
		/// Example
		static if (ut) unittest {
			S.myDocumentedSymbol();
			assert(0 == 1);
		}
	}

	S!char s; // S!char indirectly invokes static if unittest for S!int
}
