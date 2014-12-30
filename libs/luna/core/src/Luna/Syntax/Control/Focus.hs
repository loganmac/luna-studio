---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE TemplateHaskell #-}

module Luna.Syntax.Control.Focus where

import Flowbox.Prelude
import Luna.Syntax.Expr   (Expr)
import Luna.Syntax.Module (Module)
--import           Luna.Syntax.Arg    (Arg)
--import qualified Luna.Syntax.Expr   as Expr
--import           Luna.Syntax.Lit    (Lit)
--import qualified Luna.Syntax.Module as Module
--import           Luna.Syntax.Pat    (Pat)
--import           Luna.Syntax.Type   (Type)



data Focus a v = Lambda   { _expr :: Expr   a v }
               | Function { _expr :: Expr   a v }
               | Class    { _expr :: Expr   a v }
               | Module   { _module_ :: Module a v }
               deriving (Show)

makeLenses ''Focus


type FocusPath a v = [Focus a v]


--type Traversal m = (Functor m, Applicative m, Monad m)

--traverseM :: Traversal m => (Module -> m Module) -> (Expr -> m Expr) -> Focus -> m Focus
--traverseM fmod fexp focus = case focus of
--    Lambda   l -> Lambda   <$> fexp l
--    Function f -> Function <$> fexp f
--    Class    c -> Class    <$> fexp c
--    Module   m -> Module   <$> fmod m


--traverseM_ :: Traversal m => (Module -> m r) -> (Expr -> m r) -> Focus -> m r
--traverseM_ fmod fexp focus = case focus of
--    Lambda   l -> fexp l
--    Function f -> fexp f
--    Class    c -> fexp c
--    Module   m -> fmod m


--traverseMR :: Traversal m => (Module -> m Module) -> (Expr -> m Expr)
--           -> (Type -> m Type) -> (Pat -> m Pat) -> (Lit -> m Lit) -> (Arg Expr -> m (Arg Expr))
--           -> Focus -> m Focus
--traverseMR fmod fexp ftype fpat flit farg focus = case focus of
--    Lambda   expr  -> Lambda   <$> Expr.traverseMR fexp ftype fpat flit farg expr
--    Function expr  -> Function <$> Expr.traverseMR fexp ftype fpat flit farg expr
--    Class    expr  -> Class    <$> Expr.traverseMR fexp ftype fpat flit farg expr
--    Module module_ -> Module   <$> Module.traverseMR fmod fexp ftype fpat flit farg module_


getLambda :: Focus a v -> Maybe (Expr a v)
getLambda (Lambda l) = Just l
getLambda _          = Nothing


getFunction :: Focus a v -> Maybe (Expr a v)
getFunction (Function e) = Just e
getFunction _            = Nothing


getClass :: Focus a v -> Maybe (Expr a v)
getClass (Class e) = Just e
getClass _         = Nothing


getModule :: Focus a v -> Maybe (Module a v)
getModule (Module m) = Just m
getModule _          = Nothing

