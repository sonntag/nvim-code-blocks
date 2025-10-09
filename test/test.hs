-- Test Haskell file for code block highlighting

module TestBlocks where

import Data.List (sort, filter)
import Control.Monad (when, unless)

-- Simple function with where clause
outerFunction :: IO ()
outerFunction = do
  putStrLn "outer start"
  innerFunction
  putStrLn "outer end"
  where
    innerFunction :: IO ()
    innerFunction = do
      putStrLn "inner start"
      when True $ do
        putStrLn "inside when"
        let x = 1
            y = 2
        print (x + y)
      putStrLn "inner end"

-- Function with let bindings
processNumbers :: [Int] -> [Int]
processNumbers numbers =
  let doubled = map (* 2) numbers
      filtered = filter even doubled
      sorted = sort filtered
  in sorted

-- Case expression
describeNumber :: Int -> String
describeNumber n = case n of
  0 -> "zero"
  1 -> "one"
  _ -> if n > 0
       then "positive"
       else "negative"

-- List comprehension
pythagoreanTriples :: Int -> [(Int, Int, Int)]
pythagoreanTriples n =
  [ (a, b, c)
  | a <- [1..n]
  , b <- [a..n]
  , c <- [b..n]
  , a^2 + b^2 == c^2
  ]

-- Where clause with multiple bindings
complexCalculation :: Int -> Int -> Int
complexCalculation x y = result
  where
    doubled = x * 2
    tripled = y * 3

    result = if doubled > tripled
             then doubled
             else tripled

-- Guards
factorial :: Int -> Int
factorial n
  | n <= 0    = 1
  | n == 1    = 1
  | otherwise = n * factorial (n - 1)

-- Do notation with multiple blocks
ioExample :: IO ()
ioExample = do
  putStrLn "Enter name:"
  name <- getLine

  unless (null name) $ do
    putStrLn $ "Hello, " ++ name

    when (length name > 5) $ do
      putStrLn "That's a long name!"

  putStrLn "Done"

-- Lambda expressions
applyTwice :: (a -> a) -> a -> a
applyTwice f x = f (f x)

testLambdas :: [Int]
testLambdas =
  map (\x -> x * 2) $
    filter (\y -> y > 5) $
      [1..10]

-- Nested where clauses
nestedWhere :: Int -> Int
nestedWhere x = outerResult
  where
    outerResult = innerCalc * 2

    innerCalc = x + offset
      where
        offset = 10

-- Data type with record syntax
data Person = Person
  { personName :: String
  , personAge  :: Int
  , personCity :: String
  } deriving (Show, Eq)

-- Pattern matching
describePerson :: Person -> String
describePerson (Person name age city) =
  name ++ " is " ++ show age ++ " years old"

-- Main function
main :: IO ()
main = do
  outerFunction
  print $ processNumbers [1, 2, 3, 4, 5]
  print $ factorial 5
  ioExample
