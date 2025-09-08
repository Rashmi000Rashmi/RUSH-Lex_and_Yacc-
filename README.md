# RUSH Programming Language Grammar

## Overview
RUSH is a programming language with a clean and simple grammar structure. This document outlines the complete grammar specification for the RUSH language.

## Getting Started

### Prerequisites
- Flex (for lexical analysis)
- Bison/Yacc (for parsing)
- GCC (GNU Compiler Collection)
- Make (build automation tool)

### Building and Running
1. First, make the build script executable:
   ```bash
   chmod +x make.sh
   ```

2. Run the build script to compile the lexer and parser:
   ```bash
   ./make.sh
   ```
   This will:
   - Generate C code from lexer.l using Flex
   - Generate C code from parser.y using Bison/Yacc
   - Compile the generated code into an executable

3. Run a RUSH program:
   ```bash
   ./rush test.rush
   ```
   Replace `test.rush` with your own RUSH program file.

### File Structure
- `lexer.l`: Contains the lexical analyzer rules
- `parser.y`: Contains the grammar rules and parsing logic
- `make.sh`: Build script to compile the compiler
- `test.rush`: Example RUSH program for testing
- `README.md`: This documentation file

## Grammar Rules

### Program Structure
```
<program>    ::= start <block> done
```

### Block Structure
```
<block>         ::= '{' <statement_list> '}'
<statement_list>::= <statement> 
                  | <statement> <statement_list>
```

### Statements
```
<statement>  ::= <output_stmt>
                | <input_stmt>
                | <assignment_stmt>
                | <if_stmt>
                | <loop_stmt>
                | <function_def>
                | <function_call>
```

### Basic Statements
```
<output_stmt>     ::= output '(' <expr> ')'
                    | output '(' <string> ')'
<input_stmt>      ::= take '(' <var> ')'
<assignment_stmt> ::= <var> '=' <expr>
```

### Control Structures
```
<if_stmt>    ::= if '(' <condition> ')' <block>
                | if '(' <condition> ')' <block> else <block>

<loop_stmt>  ::= iterate from <expr> to <expr> by <expr> <block>
```

### Functions
```
<function_def>   ::= define <identifier> '(' <param_list> ')' <block>
<function_call>  ::= call <identifier> '(' <arg_list> ')'
<param_list>     ::= ε 
                   | <identifier>
                   | <identifier> ',' <param_list>
<arg_list>       ::= ε
                   | <expr>
                   | <expr> ',' <arg_list>
```

### Expressions
```
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
```

### Conditions
```
<condition>  ::= <expr> '==' <expr>
                | <expr> '!=' <expr>
                | <expr> '>' <expr>
                | <expr> '<' <expr>
                | <expr> '>=' <expr>
                | <expr> '<=' <expr>
```

### Basic Elements
```
<var>        ::= <identifier>
<identifier> ::= <letter> { <letter> | <digit> | '_' }
<number>     ::= <digit> { <digit> }
<string>     ::= '"' { <character> } '"'
<letter>     ::= [a-zA-Z]
<digit>      ::= [0-9]
<character>  ::= any-printable-character
```