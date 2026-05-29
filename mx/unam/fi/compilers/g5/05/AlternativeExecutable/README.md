PENTA Compiler - Executable Versions

Hello! This package contains the pre-compiled executable versions of the PENTA Compiler. We made these so you can test and evaluate the project easily, without having to set up a Python environment or run console commands.

A quick note on performance: Running the compiler from the original .bat script is still the fastest way to use it. These executable versions trade a bit of speed for convenience, so you might notice they take a little longer to start up.

We included two versions for you to choose from:

1. Portable Folder (Recommended)
This is a folder containing the main GUI.exe alongside its internal files. 
- Why use it: It opens almost instantly and is very stable.
- How to use: Just open the folder and double-click GUI.exe. Please do not move the .exe outside of this folder, or it will break.

2. Standalone Executable (Single File)
This is the entire compiler packed into one single .exe file.
- Why use it: It is the cleanest option and very easy to share.
- How to use: Double-click the file. Please be patient, it takes a few seconds to open because Windows has to silently unpack hundreds of files in the background every time you run it.

About the Visual AST (Graphs):
The compiler's core (Lexer, Parser, SDT, and Virtual Machine) is 100% self-contained and will work anywhere. However, if you want the compiler to draw the visual AST trees (.png and .svg files), your computer needs to have Graphviz installed. If you don't have it, don't worry; the compiler will still work perfectly and execute the code, it will just skip drawing the images.

Troubleshooting:
Since we compiled this locally, Windows SmartScreen might block the .exe the first time you open it. Just click "More info" and then "Run anyway".