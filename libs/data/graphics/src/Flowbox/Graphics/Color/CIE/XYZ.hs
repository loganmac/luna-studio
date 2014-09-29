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

module Flowbox.Graphics.Color.CIE.XYZ where

import Data.Array.Accelerate
import Data.Array.Accelerate.Smart
import Data.Array.Accelerate.Tuple
import Data.Array.Accelerate.Array.Sugar
import Data.Foldable                     (Foldable)
import Data.Typeable

import Flowbox.Prelude hiding (lift)



data XYZ a = XYZ { xyzX :: a, xyzY :: a, xyzZ :: a }
           deriving (Foldable, Functor, Traversable, Typeable, Show)

instance Each (XYZ a) (XYZ b) a b where
    each f (XYZ x y z) = XYZ <$> f x <*> f y <*> f z
    {-# INLINE each #-}

type instance EltRepr (XYZ a)  = EltRepr (a, a, a)
type instance EltRepr' (XYZ a) = EltRepr' (a, a, a)

instance (Elt a) => Elt (XYZ a) where
  eltType _ = eltType (undefined :: (a,a,a))
  toElt p = case toElt p of
     (x, y, z) -> XYZ x y z
  fromElt (XYZ x y z) = fromElt (x, y, z)

  eltType' _ = eltType' (undefined :: (a,a,a))
  toElt' p = case toElt' p of
     (x, y, z) -> XYZ x y z
  fromElt' (XYZ x y z) = fromElt' (x, y, z)

instance IsTuple (XYZ a) where
  type TupleRepr (XYZ a) = TupleRepr (a,a,a)
  fromTuple (XYZ x y z) = fromTuple (x,y,z)
  toTuple t = case toTuple t of
     (x, y, z) -> XYZ x y z

instance (Lift Exp a, Elt (Plain a)) => Lift Exp (XYZ a) where
  type Plain (XYZ a) = XYZ (Plain a)
  lift (XYZ x y z) = Exp $ Tuple $ NilTup `SnocTup` lift x `SnocTup` lift y `SnocTup` lift z

instance (Elt a, e ~ Exp a) => Unlift Exp (XYZ e) where
  unlift t = XYZ (Exp $ SuccTupIdx (SuccTupIdx ZeroTupIdx) `Prj` t)
                 (Exp $ SuccTupIdx ZeroTupIdx `Prj` t)
                 (Exp $ ZeroTupIdx `Prj` t)
