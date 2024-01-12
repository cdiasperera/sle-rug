module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;
import IO;

/* 
 * Transforming QL forms
 */

alias QuestionGuard = list[tuple[AQuestion question, AExpr guard]];
 
/*
  From a form, get a list that relates a question to the conditions that must
  be true for it to be viewed (referred to as the guard of that question).
*/
QuestionGuard getQuestionGuards(AForm f) {
  QuestionGuard questionGuards = []; 
  
  for (question <- f.questions) {
    questionGuards += getQuestionGuards(question, boolean(true));
  }

  return questionGuards;
}

QuestionGuard getQuestionGuards(AQuestion q, AExpr g) {
  QuestionGuard questionGuards = [];
  switch (q) {
    case ifBlock(AExpr localGuard, ABlock body): {
      for (bodyQ <- body.questions) {
        questionGuards += getQuestionGuards(bodyQ, and(g, localGuard));
      }
    }
    case ifElseBlock(AExpr localGuard, ABlock ifBody, ABlock elseBody): {
      for (bodyQ <- ifBody.questions) {
        questionGuards += getQuestionGuards(bodyQ, and(g, localGuard));
      }
      for (bodyQ <- elseBody.questions) {
        questionGuards += getQuestionGuards(bodyQ, and(g, logicalNegate(localGuard)));
      }
    }
    default:
      questionGuards += [<q, g>];
  }

  return questionGuards;
}
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
AForm flatten(AForm f) {
  QuestionGuard questionGuards = getQuestionGuards(f);

  list[AQuestion] normQuestions = [];
  for (<AQuestion question, AExpr guard> <- questionGuards) {
    normQuestions += [ifBlock(guard, block([question]))];
  }

  return form(f.name, normQuestions);
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc occ, str newName, UseDef useDef) {
   RefGraph refs = resolve(cst2ast(f));
   set[loc] toRename = {};

  if (occ in refs.uses<0>) {
    // Occurence is a usage.

    // Find definition of name
    if (<occ, loc def> <- useDef) {
      toRename += {def};
      
      // Add all usages of name
      toRename += {u | <loc u, def> <- useDef};
    }

  } else {
    // Occurance is a definition.
    // Add it to be renamed
    toRename += {occ};
    
    // Find all related uses and add them
    toRename += {u | <loc u, occ> <- useDef};
  }


   return visit (f) {
    case Id x => [Id]newName
      when x.src in toRename
   }
}