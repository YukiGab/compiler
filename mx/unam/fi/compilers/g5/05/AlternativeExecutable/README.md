\# PENTA Compiler - Executable Releases



This package contains the pre-compiled executable versions of the PENTA Compiler. These builds are provided to keep the project organized, less chaotic, and accessible to anyone without the need to configure Python virtual environments or run console commands.



\*\*⚠️ Performance Note (Executables vs. Native `.bat` Script):\*\*

Please note that running the compiler directly from the source code using the original `.bat` script remains the fastest and most stable method. By packaging the entire Python environment and its dependencies into standalone executables, we trade some performance for convenience. You may experience slower startup times or slight instability due to the extraction overhead compared to the native `.bat` execution.



\## Available Versions



We have included two different distribution formats. Please choose the one that best suits your evaluation:



\### 1. Portable Directory (Folder)

\* \*\*Description:\*\* A self-contained folder containing the main executable alongside all its unpacked libraries and internal assets.

\* \*\*Pros:\*\* Faster startup time and better stability than the single-file version, while still keeping the chaotic backend files isolated in one neat folder.

\* \*\*Cons:\*\* All internal files must remain in the same folder. You cannot move the `.exe` file outside of this directory.

\* \*\*How to use:\*\* Extract the folder and simply double-click the executable inside.



\### 2. Standalone Executable (One File)

\* \*\*Description:\*\* The entire compiler, lexer, parser, and virtual machine packed into a single `.exe` file.

\* \*\*Pros:\*\* The absolute cleanest option. Extremely portable and easy to share.

\* \*\*Cons:\*\* Noticeably slower startup time. The operating system has to silently unpack hundreds of hidden files into a temporary directory every time it runs. This overhead can cause slight delays or trigger false-positive warnings from Windows Defender.

\* \*\*How to use:\*\* Just double-click the standalone `.exe`.



\## Important System Requirements

The compiler's core logic (Lexer, Parser, SDT, TAC, and Virtual Machine) is \*\*100% self-contained\*\* in these executables. 



However, the visual AST graph generation relies on external system tools. To successfully generate the `.png` and `.svg` AST trees, the host machine must have \*\*Graphviz\*\* installed (`dot` command available in the system PATH). If Graphviz is not present, the compiler will still work perfectly and execute the target code, but it will safely skip the graph image generation.



\## Troubleshooting

Because these are locally compiled executables without a digital signature, Windows SmartScreen might block them upon the first run. If this happens, click on \*\*"More info"\*\* and then \*\*"Run anyway"\*\*.

