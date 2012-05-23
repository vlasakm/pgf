-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$




--- 
-- Each |Digraph| instance models a \emph{directed, simple}
-- graph. ``Directed'' means that all edges ``point'' from a head node
-- to a tail node. ``Simple'' means that between any nodes there can be
-- (at most) one edge. Since these properties are a bit at odds with
-- the normal behaviour of ``nodes'' and ``edges'' in \tikzname,
-- different names are used for them inside the |model| namespace:
-- The class modeling  ``edges'' is actually called |Arc| to stress
-- that an arc has a specific ``start'' (the tail) and a specific
-- ``end'' (the head). The class modeling ``nodes'' is actually called
-- |Vertex|, just to stress that this is not a direct model of a
-- \tikzname\ |node|, but can represent a arbitrary vertex of a graph,
-- independently of whether it is an actual |node| in \tikzname.
--
--   \medskip
--   \noindent\textbf{Vertices.}
--   Each digraphs stores an array of |vertices|. Internally, this array
--   is an object of type |LookupTable|, but you can mostly treat it as
--   if it were an array. In particular, you can iterate over its
--   elements using |ipairs|, but you may not modify the array; use the
--   |add| and |remove| methods, instead.
--
-- \begin{codeexample}[code only]
-- local g = Digraph.new {}
--
-- g:add { v1, v2 } -- Add vertices v1 and v2
-- g:remove { v2 }  -- Get rid of v2.
--
-- assert (g:contains(v1))
-- assert (not g:contains(v2))
-- \end{codeexample}
--
--   It is important to note that although each digraph stores a
--   |vertices| array, the elements in this array are not exclusive to
--   the digraph: A vertex can be an element of any number of
--   digraphs. Whether or not a vertex is an element of digraph is not
--   stored in the vertex, only in the |vertices| array of the
--   digraph. To test whether a digraph contains a specific node, use the
--   |contains| method, which takes time $O(1)$ to perform the test (this
--   is because, as mentioned earlier, the |vertices| array is actually a
--   |LookupTable| and for each vertex |v| the field |vertices[v]| will
--   be true if, and only if, |v| is an element of the |vertices| array).
--
--   Do not use |pairs(g.vertices)| because this may cause your graph
--   drawing algorithm to produce different outputs on different runs.
--
--   A slightly annoying effect of vertices being able to belong to
--   several graphs at the same time is that the set of arcs incident to
--   a vertex is not a property of the vertex, but rather of the
--   graph. In other words, to get a list of all arcs whose tail is a
--   given vertex |v|, you cannot say something like |v.outgoings| or
--   perhaps |v:getOutgoings()|. Rather, you have to say |g:outgoing(v)|
--   to get this list:
--\begin{codeexample}[code only]
--for _,a in ipairs(g:outgoing(v)) do  -- g is a Digraph object.    
--  pgf.debug ("There is an arc leaving " .. tostring(v) ..
--             " heading to " .. tostring(a.head))
--end
--\end{codeexample}
--   Naturally, there is also a method |g:incoming()|.
--  
--   To iterate over all arcs of a graph you can say:
--\begin{codeexample}[code only]
--for _,v in ipairs(g.vertices) do
--  for _,a in ipairs(g:outgoing(v)) do
--   ...
--  end
--end
--\end{codeexample}
--
--   However, it will often be more convenient and, in case the there
--  are far less arcs than node, also faster to write
-- 
--\begin{codeexample}[code only]
--for _,a in ipairs(g.arcs) do
--  ...
--end
--\end{codeexample}
--
--   \medskip
--   \noindent\textbf{Arcs.}
--   For any two vertices |t| and |h| of a graph, there may or may not be
--   an arc from |t| to |h|. If this is the case, there is an |Arc|
--   object that represents this arc. Note that, since |Digraph|s are
--   always simple graphs, there can be at most one such object for every
--   pair of vertices. However, you can store any information you like in
--   the |Arc|'s |storage|, see the |Storage| class for details. In
--   particular, an |Arc| can store an array of all the multiple edges
--   that are present in the user's input.
--
--   Unlike vertices, the arc objects of a graph are always local to a
--   graph; an |Arc| object can never be part of two digraphs at the same
--   time. For this reason, while for vertices it makes sense to create
--   |Vertex| objects independently of any |Digraph| objects, it is not
--   possible to instantiate an |Arc| directly: only the |Digraph| method
--   |connect| is allowed to create new |Arc| objects and it will return
--   any existing arcs instead of creating new ones, if there is already
--   an arc present between two nodes.
--
--   The |arcs| field of a digraph contains a |LookupTable| of all arc
--   objects present in the |Digraph|. Although you can access this field
--   normally and use it in |ipairs| to iterate over all arcs of a graph,
--   note that this array is actually ``reconstructed lazily'' whenever
--   an arc is deleted from the graph. What happens is the following: As
--   long as you just add arcs to a graph, the |arcs| array gets updated
--   normally. However, when you remove an arc from a graph, the arc does
--   not get removed from the |arcs| array (which would be an expensive
--   operation). Instead, the |arcs| array is invalidated (internally set
--   to |nil|), allowing us to perform a |disconnect| in time
--   $O(1)$. The |arcs| array is then ignored until the next time it is
--   accessed, for instance when a user says |ipairs(g.arcs)|. At this
--   point, the |arcs| array is reconstructed by adding all arcs of all
--   nodes to it.
--
--   The bottom line of the behaviour of the |arcs| field is that (a) the
--   ordering of the elements may change abruptly whenever you remove an
--   arc from a graph and (b) performing $k$ |disconnect| operations in
--   sequence takes time $O(k)$, provided you do not access the |arcs|
--   field between calls.
--  
--   \medskip
--   \noindent\textbf{Creating and Copying Graphs.}
--   Graphs are created using the |new| method, which takes a table of
--   initial values as input (like most |new| methods in the graph
--   drawing engine). It is permissible that this table of initial values
--   has a |vertices| field, in which case this array will be copied. In
--   contrast, an |arcs| field in the table will be ignores -- newly
--   created graphs always have an empty arcs set. This means that
--   writing |Digraph.new(g)| where |g| is a graph creates a new graph
--   whose vertex set is the same as |g|'s, but where there are no edges:%'
--  
--\begin{codeexample}[code only]
--local g = Digraph.new {}
--g:add { v1, v2, v3 }
--g:connect (v1, v2)
--
--local h = Digraph.new (g)
--assert (h:contains(v1))
--assert (not h:arc(v1, v2))
--\end{codeexample}
--
--   To completely copy a graph, including all arcs, you have to write:
--\begin{codeexample}[code only]
--local h = Digraph.new (g)
--for _,a in ipairs(g.arcs) do h:connect(a.tail, a.head) end
--\end{codeexample}
--
--   \medskip
--   \noindent\textbf{Time Bounds.}
--   Since digraphs are constantly created and modified inside the graph
--   drawing engine, some care was taken to ensure that all operations
--   work as quickly as possible. In particular:
--   \begin{itemize}
--   \item Adding an array of $k$ vertices using the |add| method needs
--     time $O(k)$.
--   \item Adding an arc between two vertices needs time $O(1)$.
--   \item Accessing both the |vertices| and the |arcs| fields takes time
--     $O(1)$, provided only the above operations are used.
--   \end{itemize}
--   Deleting vertices and arcs takes more time:
--   \begin{itemize}
--   \item Deleting the vertices given in an array of $k$ vertices from a
--     graph with $n$ vertices takes time $O(\max\{n,c\})$ where $c$ is the
--     number of arcs between the to-be-deleted nodes and the remaining
--     nodes. Note that this time bound in independent of~$k$. In
--     particular, it will be much faster to delete many vertices by once
--     calling the |remove| function instead of calling it repeatedly.
--   \item Deleting an arc takes time $O(t_o+h_i)$ where $t_o$ is the
--     number of outgoing arcs at the arc's tail and $h_i$ is the number
--     of incoming arcs at the arc's head. After a call to |disconnect|,
--     the next use of the |arcs| field will take time $\catcode`\|=12
--     O(|V| + |E|)$, while subsequent accesses take time $O(1)$ -- till the
--     next use of |disconnect|. This means that once you start deleting
--     arcs using |disconnect|, you should perform as many additional
--     |disconnect|s before accessing |arcs| one more.
--   \end{itemize}
--  
--   \medskip
--   \noindent\textbf{Stability.} The |vertices| field and the array
--   returned by |Digraph:incoming| and |Digraph:outgoing| are
--   \emph{stable} in the following sense: The ordering of the elements
--   when you use |ipairs| on the will be the ordering in which the
--   vertices or arcs were added to the graph. Even when you remove a
--   vertex or an arc, the ordering of the remaining elements stays the
--   same. 
--
-- @field vertices is the array of vertices in the graph. 
-- @field arcs is an array of arcs in the graph. 
-- @field syntactic_digraph is a reference to the syntactic digraph
--    from which this graph stems ultimately. This may be a cyclic
--    reference to the graph itself.
-- @field storage is the storage. See the section on |Storage| objects. 
--
local Digraph = {}

local function recalc_arcs (digraph)
  local arcs = {}
  local vertices = digraph.vertices
  local outgoings = digraph.outgoings
  for i=1,#vertices do
    local out = vertices[i].storage[outgoings]
    for j=1,#out do
      arcs[#arcs + 1] = out[j]
    end
  end
  digraph.arcs = arcs
  return arcs    
end

Digraph.__index = 
  function (t, k)
    if k == "arcs" then 
      return recalc_arcs(t)
    else
      return rawget(Digraph,k)
    end
  end



-- Namespace
require("pgf.gd.model").Digraph = Digraph

-- Imports
local Arc     = require "pgf.gd.model.Arc"
local Storage = require "pgf.gd.lib.Storage"






--- Creates a new digraph.
--                
-- A digraph object stores a set of vertices and a set of arcs. The
-- vertices table is both an array (for iteration) as well as a
-- hash-table of node to position mappings. This operation takes time
-- $O(1)$. 
--
-- @param initial A table of initial values. It is permissible that
--                this array contains a |vertices| field. In this
--                case, this field must be an array and its entries
--                must be nodes, which will be inserted. If initial
--                has an arcs field or a storage field, these fields
--                will be ignored.
--                The table must contain a field |syntactic_digraph|,
--                which should normally be the syntactic digraph of
--                the graph, but may also be the string |"self"|, in
--                which case it will be set to the newly created
--                (syntactic) digraph.
--
-- The bottom line is that |Digraph.new(existing_digraph)| will create a
-- new digraph with the same vertex set and the same options as the
-- existing digraph, but without arcs.
-- @return A newly-allocated digraph.
--
function Digraph.new(initial)
  local digraph = {}
  setmetatable(digraph, Digraph)

  if initial then
    for k,v in pairs(initial) do
      digraph [k] = v
    end
  end

  local vertices = digraph.vertices
  digraph.vertices = {}
  digraph.arcs = {}
  digraph.storage = Storage.new() 
  digraph.incomings = {} -- a unique handle for vertices's storage
  digraph.outgoings = {}  -- a unique handle for vertices's storage
  digraph.syntactic_digraph = assert(initial.syntactic_digraph, "no syntactic digraph specified")
  if digraph.syntactic_digraph == "self" then
    digraph.syntactic_digraph = digraph
  end
  
  if vertices then 
    digraph:add(vertices)
  end
  return digraph
end


--- Add vertices to a digraph.
--
-- This operation takes time $O(\#\mathit{array})$.
--
-- @param array An array of to-be-added vertices.
--
function Digraph:add(array)
  local vertices = self.vertices
  local incomings = self.incomings
  local outgoings = self.outgoings
  for i=1,#array do
    local v = array[i]
    if not vertices[v] then
      vertices[v] = true
      vertices[#vertices + 1] = v
      local s = v.storage
      s[incomings] = {}
      s[outgoings] = {}
    end
  end
end


--- Remove vertices from a digraph.
--
-- This operation removes an array of vertices from a graph. The
-- operation takes time linear in the number of vertices, regardless of
-- how many vertices are to be removed. Thus, it will be (much) faster
-- to delete many vertices by first compiling them in an array and to
-- then delete them using one call to this method.
--
-- This operation takes time $O(\max\{\#\mathit{array}, \#\mathit{self.vertices}\})$.
--
-- @param array The to-be-removed vertices.
--
function Digraph:remove(array)
  
  -- Mark all to-be-deleted nodes
  for i=1,#array do
    local v = array[i]
    assert(vertices[v], "to-be-deleted node is not in graph")
    vertices[v] = false
  end
  
  -- Disconnect them
  for i=1,#array do
    self:disconnect(array[i])
  end
  
  LookupTable.remove(self.vertices, array)
end



--- Test, whether a graph contains a given vertex. 
--
-- This operation takes time $O(1)$.
--
-- @param v The vertex to be tested.
--
function Digraph:contains(v)
  return v and self.vertices[v] == true
end




--- Returns the arc between two nodes, provided it exists. Otherwise,
-- nil is retured.
--
-- This operation takes time $O(1)$.
--
-- @param s The tail vertex
-- @param t The head vertex
--
-- @return The arc object connecting them
--
function Digraph:arc(s, t)
  return assert(s.storage[self.outgoings], "tail vertex not in graph")[t]
end



--- Returns an array containg the outgoing arcs of a vertex. You may
-- only iterate over his array using ipairs, not using pairs.
--
--  This operation takes time $O(1)$.
--
-- @param s The vertex
--
-- @return An array of all outgoing arcs of this vertex (all arcs
-- whose tail is the vertex)
--
function Digraph:outgoing(v)
  return assert(v.storage[self.outgoings], "vertex not in graph")
end



---
-- Sorts the array of outgoing arcs of a vertex. This allows you to
-- later iterate over the outgoing arcs in a specific order.
--
-- This operation takes time $O(\#\mathit{outgoing} \log \#\mathit{outgoings})$.
--
-- @param s The vertex
-- @param f A comparison function that is passed to table.sort
--
function Digraph:sortOutgoing(v, f)
  table.sort(assert(v.storage[self.outgoings], "vertex not in graph"), f)
end


---
-- Reorders the array of outgoing arcs of a vertex. The parameter array
-- \emph{must} contain the same set of vertices as the outgoing array,
-- but possibly in a different order.
--
-- This operation takes time $O(\#\mathit{outgoing})$.
--
-- @param s The vertex
-- @param a An array containing the outgoing verticesin some order.
--
function Digraph:orderOutgoing(v, vertices)
  local outgoing = assert (v.storage[self.outgoings], "vertex not in graph")
  assert (#outgoing == #vertices)

  -- Create back hash
  local lookup = {}
  for i=1,#vertices do
    lookup[vertices[i]] = i
  end

  -- Compute ordering of the arcs
  local reordered = {}
  for _,arc in ipairs(outgoing) do
    reordered [lookup[arc.head]] = arc 
  end

  -- Copy back
  for i=1,#outgoing do
    outgoing[i] = assert(reordered[i], "illegal vertex order")
  end
end



--- As outgoing.
--
function Digraph:incoming(v)
  return assert(v.storage[self.incomings], "vertex not in graph")
end


---
-- As sortOutgoing
--
function Digraph:sortIncoming(v, f)
  table.sort(assert(v.storage[self.incomings], "vertex not in graph"), f)
end


---
-- As reorderOutgoing
--
function Digraph:orderIncoming(v, a)
  local incoming = assert (v.storage[self.incomings], "vertex not in graph")
  assert (#incoming == #vertices)

  -- Create back hash
  local lookup = {}
  for i=1,#vertices do
    lookup[vertices[i]] = i
  end

  -- Compute ordering of the arcs
  local reordered = {}
  for _,arc in ipairs(incoming) do
    reordered [lookup[arc.head]] = arc 
  end

  -- Copy back
  for i=1,#incoming do
    incoming[i] = assert(reordered[i], "illegal vertex order")
  end
end





--- Connects two nodes by an arc and returns the arc. If they are
-- already connected, the existing arc is returned. 
--
-- This operation takes time $O(1)$.
--
-- @param s The tail vertex
-- @param t The head vertex (may be identical to s in case of a
--          loop)
--
-- @return The arc object connecting them (either newly created or
--         already existing)
--
function Digraph:connect(s, t, object)
  assert (s and t and self.vertices[s] and self.vertices[t], "trying connect nodes not in graph")

  local s_outgoings = s.storage[self.outgoings]
  local arc = s_outgoings[t]

  if not arc then
    -- Ok, create and insert new arc object
    arc = {
      tail = s,
      head = t,
      storage = Storage.new(),
      syntactic_digraph = self.syntactic_digraph
    }
    setmetatable(arc, Arc)

    -- Insert into outgoings:
    s_outgoings [#s_outgoings + 1] = arc
    s_outgoings [t] = arc

    local t_incomings = t.storage[self.incomings]
    -- Insert into incomings:
    t_incomings [#t_incomings + 1] = arc
    t_incomings [s] = arc

    -- Insert into arcs field, if it exists:
    local arcs = rawget(self, "arcs")
    if arcs then
      arcs[#arcs + 1] = arc
    end
  end

  return arc
end




--- Disconnect either a single vertex from all its neighbors (remove all
-- incoming and outgoing arcs of this vertex) or, in case two nodes
-- are given as parameter, remove the arc between them, if it exsits. 
--
-- This operation takes time $O(\#I_s + \#I_t)$, where $I_x$ is the set
-- of vertices incident to x, to remove the single arc between s and
-- t. For a single vertex x, it takes time $O(\sum_{y: \text{there is some
-- arc between x and y or y and x}} \#I_y)$.
--
-- @param s The single vertex or the tail vertex
-- @param t The head vertex
--
function Digraph:disconnect(v, t)
  if t then
    -- Case 2: Remove a single arc.
    local s_outgoings = assert(v.storage[self.outgoings], "tail node not in graph")
    local t_incomings = assert(t.storage[self.incomings], "head node not in graph")

    if s_outgoings[t] then
      -- Remove:
      s_outgoings[t] = nil
      for i=1,#s_outgoings do
	if s_outgoings[i].head == t then
	  table.remove (s_outgoings, i)
	  break
	end
      end
      t_incomings[v] = nil
      for i=1,#t_incomings do
	if t_incomings[i].tail == v then
	  table.remove (t_incomings, i)
	  break
	end
      end
      self.arcs = nil -- invalidate arcs field
    end
  else
    -- Case 1: Remove all arcs incident to v:
    local v_storage = v_storage
    local self_incomings = self.incomings
    local self_outgoings = self.outgoings
    
    -- Step 1: Delete all incomings arcs:
    local incomings = assert(v_storage[self_incomings], "node not in graph")
    local vertices = self.vertices

    for i=1,#incomings do
      local s = incomings[i].tail
      if s ~= v and vertices[s] then -- skip self-loop and to-be-deleted nodes
	-- Remove this arc from s:
	local s_outgoings = s.storage[self_outgoings]
	s_outgoings[v] = nil
	for i=1,#s_outgoings do
	  if s_outgoings[i].head == v then
	    table.remove (s_outgoings, i)
	    break
	  end
	end
      end
    end

    -- Step 2: Delete all outgoings arcs:
    local outgoings = v_storage[self_outgoings]
    for i=1,#outgoings do
      local t = outgoings[i].head
      if t ~= v and vertices[t] then
	local t_incomings = t.storage[self_incomings]
	t_incomings[v] = nil
	for i=1,#t_incomings do
	  if t_incomings[i].tail == v then
	    table.remove (t_incomings, i)
	    break
	  end
	end
      end
    end

    if #incomings > 0 or #outgoings > 0 then
      self.arcs = nil -- invalidate arcs field
    end

    -- Step 3: Reset incomings and outgoings fields
    v_storage[self_incomings] = {}
    v_storage[self_outgoings] = {}
  end
end




--- Reconnect: An arc is changed so that instead of connecting a.tail
-- and a.head, it now connects a new head and tail. The difference to
-- first disconnecting and then reconnecting is that all fields of the
-- arc (other than head and tail, of course), will be "moved
-- along". Also, all fields of the storage will be
-- copied. Reconnecting and arc in the same way as before has no
-- effect.
--
-- If there is already an arc at the new position, field of the
-- to-be-reconnected arc overwrite fields of the original arc. This is
-- especially dangerous with a syntactic digraph, so do not reconnect
-- arcs of the syntactic digraph (which you should not do anyway).
--
-- The arc object may no longer be valid after a reconnect, but the
-- operation returns the new arc object.
--
-- This operation needs the time of a disconnect (if necessary)
--
-- @param arc The original arc object
-- @param tail The new tail vertex
-- @param head The new head vertex
--
-- @return The new arc object connecting them (either newly created or
--         already existing)
--
function Digraph:reconnect(arc, tail, head)
  assert (arc and tail and head, "connect with nil parameters")
  
  if arc.head == head and arc.tail == tail then
    -- Nothing to be done
    return arc
  else
    local new_arc = self:connect(tail, head)
    
    for k,v in pairs(arc) do
      if k ~= "head" and k ~= "tail" and k ~= "storage" then
	new_arc[k] = v
      end
    end

    for k,v in pairs(arc.storage) do
      new_arc.storage[k] = v
    end

    -- Remove old arc:
    self:diconnect(arc.tail, arc.head)

    return new_arc
  end
end





--- Returns a string representation of this graph including all nodes and edges.
--
-- @return Digraph as string.
--
function Digraph:__tostring()
  local vstrings = {}
  local astrings = {}
  for i,v in ipairs(self.vertices) do
    vstrings[i] = "    " .. tostring(v) .. "[x=" .. math.floor(v.pos.x) .. "pt,y=" .. math.floor(v.pos.y) .. "pt]"
    local out_arcs = v.storage[self.outgoings]
    if #out_arcs > 0 then
      local t = {}
      for j,a in ipairs(out_arcs) do
	t[j] = tostring(a.head) 
      end
      astrings[#astrings + 1] = "  " .. tostring(v) .. " -> { " .. table.concat(t,", ") .. " }"
    end
  end
  return "graph [id=" .. tostring(self.vertices) .. "] {\n  {\n" ..
    table.concat(vstrings, ",\n") .. "\n  }; \n" .. 
    table.concat(astrings, ";\n") .. "\n}";
end




-- Done

return Digraph