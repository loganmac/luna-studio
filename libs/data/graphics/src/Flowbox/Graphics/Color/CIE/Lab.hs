---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE DeriveDataTypeable    #-}
{-# LANGUAGE DeriveFoldable        #-}
{-# LANGUAGE DeriveFunctor         #-}
{-# LANGUAGE DeriveTraversable     #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE UndecidableInstances  #-}

module Flowbox.Graphics.Color.CIE.Lab where

import Data.Array.Accelerate
import Data.Array.Accelerate.Smart
import Data.Array.Accelerate.Tuple
import Data.Array.Accelerate.Array.Sugar
import Data.Foldable                     (Foldable)
import Data.Typeable

import Flowbox.Prelude hiding (lift)



data Lab a = Lab { labL :: a, labA :: a, labB :: a }
           deriving (Foldable, Functor, Traversable, Typeable, Show)

instance Each (Lab a) (Lab b) a b where
    each f (Lab x y z) = Lab <$> f x <*> f y <*> f z
    {-# INLINE each #-}

type instance EltRepr (Lab a)  = EltRepr (a, a, a)
type instance EltRepr' (Lab a) = EltRepr' (a, a, a)

instance Elt a => Elt (Lab a) where
  eltType _ = eltType (undefined :: (a,a,a))
  toElt p = case toElt p of
     (x, y, z) -> Lab x y z
  fromElt (Lab x y z) = fromElt (x, y, z)

  eltType' _ = eltType' (undefined :: (a,a,a))
  toElt' p = case toElt' p of
     (x, y, z) -> Lab x y z
  fromElt' (Lab x y z) = fromElt' (x, y, z)

instance IsTuple (Lab a) where
  type TupleRepr (Lab a) = TupleRepr (a,a,a)
  fromTuple (Lab x y z) = fromTuple (x,y,z)
  toTuple t = case toTuple t of
     (x, y, z) -> Lab x y z

instance (Lift Exp a, Elt (Plain a)) => Lift Exp (Lab a) where
  type Plain (Lab a) = Lab (Plain a)
  lift (Lab x y z) = Exp $ Tuple $ NilTup `SnocTup` lift x `SnocTup` lift y `SnocTup` lift z

instance (Elt a, e ~ Exp a) => Unlift Exp (Lab e) where
  unlift t = Lab (Exp $ SuccTupIdx (SuccTupIdx ZeroTupIdx) `Prj` t)
                 (Exp $ SuccTupIdx ZeroTupIdx `Prj` t)
                 (Exp $ ZeroTupIdx `Prj` t)
