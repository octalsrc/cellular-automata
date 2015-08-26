{-# LANGUAGE TypeFamilies #-}

module Data.Cellular.UStack 
  ( C, U
  , UStack (..)
  , DStack (..)
  , getFrom, setAt

  ) where

import Control.Comonad

import Data.Cellular.Universe

----------------------------------------------------------------------

data C c = C c
  deriving (Show, Eq, Ord)

instance Functor C where
  fmap f (C c) = C (f c)

instance Comonad C where
  extract (C x) = x
  duplicate c = C c

----------------------------------------------------------------------

data U u c = U [u c] (u c) [u c]
  deriving (Show, Eq, Ord)

shiftUp, shiftDown :: U u c -> U u c
shiftUp   (U (a:as) x     bs) = U     as a (x:bs)
shiftDown (U     as x (b:bs)) = U (x:as) b     bs

umap :: (u c -> v k) -> U u c -> U v k
umap f (U as x bs) = U (map f as) (f x) (map f bs)

infiniteCopies :: u c -> U u c
infiniteCopies u = U (repeat u) u (repeat u)

promote :: U u c -> U (U u) c
promote u = let ds f = tail . iterate f
            in U (ds shiftUp u) u (ds shiftDown u)

demote :: U u c -> u c
demote (U _ x _) = x

modUFocus :: (u c -> u c) -> U u c -> U u c
modUFocus f (U as x bs) = U as (f x) bs

instance (Functor u) => Functor (U u) where                       
  fmap = umap . fmap

instance (Comonad u) => Comonad (U u) where
  extract = extract . demote
  duplicate = umap (\u -> u <$ demote u) . promote

----------------------------------------------------------------------

class Comonad u => UStack u where
  data DStack u
  emptyDir :: DStack u
  demoteDir :: DStack (U u) -> DStack u
  oppositeDir :: DStack u -> DStack u
  
  modFocus :: (c -> c) -> u c -> u c

  shift :: DStack u -> u c -> u c
  uniform :: c -> u c

instance UStack C where
  data DStack C = Base
  emptyDir = Base
  demoteDir _ = Base
  oppositeDir _ = Base

  modFocus f (C c) = C (f c)

  shift _ = id
  uniform = C

instance (UStack u) => UStack (U u) where
  data DStack (U u) = Stack (DStack u) | Up | Down
  emptyDir = Stack emptyDir

  demoteDir (Stack d) = d
  demoteDir _ = emptyDir

  oppositeDir Up = Down
  oppositeDir Down = Up
  oppositeDir (Stack d) = Stack (oppositeDir d)

  modFocus f u = modUFocus (modFocus f) u

  shift Up   = shiftUp
  shift Down = shiftDown
  shift d    = umap (shift (demoteDir d))

  uniform c = infiniteCopies (uniform c)

getFrom :: UStack u => DStack u -> u c -> c
getFrom d = extract . shift d

-- I suspect there is a more comonadic way to do setting though...
setAt :: UStack u => DStack u -> c -> u c -> u c
setAt d c u = shift (oppositeDir d) (modFocus (const c) (shift d u))
