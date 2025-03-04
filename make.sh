#!/bin/bash

# Clear previous compilations
clear
rm -f *.c *.h *.o

# Generate the Flexer lexerical analyzer
flex -o lexer.yy.c lexer.l

# Generate the Bison parser
bison -d parser.y

# Compile the generated C files into an executable
gcc parser.tab.c lexer.yy.c -lm -o rush -std=c99

# Check if the compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    echo "Run the executable with: ./rush"
else
    echo "Compilation failed. Please check the errors above."
fi