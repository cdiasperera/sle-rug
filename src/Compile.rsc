module Compile

import AST;
import Resolve;
import Eval;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

HTMLElement form2html(AForm f) {
  return html([
    head([
      script([],\type="text/javascript", \src="<f.src[extension="js"].file>")
    ]),
    body([
      h1([text("Form: " + "<f.src[extension=""].file>")]),
      form(
        [
          elem | question <- f.questions, elem <- question2html(question)
        ] +
        [
          input(\type="submit", oninput="updateForm")
        ],
        class="form"
      )
    ])
  ]);
}

list[HTMLElement] question2html(basicQuestion(str lbl, id(str variable), AType t)) {
  return [div(
    [
      label(
        [
          text(lbl),
          input(\type=type2Inputstr(t), name=variable)
        ]
      )
    ],
    class="basicQuestion"
  )];
}

list[HTMLElement] question2html(computedQuestion(str lbl, id(str variable), AType t, AExpr val)) {
  return [div(
    [
      label(
        [
          text(lbl),
          // span([text(expr2Str(val))], hidden=""),
          input(\type=type2Inputstr(t), name=variable, disabled="")
        ]
      )
    ],
    class="computedQuestion"
  )];
}

list[HTMLElement] question2html(ifBlock(AExpr val, ABlock ifBlock)) {
  return [div(
    [
      // span([text(expr2Str(val))], hidden="")
    ] + 
    [
      elem | elem <- block2html(ifBlock)
    ],
    class="if"
  )];
}

list[HTMLElement] question2html(ifElseBlock(AExpr val, ABlock ifBlock, ABlock elseBlock)) {
  return [div(
    [
      // span([text(expr2Str(val))], hidden=""),
      div(block2html(ifBlock), class="ifBlock"),
      div(block2html(elseBlock), class="elseBlock")
    ],
    class="ifElse"
  )];
}

// str expr2Str(ref(id(str name))) = name;
// str expr2Str(boolean(bool b)) = "<b>";
// str expr2Str(integer(int i)) = "<i>";
// str expr2Str(string(str s)) = s;
// str expr2Str(logicalNegate(AExpr e)) = "!(" + expr2Str(e) + ")";
// str expr2Str(negate(AExpr e)) = "-(" + expr2Str(e) + ")";
// str expr2Str(multiply(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") * (" + expr2Str(e2) + ")";
// str expr2Str(divide(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") / (" + expr2Str(e2) + ")";
// str expr2Str(subtract(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") - (" + expr2Str(e2) + ")";
// str expr2Str(add(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") + (" + expr2Str(e2) + ")";
// str expr2Str(lessThan(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") \< (" + expr2Str(e2) + ")";
// str expr2Str(moreThan(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") \> (" + expr2Str(e2) + ")";
// str expr2Str(lessThan(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") \<= (" + expr2Str(e2) + ")";
// str expr2Str(moreThan(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") \>= (" + expr2Str(e2) + ")";
// str expr2Str(equals(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") == (" + expr2Str(e2) + ")";
// str expr2Str(notEquals(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") != (" + expr2Str(e2) + ")";
// str expr2Str(and(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") && (" + expr2Str(e2) + ")";
// str expr2Str(or(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") || (" + expr2Str(e2) + ")";

str type2Inputstr(boolean()) = "checkbox";
str type2Inputstr(integer()) = "number";
str type2Inputstr(string()) = "text";
default str type2Inputstr(AType t) = "Unsupported";


list[HTMLElement] block2html(ABlock b)
{
  return [
    elem | question <- b.questions, elem <- question2html(question)
  ];
}

str form2js(AForm f) {
  return  " var names2values = Map()
          ' <registerInputs(f)>
          '
          ";
}

str registerInputs(AForm f) {
  str jsCode = "";
  for (question <- f.questions)
    if (basicQuestion(str label, id(str name) ,_) := question) {
      return "";
    }
  return jsCode;
}