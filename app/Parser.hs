module Parser where

import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)

data Token
  = TIdent String
  | TNumber String
  | TSymbol String
  deriving (Show, Eq)

tokenize :: String -> [Token]
tokenize [] = []
tokenize ('/' : '/' : cs) = tokenize (dropWhile (/= '\n') cs)
tokenize ('/' : '*' : cs) = tokenize (skipBlockComment cs)
tokenize (c : cs)
  | isSpace c = tokenize cs
  | isAlpha c || c == '_' =
      let (word, rest) = span (\x -> isAlphaNum x || x == '_') cs
       in TIdent (c : word) : tokenize rest
  | isDigit c =
      let (num, rest) = span isDigit cs
       in case rest of
            (r : _)
              | isAlpha r || r == '_' ->
                  lexError ("invalid token: " ++ (c : num) ++ [r])
            _ -> TNumber (c : num) : tokenize rest
  | c `elem` validSymbols = TSymbol [c] : tokenize cs
  | otherwise = lexError ("invalid character: " ++ [c])

skipBlockComment :: String -> String
skipBlockComment ('*' : '/' : rest) = rest
skipBlockComment (_ : rest) = skipBlockComment rest
skipBlockComment [] = lexError "unterminated block comment"

validSymbols :: String
validSymbols = "(){};,~-+*/%&|^!?:<>="

lexError :: String -> a
lexError msg = error msg

newtype Program = Program Function
  deriving (Show)

data Function = Function String Statement
  deriving (Show)

newtype Statement = Return Exp
  deriving (Show)

newtype Exp = Constant Integer
  deriving (Show)

--
-- Chapter 1 grammar:
--   <program>   ::= <function>
--   <function>  ::= "int" <identifier> "(" "void" ")" "{" <statement> "}"
--   <statement> ::= "return" <exp> ";"
--   <exp>       ::= <int>

keywords :: [String]
keywords = ["int", "void", "return"]

parseProgram :: [Token] -> Either String Program
parseProgram ts = do
  (fn, rest) <- parseFunction ts
  case rest of
    [] -> Right (Program fn)
    _ -> Left ("unexpected tokens after function: " ++ describe rest)

parseFunction :: [Token] -> Either String (Function, [Token])
parseFunction ts0 = do
  ts1 <- keyword "int" ts0
  (name, ts2) <- identifier ts1
  ts3 <- symbol "(" ts2
  ts4 <- keyword "void" ts3
  ts5 <- symbol ")" ts4
  ts6 <- symbol "{" ts5
  (stmt, ts7) <- parseStatement ts6
  ts8 <- symbol "}" ts7
  Right (Function name stmt, ts8)

parseStatement :: [Token] -> Either String (Statement, [Token])
parseStatement ts0 = do
  ts1 <- keyword "return" ts0
  (e, ts2) <- parseExp ts1
  ts3 <- symbol ";" ts2
  Right (Return e, ts3)

parseExp :: [Token] -> Either String (Exp, [Token])
parseExp (TNumber n : ts) = Right (Constant (read n), ts)
parseExp ts = Left ("expected constant, got " ++ describe ts)

identifier :: [Token] -> Either String (String, [Token])
identifier (TIdent x : ts)
  | x `notElem` keywords = Right (x, ts)
identifier ts = Left ("expected identifier, got " ++ describe ts)

keyword :: String -> [Token] -> Either String [Token]
keyword k (TIdent x : ts) | x == k = Right ts
keyword k ts = Left ("expected keyword '" ++ k ++ "', got " ++ describe ts)

symbol :: String -> [Token] -> Either String [Token]
symbol s (TSymbol x : ts) | x == s = Right ts
symbol s ts = Left ("expected '" ++ s ++ "', got " ++ describe ts)

describe :: [Token] -> String
describe [] = "end of input"
describe (t : _) = show t
