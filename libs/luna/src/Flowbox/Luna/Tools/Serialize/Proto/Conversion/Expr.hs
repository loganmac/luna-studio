---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

{-# OPTIONS_GHC -fno-warn-orphans  #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances  #-}

module Flowbox.Luna.Tools.Serialize.Proto.Conversion.Expr where

import           Control.Applicative
import qualified Data.Map                                          as Map
import           Flowbox.Control.Error
import           Flowbox.Luna.Data.AST.Expr                        (Expr)
import qualified Flowbox.Luna.Data.AST.Expr                        as Expr
import           Flowbox.Luna.Tools.Serialize.Proto.Conversion.Pat ()
import           Flowbox.Prelude
import           Flowbox.Tools.Serialize.Proto.Conversion.Basic
import qualified Generated.Proto.Expr.Accessor                     as GenAccessor
import qualified Generated.Proto.Expr.App                          as GenApp
import qualified Generated.Proto.Expr.AppCons_                     as GenAppCons_
import qualified Generated.Proto.Expr.Arg                          as GenArg
import qualified Generated.Proto.Expr.Assignment                   as GenAssignment
import qualified Generated.Proto.Expr.Class                        as GenClass
import qualified Generated.Proto.Expr.Con_                         as GenCon_
import qualified Generated.Proto.Expr.Expr                         as Gen
import qualified Generated.Proto.Expr.Expr.Cls                     as GenCls
import qualified Generated.Proto.Expr.Field                        as GenField
import qualified Generated.Proto.Expr.Function                     as GenFunction
import qualified Generated.Proto.Expr.Import                       as GenImport
import qualified Generated.Proto.Expr.Infix                        as GenInfix
import qualified Generated.Proto.Expr.Lambda                       as GenLambda
import qualified Generated.Proto.Expr.List                         as GenList
import qualified Generated.Proto.Expr.Lit                          as GenLit
import qualified Generated.Proto.Expr.Native                       as GenNative
import qualified Generated.Proto.Expr.NativeCode                   as GenNativeCode
import qualified Generated.Proto.Expr.NativeVar                    as GenNativeVar
import qualified Generated.Proto.Expr.NOP                          as GenNOP
import qualified Generated.Proto.Expr.RangeFrom                    as GenRangeFrom
import qualified Generated.Proto.Expr.RangeFromTo                  as GenRangeFromTo
import qualified Generated.Proto.Expr.Tuple                        as GenTuple
import qualified Generated.Proto.Expr.Typed                        as GenTyped
import qualified Generated.Proto.Expr.Var                          as GenVar
import qualified Generated.Proto.Expr.Wildcard                     as GenWildcard
import qualified Text.ProtocolBuffers.Extensions                   as Extensions



instance Convert Expr Gen.Expr where
    encode t = case t of
        Expr.NOP        i          -> genExpr GenCls.NOP GenNOP.ext $ GenNOP.NOP
                                      (encodePJ i)
        Expr.Accessor   i name dst -> genExpr GenCls.Accessor GenAccessor.ext $ GenAccessor.Accessor
                                      (encodePJ i) (encodePJ name) (encodeJ dst)
        Expr.App        i src args -> genExpr GenCls.App GenApp.ext $ GenApp.App
                                      (encodePJ i) (encodeJ src) (encodeList args)
        Expr.AppCons_   i args     -> genExpr GenCls.AppCons_ GenAppCons_.ext $ GenAppCons_.AppCons_
                                      (encodePJ i) (encodeList args)
        Expr.Assignment i pat dst  -> genExpr GenCls.Assignment GenAssignment.ext $ GenAssignment.Assignment
                                      (encodePJ i) (encodeJ pat) (encodeJ dst)
        Expr.Class      i cls classes fields methods
                                   -> genExpr GenCls.Class GenClass.ext $ GenClass.Class
                                      (encodePJ i) (encodeJ cls) (encodeList classes) (encodeList fields) (encodeList methods)
        Expr.Con        i name     -> genExpr GenCls.Con_ GenCon_.ext $ GenCon_.Con_
                                      (encodePJ i) (encodePJ name)
        Expr.Function   i path name inputs output body
                                   -> genExpr GenCls.Function GenFunction.ext $ GenFunction.Function
                                      (encodePJ i) (encodeListP path) (encodePJ name) (encodeList inputs) (encodeJ output) (encodeList body)
        Expr.Lambda     i inputs output body
                                   -> genExpr GenCls.Lambda GenLambda.ext $ GenLambda.Lambda
                                      (encodePJ i) (encodeList inputs) (encodeJ output) (encodeList body)
        Expr.Import     i path target rename
                                   -> genExpr GenCls.Import GenImport.ext $ GenImport.Import
                                      (encodePJ i) (encodeListP path) (encodeJ target) (fmap encodeP rename)
        Expr.Infix      i name src dst
                                   -> genExpr GenCls.Infix GenInfix.ext $ GenInfix.Infix
                                      (encodePJ i) (encodePJ name) (encodeJ src) (encodeJ dst)
        Expr.List       i items    -> genExpr GenCls.List GenList.ext $ GenList.List
                                      (encodePJ i) (encodeList items)
        Expr.Lit        i lvalue   -> genExpr GenCls.Lit GenLit.ext $ GenLit.Lit
                                      (encodePJ i) (encodeJ lvalue)
        Expr.Tuple      i items    -> genExpr GenCls.Tuple GenTuple.ext $ GenTuple.Tuple
                                      (encodePJ i) (encodeList items)
        Expr.Typed      i cls expr -> genExpr GenCls.Typed GenTyped.ext $ GenTyped.Typed
                                      (encodePJ i) (encodeJ cls) (encodeJ expr)
        Expr.Var        i name     -> genExpr GenCls.Var GenVar.ext $ GenVar.Var
                                      (encodePJ i) (encodePJ name)
        Expr.Wildcard   i          -> genExpr GenCls.Wildcard GenWildcard.ext $ GenWildcard.Wildcard
                                      (encodePJ i)
        Expr.RangeFromTo i start end
                                   -> genExpr GenCls.RangeFromTo GenRangeFromTo.ext $ GenRangeFromTo.RangeFromTo
                                      (encodePJ i) (encodeJ start) (encodeJ end)
        Expr.RangeFrom  i start    -> genExpr GenCls.RangeFrom GenRangeFrom.ext $ GenRangeFrom.RangeFrom
                                      (encodePJ i) (encodeJ start)
        Expr.Field      i name cls value
                                   -> genExpr GenCls.Field GenField.ext $ GenField.Field
                                      (encodePJ i) (encodePJ name) (encodeJ cls) (fmap encode value)
        Expr.Arg        i pat value
                                   -> genExpr GenCls.Arg GenArg.ext $ GenArg.Arg
                                      (encodePJ i) (encodeJ pat) (fmap encode value)
        Expr.Native     i segments -> genExpr GenCls.Native GenNative.ext $ GenNative.Native
                                      (encodePJ i) (encodeList segments)
        Expr.NativeCode i code     -> genExpr GenCls.NativeCode GenNativeCode.ext $ GenNativeCode.NativeCode
                                      (encodePJ i) (encodePJ code)
        Expr.NativeVar  i name     -> genExpr GenCls.NativeVar GenNativeVar.ext $ GenNativeVar.NativeVar
                                      (encodePJ i) (encodePJ name)
        where
            genExpr :: GenCls.Cls -> Extensions.Key Maybe Gen.Expr v -> v -> Gen.Expr
            genExpr cls key ext = Extensions.putExt key (Just ext)
                                $ Gen.Expr cls $ Extensions.ExtField Map.empty

    decode t@(Gen.Expr cls _) = case cls of
        GenCls.NOP -> do
            ext <- getExt GenNOP.ext
            (GenNOP.NOP mtid) <- ext <?> "Failed to decode Expr.NOP: extension is missing"
            tid <- mtid <?> "Failed to decode Expr.NOP: 'id' field is missing"
            pure $ Expr.NOP (decodeP tid)
        GenCls.Accessor -> do
            ext <- getExt GenAccessor.ext
            (GenAccessor.Accessor mtid mtname mtdst) <- ext <?> "Failed to decode Expr.Accessor: extension is missing"
            tid   <- mtid   <?> "Failed to decode Expr.Accessor: 'id' field is missing"
            tname <- mtname <?> "Failed to decode Expr.Accessor: 'name' field is missing"
            tdst  <- mtdst  <?> "Failed to decode Expr.Accessor: 'dst' field is missing"
            Expr.Accessor (decodeP tid) (decodeP tname) <$> (decode tdst)
        GenCls.App -> do
            ext <- getExt GenApp.ext
            (GenApp.App mtid mtsrc targs) <- ext <?> "Failed to decode Expr.App: extension is missing"
            tid  <- mtid  <?> "Failed to decode Expr.App: 'id' field is missing"
            tsrc <- mtsrc <?> "Failed to decode Expr.App: 'src' field is missing"
            Expr.App (decodeP tid) <$> decode tsrc <*> decodeList targs
        GenCls.AppCons_ -> do
            ext <- getExt GenAppCons_.ext
            (GenAppCons_.AppCons_ mtid targs) <- ext <?> "Failed to decode Expr.AppCons_: extension is missing"
            tid <- mtid  <?> "Failed to decode Expr.AppCons_: 'id' field is missing"
            Expr.AppCons_ (decodeP tid) <$> decodeList targs
        GenCls.Assignment -> do
            ext <- getExt GenAssignment.ext
            (GenAssignment.Assignment mtid mtpat mtdst) <- ext <?> "Failed to decode Expr.Assignment: extension is missing"
            tid  <- mtid  <?> "Failed to decode Expr.Assignment: 'id' field is missing"
            tpat <- mtpat <?> "Failed to decode Expr.Assignment: 'pat' field is missing"
            tdst <- mtdst <?> "Failed to decode Expr.Assignment: 'dst' field is missing"
            Expr.Assignment (decodeP tid) <$> decode tpat <*> decode tdst
        GenCls.Class -> do
            ext <- getExt GenClass.ext
            (GenClass.Class mtid mtcls tclasses tfields tmethods) <- ext <?> "Failed to decode Expr.Class: extension is missing"
            tid  <- mtid  <?> "Failed to decode Expr.Class: 'id' field is missing"
            tcls <- mtcls <?> "Failed to decode Expr.Class: 'cls' field is missing"
            Expr.Class (decodeP tid) <$> decode tcls <*> decodeList tclasses <*> decodeList tfields <*> decodeList tmethods
        GenCls.Con_ -> do
            ext <- getExt GenCon_.ext
            (GenCon_.Con_ mtid mtname) <- ext <?> "Failed to decode Expr.Con: extension is missing"
            tid   <- mtid  <?> "Failed to decode Expr.Con: 'id' field is missing"
            tname <- mtname <?> "Failed to decode Expr.Con: 'name' field is missing"
            pure $ Expr.Con (decodeP tid) (decodeP tname)
        GenCls.Function -> do
            ext <- getExt GenFunction.ext
            (GenFunction.Function mtid tpath mtname tinputs mtoutput tbody) <- ext <?> "Failed to decode Expr.Function: extension is missing"
            tid     <- mtid     <?> "Failed to decode Expr.Function: 'id' field is missing"
            tname   <- mtname   <?> "Failed to decode Expr.Function: 'name' field is missing"
            toutput <- mtoutput <?> "Failed to decode Expr.Function: 'output' field is missing"
            Expr.Function (decodeP tid) (decodeListP tpath) (decodeP tname) <$> decodeList tinputs <*> decode toutput <*> decodeList tbody
        GenCls.Lambda -> do
            ext <- getExt GenLambda.ext
            (GenLambda.Lambda mtid tinputs mtoutput tbody) <- ext <?> "Failed to decode Expr.Lambda: extension is missing"
            tid     <- mtid     <?> "Failed to decode Expr.Lambda: 'id' field is missing"
            toutput <- mtoutput <?> "Failed to decode Expr.Lambda: 'output' field is missing"
            Expr.Lambda (decodeP tid) <$> decodeList tinputs <*> decode toutput <*> decodeList tbody
        GenCls.Import -> do
            ext <- getExt GenImport.ext
            (GenImport.Import mtid tpath mttarget mtrename) <- ext <?> "Failed to decode Expr.Import: extension is missing"
            tid     <- mtid     <?> "Failed to decode Expr.Import: 'id' field is missing"
            ttarget <- mttarget <?> "Failed to decode Expr.Import: 'target' field is missing"
            Expr.Import (decodeP tid) (decodeListP tpath) <$> decode ttarget
                                                          <*> (pure $ fmap decodeP mtrename)
        GenCls.Infix -> do
            ext <- getExt GenInfix.ext
            (GenInfix.Infix mtid mtname mtsrc mtdst) <- ext <?> "Failed to decode Expr.Infix: extension is missing"
            tid   <- mtid   <?> "Failed to decode Expr.Infix: 'id' field is missing"
            tname <- mtname <?> "Failed to decode Expr.Infix: 'name' field is missing"
            tsrc  <- mtsrc  <?> "Failed to decode Expr.Infix: 'src' field is missing"
            tdst  <- mtdst  <?> "Failed to decode Expr.Infix: 'dst' field is missing"
            Expr.Infix (decodeP tid) (decodeP tname) <$> decode tsrc <*> decode tdst
        GenCls.List -> do
            ext <- getExt GenList.ext
            (GenList.List mtid titems) <- ext <?> "Failed to decode Expr.List: extension is missing"
            tid <- mtid   <?> "Failed to decode Expr.List: 'id' field is missing"
            Expr.List (decodeP tid) <$> decodeList titems
        GenCls.Lit -> do
            ext <- getExt GenLit.ext
            (GenLit.Lit mtid mtlit) <- ext <?> "Failed to decode Expr.Lit: extension is missing"
            tid  <- mtid  <?> "Failed to decode Expr.Lit: 'id' field is missing"
            tlit <- mtlit <?> "Failed to decode Expr.Lit: 'lit' field is missing"
            Expr.Lit (decodeP tid) <$> decode tlit
        GenCls.Tuple -> do
            ext <- getExt GenTuple.ext
            (GenTuple.Tuple mtid titems) <- ext <?> "Failed to decode Expr.Tuple: extension is missing"
            tid <- mtid <?> "Failed to decode Expr.Tuple: 'id' field is missing"
            Expr.Tuple (decodeP tid) <$> decodeList titems
        GenCls.Typed -> do
            ext <- getExt GenTyped.ext
            (GenTyped.Typed mtid mtcls mtexpr) <- ext <?> "Failed to decode Expr.Typed: extension is missing"
            tid   <- mtid   <?> "Failed to decode Expr.Typed: 'id' field is missing"
            tcls  <- mtcls  <?> "Failed to decode Expr.Typed: 'cls' field is missing"
            texpr <- mtexpr <?> "Failed to decode Expr.Typed: 'expr' field is missing"
            Expr.Typed (decodeP tid) <$> decode tcls <*> decode texpr
        GenCls.Var -> do
            ext <- getExt GenVar.ext
            (GenVar.Var mtid mtname) <- ext <?> "Failed to decode Expr.Var: extension is missing"
            tid   <- mtid   <?> "Failed to decode Expr.Var: 'id' field is missing"
            tname <- mtname <?> "Failed to decode Expr.Var: 'name' field is missing"
            pure $ Expr.Var (decodeP tid) (decodeP tname)
        GenCls.Wildcard -> do
            ext <- getExt GenWildcard.ext
            (GenWildcard.Wildcard mtid) <- ext <?> "Failed to decode Expr.Wildcard: extension is missing"
            tid <- mtid <?> "Failed to decode Expr.Wildcard: 'id' field is missing"
            pure $ Expr.Wildcard (decodeP tid)
        GenCls.RangeFromTo -> do
            ext <- getExt GenRangeFromTo.ext
            (GenRangeFromTo.RangeFromTo mtid mtstart mtend) <- ext <?> "Failed to decode Expr.RangeFromTo: extension is missing"
            tid    <- mtid    <?> "Failed to decode Expr.RangeFromTo: 'id' field is missing"
            tstart <- mtstart <?> "Failed to decode Expr.RangeFromTo: 'start' field is missing"
            tend   <- mtend   <?> "Failed to decode Expr.RangeFromTo: 'end' field is missing"
            Expr.RangeFromTo (decodeP tid) <$> decode tstart <*> decode tend
        GenCls.RangeFrom -> do
            ext <- getExt GenRangeFrom.ext
            (GenRangeFrom.RangeFrom mtid mtstart) <- ext <?> "Failed to decode Expr.RangeFrom: extension is missing"
            tid    <- mtid    <?> "Failed to decode Expr.RangeFrom: 'id' field is missing"
            tstart <- mtstart <?> "Failed to decode Expr.RangeFrom: 'start' field is missing"
            Expr.RangeFrom (decodeP tid) <$> decode tstart
        GenCls.Field -> do
            ext <- getExt GenField.ext
            (GenField.Field mtid mtname mtcls mtvalue) <- ext <?> "Failed to decode Expr.Field: extension is missing"
            tid   <- mtid   <?> "Failed to decode Expr.Field: 'id' field is missing"
            tname <- mtname <?> "Failed to decode Expr.Field: 'name' field is missing"
            tcls  <- mtcls  <?> "Failed to decode Expr.Field: 'cls' field is missing"
            Expr.Field (decodeP tid) (decodeP tname) <$> decode tcls  <*> case mtvalue of
                                                            Nothing     -> pure Nothing
                                                            Just tvalue -> Just <$> decode tvalue
        GenCls.Arg -> do
            ext <- getExt GenArg.ext
            (GenArg.Arg mtid mtpat mtvalue) <- ext <?> "Failed to decode Expr.Arg: extension is missing"
            tid  <- mtid  <?> "Failed to decode Expr.Arg: 'id' field is missing"
            tpat <- mtpat <?> "Failed to decode Expr.Arg: 'pat' field is missing"
            Expr.Arg (decodeP tid) <$> (decode tpat) <*> case mtvalue of
                                                            Nothing     -> pure Nothing
                                                            Just tvalue -> Just <$> decode tvalue
        GenCls.Native -> do
            ext <- getExt GenNative.ext
            (GenNative.Native mtid tsegments) <- ext <?> "Failed to decode Expr.Native: extension is missing"
            tid <- mtid <?> "Failed to decode Expr.Native: 'id' field is missing"
            Expr.Native (decodeP tid) <$> decodeList tsegments
        GenCls.NativeCode -> do
            ext <- getExt GenNativeCode.ext
            (GenNativeCode.NativeCode mtid mtcode) <- ext <?> "Failed to decode Expr.NativeCode: extension is missing"
            tid   <- mtid   <?> "Failed to decode Expr.NativeCode: 'id' field is missing"
            tcode <- mtcode <?> "Failed to decode Expr.NativeCode: 'code' field is missing"
            pure $ Expr.NativeCode (decodeP tid) (decodeP tcode)
        GenCls.NativeVar -> do
            ext <- getExt GenNativeVar.ext
            (GenNativeVar.NativeVar mtid mtname) <- ext <?> "Failed to decode Expr.NativeVar: extension is missing"
            tid   <- mtid   <?> "Failed to decode Expr.NativeVar: 'id' field is missing"
            tname <- mtname <?> "Failed to decode Expr.NativeVar: 'name' field is missing"
            pure $ Expr.NativeVar (decodeP tid) (decodeP tname)
       where getExt k = case Extensions.getExt k t of
                                Right a -> return a
                                Left m  -> fail m
