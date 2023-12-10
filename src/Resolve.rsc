module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  return {<s,"<i>"> | /ref(id(str i), src=s) := f}; 
}

Def defs(AForm f) {
  // Form name
  return {<"<i>", s> | /form(id(str i, src=s), _) := f}
    // question variable in basic question
    + {<"<i>", s> | /basicQuestion(_,id(str i,src=s), _) := f}
    // question variable in computed question
    + {<"<i>", s> | /computedQuestion(_,id(str i, src=s), _, _) := f}; 
}