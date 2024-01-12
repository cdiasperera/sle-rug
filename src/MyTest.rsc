module MyTest

import Syntax;
import Compile;
import CST2AST;
import ParseTree;
import Transform;
import Resolve;
import IO;
import vis::Text;
void mainTest() {
  str newName = "myName";

  pt = parse(#start[Form], |project://sle-rug/examples/tax.myql|);
  ast = cst2ast(pt);
  RefGraph refGraph = resolve(ast);
  
  loc occ1 = getFirstUsageLocFor("hasSoldHouse", refGraph);
  loc occ2 = getDefLocFOr("hasMaintLoan", refGraph);

  // println(rename(pt, occ2, newName, refGraph.useDef));
  flattened = flatten(ast);

  loc flattenedJS = |project://sle-rug/examples/flattened.js|;
  loc flattenedHTML = |project://sle-rug/examples/flattened.html|;
  compile(flattened, flattenedJS, flattenedHTML);

}

loc getFirstUsageLocFor(str name, RefGraph refGraph)
{
  for (<loc use, str n> <- refGraph.uses) {
    if (name == n) {
      return use;
    }
  }
}

loc getDefLocFOr(str name, RefGraph refGraph)
{
  for (<str n, loc def> <- refGraph.defs) {
    if (name == n) {
      return def;
    }
  }
  
}