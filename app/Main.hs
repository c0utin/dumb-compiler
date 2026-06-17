module Main where

import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)
import System.Environment (getArgs)

data Token
 = TIdent String
 | TNumber String
 | TSymbol String
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
   in case rest of
        (r:_) | isAlpha r || r == '_' ->
          lexError ("invalid token: " ++ (c:num) ++ [r])
        _ -> TNumber (c:num) : tokenize rest
 | c `elem` validSymbols = TSymbol [c] : tokenize cs
 | otherwise = lexError ("invalid character: " ++ [c])

validSymbols :: String
validSymbols = "(){};,~-+*/%&|^!?:<>="

lexError :: String -> a
lexError msg = error msg

main :: IO ()
main = do
 args <- getArgs
 case args of
  [file] -> do
   src <- readFile file
   mapM_ print (tokenize src)
  _ -> putStrLn "usage: dumb-c <file>"
