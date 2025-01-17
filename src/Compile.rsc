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
  compile(f, f.src[extension="js"].top, f.src[extension="html"].top);
}

void compile(AForm f, loc outJS, loc outHTML) {
  writeFile(outJS, form2js(f));
  writeFile(outHTML, writeHTMLString(form2html(f, outJS)));
}

HTMLElement form2html(AForm f, loc jsLOC) {
  return html([
    head([
      script([],\type="text/javascript", \src="<jsLOC.file>")
    ]),
    body([
      h1([text("Form: " + "<f.src[extension=""].file>")]),
      form(
        [
          elem | question <- f.questions, elem <- question2html(question)
        ] +
        [
          input(\type="submit")
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
      span([text(expr2Str(val))], hidden="")
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
      span([text(expr2Str(val))], hidden=""),
      div(block2html(ifBlock), class="ifBlock"),
      div(block2html(elseBlock), class="elseBlock")
    ],
    class="ifElse"
  )];
}

str expr2Str(ref(id(str name))) = "name2Value[\'<name>\']";
str expr2Str(boolean(bool b)) = "<b>";
str expr2Str(integer(int i)) = "<i>";
str expr2Str(string(str s)) = s;
str expr2Str(logicalNegate(AExpr e)) = "!(" + expr2Str(e) + ")";
str expr2Str(negate(AExpr e)) = "-(" + expr2Str(e) + ")";
str expr2Str(multiply(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") * (" + expr2Str(e2) + ")";
str expr2Str(divide(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") / (" + expr2Str(e2) + ")";
str expr2Str(subtract(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") - (" + expr2Str(e2) + ")";
str expr2Str(add(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") + (" + expr2Str(e2) + ")";
str expr2Str(lessThan(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") \< (" + expr2Str(e2) + ")";
str expr2Str(moreThan(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") \> (" + expr2Str(e2) + ")";
str expr2Str(lessThan(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") \<= (" + expr2Str(e2) + ")";
str expr2Str(moreThan(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") \>= (" + expr2Str(e2) + ")";
str expr2Str(equals(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") == (" + expr2Str(e2) + ")";
str expr2Str(notEquals(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") != (" + expr2Str(e2) + ")";
str expr2Str(and(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") && (" + expr2Str(e2) + ")";
str expr2Str(or(AExpr e1, AExpr e2)) = "(" + expr2Str(e1) + ") || (" + expr2Str(e2) + ")";

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
  return  " const MAX_ITERS = 3;
          ' var name2Value = new Map();
          ' window.onload = () =\> {
          '   <initializeMap(f)>
          '   <registerListeners()>
          '   <updateFormGUIAsJS(f)>
          ' }
          ' function updateForm(e) {
          '   var updated = false;
          '   var iters = 0;
          '   do {
          '     updated ||= processEvents(e);
          '     iters++
          '   } while (updated && iters \< MAX_ITERS);
              <updateFormGUIAsJS(f)>
          ' }
          ' function submitForm(e) {
          '   e.preventDefault();
          '   alert(\'The form has been submitted!\');
          ' }
          ' <processEventAsJS(f)>
          ";
}

str updateFormGUIAsJS(AForm f) {
  return  " <for (AQuestion q <- f.questions) {>
          '   <question2updateFormGUI(q)>
          ' <}>
          ";
}

str question2updateFormGUI(basicQuestion(_,_,_)) = "";
str question2updateFormGUI(computedQuestion(_,_,AType \type,_)) {
  return  " var computedQuestions = document.getElementsByClassName(\'computedQuestion\');
          ' for (const question of computedQuestions)
          '   var input = question.firstElementChild.firstElementChild;
          '   var name = input.name;
          '   var value = name2Value[name];
          '   if (typeof value === \'string\') {
          '     input.value = value;
          '   } else if (typeof value === \'number\') {
          '     input.value = Math.floor(value)
          '   } else {
          '     input.checked = value;
          '   }
          ";
}
str question2updateFormGUI(ifBlock(AExpr expr, ABlock ifBlock)) {
  return  " var ifBlocks = document.getElementsByClassName(\'if\');
          ' for (const block of ifBlocks) {
          '   var guardExpr = block.firstElementChild.textContent;
          '   if (guardExpr  == \"<expr2Str(expr)>\") {
          '     var guardRes = <expr2Str(expr)>;
          '     if (guardRes) {
          '       block.hidden = false;
          '     } else {
          '       block.hidden = true;  
          '     }
          '   }
          ' }
          ";
}
str question2updateFormGUI(ifElseBlock(AExpr expr, ABlock ifBlock, ABlock elseBlock)) {
  return  " var ifElseBlocks = document.getElementsByClassName(\'ifElse\');
          ' for (const block of ifElseBlocks) {
          '   var guardExpr = block.firstElementChild.textContent;
          '   var ifBlock = block.firstElementChild.nextElementSibling;
          '   var elseBlock = ifBlock.nextElementSibling;
          '   if (guardExpr == \"<expr2Str(expr)>\") {
          '     var guardRes = <expr2Str(expr)>;
          '     if (guardRes) {
          '       ifBlock.hidden = false;
          '       elseBlock.hidden = true;
          '     } else {
          '       ifBlock.hidden = true;
          '       elseBlock.hidden = false;
          '     }
          '   }
          ' }
          ";
}

str registerListeners() {
  return  " inputs = document.getElementsByTagName(\'input\');
          ' for (const input of inputs) {
          '   if (input.type != \'submit\') {
          '     input.addEventListener(\'input\', updateForm) 
          '   } else {
          '     input.addEventListener(\'input\', submitForm)
          '   }
          ' }
          ";
}

str initializeMap(AForm f) {
  return  " <for (AQuestion q <- f.questions) {>
          '     <initializeMapWithQuestion(q)>
          '   <}>
          ";
}

str initializeMapWithQuestion(basicQuestion(_, id(str name), AType \type)) {
  return "name2Value[\'<name>\'] = <defaultForType(\type)>";
}
str initializeMapWithQuestion(computedQuestion(_, id(str name), AType \type,_)) {
  return "name2Value[\'<name>\'] = <defaultForType(\type)>";
}

str initializeMapWithQuestion(ifBlock(_, ABlock b)) = initializeMapWithBlock(b);
str initializeMapWithQuestion(ifElseBlock(_,ABlock ifBlock, ABlock elseBlock)) = 
  initializeMapWithBlock(ifBlock) + initializeMapWithBlock(elseBlock);

str initializeMapWithBlock(ABlock b) {
  return  " <for (AQuestion q <- b.questions) {>
          '   <initializeMapWithQuestion(q)>
          ' <}>
          ";
}

str defaultForType(boolean()) = "false";
str defaultForType(string()) = "\"\"";
str defaultForType(integer()) = "0";

str processEventAsJS(AForm f) {
  return  " function processEvents(e) {
          '   var inputLabel = e.target.previousSibling.textContent;
          '   inputLabel = inputLabel.slice(1, inputLabel.length - 1);
          '   var updated = false
          '   <for (AQuestion q <- f.questions) {>
          '     <question2code(q)>
          '   <}>
          '   return updated;
          ' }
          ";
}

str question2code(basicQuestion(str label, id(str name) , AType \type)) {
  return  " if (<label> == inputLabel) {
          '   <if (\type := boolean()) { >
          '     var value = e.target.checked ? true : false;
          '   <} else {>
          '     var value = e.target.value;
          '   <}>
          '   name2Value[\'<name>\'] = value;
          '   updated = true;
          ' }
          ";
}

str question2code(computedQuestion(str label, id(str name) , AType \type, AExpr val)) {
  return  " var curr = name2Value[\'<name>\'];
          ' var newVal = <expr2Str(val)>;
          ' if (newVal != curr) {
          '   name2Value[\'<name>\'] = newVal;
          '   updated = true;
          ' }
          ";
}

str question2code(ifBlock(AExpr val, ABlock ifBlock)) {
  return  " if (<expr2Str(val)>) {
          '   <for (AQuestion q <- ifBlock.questions) {>
          '     <question2code(q)>
          '   <}>
          ' }
          ";
}

str question2code(ifElseBlock(AExpr val, ABlock ifBlock, ABlock elseBlock)) {
  return  " if (<expr2Str(val)>) {
          '   <for (AQuestion q <- ifBlock.questions) {>
          '     <question2code(q)>
          '   <}>
          ' } else {
          '   <for (AQuestion q <- elseBlock.questions) {>
          '     <question2code(q)>
          '   <}>
          ' }
          ";
}


default str question2code(AQuestion q) {
  return "A Question!";
}
