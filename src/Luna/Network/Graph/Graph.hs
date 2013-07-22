---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Luna.Network.Graph.Graph(
    Graph(..),
    empty,

    --insFreshNode, 
    add,        addMany, 
    delete,     deleteMany,
    connect,    connectMany,
    disconnect, disconnectMany,

    lnodeById, nodeById, 

    childrenByName,
    typeByName, callByName, classByName, packageByName, functionsByName
) where


import qualified Data.Graph.Inductive    as DG
import qualified Data.Map                as Map
import           Data.Map                  (Map)

import qualified Luna.Common.Graph       as CommonG
import           Luna.Data.List            (foldri)
import           Luna.Network.Graph.Edge   (Edge)
import qualified Luna.Network.Graph.Node as Node
import           Luna.Network.Graph.Node   (Node)


data Graph = Graph {
    repr      :: DG.Gr Node Edge,
    children  :: Map String DG.Node,
    types     :: Map String DG.Node,
    calls     :: Map String DG.Node,
    classes   :: Map String DG.Node,
    functions :: Map String DG.Node,
    packages  :: Map String DG.Node
} deriving (Show)


empty :: Graph
empty = Graph DG.empty Map.empty Map.empty Map.empty Map.empty Map.empty Map.empty

------------------------- EDITION ---------------------------

addMany :: [DG.LNode Node] -> Graph -> Graph
addMany = foldri add

add :: DG.LNode Node -> Graph -> Graph
add lnode@(nid, node) graph =
    let 
        newgraph                 = graph{repr=DG.insNode lnode $ repr graph}
        updateNodeMap            = Map.insert (Node.name node) nid
        updateNodeMultiMap       = Map.insert (Node.name node) nid
        updatechildrenMap graph' = graph'{children=updateNodeMultiMap $ children graph'}
    in case node of
        Node.TypeNode _ _ _ -> updatechildrenMap newgraph{types     = updateNodeMap      $ types graph     }
        Node.CallNode _ _ _ -> updatechildrenMap newgraph{calls     = updateNodeMap      $ calls graph     }
        Node.ClassNode    _ -> updatechildrenMap newgraph{classes   = updateNodeMap      $ classes graph   }
        Node.FunctionNode _ -> updatechildrenMap newgraph{functions = updateNodeMultiMap $ functions graph }
        Node.PackageNode  _ -> updatechildrenMap newgraph{packages  = updateNodeMap      $ packages graph  }
        _                   -> newgraph

-- deprecated
freshNodeID :: Graph -> Int 
freshNodeID gr = case DG.nodes $ repr gr of
                   []       -> 0
                   nodeList -> 1 + maximum nodeList

-- deprecated
insFreshNode :: Node -> Graph -> Graph
insFreshNode node gr = add ((freshNodeID gr), node) gr 


deleteMany :: [DG.Node] -> Graph -> Graph
deleteMany = foldri delete

delete :: DG.Node -> Graph -> Graph
delete id_ graph =
    let
        newgraph                 = graph{repr=DG.delNode id_ $ repr graph }
        (_, node)                = DG.labNode' $ DG.context (repr graph) id_
        updateNodeMap            = Map.delete      (Node.name node)
        updatechildrenMap graph' = newgraph{children=updateNodeMap $ children graph'}
    in case node of
        Node.TypeNode _ _ _ -> updatechildrenMap newgraph{types     = updateNodeMap      $ types graph}
        Node.CallNode _ _ _ -> updatechildrenMap newgraph{calls     = updateNodeMap      $ calls graph}
        Node.ClassNode    _ -> updatechildrenMap newgraph{classes   = updateNodeMap      $ classes graph}
        Node.FunctionNode _ -> updatechildrenMap newgraph{functions = updateNodeMap $ functions graph}
        Node.PackageNode  _ -> updatechildrenMap newgraph{packages  = updateNodeMap      $ packages graph}
        _                     -> newgraph


connectMany :: [DG.LEdge Edge] -> Graph -> Graph
connectMany = foldri connect 

connect :: DG.LEdge Edge -> Graph -> Graph
connect ledge graph = graph{repr = DG.insEdge ledge $ repr graph}


disconnectMany :: [DG.Edge] -> Graph -> Graph
disconnectMany = foldri disconnect 

disconnect :: DG.Edge -> Graph -> Graph
disconnect edge graph = graph{repr = DG.delEdge edge $ repr graph}

------------------------- GETTERS ---------------------------

lnodeById :: Graph -> DG.Node -> DG.LNode Node
lnodeById graph nid = CommonG.lnodeById (repr graph) nid

nodeById :: Graph -> DG.Node -> Node
nodeById graph nid = CommonG.nodeById (repr graph) nid

nodeByNameFrom :: Ord k => (Graph -> Map.Map k DG.Node) -> k -> Graph -> Maybe Node
nodeByNameFrom getter name graph = 
    case Map.lookup name $ getter graph of
        Just id_ -> Just(nodeById graph id_)
        Nothing  -> Nothing

childrenByName :: String -> Graph -> Maybe Node
childrenByName = nodeByNameFrom children

typeByName :: String -> Graph -> Maybe Node
typeByName      = nodeByNameFrom  types

callByName :: String -> Graph -> Maybe Node
callByName      = nodeByNameFrom  calls

classByName :: String -> Graph -> Maybe Node
classByName     = nodeByNameFrom  classes

packageByName :: String -> Graph -> Maybe Node
packageByName   = nodeByNameFrom  packages

functionsByName :: String -> Graph -> Maybe Node
functionsByName = nodeByNameFrom functions

------------------------- INSTANCES -------------------------

--instance Serialize Graph where
--  put i = Serialize.put (repr i, children i, types i, calls i, classes i, functions i, packages i)
--  get   = do 
--            (repr', children', types', calls', classes', functions', packages') <- Serialize.get
--            return $ Graph repr' children' types' calls' classes' functions' packages'


--instance (Serialize a, Serialize b) => Serialize (DG.Gr a b) where
--  put i = Serialize.put (DG.labNodes i, DG.labEdges i)
--  get = do
--          (nd, edg) <- Serialize.get
--          return $ DG.mkGraph nd edg


---- FIXME[wd] move the following instance to the right place
--instance (Show k, Show a) => Show (MultiMap k a) where
--    show a = show $ MultiMap.toMap a