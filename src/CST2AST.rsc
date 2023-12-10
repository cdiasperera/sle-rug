module CST2AST

import String;
import Syntax;
import AST;

import ParseTree;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form

  return cst2ast(f);
}

AForm cst2ast(f:(Form)`form <Id name> { <Question* questions> }`) {
  return form(cst2ast(name), [cst2ast(question) | question <- questions], src=f.src);
}

AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str label> <Id variable> : <Type t>`: 
      return basicQuestion("<label>", cst2ast(variable), cst2ast(t), src=q.src);
    case (Question)`<Str label> <Id variable> : <Type t> = <Expr val>`: 
      return computedQuestion("<label>", cst2ast(variable), cst2ast(t), cst2ast(val), src=q.src);
    case (Question)`if ( <Expr val> ) <Block block>` : 
      return ifBlock(cst2ast(val), cst2ast(block), src=q.src);
    case (Question)`if ( <Expr val> ) <Block ifBlock> else <Block elseBlock>` : 
      return ifElseBlock(cst2ast(val), cst2ast(ifBlock), cst2ast(elseBlock), src=q.src);
    default: throw "Unhandled question: <q>";
  }
}

ABlock cst2ast(b:(Block)`{ <Question* questions>}`) 
  = block([cst2ast(question) | question <- questions], src=b.src);

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`( <Expr e> )` : return cst2ast(e);
    case (Expr)`<Id x>`: return ref(id("<x>", src=x.src), src=x.src);
    case (Expr)`true` : return boolean(true, src=e.src);
    case (Expr)`false` : return boolean(false, src=e.src);
    case (Expr)`<Int i>` : return integer(toInt("<i>"), src=e.src);
    case (Expr)`<Str s>` : return string("<s>", src=e.src);
    case (Expr)`! <Expr e>` : return logicalNegate(cst2ast(e), src = e.src);
    case (Expr)`- <Expr e>` : return negate(cst2ast(e), src=e.src);
    case (Expr)`<Expr e1> * <Expr e2>` : return multiply(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> / <Expr e2>` : return divide(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> - <Expr e2>` : return subtract(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> + <Expr e2>` : return add(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \< <Expr e2>` : return lessThan(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \> <Expr e2>` : return moreThan(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \<= <Expr e2>` : return lessThanEqual(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \>= <Expr e2>` : return moreThanEqual(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> == <Expr e2>` : return equals(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> != <Expr e2>` : return notEquals(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> && <Expr e2>` : return and(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> || <Expr e2>` : return or(cst2ast(e1), cst2ast(e2), src=e.src);
    default: throw "Unhandled expression: <e>";
  }
}

AId cst2ast(i:(Id) identity) = id("<identity>", src=i.src);

AType cst2ast(t:(Type)`boolean`) = boolean(src=t.src);
AType cst2ast(t:(Type)`integer`) = integer(src=t.src);
AType cst2ast(t:(Type)`string`) = string(src=t.src);
