/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

// TODO test with UTF

import std.array : empty;
import std.algorithm : find;

//~ version = Simple;

version(Simple)
T[] subString(T)(T[] haystack, T[] needle)
{
    if (needle.empty)
        return haystack;
    const first = needle[0];

match:
    haystack = find(haystack, first);
    if (haystack.length < needle.length)
        return [];
    // test remainder
    if (haystack[1..needle.length] == needle[1..$])
        return haystack;
    // try again
    haystack = haystack[1..$];
    goto match;
}
else
T[] subString(T)(T[] haystack, T[] needle)
{
    if (needle.empty)
        return haystack;
    const first = needle[0];

find_first:
    haystack = find(haystack, first);
match_tail:
    if (haystack.length < needle.length)
        return [];
        
    // index of next potential match start in haystack
    size_t nextFirst = 0;
    // skip first char
    foreach (i; 1..needle.length)
    {
        const e = haystack[i];
        // remember next match start
        if (!nextFirst && e == first)
            nextFirst = i;
        if (e != needle[i])
        {
            // match failed
            if (nextFirst)
            {
                haystack = haystack[nextFirst..$];
                goto match_tail;
            }
            // No next match found, we can skip all tested chars.
            // We also know haystack[i] != first.
            haystack = haystack[i+1..$];
            goto find_first;
        }
    }
    // match found
    return haystack;
}

unittest
{
    assert(subString("gogot", "got") == "got");
    assert(subString("gogotw", "got") == "gotw");
    assert(subString("gotw", "got") == "gotw");
    assert(subString("got", "got") == "got");
    assert(subString("go", "got").empty);
    
    assert(find("asd", "") == "asd");
    assert(subString("asd", "") == "asd");
}

