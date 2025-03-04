# RUSH-Lex_and_Yacc-

// Program Structure
<program>    ::= start <block> done

// Block Structure
<block>      ::= '{' <statement_list> '}'
<statement_list> ::= <statement> 
                   | <statement> <statement_list>

// Statements
<statement>  ::= <output_stmt>
                | <input_stmt>
                | <assignment_stmt>
                | <if_stmt>
                | <loop_stmt>
                | <function_def>
                | <function_call>

// Basic Statements
<output_stmt>    ::= output '(' <expr> ')'
                   | output '(' <string> ')'
<input_stmt>     ::= take '(' <var> ')'
<assignment_stmt> ::= <var> '=' <expr>

// Control Structures
<if_stmt>    ::= if '(' <condition> ')' <block>
                | if '(' <condition> ')' <block> else <block>

<loop_stmt>  ::= iterate from <expr> to <expr> by <expr> <block>

// Functions
<function_def>   ::= define <identifier> '(' <param_list> ')' <block>
<function_call>  ::= call <identifier> '(' <arg_list> ')'
<param_list>     ::= ε 
                   | <identifier>
                   | <identifier> ',' <param_list>
<arg_list>       ::= ε
                   | <expr>
                   | <expr> ',' <arg_list>

// Expressions
<expr>       ::= <term>
                | <expr> '+' <term>
                | <expr> '-' <term>
<term>       ::= <factor>
                | <term> '*' <factor>
                | <term> '/' <factor>
                | <term> '%' <factor>
<factor>     ::= <number>
                | <var>
                | <function_call>
                | '(' <expr> ')'

// Conditions
<condition>  ::= <expr> '==' <expr>
                | <expr> '!=' <expr>
                | <expr> '>' <expr>
                | <expr> '<' <expr>
                | <expr> '>=' <expr>
                | <expr> '<=' <expr>

// Basic Elements
<var>        ::= <identifier>
<identifier> ::= <letter> { <letter> | <digit> | '_' }
<number>     ::= <digit> { <digit> }
<string>     ::= '"' { <character> } '"'
<letter>     ::= [a-zA-Z]
<digit>      ::= [0-9]
<character>  ::= any-printable-character