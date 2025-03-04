%{
#define YYSTYPE long
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h> 

/* Global variables */
#define null 0

/* Parse tree record structure */
typedef struct node 
{
    int token;
    long val;
    struct node *ptr1;
    struct node *ptr2;
    struct node *ptr3;
    struct node *ptr4;
    int loop_flag;
} node;

typedef struct 
{
    char name[2];         // Function name Can only take single character
    node* param_list;     // Parameters
    node* body;           // Function body
    int param_count;      // Number of parameters
} Function;

/* Global variables */
#define MAX_FUNCTIONS 100
Function functions[MAX_FUNCTIONS];
int function_count = 0;

/* Prototypes */
void yyerror(const char* s);
int yylex(void);
long makeNode(int token, int val, long p1, long p2, long p3, long p4);
int evalExpr(node* tree);
void runStmt(long ptr);
void computeStmt(node* tree);
void cleanUp(node* tree);
void systemError(const char* str);
void processLoopBody(node* body);
long processLoop(node* loopNode);
void storeStringVar(int id, const char* str);
char* getStringVar(int id);
void cleanupStringVars();
void initStringVars();
void defineFunction(node* funcNode);
void callFunction(node* callNode);

int getVar(int id);
void storeVar(int id, int val);

/* Variables */
int vars[26];
int in_loop = 0; // Flag to prevent cleanUp from removing nodes used in loops
char* string_vars[26]; 

%}

/* BISON Declarations */
%start program  /* start rule */

%token NUMBER IDENTIFIER STRING
%token START DONE OUTPUT TAKE IF ELSE
%token ITERATE FROM TO BY DEFINE CALL
%token EQ NEQ GT LT GTE LTE
%token PLUS MINUS TIMES DIVIDE MOD ASSIGN
%token LPAREN RPAREN LBRACE RBRACE COMMA
%token LOOP_BODY_FLAG

%left PLUS MINUS
%left TIMES DIVIDE MOD

/* Grammar follows */
%%
program: START block DONE
;

block: LBRACE statement_list RBRACE 
{
    // Create a block node that contains the first statement
    node* blockNode = malloc(sizeof(node));
    blockNode->token = LBRACE;
    blockNode->val = 0;
    blockNode->ptr1 = (node*)$2;  // First statement
    blockNode->ptr2 = NULL;
    blockNode->ptr3 = NULL;
    blockNode->ptr4 = NULL;
    
    $$ = (long)blockNode;
}
;

statement_list: statement 
{
    $$ = $1;
}
| statement statement_list 
{
    // Add safety check for valid first statement
    if ($1 > 1000)  // Basic pointer sanity check
    {
        node* firstStmt = (node*)$1;
        firstStmt->ptr2 = (node*)$2;  // Link to next statement
        $$ = $1;
    } 
    else
    {
        // If first statement is invalid, use the next statements
        $$ = $2;
    }
}
;

statement: OUTPUT LPAREN expr RPAREN
{
    $$ = makeNode(OUTPUT, 0, $3, null, null, null); 
    runStmt($$); 
}
| OUTPUT LPAREN STRING RPAREN
{
    $$ = makeNode(OUTPUT, $3, null, null, null, null); 
    runStmt($$); 
}
| TAKE LPAREN IDENTIFIER RPAREN
{
    $$ = makeNode(TAKE, 0, $3, null, null, null); 
    runStmt($$); 
}
| IDENTIFIER ASSIGN expr
{
    $$ = makeNode(ASSIGN, $1, $3, null, null, null); 
    runStmt($$); 
}
| if_stmt
{
    $$ = $1;
}
| loop_stmt
{
    $$ = $1;
}
| function_def
{
    $$ = $1;
}
| function_call
{
    $$ = $1;
}
;

if_stmt: IF LPAREN condition RPAREN block
{
    $$ = makeNode(IF, 0, $3, $5, null, null); 
    runStmt($$); 
}
| IF LPAREN condition RPAREN block ELSE block
{
    $$ = makeNode(IF, 0, $3, $5, $7, null); 
    runStmt($$); 
}
;

loop_stmt: ITERATE FROM expr TO expr BY expr block
{
    // Create a comprehensive loop node
    node* loopNode = makeNode(ITERATE, 0, 
        (long)$3,    // Start expression 
        (long)$5,    // End expression
        (long)$7,    // Step expression
        (long)$8     // Body block
    );

    // During parsing, prepare the loop body statements
    $$ = (long)processLoop(loopNode);
}
;

function_def: DEFINE IDENTIFIER LPAREN param_list RPAREN block
{
    // Create a function definition node
    $$ = makeNode(DEFINE, $2, $4, $6, null, null); 
    // Immediately run the statement to register the function
    runStmt($$); 
}
;

function_call: IDENTIFIER LPAREN arg_list RPAREN
{
    // Create a function call node
    $$ = makeNode(CALL, $1, $3, null, null, null); 
    // Immediately run the statement to execute the function
    runStmt($$); 
}
;

param_list: /* empty */
{
    $$ = null;
}
| IDENTIFIER
{
    $$ = makeNode(IDENTIFIER, $1, null, null, null, null);
}
| IDENTIFIER COMMA param_list
{
    $$ = makeNode(IDENTIFIER, $1, $3, null, null, null);
}
;

arg_list: /* empty */
{
    $$ = null;
}
| expr
{
    $$ = $1;
}
| expr COMMA arg_list
{
    $$ = makeNode(COMMA, 0, $1, $3, null, null);
}
;

expr: expr PLUS term
{
    $$ = makeNode(PLUS, 0, $1, $3, null, null);
}
| expr MINUS term
{
    $$ = makeNode(MINUS, 0, $1, $3, null, null);
}
| term
{
    $$ = $1;
}
;

term: term TIMES factor
{
    $$ = makeNode(TIMES, 0, $1, $3, null, null);
}
| term DIVIDE factor
{
    $$ = makeNode(DIVIDE, 0, $1, $3, null, null);
}
| term MOD factor
{
    $$ = makeNode(MOD, 0, $1, $3, null, null);
}
| factor
{
    $$ = $1;
}
;

factor: NUMBER
{
    $$ = makeNode(NUMBER, $1, null, null, null, null);
}
| IDENTIFIER
{
    $$ = makeNode(IDENTIFIER, $1, null, null, null, null);
}
| LPAREN expr RPAREN
{
    $$ = $2;
}
| function_call
{
    $$ = $1;
}
;

condition: expr EQ expr
{
    $$ = makeNode(EQ, 0, $1, $3, null, null);
}
| expr NEQ expr
{
    $$ = makeNode(NEQ, 0, $1, $3, null, null);
}
| expr GT expr
{
    $$ = makeNode(GT, 0, $1, $3, null, null);
}
| expr LT expr
{
    $$ = makeNode(LT, 0, $1, $3, null, null);
}
| expr GTE expr
{
    $$ = makeNode(GTE, 0, $1, $3, null, null);
}
| expr LTE expr
{
    $$ = makeNode(LTE, 0, $1, $3, null, null);
}
;

%%

int main()
{
    printf("RUSH Compiler\n");
    initStringVars();
    yyparse();
    cleanupStringVars();
    return 0;
}

void yyerror(const char* s)
{
    printf("%s\n", s);
}

long makeNode(int token, int val, long p1, long p2, long p3, long p4)
{
    node* myNode;
    myNode = (node*)malloc(sizeof(node));
    if (!myNode)
    {
        systemError("makeNode: Memory allocation failed");
    }
    myNode->token = token;
    myNode->val = val;
    myNode->ptr1 = (node*)p1;
    myNode->ptr2 = (node*)p2;
    myNode->ptr3 = (node*)p3;
    myNode->ptr4 = (node*)p4;
    return (long)myNode;
}

int getVar(int id)
{
    // Validate variable name
    if (id < 'a' || id > 'z')
    {
        return 0;
    }

    int index = id - 'a';
    return vars[index];
}

void storeVar(int id, int val)
{
    // Validate variable name
    if (id < 'a' || id > 'z')
    {
        return;
    }

    // Calculate array index
    int index = id - 'a';
    vars[index] = val;
}

void runStmt(long ptr)
{
    node* tree = (node*)ptr;

    // Special handling for loop body statements
    if (tree->token & LOOP_BODY_FLAG)
    {
        // Specific processing for statements within a loop
        computeStmt(tree);
    }
    else
    {
        // Existing statement processing logic
        computeStmt(tree);
    }
}

void computeStmt(node* tree)
{
    if (!tree)
    {
        return;
    }
    int val;
    
    switch (tree->token)
    {
        case OUTPUT:
            if (tree->ptr1)
            {
                val = evalExpr(tree->ptr1);
                printf("%d\n", val);  
            }
            else if (tree->val)
            {
                char* str = (char*)tree->val;
                
                if (str[0] == '"')
                {
                    str++;  // Skip first quote
                    str[strlen(str)-1] = '\0'; 
                }
                printf("%s\n", str);
            }
            break;

        case TAKE:
        {
            // Ensure the node has a valid identifier
            if (!tree->ptr1)
            {
                break;
            }

            // Debug the identifier
            node* identNode = (node*)tree->ptr1;

            // Validate identifier
            if (identNode->token != IDENTIFIER)
            {
                break;
            }

            // Interactive input handling
            char input[256] = {0};
            
            // Check if input is from terminal
            if (isatty(STDIN_FILENO))
            {
                printf("Enter value for %c: ", (char)identNode->val);
                fflush(stdout);
            }

            // Read input
            if (fgets(input, sizeof(input), stdin) == NULL)
            {
                break;
            }
            
            // Remove trailing newline
            input[strcspn(input, "\n")] = 0;
            
            // Store as string
            storeStringVar((int)identNode->val, input);
            break;
        }

        case ASSIGN:
            val = evalExpr(tree->ptr1);
            storeVar(tree->val, val);
            break;

        case IF:
            val = evalExpr(tree->ptr1);
            if (val)
            {
                // Don't execute: computeStmt(tree->ptr2);
            }
            else if (tree->ptr3)
            {
                // Don't execute: computeStmt(tree->ptr3);
            }
            break;

        case ITERATE:
            break;

        case DEFINE:
            defineFunction(tree);
            break;

        case CALL:
            callFunction(tree);
            break;

        default:
            if (tree->ptr1) computeStmt(tree->ptr1);
            if (tree->ptr2) computeStmt(tree->ptr2);
            if (tree->ptr3) computeStmt(tree->ptr3);
            if (tree->ptr4) computeStmt(tree->ptr4);
            break;
    }
}

int evalExpr(node* tree)
{
    if (!tree)
    {
        exit(1);
    }

    switch (tree->token)
    {
        case NUMBER:
            return (int)tree->val;
        case IDENTIFIER:
            // Check if this is a numeric or string identifier
            if (tree->val >= 'a' && tree->val <= 'z')
            {
                char* strVal = getStringVar((int)tree->val);
                if (strVal)
                {
                    // If you want to convert string to int, you can use atoi
                    return atoi(strVal);
                }
            }
            return getVar((int)tree->val);
        case PLUS:
            return evalExpr(tree->ptr1) + evalExpr(tree->ptr2);
        case MINUS:
            return evalExpr(tree->ptr1) - evalExpr(tree->ptr2);
        case TIMES:
            return evalExpr(tree->ptr1) * evalExpr(tree->ptr2);
        case DIVIDE:
            if (evalExpr(tree->ptr2) == 0)
            {
                return 0;
            }
            return evalExpr(tree->ptr1) / evalExpr(tree->ptr2);
        case MOD:
            if (evalExpr(tree->ptr2) == 0)
            {
                return 0;
            }
            return evalExpr(tree->ptr1) % evalExpr(tree->ptr2);
        case EQ:
            return evalExpr(tree->ptr1) == evalExpr(tree->ptr2);
        case NEQ:
            return evalExpr(tree->ptr1) != evalExpr(tree->ptr2);
        case GT:
            return evalExpr(tree->ptr1) > evalExpr(tree->ptr2);
        case LT:
            return evalExpr(tree->ptr1) < evalExpr(tree->ptr2);
        case GTE:
            return evalExpr(tree->ptr1) >= evalExpr(tree->ptr2);
        case LTE:
            return evalExpr(tree->ptr1) <= evalExpr(tree->ptr2);
        default:
            exit(1);
    }
    return 0;
}

void cleanUp(node* tree)
{
    if (!tree) return;
    
    // For extra safety, make local copies of child pointers 
    // before recursively cleaning them up
    node* ptr1 = tree->ptr1;
    node* ptr2 = tree->ptr2;
    node* ptr3 = tree->ptr3;
    node* ptr4 = tree->ptr4;
    
    // Set the pointers to NULL to prevent double-free issues
    tree->ptr1 = NULL;
    tree->ptr2 = NULL;
    tree->ptr3 = NULL;
    tree->ptr4 = NULL;
    
    // Free the node itself
    free(tree);
    
    // Now recursively clean up the child nodes
    if (ptr1) cleanUp(ptr1);
    if (ptr2) cleanUp(ptr2);
    if (ptr3) cleanUp(ptr3);
    if (ptr4) cleanUp(ptr4);
}

void systemError(const char* str)
{
    printf("ERROR: in \"%s\", something went wrong.\n", str);
    exit(-1);
}

long processLoop(node* loopNode)
{
    if (!loopNode)
    {
        return 0;
    }
    
    // Extract loop parameters
    node* startExpr = (node*)loopNode->ptr1;
    node* endExpr = (node*)loopNode->ptr2;
    node* stepExpr = (node*)loopNode->ptr3;
    node* bodyBlock = (node*)loopNode->ptr4;

    // Existing loop parameter evaluation logic
    int start = evalExpr(startExpr);
    int end = evalExpr(endExpr);
    int step = evalExpr(stepExpr);

    // Loop execution
    for (int i = start; i <= end; i += step)
    {
        // Store loop variable
        storeVar('i', i);

        // Process prepared loop body statements
        if (bodyBlock && bodyBlock->token == LBRACE)
        {
            node* currentStmt = bodyBlock->ptr1;
            while (currentStmt)
            {
                // Process each statement with loop context
                runStmt((long)currentStmt);
                currentStmt = currentStmt->ptr2;
            }
        }
    }

    return 1;
}

void processLoopBody(node* body)
{
    if (body == NULL)
    {
        return;
    }

    // Handle different body node types
    switch (body->token)
    {
        case OUTPUT:
            // Handle string output
            if (body->val)
            {
                char* str = (char*)body->val;
                if (str[0] == '"')
                {
                    str++;
                    str[strlen(str)-1] = '\0';
                }
                printf("%s\n", str);
            }
            
            // Handle expression output
            if (body->ptr1)
            {
                int outputVal = evalExpr(body->ptr1);
                printf("%d\n", outputVal);
            }
            break;
        
        default:
            break;
    }
}

void storeStringVar(int id, const char* str)
{
    // Validate variable name
    if (id < 'a' || id > 'z')
    {
        return;
    }

    // Calculate array index
    int index = id - 'a';

    // Free existing string if it exists
    if (string_vars[index] != NULL)
    {
        free(string_vars[index]);
    }

    // Allocate and copy new string
    string_vars[index] = strdup(str);
}

// Add a corresponding getString function
char* getStringVar(int id)
{
    // Validate variable name
    if (id < 'a' || id > 'z')
    {
        return NULL;
    }

    int index = id - 'a';
    return string_vars[index];
}

// Add cleanup function to prevent memory leaks
void cleanupStringVars()
{
    for (int i = 0; i < 26; i++)
    {
        if (string_vars[i] != NULL)
        {
            free(string_vars[i]);
            string_vars[i] = NULL;
        }
    }
}

// Initialize string variables at program start
void initStringVars()
{
    for (int i = 0; i < 26; i++)
    {
        string_vars[i] = NULL;
    }
}

void defineFunction(node* funcNode)
{
    // Check if we've reached maximum function limit
    if (function_count >= MAX_FUNCTIONS)
    {
        return;
    }

    // Validate function node
    if (!funcNode || funcNode->token != DEFINE)
    {
        return;
    }

    // Extract function details
    int func_name = funcNode->val;  // Function name (as ASCII)
    node* param_list = (node*)funcNode->ptr1;
    node* body = (node*)funcNode->ptr2;

    // Create function entry
    Function* new_func = &functions[function_count];
    
    // Store function name
    new_func->name[0] = (char)func_name;
    new_func->name[1] = '\0';
    
    // Store parameter list
    new_func->param_list = param_list;
    
    // Store function body
    new_func->body = body;

    // Count parameters
    int param_count = 0;
    node* current_param = param_list;
    while (current_param)
    {
        param_count++;
        current_param = current_param->ptr2;
    }
    new_func->param_count = param_count;

    // Increment function count
    function_count++;
}

void callFunction(node* callNode)
{
    // Validate call node
    if (!callNode || callNode->token != CALL)
    {
        return;
    }

    // Extract function name and arguments
    int func_name = callNode->val;
    node* arg_list = (node*)callNode->ptr1;

    // Find the function
    Function* func = NULL;
    for (int i = 0; i < function_count; i++)
    {
        if (functions[i].name[0] == (char)func_name)
        {
            func = &functions[i];
            break;
        }
    }

    // Check if function exists
    if (!func)
    {
        return;
    }

    // Count and validate arguments
    int arg_count = 0;
    node* current_arg = arg_list;
    while (current_arg)
    {
        arg_count++;
        current_arg = current_arg->ptr2;
    }

    if (arg_count != func->param_count)
    {
        return;
    }

    // Save current variable state
    int old_vars[26];
    memcpy(old_vars, vars, sizeof(vars));

    // Bind arguments to parameters
    node* param = func->param_list;
    current_arg = arg_list;
    while (param && current_arg)
    {
        // Evaluate argument value
        int arg_val = evalExpr((node*)current_arg);
        
        // Store argument value in parameter variable
        storeVar(param->val, arg_val);

        param = param->ptr2;
        current_arg = current_arg->ptr2;
    }

    // Execute function body
    node* currentStmt = func->body->ptr1;
    while (currentStmt)
    {
        runStmt((long)currentStmt);
        currentStmt = currentStmt->ptr2;
    }

    // Restore previous variable state
    memcpy(vars, old_vars, sizeof(vars));
}

void cleanupFunctions()
{
    for (int i = 0; i < function_count; i++)
    {
        free(functions[i].name);
    }
    function_count = 0;
}