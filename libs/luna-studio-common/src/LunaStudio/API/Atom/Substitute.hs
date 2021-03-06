{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances  #-}
module LunaStudio.API.Atom.Substitute where

import           Data.Aeson.Types              (ToJSON)
import           Data.Binary                   (Binary)
import qualified LunaStudio.API.Graph.Request  as G
import qualified LunaStudio.API.Graph.Result   as Result
import qualified LunaStudio.API.Request        as R
import qualified LunaStudio.API.Response       as Response
import qualified LunaStudio.API.Topic          as T
import           LunaStudio.Data.Diff          (Diff)
import           LunaStudio.Data.GraphLocation (GraphLocation)
import           LunaStudio.Data.NodeSearcher  (ImportName)
import           LunaStudio.Data.Point         (Point)
import           Prologue


data Request = Request
        { _location :: GraphLocation
        , _diffs    :: [Diff]
        } deriving (Eq, Generic, Show)

data Update = Update
        { _filePath' :: FilePath
        , _diffs'    :: [Diff]
        } deriving (Eq, Generic, Show)

data Result = Result
        { _defResult    :: Result.Result
        , _importChange :: Maybe [ImportName]
        } deriving (Eq, Generic, Show)

makeLenses ''Request
makeLenses ''Update
makeLenses ''Result
instance Binary Request
instance NFData Request
instance ToJSON Request
instance Binary Update
instance NFData Update
instance ToJSON Update
instance Binary Result
instance NFData Result
instance ToJSON Result
instance G.GraphRequest Request where location = location


type Response = Response.Response Request () Result
instance Response.ResponseResult Request () Result

topicPrefix :: T.Topic
topicPrefix = "empire.atom.file.substitute"
instance T.MessageTopic (R.Request Request) where topic _ = topicPrefix <> T.request
instance T.MessageTopic Response            where topic _ = topicPrefix <> T.response
instance T.MessageTopic Update              where topic _ = topicPrefix <> T.update
