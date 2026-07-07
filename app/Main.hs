module Main where

import Control.Exception (evaluate)
import Parser (parseProgram, tokenize)
import System.Environment (getArgs)
import System.Exit (ExitCode (..), exitSuccess, exitWith)
import System.IO (hPutStrLn, stderr)

data Mode = Lex | Parse | Ast

data Args
  = Run Mode FilePath
  | Help
  | Invalid

parseArgs :: [String] -> Args
parseArgs ["--help"] = Help
parseArgs [file] = Run Parse file
parseArgs ["--lex", file] = Run Lex file
parseArgs ["--parse", file] = Run Parse file
parseArgs ["--ast", file] = Run Ast file
parseArgs _ = Invalid

usage :: String
usage =
  unlines
    [ "usage: compiler [OPTIONS] <file>",
      "",
      "Options:",
      "  --lex     Tokenize the input and exit",
      "  --parse   Parse the input and exit (default)",
      "  --ast     Parse the input and print the AST",
      "  --help    Show this help message"
    ]

main :: IO ()
main = do
  args <- getArgs
  case parseArgs args of
    Help -> putStr usage
    Invalid -> failWith usage
    Run mode file -> do
      src <- readFile file
      let toks = tokenize src
      case mode of
        Lex -> do
          _ <- evaluate (length toks)
          exitSuccess
        Parse -> case parseProgram toks of
          Right _ -> exitSuccess
          Left msg -> failWith ("parse error: " ++ msg)
        Ast -> case parseProgram toks of
          Right ast -> do
            print ast
            exitSuccess
          Left msg -> failWith ("parse error: " ++ msg)

failWith :: String -> IO a
failWith msg = do
  hPutStrLn stderr msg
  exitWith (ExitFailure 1)
