module AST

data AForm(loc src = |tmp:///|)
  = form(AId name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = basicQuestion(str label, AId variable, AType \type)
  | computedQuestion(str label, AId variable, AType \type, AExpr val)
  | ifBlock(AExpr val, ABlock ifBlock)
  | ifElseBlock(AExpr val, ABlock ifBlock, ABlock elseBlock)
  ; 

data ABlock(loc src = |tmp:///|)
  = block(list[AQuestion] questions)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | boolean(bool b)
  | integer(int i)
  | string(str s)
  | logicalNegate(AExpr e)
  | negate(AExpr e)
  | multiply(AExpr e1, AExpr e2)
  | divide(AExpr e1, AExpr e2)
  | subtract(AExpr e1, AExpr e2)
  | add(AExpr e1, AExpr e2)
  | lessThan(AExpr e1, AExpr e2)
  | moreThan(AExpr e1, AExpr e2)
  | lessThanEqual(AExpr e1, AExpr e2)
  | moreThanEqual(AExpr e1, AExpr e2)
  | equals(AExpr e1, AExpr e2)
  | notEquals(AExpr e1, AExpr e2)
  | and(AExpr e1, AExpr e2)
  | or(AExpr e1, AExpr e2)
  ;


data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = boolean()
  | integer()
  | string()
  ;