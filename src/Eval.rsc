module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str label, Value \value);
  
Value defaultValueForType(integer()) = vint(0);
Value defaultValueForType(boolean) = vbool(true);
Value defaultValueForType(string()) = vstr("");

// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  
  for (/basicQuestion(_, id(str name), AType \type) := f) {
    venv += (name : defaultValueForType(\type));
  }

  for (/computedQuestion(_, id(str name), AType \type, _) := f) {
    venv += (name : defaultValueForType(\type));
  }

  return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for (question <- f.questions) {
    venv = eval(question, inp, venv);
  }
  return venv;
}

VEnv eval(ABlock b, Input inp, VEnv venv) {
  for (question <- b.questions) {
    venv = eval(question, inp, venv);
  }

  return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch (q) {
    // evaluate inp and computed questions to return updated VEnv
    case basicQuestion(str label, id(str name), _) : 
      if (inp.label == label) {
        venv += (name : inp.\value);
      }
    case computedQuestion(_, id(str name), _, AExpr val) : 
      venv += (name : eval(val, venv));
    // Evaluate conditions for branching
    case ifBlock(AExpr val, ABlock ifBlock) :
      if (vbool(true) := eval(val, venv)) {
        return eval(ifBlock, inp, venv);
      }
    case ifElseBlock(AExpr val, ABlock ifBlock, ABlock elseBlock) :
      if (vbool(true) := eval(val, venv)) {
        return eval(ifBlock, inp, venv);
      } else {
        return eval(elseBlock, inp, venv);
      }
  }
  return venv;
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case boolean(bool b): return vbool(b);
    case integer(int i): return vint(i);
    case string(str s): return vstr(s);
    case logicalNegate(AExpr e) : 
      if (vbool(bool b) := eval(e, venv)) {
        return vbool(!b); 
      }
    case negate(AExpr e): 
      if (vint(int i) := eval(e, venv)) {
        return vint(-i); 
      }
    case multiply(AExpr e1, AExpr e2): 
      if (vint(int i1) := eval(e, venv) && vint(int i2) := eval(e, venv)) {
        return vint(i1 * i2); 
      }
    case divide(AExpr e1, AExpr e2): 
      if (vint(int i1) := eval(e, venv) && vint(int i2) := eval(e, venv)) {
        return vint(i1 / i2); 
      }
    case subtract(AExpr e1, AExpr e2): 
      if (vint(int i1) := eval(e, venv) && vint(int i2) := eval(e, venv)) {
        return vint(i1 - i2); 
      }
    case add(AExpr e1, AExpr e2): 
      if (vint(int i1) := eval(e, venv) && vint(int i2) := eval(e, venv)) {
        return vint(i1 + i2); 
      }
    case lessThan(AExpr e1, AExpr e2): 
      if (vint(int i1) := eval(e, venv) && vint(int i2) := eval(e, venv)) {
        return vbool(i1 < i2); 
      }
    case moreThan(AExpr e1, AExpr e2): 
      if (vint(int i1) := eval(e, venv) && vint(int i2) := eval(e, venv)) {
        return vbool(i1 > i2); 
      }
    case lessThanEqual(AExpr e1, AExpr e2): 
      if (vint(int i1) := eval(e, venv) && vint(int i2) := eval(e, venv)) {
        return vbool(i1 <= i2); 
      }
    case moreThanEqual(AExpr e1, AExpr e2): 
      if (vint(int i1) := eval(e, venv) && vint(int i2) := eval(e, venv)) {
        return vbool(i1 >= i2); 
      }
    case and(AExpr e1, AExpr e2): 
      if (vbool(bool b1) := eval(e, venv) && vbool(bool b2) := eval(e, venv)) {
        return vbool(b1 && b2); 
      }
    case or(AExpr e1, AExpr e2): 
      if (vbool(bool b1) := eval(e, venv) && vbool(bool b2) := eval(e, venv)) {
        return vbool(b1 || b2); 
      }
    case equals(AExpr e1, AExpr e2): 
      if (eval(e1, venv) == eval(e2, venv)) {
        return vbool(true);
      } else {
        return vbool(false);
      }
    case notEquals(AExpr e1, AExpr e2): 
      if (eval(e1, venv) == eval(e2, venv)) {
        return vbool(false);
      } else {
        return vbool(true);
      }
    default: throw "Unsupported expression <e>";
  }

  throw "Error in evaluating expression";
}