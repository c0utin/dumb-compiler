module Main where

import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)
import System.Environment (getArgs)

data Token
  = TIdent String
  | TNumber String
  | TSymbol Char
  deriving (Show)

tokenize :: String -> [Token]
tokenize [] = []
tokenize (c:cs)
  | isSpace c = tokenize cs
  | isAlpha c || c == '_' =
      let (word, rest) = span (\x -> isAlphaNum x || x == '_') cs
      in TIdent (c:word) : tokenize rest
  | isDigit c =
      let (num, rest) = span isDigit cs
      in TNumber (c:num) : tokenize rest
  | otherwise = TSymbol c : tokenize cs

main :: IO ()
main = do
  args <- getArgs
  case args of
    [file] -> do
      src <- readFile file
      mapM_ print (tokenize src)
    _ -> putStrLn "usage: normie-c <file>"
