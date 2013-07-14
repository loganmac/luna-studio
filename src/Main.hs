---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

--import Control.Monad.State
--import Data.Graph.Inductive.Tree
--import Data.Graph.Inductive.Monad
--import Data.Graph.Inductive.Monad.IOArray

import qualified Luna.DefManager as DefManager
import           Luna.DefManager            (DefManager)
import qualified Luna.Graph as Graph
import qualified Luna.Node                as Node
import           Luna.Node                  (Node)
import qualified Luna.NodeDef             as NodeDef
import qualified Luna.Samples             as Samples
import qualified Luna.Tools.CodeGenerator as CG
import qualified Luna.Tools.Graphviz      as Graphviz
import qualified Luna.Tools.TypeChecker as TC

--import Text.Show.Pretty
--import Text.Groom

main :: IO ()
main = do 
        let 
                (node, manager) = Samples.sample_helloWorld
                nodeDef = Node.def node
                graph = NodeDef.graph nodeDef
        Graphviz.showGraph graph
        print $ show $ TC.typeCheck graph manager
        showCode node manager
        return ()

showCode :: Node -> DefManager -> IO ()
showCode node manager = putStrLn $ CG.generateCode node manager

