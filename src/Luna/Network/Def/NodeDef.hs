---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Luna.Network.Def.NodeDef(
    NodeDef(..),
    ID,

    empty,

    noImports,
    noPorts
) where

import           Luna.Type.Type             (Type)
import qualified Luna.Lib.Library         as Library
import           Luna.Network.Graph.Graph   (Graph)
import qualified Luna.Network.Graph.Graph as Graph
import qualified Luna.Network.Flags       as Flags
import           Luna.Network.Flags         (Flags)
import qualified Luna.Network.Attributes  as Attributes
import           Luna.Network.Attributes    (Attributes)


data NodeDef = NotLoaded
             | NodeDef {
                   cls        :: Type,
                   imports    :: [String],
                   graph      :: Graph,
                   flags      :: Flags, 
                   attributes :: Attributes,
                   libID      :: Library.ID
               } deriving (Show)

type ID   = Int

empty :: Type -> Library.ID -> NodeDef
empty t lib = NodeDef t noImports Graph.empty Flags.empty Attributes.empty lib

noImports :: [String]
noImports = []

noPorts :: [String]
noPorts = []

------------------------- INSTANCES -------------------------

--instance Serialize NodeDef where
--  put i = Serialize.put (inputs i, outputs i, imports i, graph i, libID i)
--  get   = do
--            (inputs', outputs', imports', graph', libID') <- Serialize.get
--            return $ NodeDef inputs' outputs' imports' graph' libID'