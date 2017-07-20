{-# LANGUAGE DeriveAnyClass #-}
module NodeEditor.Event.Atom where

import           Common.Prelude
import           Data.Aeson     (FromJSON, ToJSON)


data Event = SetFile { path :: FilePath }
           | UnsetFile
           | LunaStudioFocused
           deriving (Eq, FromJSON, Generic, NFData, Show, ToJSON, Typeable)
