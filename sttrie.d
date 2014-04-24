/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

import std.stdio;

final class Table
{
    // TODO: null object pattern?
    Node[256] nodes;
}

final class Node
{
    Table table;
    Node parent;
    //~ ubyte offset;
    //~ ubyte[] indexes;
    //~ ubyte parentIndex;
    static collisions = 0;
    
    this(Table t)
    {
        table = t;
    }
    
    bool has(const(ubyte)[] data)
    {
        Node sub = table.nodes[data[0]];
        return sub && sub.parent is this &&
            (data.length == 1 || sub.has(data[1..$]));
    }
    
    void insert(const(ubyte)[] data)
    {
        Node sub = table.nodes[data[0]];
        if (!sub)
        {
            sub = new Node(table);
            sub.parent = this;
            data.length == 1 || sub.insert(data[1..$]);
            table.nodes[data[0]] = sub;
            return;
        }
        if (sub.parent !is this)
        {
            // collision
            debug collisions++;
            auto t = new Table;
            // TODO opt
            t.nodes = table.nodes;
            sub = table.nodes[data[0]];
            // overwrite slot
        }
        sub.insert(data[1..$]);
    }
}

unittest
{
    import std.string : rep = representation;
    
    auto n = new Node(new Table);
    n.insert("hi".rep);
    assert(n.has("hi".rep));
    n.insert("ho".rep);
    assert(n.has("ho".rep));
    assert(n.has("hi".rep));
}

