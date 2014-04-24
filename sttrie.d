/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

import std.stdio;

final class Table
{
    Node[256] nodes;
}

final class Node
{
    Table table;
    Node parent;
    //~ ubyte offset;
    //~ ubyte[] indexes;
    //~ ubyte parentIndex;
    
    bool has(ubyte[] data)
    {
        Node sub = table.nodes[data[0]];
        return sub && sub.parent is this &&
            (data.length == 1 || sub.has(data[1..$]));
    }
    
    void insert(ubyte[] data)
    {
        Node sub = table.nodes[data[0]];
        if (!sub)
        {
            sub = new Node;
            sub.table = table;
            sub.parent = this;
            data.length == 1 || sub.insert(data[1..$]);
            table.nodes[data[0]] = sub;
            return;
        }
        if (sub.parent !is this)
        {
            //TODO collision
            return;
        }
        sub.insert(data[1..$]);
    }
}

void main(string[] args)
{
    
}

