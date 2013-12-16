---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------
module Flowbox.Batch.Server.Handler.AST where

import Data.IORef (IORef)

import qualified Data.IORef                                            as IORef
import           Flowbox.Batch.Batch                                   (Batch)
import qualified Flowbox.Batch.Handler.AST                             as BatchAST
import           Flowbox.Luna.Tools.Serialize.Proto.Conversion.Crumb   ()
import           Flowbox.Luna.Tools.Serialize.Proto.Conversion.Expr    ()
import           Flowbox.Luna.Tools.Serialize.Proto.Conversion.Focus   ()
import           Flowbox.Luna.Tools.Serialize.Proto.Conversion.Module  ()
import           Flowbox.Prelude                                       hiding (focus)
import           Flowbox.System.Log.Logger
import           Flowbox.Tools.Serialize.Proto.Conversion.Basic
import qualified Generated.Proto.Batch.AST.AddClass.Args               as AddClass
import qualified Generated.Proto.Batch.AST.AddClass.Result             as AddClass
import qualified Generated.Proto.Batch.AST.AddFunction.Args            as AddFunction
import qualified Generated.Proto.Batch.AST.AddFunction.Result          as AddFunction
import qualified Generated.Proto.Batch.AST.AddModule.Args              as AddModule
import qualified Generated.Proto.Batch.AST.AddModule.Result            as AddModule
import qualified Generated.Proto.Batch.AST.Definitions.Args            as Definitions
import qualified Generated.Proto.Batch.AST.Definitions.Result          as Definitions
import qualified Generated.Proto.Batch.AST.Remove.Args                 as Remove
import qualified Generated.Proto.Batch.AST.Remove.Result               as Remove
import qualified Generated.Proto.Batch.AST.UpdateClassCls.Args         as UpdateClassCls
import qualified Generated.Proto.Batch.AST.UpdateClassCls.Result       as UpdateClassCls
import qualified Generated.Proto.Batch.AST.UpdateClassFields.Args      as UpdateClassFields
import qualified Generated.Proto.Batch.AST.UpdateClassFields.Result    as UpdateClassFields
import qualified Generated.Proto.Batch.AST.UpdateFunctionInputs.Args   as UpdateFunctionInputs
import qualified Generated.Proto.Batch.AST.UpdateFunctionInputs.Result as UpdateFunctionInputs
import qualified Generated.Proto.Batch.AST.UpdateFunctionName.Args     as UpdateFunctionName
import qualified Generated.Proto.Batch.AST.UpdateFunctionName.Result   as UpdateFunctionName
import qualified Generated.Proto.Batch.AST.UpdateFunctionOutput.Args   as UpdateFunctionOutput
import qualified Generated.Proto.Batch.AST.UpdateFunctionOutput.Result as UpdateFunctionOutput
import qualified Generated.Proto.Batch.AST.UpdateFunctionPath.Args     as UpdateFunctionPath
import qualified Generated.Proto.Batch.AST.UpdateFunctionPath.Result   as UpdateFunctionPath
import qualified Generated.Proto.Batch.AST.UpdateModuleCls.Args        as UpdateModuleCls
import qualified Generated.Proto.Batch.AST.UpdateModuleCls.Result      as UpdateModuleCls
import qualified Generated.Proto.Batch.AST.UpdateModuleFields.Args     as UpdateModuleFields
import qualified Generated.Proto.Batch.AST.UpdateModuleFields.Result   as UpdateModuleFields
import qualified Generated.Proto.Batch.AST.UpdateModuleImports.Args    as UpdateModuleImports
import qualified Generated.Proto.Batch.AST.UpdateModuleImports.Result  as UpdateModuleImports



loggerIO :: LoggerIO
loggerIO = getLoggerIO "Flowbox.Batch.Server.Handlers.AST"

-------- public api -------------------------------------------------

definitions :: IORef Batch -> Definitions.Args -> IO Definitions.Result
definitions batchHandler (Definitions.Args mtmaxDepth tbc tlibID tprojectID) = do
    loggerIO info "called definitions"
    bc  <- decode tbc
    let mmaxDepth = fmap decodeP mtmaxDepth
        libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    focus <- BatchAST.definitions mmaxDepth bc libID projectID batch
    return $ Definitions.Result $ encode focus


addModule :: IORef Batch -> AddModule.Args -> IO AddModule.Result
addModule batchHandler (AddModule.Args tnewModule tbcParent tlibID tprojectID) = do
    loggerIO info "called addModule"
    newModule <- decode tnewModule
    bcParent  <- decode tbcParent
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.addModule newModule bcParent libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return AddModule.Result


addClass :: IORef Batch -> AddClass.Args -> IO AddClass.Result
addClass batchHandler (AddClass.Args tnewClass tbcParent tlibID tprojectID) = do
    loggerIO info "called addClass"
    newClass <- decode tnewClass
    bcParent <- decode tbcParent
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.addClass newClass bcParent libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return AddClass.Result


addFunction :: IORef Batch -> AddFunction.Args -> IO AddFunction.Result
addFunction batchHandler (AddFunction.Args tnewFunction tbcParent tlibID tprojectID) = do
    loggerIO info "called addFunction"
    newFunction <- decode tnewFunction
    bcParent    <- decode tbcParent
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.addFunction newFunction bcParent libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return AddFunction.Result


remove :: IORef Batch -> Remove.Args -> IO Remove.Result
remove batchHandler (Remove.Args tbc tlibID tprojectID) = do
    loggerIO info "called remove"
    bc  <- decode tbc
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.remove bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return Remove.Result


updateModuleCls :: IORef Batch -> UpdateModuleCls.Args -> IO UpdateModuleCls.Result
updateModuleCls batchHandler (UpdateModuleCls.Args tcls tbc tlibID tprojectID) = do
    loggerIO info "called updateModuleCls"
    cls <- decode tcls
    bc  <- decode tbc
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateModuleCls cls bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateModuleCls.Result


updateModuleImports :: IORef Batch -> UpdateModuleImports.Args -> IO UpdateModuleImports.Result
updateModuleImports batchHandler (UpdateModuleImports.Args timports tbc tlibID tprojectID) = do
    loggerIO info "called updateModuleImports"
    imports <- decodeList timports
    bc      <- decode tbc
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateModuleImports imports bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateModuleImports.Result


updateModuleFields :: IORef Batch -> UpdateModuleFields.Args -> IO UpdateModuleFields.Result
updateModuleFields batchHandler (UpdateModuleFields.Args tfields tbc tlibID tprojectID) = do
    loggerIO info "called updateModuleFields"
    fields <- decodeList tfields
    bc     <- decode tbc
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateModuleFields fields bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateModuleFields.Result


updateClassCls :: IORef Batch -> UpdateClassCls.Args -> IO UpdateClassCls.Result
updateClassCls batchHandler (UpdateClassCls.Args tcls tbc tlibID tprojectID) = do
    loggerIO info "called updateClassCls"
    cls <- decode tcls
    bc  <- decode tbc
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateClassCls cls bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateClassCls.Result


updateClassFields :: IORef Batch -> UpdateClassFields.Args -> IO UpdateClassFields.Result
updateClassFields batchHandler (UpdateClassFields.Args tfields tbc tlibID tprojectID) = do
    loggerIO info "called updateClassFields"
    fields <- decodeList tfields
    bc     <- decode tbc
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateClassFields fields bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateClassFields.Result


updateFunctionName :: IORef Batch -> UpdateFunctionName.Args -> IO UpdateFunctionName.Result
updateFunctionName batchHandler (UpdateFunctionName.Args tname tbc tlibID tprojectID) = do
    loggerIO info "called updateFunctionName"
    bc <- decode tbc
    let name      = decodeP tname
        libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateFunctionName name bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateFunctionName.Result


updateFunctionPath :: IORef Batch -> UpdateFunctionPath.Args -> IO UpdateFunctionPath.Result
updateFunctionPath batchHandler (UpdateFunctionPath.Args tpath tbc tlibID tprojectID) = do
    loggerIO info "called updateFunctionPath"
    bc <- decode tbc
    let path      = decodeListP tpath
        libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateFunctionPath path bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateFunctionPath.Result


updateFunctionInputs :: IORef Batch -> UpdateFunctionInputs.Args -> IO UpdateFunctionInputs.Result
updateFunctionInputs batchHandler (UpdateFunctionInputs.Args tinputs tbc tlibID tprojectID) = do
    loggerIO info "called updateFunctionInputs"
    inputs <- decodeList tinputs
    bc     <- decode tbc
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateFunctionInputs inputs bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateFunctionInputs.Result


updateFunctionOutput :: IORef Batch -> UpdateFunctionOutput.Args -> IO UpdateFunctionOutput.Result
updateFunctionOutput batchHandler (UpdateFunctionOutput.Args toutput tbc tlibID tprojectID) = do
    loggerIO info "called updateFunctionOutput"
    output <- decode toutput
    bc     <- decode tbc
    let libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef batchHandler
    newBatch <- BatchAST.updateFunctionOutput output bc libID projectID batch
    IORef.writeIORef batchHandler newBatch
    return UpdateFunctionOutput.Result
