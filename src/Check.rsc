module Check

import AST;
import Resolve;
import Message;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// Collect question name information
TEnv collect(AForm f) {
  env = {};

  visit(f) {
    case basicQuestion(str label, id(str name, src = nameLoc), AType \type):
      env += {<nameLoc, name, label, semanticType(\type)>};
    case computedQuestion(str label, id(str name, src = nameLoc), AType \type, _):
      env += {<nameLoc, name, label, semanticType(\type)>};
  };

  return env;
}

set[Message] check(form(_,list[AQuestion] questions), TEnv tenv, UseDef useDef) {
  return {message | question <- questions, message <- check(question, tenv, useDef)};
}

set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  messages = {};
  switch (q) {
    case basicQuestion(str label, id(str name, src = nameLoc), AType \type, src = qLoc) : 
      for (otherQ <- tenv) {
        messages += questionMessages(<qLoc, name, label, semanticType(\type)>, otherQ, nameLoc);
      }
    case computedQuestion(str label, id(str name, src = nameLoc), AType \type, AExpr val, src = qLoc) : 
      for (otherQ <- tenv) {
        messages += questionMessages(<qLoc, name, label, semanticType(\type)>, otherQ, nameLoc);

        // Check for issues in evaluating val
        valEvaluationMessages = check(val, tenv, useDef);
        messages += valEvaluationMessages;

        // Check if declared type matches value type, only if no issue with val evaluation
        if (valEvaluationMessages == {} && typeOf(val, tenv, useDef) != semanticType(\type)) {
          messages += error("Type of evaluated value does not match declared type", \type.src);
        }
      }
    case ifBlock(AExpr val, ABlock ifBlock) : {
      messages += checkGuard(val, tenv, useDef, val.src);
      messages += check(ifBlock, tenv, useDef);
    }
    case ifElseBlock(AExpr val, ABlock ifBlock, ABlock elseBlock) : {
      messages += checkGuard(val, tenv, useDef, val.src);
      messages += check(ifBlock, tenv, useDef);
      messages += check(elseBlock, tenv, useDef);
    }
  };
  return messages; 
}

// Messages that arises from comparing two questions
set[Message] questionMessages(<loc1, name1, label1, type1>, <loc2, name2, label2, type2>, errorLoc) {
  set[Message] messages = {};
  // Only check against different questions
  if (loc2 != loc1) {
    // Error if there are declared questions with the same name but different types.
    if (name2 == name1 && type2 != type1) {
      messages += {error("Question has the same name as another question", errorLoc)};
    }
    // Warning if there are different labels for the same question (name)
    if (name2 == name1 && label2 != label1) {
      messages += {warning("Another question with the same name has a different label", errorLoc)};
    }
    // Warning if there are the same labels for different question (name)
    if (name2 != name1 && label2 == label1) {
      messages += {warning("Another question with a different name but the same label", errorLoc)};
    }
  }

  return messages;
}

// Messages that arises from conditional constructs in our syntax
set[Message] checkGuard(AExpr val, TEnv tenv, UseDef useDef, errorLoc) {
  set[Message] messages = {};

  // Check if any issues with evaluating guard
  messages += check(val, tenv, useDef);
  
  // Only check type correctness of guard if no issue in guard evaluation
  if (messages == {} && typeOf(val, tenv, useDef) != tbool()) {
    messages += {error("Guard value does not evaluate to boolean", errorLoc)};
  }
  
  return messages;
}

set[Message] check(ABlock block, TEnv tenv, UseDef useDef) {
  return {message | list[AQuestion] questions <- block, question <- questions, message <- check(question, tenv, useDef)};
}

// Check operand compatibility with operators / Undefined usages
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(AId x): {
      return { error("Undeclared question", x.src) | useDef[x.src] == {} };
    }
    case logicalNegate(AExpr e): return checkOperand(e, "logically negate", tbool(), tenv, useDef);  
    case negate(AExpr e): return checkOperand(e, "negate", tint(), tenv, useDef);
    case multiply(AExpr e1, AExpr e2) : return checkOperand(e1, "multiply", tint(), tenv, useDef) + checkOperand(e2, "multiply", tint(), tenv, useDef);
    case divide(AExpr e1, AExpr e2) : return checkOperand(e1, "divide", tint(), tenv, useDef) + checkOperand(e2, "divide", tint(), tenv, useDef);
    case subtract(AExpr e1, AExpr e2) : return checkOperand(e1, "subtract", tint(), tenv, useDef) + checkOperand(e2, "subtract", tint(), tenv, useDef);
    case add(AExpr e1, AExpr e2) : return checkOperand(e1, "add", tint(), tenv, useDef) + checkOperand(e2, "add", tint(), tenv, useDef);
    case lessThan(AExpr e1, AExpr e2) : return checkOperand(e1, "compare", tint(), tenv, useDef) + checkOperand(e2, "compare", tint(), tenv, useDef);
    case moreThan(AExpr e1, AExpr e2) : return checkOperand(e1, "compare", tint(), tenv, useDef) + checkOperand(e2, "compare", tint(), tenv, useDef);
    case lessThanEqual(AExpr e1, AExpr e2) : return checkOperand(e1, "compare", tint(), tenv, useDef) + checkOperand(e2, "compare", tint(), tenv, useDef);
    case moreThanEqual(AExpr e1, AExpr e2) : return checkOperand(e1, "compare", tint(), tenv, useDef) + checkOperand(e2, "compare", tint(), tenv, useDef);
    case and(AExpr e1, AExpr e2) : return checkOperand(e1, "AND", tint(), tenv, useDef) + checkOperand(e2, "AND", tint(), tenv, useDef); 
    case or(AExpr e1, AExpr e2) : return checkOperand(e1, "OR", tint(), tenv, useDef) + checkOperand(e2, "OR", tint(), tenv, useDef);
    case equals(AExpr e1, AExpr e2) : return checkEqualOperandTypes(e1, e2, tenv, useDef, e.src); 
    case notEquals(AExpr e1, AExpr e2) : return checkEqualOperandTypes(e1, e2, tenv, useDef, e.src);
  }

  return {};  
}

set[Message] checkOperand(AExpr e, str action, Type expectedType, TEnv tenv, UseDef useDef) {

  // Check that there's no issues evaluatign e
  evalMessages = check(e, tenv, useDef);

  // If there's an issue, return those messages
  if (evalMessages != {}) {
    return evalMessages;
  }

  // Evaluation of e is fine, now checking if it matches expected type

  str typeName = "";  

  switch (expectedType) {
    case tbool() : typeName = "Boolean"; 
    case tint() : typeName = "Integer"; 
    case tstr() : typeName = "String"; 
  }

  return {error("Cannot " + action + " non-" + typeName, e.src) | typeOf(e, tenv, useDef) != expectedType};
}

set[Message] checkEqualOperandTypes(AExpr e1, AExpr e2, tenv, useDef, errLoc) {
  set[Message] messages = {};

  // Check if there's any issues with evaluating either operands
  messages += check(e1, tenv, useDef);
  messages += check(e2, tenv, useDef);
  if (messages != {}) {
    return messages;
  }

  // Check if there is a type mismatch
  return {error("Types in comparison do not match", errLoc) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef)};
}

Type semanticType(boolean()) = tbool();
Type semanticType(integer()) = tint();
Type semanticType(string()) = tstr();

Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
  when 
    <u, loc d> <- useDef, <d, _, _, Type t> <- tenv;

Type typeOf(boolean(_), TEnv tenv, UseDef useDef) = tbool();
Type typeOf(integer(_), TEnv tenv, UseDef useDef) = tint();
Type typeOf(string(_), TEnv tenv, UseDef useDef) = tstr();

Type typeOf(logicalNegate(_), TEnv, UseDef useDef) = tbool();
Type typeOf(negate(_), TEnv, UseDef useDef) = tint();
Type typeOf(multiply(_,_), TEnv, UseDef useDef) = tint();
Type typeOf(divide(_,_), TEnv, UseDef useDef) = tint();
Type typeOf(subtract(_,_), TEnv, UseDef useDef) = tint();
Type typeOf(add(_,_), TEnv, UseDef useDef) = tint();

Type typeOf(lessThan(_,_), TEnv, UseDef useDef) = tbool();
Type typeOf(moreThan(_,_), TEnv, UseDef useDef) = tbool();
Type typeOf(lessThanEqual(_,_), TEnv, UseDef useDef) = tbool();
Type typeOf(moreThanEqual(_,_), TEnv, UseDef useDef) = tbool();
Type typeOf(equals(_,_), TEnv, UseDef useDef) = tbool();
Type typeOf(notEquals(_,_), TEnv, UseDef useDef) = tbool();
Type typeOf(and(_,_), TEnv, UseDef useDef) = tbool();
Type typeOf(or(_,_), TEnv, UseDef useDef) = tbool();

default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();