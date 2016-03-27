import System.IO
import Data.List.Split
import Data.Maybe
import Text.Read

---------------------- MAIN CODE ---------------------

data BoolExpr a = 
    AND (BoolExpr a) (BoolExpr a) | 
    OR (BoolExpr a) (BoolExpr a) | 
    NOT (BoolExpr a) |
    Gt (NumExpr a) (NumExpr a) |
    Eq (NumExpr a) (NumExpr a)
    deriving(Read, Show) 
{-
instance Show a => Show (BoolExpr a) where
    show (AND a b)  = (show a) ++ " AND " ++ (show b)
    show (OR a b)   = (show a) ++ " OR " ++ (show b)
    show (NOT a)    = "NOT " ++ (show a)
    show (Gt a b)   = (show a) ++ " > " ++ (show b)
    show (Eq a b)   = (show a) ++ " = " ++ (show b)
-}

data NumExpr a = 
    Var String | 
    Const a |
    Plus (NumExpr a) (NumExpr a) |
    Minus (NumExpr a) (NumExpr a) |
    Times (NumExpr a) (NumExpr a) |
    Div (NumExpr a) (NumExpr a) 
    deriving (Read, Show)
{-
instance Show a => Show (NumExpr a) where
    show (Var s)        = s
    show (Const a)      = show a
    show (Plus a b)     = (show a) ++ " + " ++ (show b)
    show (Minus a b)    = (show a) ++ " - " ++ (show b)
    show (Times a b)    = (show a) ++ " * " ++ (show b)
    show (Div a b)      = (show a) ++ " / " ++ (show b) 
    -}

data Command a = 
    Assign (NumExpr a) (NumExpr a) | 
    Input (NumExpr a) | 
    Print (NumExpr a) | 
    Seq [Command a] | 
    Cond (BoolExpr a) (Command a) (Command a) | 
    Loop (BoolExpr a) (Command a)
    deriving(Read, Show)

{-instance Show a => Show (Command a) where
     show (Assign x y)  = (show x) ++ " := " ++ (show y) ++ ";\n"
     show (Input x)     = "INPUT " ++ (show x) ++ ";\n"
     show (Print x)     = "PRINT " ++ (show x) ++ ";\n"
     show (Seq [])      = []
     show (Seq (x:xs))  = (show x) ++ ("\n") ++ (show (Seq xs))
     show (Cond b i e)  = "IF " ++ (show b) ++ " THEN\n" ++ (show i) ++ "ELSE\n" ++ (show e) ++ "END"
     show (Loop b c)    = "WHILE " ++ (show b) ++ "\nDO\n" ++ (show c) ++ "END\n"
-}

dropNextWord ::  String -> (String, String)
dropNextWord s  = (w, d)
    where 
        begin       = dropWhile (==' ') s
        (w, r)      = span (/=' ') begin
        d           = dropWhile (==' ') r

-- Reads a String and returns a NumExpr (if it founds a String name
-- creates a Var "name", otherwise creates a const "Number")
readStringNum :: Read a => String -> NumExpr a
readStringNum s
    | isJust num    = Const n
    | otherwise     = Var s
    where 
        num     = readMaybe s
        Just n  = num

-- Read multiplications, 4th level of recursion (last)
readNumExprMul :: Read a => String -> NumExpr a
readNumExprMul s    = concatMul nums
    where
        timesS      = splitOn " * " s
        nums        = map readStringNum timesS

        concatMul :: [NumExpr a] -> NumExpr a
        concatMul []        = error "concatMul: Llista buida"
        concatMul (x:[])    = x
        concatMul (x:xs)    = Times x (concatMul xs)

-- Read divisions, 3rd level of recursion
readNumExprDiv :: Read a => String -> NumExpr a
readNumExprDiv s     = concatDiv nums
    where
        divsS   = splitOn " / " s
        nums    = map readNumExprMul divsS

        concatDiv :: [NumExpr a] -> NumExpr a
        concatDiv []        = error "concatDiv: Llista buida"
        concatDiv (x:[])    = x
        concatDiv (x:xs)    = Div x (concatDiv xs)

-- Read minus, 2nd level of recursion
readNumExprMin :: Read a => String -> NumExpr a
readNumExprMin s    = concatMin nums
    where
        minsS   = splitOn " - " s
        nums    = map readNumExprDiv minsS

        concatMin :: [NumExpr a] -> NumExpr a
        concatMin []        = error "concatMin: Llista buida"
        concatMin (x:[])    = x
        concatMin (x:xs)    = Minus x (concatMin xs)

-- Read plus, 1st level of recursion
readNumExprPlu :: Read a => String -> NumExpr a
readNumExprPlu s    = concatPlu nums
    where
        plusS   = splitOn " + " s
        nums    = map readNumExprMin plusS

        concatPlu :: [NumExpr a] -> NumExpr a
        concatPlu []        = error "concatPlu: Llista buida"
        concatPlu (x:[])    = x
        concatPlu (x:xs)    = Plus x (concatPlu xs)

-- Reads a numeric expression and returns the remaining string
readNumExpr :: Read a => String -> (NumExpr a, String)
readNumExpr s = (readNumExprPlu str, r)
    where 
        (str, r)  = takeCommand s [">", "<", "AND", "OR", "THEN", "DO"]


{-readBoolExprGt :: Read a => String -> BoolExpr a
readBoolExprGt s    = Gt x y
    where
        str         = splitOn " > " s
        exp         = map (\x -> fst (readNumExpr x)) str
        (x:y:[])  = exp
-}

-- Takes items until a command from the list is found
takeCommand :: String -> [String] -> (String, String) 
takeCommand s xs
    | elem com xs    = ("", s)
    | expr == ""        = (com, cuar)
    | otherwise         = (com ++ " " ++ expr, cuar)
    where 
        (com, cua)      = dropNextWord s
        (expr, cuar)    = takeCommand cua xs

{-readBoolExprEq :: Read a => String -> (BoolExpr a, String)
readBoolExprEq s-}

readBoolExpr :: String -> (BoolExpr a, String)
readBoolExpr s = (Gt (Var "3") (Var "4"), "")


-- Creates a Input Command from a String
readCommandInput :: String -> (Command a, String)
readCommandInput s  = (Input (Var var), remaining)
    where
        varBruta    = snd (dropNextWord s)              -- Remove INPUT
        (var, rest) = span (/= ';') varBruta            -- Separate variable name
        remaining   = dropWhile (==' ') (drop 1 rest)   -- Remove ';' and remaining spaces

-- Creates a If Command from a String
readCommandIf :: String -> (Command a, String)
readCommandIf s = (Cond b ifCom elCom, remaining)
    where 
        noIf            = fst $ dropNextWord s      -- Remove IF 
        (b, bRem)       = readBoolExpr noIf         -- Read boolean expression
        thenRem         = fst $ dropNextWord bRem   -- Remove THEN
        (ifCom, ifRem)  = readCommandSeq thenRem    -- Read if commands, stops when founds the ELSE
        eRem            = fst $ dropNextWord ifRem  -- Remove ELSE
        (elCom, elRem)  = readCommandSeq elRem      -- Read else commands, stops when founds END
        remaining       = fst $ dropNextWord elRem  -- Remove END

readCommandWhile :: String -> (Command a , String)
readCommandWhile s      = (Loop b wCom, remaining)
    where
        noWhile         = fst $ dropNextWord s      -- Remove WHILE
        (b, bRem)       = readBoolExpr noWhile      -- Read boolean expression
        dRem            = fst $ dropNextWord bRem   -- Remove DO
        (wCom, wRem)    = readCommandSeq dRem       -- Read sequence
        remaining       = fst $ dropNextWord wRem   -- Remove END


-- Creates a Seq Command from a String
readCommandSeq :: String -> (Command a, String)
readCommandSeq s
    | com == "INPUT"    = readCommandSomSeq readCommandInput s
    | com == "IF"       = readCommandSomSeq readCommandIf s
    | com == "WHILE"    = readCommandSomSeq readCommandWhile s
  {-  | com == "DO"       =
    | com == "PRINT"    =
    | com == "END"      = -}
    | otherwise         = (Seq [], [])
    where 
        com             = fst $ dropNextWord s

        -- Creates a Seq Command from a String and the selected function
        readCommandSomSeq :: (String -> (Command a, String)) -> String -> (Command a, String)
        readCommandSomSeq _ [] = (Seq [], [])
        readCommandSomSeq f x  = (Seq (singleCommand:xs), remaining)
            where   
                (singleCommand, remAux) = f x                   -- Apply the desired function
                (Seq xs, remaining)     = readCommandSeq remAux -- Call the main function to read another command

-- Creates an AST from the input String
readCommand :: Num a => String -> Command a
readCommand s = fst $ readCommandSeq s
    
main :: IO ()
main = 
    do
        h <- openFile "codiPractica.txt" ReadMode
        s <- hGetContents h
        putStrLn (show (readCommand s :: Command Int))
