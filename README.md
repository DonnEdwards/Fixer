Fixer 1.0
=========

Written by Donn Edwards (c) 2019 Watchmanager.net

This utility looks through text files and does a string search and replace. 
The resulting files are saved with a .txt folder, with a .txt extension, so c:\dev\Hello.clw 
becomes c:\dev\.txt\Hello.clw.txt

It was written as a learning exercise to understand how hand coded Clarion programs work
and how to put everything together to create a working program. Hopefully it is sufficently 
well documented to explain what is going on and how it all works.

Mark Goldberg's debug library isn't absolutely necessary, but has been extremely helpful in finding
bugs and getting the program to work as required.

The Fixer.ini file contains the settings needed. It will be created for you if it doesn't exist
Most of them can be modified using the form, but there are two items that needs further explanation:

Extensions=.clw|.inc

This specifies the file extensions to be edited. Separate the extensions you want to edit with a 
pipe symbol, instead of the usual semicolon. The star character doesn't work as a wild card.

ExcludeSubFolders=.txt|.git|map|obj

This excludes certain subfolders from being inspected, such as the .txt and .git folders.

Your original files are not modified.
