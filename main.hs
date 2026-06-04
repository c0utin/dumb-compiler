x1 = 10

sayHello :: String -> IO ()
sayHello x = putStrLn ("Hello, " ++ x ++ "!" ++ show x1 ++  "!")

main :: IO ()

main = sayHello "sarah"
