module Empire.Commands.Typecheck where

import           Prologue
import           Control.Monad.State
import           Unsafe.Coerce           (unsafeCoerce)
import           Control.Monad.Error     (throwError)
import           Control.Monad           (forM, forM_)
import           Data.IntMap             (IntMap)
import qualified Data.IntMap             as IntMap
import qualified Data.Map                as Map
import           Data.Maybe              (isNothing, fromMaybe)

import qualified Empire.Data.Graph       as Graph
import           Empire.Data.Graph       (Graph)

import           Empire.API.Data.Node              (NodeId)
import           Empire.API.Data.DefaultValue      (Value (..))
import           Empire.API.Data.GraphLocation     (GraphLocation (..))
import qualified Empire.API.Graph.NodeResultUpdate as NodeResult

import           Empire.Empire
import qualified Empire.Commands.AST          as AST
import qualified Empire.Commands.GraphUtils   as GraphUtils
import qualified Empire.Commands.GraphBuilder as GraphBuilder
import qualified Empire.Commands.Publisher    as Publisher

import qualified Luna.Library.Standard                           as StdLib
import qualified Luna.Library.Symbol.Class                       as Symbol
import qualified Luna.Compilation.Stage.TypeCheck                as TypeCheck
import qualified Luna.Compilation.Stage.TypeCheck.Class          as TypeCheckState
import           Luna.Compilation.Stage.TypeCheck                (Loop (..), Sequence (..))
import           Luna.Compilation.Pass.Inference.Literals        (LiteralsPass (..))
import           Luna.Compilation.Pass.Inference.Struct          (StructuralInferencePass (..))
import           Luna.Compilation.Pass.Inference.Unification     (UnificationPass (..))
import           Luna.Compilation.Pass.Inference.Calling         (FunctionCallingPass (..))
import           Luna.Compilation.Pass.Inference.Importing       (SymbolImportingPass (..))
import           Luna.Compilation.Pass.Inference.Scan            (ScanPass (..))

import qualified Luna.Compilation.Pass.Interpreter.Interpreter   as Interpreter

import qualified Empire.ASTOp as ASTOp
import           Empire.Data.AST                                 (AST, NodeRef)

getNodeValue :: NodeId -> Command Graph (Maybe Value)
getNodeValue nid = do
    ref <- GraphUtils.getASTTarget nid
    zoom Graph.ast $ AST.getNodeValue ref

collect pass = do --return ()
    putStrLn $ "After pass: " <> pass
    st <- TypeCheckState.get
    putStrLn $ "State is: " <> show st

runTC :: Command Graph ()
runTC = do
    allNodeIds <- uses Graph.nodeMapping IntMap.keys
    roots <- mapM GraphUtils.getASTPointer allNodeIds
    ast   <- use Graph.ast
    (_, g) <- TypeCheck.runT $ flip ASTOp.runGraph ast $ do
        Symbol.loadFunctions StdLib.symbols
        TypeCheckState.modify_ $ (TypeCheckState.freshRoots .~ roots)
        let seq3 a b c = Sequence a $ Sequence b c
        let tc = Sequence (seq3 ScanPass LiteralsPass StructuralInferencePass)
               $ Loop $ seq3 SymbolImportingPass (Loop UnificationPass) FunctionCallingPass

        TypeCheck.runTCWithArtifacts tc collect
    Graph.ast .= g
    return ()

runInterpreter :: Command Graph ()
runInterpreter = do
    allNodeIds <- uses Graph.nodeMapping IntMap.keys
    evals      <- mapM GraphUtils.getASTTarget allNodeIds
    ast        <- use Graph.ast
    newAst     <- liftIO $ fmap snd $ flip ASTOp.runBuilder ast $ Interpreter.run evals
    Graph.ast .= newAst
    return ()

updateNodes :: GraphLocation -> Command InterpreterEnv ()
updateNodes loc = do
    allNodeIds <- uses (graph . Graph.nodeMapping) IntMap.keys
    forM_ allNodeIds $ \id -> do
        ref <- zoom graph $ GraphUtils.getASTTarget id

        err <- zoom (graph . Graph.ast) $ AST.getError ref
        cachedErr <- uses errorsCache $ IntMap.lookup id
        if cachedErr /= err
            then do
                errorsCache %= IntMap.alter (const err) id
                case err of
                    Just e  -> Publisher.notifyResultUpdate loc id (NodeResult.Error e) 0
                    Nothing -> Publisher.notifyResultUpdate loc id (NodeResult.NoValue) 0
            else return ()

        rep <- zoom graph $ GraphBuilder.buildNode id
        cached <- uses nodesCache $ IntMap.lookup id
        if cached /= Just rep
            then do
                Publisher.notifyNodeUpdate loc rep
                nodesCache %= IntMap.insert id rep
            else return ()


updateValues :: GraphLocation -> Command InterpreterEnv ()
updateValues loc = do
    allNodeIds <- uses (graph . Graph.nodeMapping) IntMap.keys
    forM_ allNodeIds $ \id -> do
        noErrors <- isNothing <$> uses errorsCache (IntMap.lookup id)
        if noErrors
            then do
                val    <- zoom graph $ getNodeValue id
                cached <- uses valuesCache $ IntMap.lookup id
                if cached /= Just val
                    then do
                        Publisher.notifyResultUpdate loc id (fromMaybe NodeResult.NoValue $ NodeResult.Value <$> val) 100
                        valuesCache %= IntMap.insert id val
                    else return ()
            else return ()

flushCache :: Command InterpreterEnv ()
flushCache = do
    errorsCache .= def
    valuesCache .= def
    nodesCache  .= def

run :: GraphLocation -> Command InterpreterEnv ()
run loc = do
    zoom graph runTC
    updateNodes loc
    zoom graph runInterpreter
    updateValues loc