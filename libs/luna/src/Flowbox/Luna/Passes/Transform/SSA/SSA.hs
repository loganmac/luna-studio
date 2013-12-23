---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------
{-# LANGUAGE ConstraintKinds           #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

module Flowbox.Luna.Passes.Transform.SSA.SSA where

import           Control.Applicative
import           Control.Monad.State
import qualified Data.IntMap         as IntMap

import           Flowbox.Luna.Data.Analysis.Alias.Alias (AA)
import qualified Flowbox.Luna.Data.Analysis.Alias.Alias as AA
import qualified Flowbox.Luna.Data.AST.Expr             as Expr
import           Flowbox.Luna.Data.AST.Module           (Module)
import qualified Flowbox.Luna.Data.AST.Module           as Module
import           Flowbox.Luna.Data.AST.Pat              (Pat)
import qualified Flowbox.Luna.Data.AST.Pat              as Pat
import           Flowbox.Luna.Passes.Pass               (PassMonad)
import qualified Flowbox.Luna.Passes.Pass               as Pass
import           Flowbox.Prelude                        hiding (error, id, mod)
import           Flowbox.System.Log.Logger


logger :: Logger
logger = getLogger "Flowbox.Luna.Passes.SSA.SSA"


type SSAMonad m = PassMonad Pass.NoState m


mkVar :: Int -> String
mkVar id = "v_" ++ show id


run :: PassMonad s m => AA -> Module -> Pass.Result m Module
run vs = (Pass.run_ (Pass.Info "SSA") Pass.NoState) . (ssaModule vs)
--run vs = (Pass.run_ (Pass.Info "SSA") Pass.NoState) . (ssaModule vs)


ssaModule :: SSAMonad m => AA -> Module -> Pass.Result m Module
ssaModule vs mod = Module.traverseM (ssaModule vs) (ssaExpr vs) pure ssaPat pure mod


ssaExpr :: SSAMonad m => AA -> Expr.Expr -> Pass.Result m Expr.Expr
ssaExpr vs ast = case ast of
    Expr.Accessor   id name dst           -> Expr.Accessor id name <$> ssaExpr vs dst
    Expr.Var        id name               -> case IntMap.lookup id (AA.varmap vs) of
                                                  Just nid -> return $ Expr.Var id (mkVar nid)
                                                  Nothing  -> Pass.fail ("Not in scope '" ++ name ++ "'.")
    Expr.NativeVar  id name               -> case IntMap.lookup id (AA.varmap vs) of
                                                  Just nid -> return $ Expr.NativeVar id (mkVar nid)
                                                  Nothing  -> Pass.fail ("Not in scope '" ++ name ++ "'.")
    _                                     -> Expr.traverseM (ssaExpr vs) pure ssaPat pure ast


ssaPat :: SSAMonad m => Pat -> Pass.Result m Pat
ssaPat pat = case pat of
    Pat.Var  id _  -> return $ Pat.Var id (mkVar id)
    _              -> Pat.traverseM ssaPat pure pure pat
