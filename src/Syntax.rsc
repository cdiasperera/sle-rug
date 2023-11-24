module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

syntax Question 
  = Str question Id variable ":" Type type ("=" Expr value)?
  | "if" "(" Expr value ")" Block block ("else" Block block)?
  ;

syntax Block
  = "{" Question* questions "}"
  ;

// Following C style precedene
syntax Expr 
  = "(" Expr e ")"
  | Id \ "true" \ "false" // true/false are reserved keywords.
  > Bool bool | Int int | Str str
  > "!" Expr e | "-" Expr e
  > left ( Expr e1 "*" Expr e2 | Expr e1 "/" Expr e2 )
  > left ( Expr e1 "-" Expr e2 | Expr e1 "+" Expr e2 )
  > left (Expr e1 "\<" Expr e2 | Expr e1 "\>" Expr e2 | Expr e1 "\<=" Expr e2 | Expr e1 "\>=" Expr e2 )
  > left ( Expr e1 "==" Expr e2 | Expr e1 "!=" Expr e2 )
  > left ( Expr e1 "&&" Expr e2 | Expr e1 "||" Expr e2 )
  ;

syntax Type = "integer" | "boolean" | "string";

lexical Str = "\"" [\ !\a23-\a7f]* "\"";

lexical Int = [0-9]+;

lexical Bool = "true" | "false";