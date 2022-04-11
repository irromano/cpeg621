#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <vector>
#include <iostream>
#include <string>
#include <fstream>
#include <list>
#include <algorithm>

const int MAXLINE_LEN = 10000;

std::vector<std::string> instructions;
std::list<std::string> vars;

int main(int argc, char *argv[])
{
    std::ifstream inFile;
    inFile.open(argv[1]);

    const std::string eq = "=";
    const std::string ad = "+";
    const std::string sb = "-";
    const std::string ml = "*";
    const std::string dv = "/";
    const std::string ex = "**";
    const std::string if_low = "if";
    const std::string if_high = "If";
    const std::string else_low = "else";
    while (inFile)
    {
        std::string line;
        getline(inFile, line);
        int endVar = line.find(eq);
        int ifPos = line.find(if_low);
        int ifPosH = line.find(if_high);
        int elsePos = line.find(else_low);
        int bracket = line.find("}");

        if (endVar != std::string::npos)
        {
            std::string varLine = line;
            remove(varLine.begin(), varLine.end(), '\t');
            vars.push_back(line.substr(0, endVar));
        }

        if (endVar != std::string::npos || endVar != std::string::npos || endVar != std::string::npos || endVar != std::string::npos || bracket != std::string::npos)
        {
            instructions.push_back(line);
        }
    }

    vars.sort();
    vars.unique();

    std::cout << "main(){\n"
              << std::endl;

    std::cout << "\t"
              << "int ";
    for (auto line = vars.begin(); line != vars.end(); ++line)
    {
        std::cout << *line << ", ";
    }
    std::cout << vars.back() << ";\n"
              << std::endl;

    for (auto line = vars.begin(); line != vars.end(); ++line)
    {
        std::cout << "\t"
                  << "printf(\"" << *line << "=\");" << std::endl;
        std::cout << "\t"
                  << "scanf(\"\%d\",&" << *line << ");\n"
                  << std::endl;
    }

    int lineNumber = 1;
    for (std::string line : instructions)
    {

        std::cout << "\t"
                  << "S" << lineNumber << ":\t" << line << std::endl;
        lineNumber++;
    }
    std::cout << "}" << std::endl;
}