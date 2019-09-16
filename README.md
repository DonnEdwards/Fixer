Fixer 1.0
=========

Written by Donn Edwards (c) 2019 Watchmanager.net

This utility looks through text files and does a string search and replace. 
The resulting files are saved with a .txt extension, so Hello.clw becomes Hello.clw.txt

It was written as a learning exercise to understand how hand coded Clarion programs work
and how to put everything together to create a working program. Hopefully it is sufficently 
well documented to explain what is going on and how it all works.

Mark Goldberg's debug library isn't absolutely necessary, but has been extremely helpful in finding
bugs and getting the program to work as required.

The Fixer.ini file contains the settings needed. Most of them can be modified using the form, but
there are a few items that need further explanation:

Extensions=.clw|.inc

This specifies the file extensions to be edited. Do not use .txt as an extension, but separate the 
extensions you want to edit with a pipe symbol, instead of the usual semicolon. The star character 
doesn't work as a wild card.

Modified files are copied and a .txt extension is added. Your original files are not modified.
