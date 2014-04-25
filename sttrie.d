/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

import std.stdio;

final class Table
{
    Node[256] nodes = void;
    
    this()
    {
        nodes[] = Node.none;
    }
}

final class Node
{
    Table table;
    Node parent;
    //~ ubyte offset;
    //~ ubyte[] indexes;
    //~ ubyte parentIndex;
    // termination point
    bool term;
    
    debug static collisions = 0;
    
    this(Table t)
    {
        table = t;
    }
    
    // null object pattern
    static Node none;
    
    static this()
    {
        none = new Node(null);
    }
    
    bool has(const(ubyte)[] data)
    {
        Node sub = table.nodes[data[0]];
        if (sub.parent !is this)
            return false;
        if (data.length == 1)
            return sub.term;
            
        return sub.has(data[1..$]);
    }
    
    void insert(const(ubyte)[] data)
    {
        import std.algorithm : swap;
        Node sub = table.nodes[data[0]];
        
        if (sub is none)
        {
        newNode:
            sub = new Node(table);
            sub.parent = this;
            if (data.length == 1)
                sub.term = true;
            else
                sub.insert(data[1..$]);
                
            table.nodes[data[0]] = sub;
            return;
        }
        if (sub.parent !is this)
        {
            // collision
            debug collisions++;
            auto t = new Table;
            // TODO opt
            foreach (i, ref n; table.nodes)
            {
                if (n.parent is this)
                    swap(n, t.nodes[i]);
            }
            
            table = t;
            assert(table.nodes[data[0]] is none);
            goto newNode;
        }
        // node already exists
        sub.insert(data[1..$]);
    }
}

unittest
{
    import std.string : rep = representation;
    
    auto n = new Node(new Table);
    n.insert("hi".rep);
    assert(n.has("hi".rep));
    assert(!n.has("h".rep));
    n.insert("ho".rep);
    assert(n.has("ho".rep));
    assert(n.has("hi".rep));
    n.insert("ah".rep);
    assert(n.has("ah".rep));
    assert(n.has("hi".rep));
}

