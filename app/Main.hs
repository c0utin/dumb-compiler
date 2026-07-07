module Main where

import Control.Exception (evaluate)
import Data.List (isPrefixOf, partition)
import Parser (parseProgram, tokenize)
import System.Environment (getArgs)
import System.Exit (ExitCode (..), exitSuccess, exitWith)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
  args <- getArgs
  let (flags, files) = partition ("--" `isPrefixOf`) args
  case files of
    [file] -> do
      src <- readFile file
      let toks = tokenize src
      if "--lex" `elem` flags
        then do
          _ <- evaluate (length toks)
          exitSuccess
        else
          if "--ast" `elem` flags
            then case parseProgram toks of
              Right ast -> do
                print ast
                exitSuccess
              Left msg -> failWith ("parse error: " ++ msg)
            else case parseProgram toks of
              Right _ -> exitSuccess
              Left msg -> failWith ("parse error: " ++ msg)
    _ -> failWith "usage: compiler -- [--lex|--ast|--parse] <file>"

failWith :: String -> IO a
failWith msg = do
  hPutStrLn stderr msg
  exitWith (ExitFailure 1)
