/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

import std.range;
import std.algorithm;

// TODO check no bugs because of UTF front != h[0]

version(Simple)
T[] subString(T)(T[] haystack, T[] needle)
{
    assert(!needle.empty);
    haystack = find(haystack, needle[0]);
    if (haystack.length < needle.length)
        return [];
        
    if (haystack[0..needle.length] == needle)
        return haystack;
    else
        return subString(haystack[1..$], needle);
}

T[] subString(T)(T[] haystack, T[] needle)
{
    assert(!needle.empty);
    const first = needle[0];
    haystack = find(haystack, first);

match_tail:
    if (haystack.length < needle.length)
        return [];
        
    // next first char
    size_t nf = 0;
    // skip haystack[0] == first
    foreach (i; 1..needle.length)
    {
        const e = haystack[i];
        // remember next first char past 0
        if (!nf && e == first)
            nf = i;
        if (e != needle[i])
        {
            // match failed
            if (nf)
            {
                haystack = haystack[nf..$];
                goto match_tail;
            }
            // no next first char found past 0, can skip tested chars.
            // we also know haystack[i] != first
            return subString(haystack[i+1..$], needle);
        }
    }
    // match found
    return haystack[0..$];
}

unittest
{
    assert(subString("gogot", "got") == "got");
    assert(subString("gogotw", "got") == "gotw");
    assert(subString("gotw", "got") == "gotw");
    assert(subString("got", "got") == "got");
    assert(subString("go", "got").empty);
    
    assert(find("asd", "") == "asd");
    // FIXME
    //~ assert(subString("asd", "") == "asd");
}

