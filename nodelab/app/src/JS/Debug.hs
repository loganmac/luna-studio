module JS.Debug where

import           Data.Aeson         (ToJSON, toJSON)
import           Data.JSString      (pack)
import           Data.JSString.Text (lazyTextToJSString)
import           GHCJS.Marshal      (toJSVal)
import           GHCJS.Types        (JSString, JSVal)
import           Utils.PreludePlus

foreign import javascript safe "window.state  = $1"         saveState :: JSVal -> IO ()
foreign import javascript safe "window.lastEv = $1"         lastEv    :: JSVal -> IO ()
foreign import javascript safe "console.log($1)"            clog      :: JSVal -> IO ()
foreign import javascript safe "console.info('Incoming message', $1)" cinfo     :: JSVal -> IO ()
foreign import javascript safe "console.error($1, $2)"      error'    :: JSString -> JSVal -> IO ()
foreign import javascript safe "config.exportState" shouldExportState :: Bool
foreign import javascript safe "window.processedEvents.push($1)" processedEvent :: Int -> IO ()

error :: (ToJSON o) => Text -> o -> IO ()
error msg o = do
    let msg' = lazyTextToJSString msg
    o' <- toJSVal $ toJSON o
    error' msg' o'
