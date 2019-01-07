{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

module WaveletTree where
import Data.Char (chr,ord)
import Data.List (partition)
import Data.BitVector (BitVector,showBin,(!.),most,fromBits) -- requires package bv
import qualified Data.BitVector as BV (foldl)

data WaveletTree a = Leaf (Maybe a) | Node BitVector (WaveletTree a) (WaveletTree a)

class Wv a where
  midpoint :: a -> a -> a
instance Wv Char where
  midpoint x y = chr $ (ord x + ord y) `div` 2
instance {-# OVERLAPPABLE #-} (Enum a, Integral a) => Wv a where
  midpoint x y = (x + y) `div` 2

instance Show a => Show (WaveletTree a) where
  show w = show' 0 w
    where show' _ (Leaf Nothing) = ""
          show' pad (Leaf (Just x)) = replicate pad ' ' ++ show x
          show' pad (Node bitmap left right) = replicate pad ' '
                                            ++ showBin bitmap
                                            ++ "\n" ++ show' (pad+2) left
                                            ++ "\n" ++ show' (pad+2) right

-- It is assumed that (minimum xs) == 1 and (maximum xs) is the size of the alphabet
wavelet :: (Wv a, Ord a, Enum a) => [a] -> WaveletTree a
wavelet xs = wavelet' (minimum xs) (maximum xs) xs
  where wavelet' from to xs
          | null xs    = Leaf Nothing -- fake node, will never be reached during indexing
          | from == to = Leaf $ Just from
          | otherwise  = Node bitmap (wavelet' from mid ys) (wavelet' (succ mid) to zs)
          where mid = midpoint from to
                bitmap = fromBits $ map (>mid) xs
                (ys,zs) = partition (<=mid) xs

(!) :: Integral ix => WaveletTree a -> ix -> a
(Leaf (Just x)) ! _ = x
(Node bitmap left right) ! i
  | bitmap !. i = right ! (rank i)
  | otherwise   = left ! (i - rank i)
  where rank 0 = 0
        rank i = BV.foldl (\c b -> if b then c+1 else c) 0 $ most i bitmap

check :: (Wv a, Ord a, Enum a) => [a] -> Bool
check xs = xs == map (wavelet xs !) [0..length xs - 1]
