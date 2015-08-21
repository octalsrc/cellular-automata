{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PatternSynonyms #-}

module Data.Cellular.Common.Sidewalk
  ( Sidewalk
  , mkSidewalk
  , string
  , printSteps
  
  , pattern Up
  , pattern Down

  ) where

import Data.Cellular


data Axis = UpDown

data Sidewalk a = Sidewalk [a] a [a]
  deriving (Show, Eq, Ord)

type instance Axes (Sidewalk c) = Axis

pattern Down = Just (RightSide UpDown)
pattern Up = Just (LeftSide UpDown)

instance Functor Sidewalk where
  fmap f (Sidewalk as x bs) = Sidewalk (fmap f as) (f x) (fmap f bs)

instance Comonad Sidewalk where
  extract (Sidewalk _ x _) = x
  duplicate u = Sidewalk (tail $ iterate (shift Up) u) 
                         u 
                         (tail $ iterate (shift Down) u)

instance Universe Sidewalk where
  shift Down (Sidewalk     as x (b:bs)) = Sidewalk (x:as) b     bs
  shift Up   (Sidewalk (a:as) x     bs) = Sidewalk     as a (x:bs)
 
mkSidewalk :: [a] -> a -> [a] -> Sidewalk a
mkSidewalk = Sidewalk

string :: (ToChar c) => Int -> Sidewalk c -> String
string r (Sidewalk as x bs) = 
  let lefthand =  fmap toChar $ reverse (take r as)
      righthand = fmap toChar $ take r bs
  in lefthand ++ [toChar x] ++ righthand

printSteps :: (ToChar c, Cell Sidewalk c) => Int -> Sidewalk c -> IO ()
printSteps r u = sequence_ $ take r $ fmap (putStrLn . string r) 
                                             (iterate next u)