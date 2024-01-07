module MyTest

import Syntax;
import CST2AST;
import ParseTree;
import Compile;

void mainTest() {
  pt = parse(#Form, |project://sle-rug/examples/tax.myql|);
  ast = cst2ast(pt);

  compile(ast);
}