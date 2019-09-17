PROGRAM
! Fixer 1.0     Begun 30 July 2019
!               First posted to GitHub 16 Sept 2019 https://github.com/DonnEdwards/Fixer
! Written by Donn Edwards (c) 2019 WatchManager.Net donn (at) watchmanager.net
! with much help from the ClarionLive and ClarionHub community.
! Also from the Clarion SHOWIMG example at SoftVelocity\Clarion10\Examples\SRC\SHOWIMG
! And the CapeSoft String Theory library
! And Mark Goldberg for the Debuger library https://github.com/MarkGoldberg/ClarionCommunity
!     and his generous code review
! I used the debug viewer found here: https://github.com/CobaltFusion/DebugViewPP
! Thanks to Graham Smith of WatchManager.Net for his time and attention, and library code
!
!Region Principled programming
! ---------------------------------------------------------------------------
! From www.developerdotstar.com:
!
! Principled Programming:
! =======================
!
! Personal Character
! ------------------
! Write your code so that it reflects, or rises above, the best parts of your
! personal character.
!
! Aesthetics
! ----------
! Strive for beauty and elegance in every aspect of your work.
!
! Clarity
! -------
! Value clarity equally with correctness. Utilize the proven techniques that
! will produce clarity in your code. Correctness will likely follow suit.
!
! Layout
! ------
! Use the visual layout of your code to communicate the structure of your code
! to human readers.
!
! Explicitness
! ------------
! Always favour the explicit over the implicit.
!
! Self-Documenting Code
! ---------------------
! The most reliable document of software is the code itself. In many cases,
! the code is the *only* documentation. Therefore, strive to make your code
! self-documenting, and where you can't, add comments.
!
! Comments
! --------
! Comment in full sentences in order to summarize and communicate intent.
!
! Assumptions
! -----------
! Take reasonable steps to test, document, and otherwise draw attention to the
! assumptions made in every module and routine.
!
! User Interaction
! ----------------
! Never make the user feel stupid.
!
! Going Back
! ----------
! The time to write good code is at the time you are writing it.
!
! Other People's Time and Money
! -----------------------------
! A true professional does not waste the time and money of other people by
! handing over software that is not reasonably free of obvious bugs; that has
! not undergone minimal unit testing; that does not meet the specifications and
! requirements; that is gold-plated with unnecessary features; or that looks
! like junk.
!
! Written by Daniel Read dan (at) developerdotstar.com
! Full version at http://www.developerdotstar.com/mag/articles/read_princprog.html
!
! -----------------------------------------------------------------------------
!EndRegion Principled programming

    INCLUDE('equates.clw'),ONCE 
    INCLUDE('StringTheory.Inc'),ONCE                        ! String Theory (c) CapeSoft
    INCLUDE('debuger.inc'),ONCE                             ! \Examples\ClarionCommunity-master\CW\Shared\Src
DBG                 Debuger                                 ! https://github.com/MarkGoldberg/ClarionCommunity

clsNameQ            QUEUE,TYPE                              ! Queue structure for file names
qFullFileName           CSTRING(FILE:MaxFilePath)           ! Full file name including path
qShortFileName          CSTRING(FILE:MaxFileName)           ! File name without the path
                    END

clsSearchReplaceQ   QUEUE,TYPE                              ! Queue structure for search and replace
qSearchString           CSTRING(1024)                       ! Search for this string
qReplaceString          CSTRING(1024)                       ! Replace it with this string
qPairNo                 SHORT                               ! Pair Number
                    END
strSearchString     CSTRING(255)                            ! Search for this string
strReplaceString    CSTRING(255)                            ! Replace it with this string
intPairNo           SHORT                                   ! Displayed Pair number

qqFileNames         clsNameQ                                ! Queue containing list of files to be processed
strBrowseBase       CSTRING(FILE:MaxFilePath)               ! Project folder
strIniFileName      CSTRING(FILE:MaxFilePath)               ! Location of Fixer.ini
strBrowseExtensions CSTRING(255)                            ! List of File extensions to be processed

qqSearchReplace     clsSearchReplaceQ                       ! Queue containing search and replace strings

!===============================================================================================================
                    MAP
                        INCLUDE('cwutil.inc'),ONCE
                        UpdateVaues                         ! Update the edited values on the form, save them to the INI file
                        GetListBoxValues                    ! When the user click on an entry in the listbox, update the editing controls
                        ProcessAllFiles                     ! The bulk of the file processing happens here
                        OpenConfigFile                      ! Display Fixer.ini in the default INI text editor      
                        ReadConfigFile                      ! Read the contents of fixer.ini
                        SaveConfigFile                      ! Save values to Fixer.ini
                        GetAllFiles (STRING pDir, *clsNameQ pDirQ)    ! Procedure to find all the matching files to be processed
                        ProcessThisFile (STRING pFileName)  ! Read the file, make a backup, make changes, save
                        ExtractFileExtension (STRING pFileName) STRING ! Get the filename extension
                        Fix_Path (STRING pPath) STRING      ! Check Path for trailing \

                        MODULE('')                          
                            OutputDebugString (CONST *CSTRING),PASCAL,NAME('OutputDebugStringA') ! Debuger  
                            errno(),*SIGNED,NAME('__errno__') !prototype built-in error flag, used by CreateDirectory
                        END

                        ODS (STRING Msg)                    ! Clarionized OutputDebugString
                    END

!---------------------------------------------------------------------------------------------------------------

MyWindow            WINDOW('Fixer 1.0'),AT(,,270,196),FONT('Tahoma',9,,FONT:regular),RESIZE,CENTER,GRAY,|
                        ICON('WIZFIND.ICO'),SYSTEM,STATUS
                        ! Go button is the default button for the program
                        BUTTON('&Go'),AT(100,170,36,14),USE(?GoButton),DEFAULT,RIGHT,TIP('Scan and process the files')
                        ! Title and explanation of what the program does
                        PROMPT('Scan and replace text in Clarion text files'),AT(10,10,250),CENTER,FONT(,12,,FONT:regular)
                        ! Button to open the currently selected project folder
                        BUTTON('Open the project folder'),AT(10,30,250,14),USE(?OpenFolder),FLAT,TIP('Open the project folder')                  
                        ! List box with the search/replace queue
                        LIST,AT(17,50,240,60),VSCROLL,FROM(qqSearchReplace),IMM,MSG('Search and Replace data'),|
                            FORMAT('100L(2)|M~Search~C(2)@s40@102L(2)|M~Replace~C(2)@s38@40L(2)|M~No~L(2)'),|
                            USE(?ListBox)
                        ! Edit box for search/replace pairs and sequence number
                        ENTRY(@S255),AT(17,115,99,10), USE(strSearchString),MSG('Use this to edit the search string')
                        ENTRY(@S255),AT(119,115,98,10),USE(strReplaceString),MSG('Use this to edit the replace string')
                        ENTRY(@N4),AT(221,115,36,10), USE(intPairNo),MSG('Use this to edit a particular entry')
                        ! Update button to make the edit happen
                        BUTTON('Update'),AT(221,127,36,14),USE(?UpdateButton),DEFAULT,LEFT,MSG('Update the Search and Replace Data'),|
                            TIP('Click to update the Search and Replace pair')
                        ! Button to inspect the INI config file
                        BUTTON('View &Config'),AT(140,150,66,14),USE(?EditButton),DEFAULT,LEFT,MSG('View the config file'),|
                            TIP('Click to open the config file for viewing')
                        ! Button to get a dialog box to choose the project folder
                        BUTTON('Project &Folder'),AT(70,150,66,14),USE(?FolderButton),DEFAULT,RIGHT,MSG('Select the folder'),|
                            TIP('Select the project folder and store it in the config file')
                        ! Exit the program
                        BUTTON('E&xit'),AT(140,170,36,14),USE(?CloseButton),LEFT,MSG('Close the program'),|
                            TIP('Close the program'),STD(STD:Close)                              
                    END

!---------------------------------------------------------------------------------------------------------------

    CODE
        DBG.mg_init('Fixer')                                ! Get the Debuger started                         
        DBG.ClearLog()
        ReadConfigFile                                      ! Get all the INI settings
        OPEN(MyWindow)
        ?OpenFolder{PROP:Text} = strBrowseBase              ! set the button text to the project folder setting
!        ?PairNo{PROP:Use} = intPairNo 
        !DBG.PrintEvent('No=' & intPairNo)
!        ?SearchString{PROP:Use} = strSearchString  
        !DBG.PrintEvent('Search=' & strSearchString)
!        ?ReplaceString{PROP:Use} = strReplaceString   
        !DBG.PrintEvent('Replace=' & strReplaceString)
        MyWindow{PROP:StatusText} = 'Fixer 1.0.4 (c) 2019 Watchmanager.net'
        ACCEPT

            CASE ACCEPTED() 
            
            OF ?UpdateButton     ; UpdateVaues              ! Update the edited values
           
            OF ?ListBox          ; GetListBoxValues         ! Get the clicked value of the list box

            OF ?FolderButton     ; DO AskFolderRoutine      ! Ask for the correct folder

            OF ?EditButton       ; OpenConfigFile()         ! Allow the user to inspect Fixer.ini

            OF ?OpenFolder       ; RUN('explorer.exe "' & strBrowseBase & '"',1) ! Show the folder

            OF ?GoButton         ; ProcessAllFiles()        ! The bulk of the work happens here

            OF ?CloseButton      ; POST(EVENT:CloseWindow)  ! All done

            END 

        END 

        
        RETURN
 
!---------------------------------------------------------------------------------------------------------------
       
AskFolderRoutine           ROUTINE            
!// When the user clicks on the project folder button, get the project path
    FILEDIALOG('Choose Project Folder',strBrowseBase,,FILE:Directory+FILE:LongName+FILE:KeepDir)
    IF ~strBrowseBase                                       ! Default if nothing selected       
        strBrowseBase = PATH() & '\'                   
    END
    strBrowseBase = CLIP(Fix_Path(strBrowseBase))           ! Fix the path selected to have a trailing \
    SaveConfigFile()                                        ! Remember it
    ?OpenFolder{PROP:Text} = strBrowseBase                  ! Update the button text with the new folder
    

!===============================================================================================================

UpdateVaues    PROCEDURE
!// Update the edited values on the form, save them to the INI file
    CODE
        !DBG.PrintEvent(RECORDS(qqSearchReplace)) 
        !DBG.PrintEvent('No=' & ?No)
!        intPairNo = ?PairNo{PROP:Value}                             ! Which entry are we working with?
        IF intPairNo < 1                                        ! Invalid entry number or empty queue
            intPairNo = 1
        END
        DBG.PrintEvent('PairNo=' & intPairNo)
!        strSearchString = ?SearchString{PROP:Value}
        DBG.PrintEvent('Find=' & strSearchString)
!        strReplaceString = ?ReplaceString{PROP:Value}
        DBG.PrintEvent('Repl=' & strReplaceString)
        IF intPairNo > RECORDS(qqSearchReplace)                 ! Invalid entry number
            intPairNo = RECORDS(qqSearchReplace) + 1            ! Add a new entry
!            ?PairNo{PROP:Use} = intPairNo                           ! Correct the display
        END
        IF intPairNo > RECORDS(qqSearchReplace)                 ! Add a new entry
            IF LEN(CLIP(strSearchString)) > 0               ! Ignore blank searches
                CLEAR(qqSearchReplace)                      ! Clear the queue entry
                qqSearchReplace.qSearchString = strSearchString
                qqSearchReplace.qReplaceString = strReplaceString
                qqSearchReplace.qPairNo = intPairNo
                ADD(qqSearchReplace)                        ! Add the pair to the queue
                !DBG.PrintEvent('ADD ' & RECORDS(qqSearchReplace)) 
            END
        ELSE
            CLEAR(qqSearchReplace)                          ! Clear the queue entry
            GET(qqSearchReplace,intPairNo)                      ! get the entry to be updated                       
            qqSearchReplace.qSearchString = strSearchString
            qqSearchReplace.qReplaceString = strReplaceString
            qqSearchReplace.qPairNo = intPairNo   
            PUT(qqSearchReplace)                            ! Update the queue
            !DBG.PrintEvent('PUT ' & intPairNo) 
        END
        SaveConfigFile()                                    ! Store the queue in the INI file
        !
        ReadConfigFile()                                    ! Update the display with current values
!        ?PairNo{PROP:Use} = intPairNo 
!        !DBG.PrintEvent('No=' & intPairNo)
!        ?SearchString{PROP:Use} = strSearchString  
!        !DBG.PrintEvent('Search=' & strSearchString)
!        ?ReplaceString{PROP:Use} = strReplaceString 
        ?ListBox{PROP:Use} = qqSearchReplace                ! Update the listbox
        ?ListBox{PROP:Selected} = intPairNo                     ! Highlight the correct entry
        RETURN

!---------------------------------------------------------------------------------------------------------------

GetListBoxValues    PROCEDURE
!// When the user click on an entry in the listbox, update the editing controls
i                       LONG
    CODE
        i = ?ListBox{PROP:Selected}                         ! Get highlighted entry from queue
        GET(qqSearchReplace,i)                              ! Get the data from the queue
        strSearchString = qqSearchReplace.qSearchString     ! Save it locally
        strReplacestring = qqSearchReplace.qReplaceString 
        intPairNo = qqSearchReplace.qPairNo
        ?strSearchString{PROP:Use} = strSearchString        ! Update the editing controls
        ?strReplaceString{PROP:Use} = strReplaceString
        ?intPairNo{PROP:Use} = intPairNo    
!        DBG.PrintEvent('No_=' & intPairNo) 
!        DBG.PrintEvent('Search_=' & strSearchString)
!        DBG.PrintEvent('Replace_=' & strReplaceString)
        RETURN

!---------------------------------------------------------------------------------------------------------------
 
ProcessAllFiles   PROCEDURE
!// The bulk of the file processing happens here
loc:fullfilename        CSTRING(FILE:MaxFilePath)
loc:shortfilename       CSTRING(64)
i                       LONG,AUTO
n                       LONG,AUTO
    CODE

        MyWindow{PROP:StatusText} = 'Processing the folders ...'
        FREE(qqFileNames)
        CLEAR(qqFileNames)                                  ! Clear the queue
        !
        GetAllFiles(strBrowseBase,qqFileNames)              ! Load the file names into qqFileNames
        n = 0
        MyWindow{PROP:StatusText} = 'Processing each file ...'
        LOOP i = 1 to RECORDS(qqFileNames)
            GET(qqFileNames,i)                              ! Get the file name from the queue
            IF ERRORCODE()
                STOP(ERROR())
            END
            loc:fullfilename = qqFileNames.qFullFileName    ! Save the file name locally
            loc:shortfilename = qqFileNames.qShortFileName   
            MyWindow{PROP:StatusText} = loc:shortfilename   ! Display it
            DISPLAY
            !DBG.PrintEvent (loc:fullfilename)
            ProcessThisFile(loc:fullfilename)
            n += 1
        END ! LOOP i
        FREE(qqFileNames)                                   ! Get rid of the entire queue
        CLEAR(qqFileNames)                                  ! Clear the buffers
        MyWindow{PROP:StatusText} = n & ' files processed'
        SaveConfigFile
        !RUN('explorer.exe "' & strBrowseBase & '"',1)      ! Show the folder
        RETURN

!---------------------------------------------------------------------------------------------------------------
        
ProcessThisFile     PROCEDURE(STRING pFileName)  
!// Read the file, make a backup, make changes, save   
st                      StringTheory
i                       LONG,AUTO
loc:searchstring        CSTRING(255)
loc:replacestring       CSTRING(255)
    CODE
        IF EXISTS(pFileName & '.txt')
            REMOVE(pFileName & '.txt')
            IF ERRORCODE()
                STOP(ERROR())
            END            
        END
        COPY(pFileName,pFileName & '.txt')                  ! Make a copy of the file
        st.LoadFile(pFileName & '.txt')                     ! Read the entire copied file
        ! Make the changes to the file here
        LOOP i = 1 to RECORDS(qqSearchReplace)
            GET(qqSearchReplace,i)                          ! Get the data from the queue
            IF ERRORCODE()
                STOP(ERROR())
            END
            loc:searchstring = qqSearchReplace.qSearchString ! Save it locally
            loc:replacestring = qqSearchReplace.qReplaceString 
            IF LEN(CLIP(loc:searchstring)) > 0              ! Only valid searches 
                st.Replace(loc:searchstring,loc:replacestring) ! Do the search and replace across the entire file
            END
        END ! LOOP i
        st.SaveFile(pFileName & '.txt')                     ! Write the file back to disk
!        
        RETURN
   
       
!---------------------------------------------------------------------------------------------------------------

OpenConfigFile      PROCEDURE
!// Open the config file for editing or viewing in notepad or whatever
    CODE
        RUN(strIniFileName)                                 ! Open Fixer.ini in notepad or text editor
        RETURN
   
!---------------------------------------------------------------------------------------------------------------

ReadConfigFile      PROCEDURE
!// Read the contents of the config file into their respective variables and queue
loc:findcount           SHORT,AUTO
i                       SHORT,AUTO
    CODE
        strIniFileName = PATH() & '\Fixer.ini'              ! The location of Fixer.ini
        strBrowseBase =       GETINI('Fixer', 'Project',   PATH() & '\',strIniFileName)     ! The folder Fixer will work in
        strBrowseExtensions = GETINI('Fixer', 'Extensions','.clw|.inc', strIniFileName)     ! List of file extensions
        FREE(qqSearchReplace)
        CLEAR(qqSearchReplace)                                                              ! Clear the queue
        loc:findcount = (CLIP(GETINI('FixerSR','FindCount',0,           strIniFileName)))
        loc:findcount += 1                                                                  ! Check for one more pair
        intPairNo = 0
        LOOP     i = 1 TO loc:findcount                                                     ! Go through the declared pairs
            strSearchString =  GETINI('FixerSR','Find_' & CLIP(i),'',   strIniFileName)
            strReplaceString = GETINI('FixerSR','Repl_' & CLIP(i),'',   strIniFileName)
            IF LEN(CLIP(strSearchString)) > 0               ! Ignore blank searches
                intPairNo += 1                              ! increment intPairNo
                qqSearchReplace.qSearchString = strSearchString
                qqSearchReplace.qReplaceString = strReplaceString
                qqSearchReplace.qPairNo = intPairNo
                ADD(qqSearchReplace)                        ! Add the pair to the queue
            END
        END ! LOOP i
        strSearchString = qqSearchReplace.qSearchString     ! Remember the last value
        strReplaceString = qqSearchReplace.qReplaceString 
        intPairNo = RECORDS(qqSearchReplace)
        !DBG.PrintEvent('No_=' & intPairNo) 
        !DBG.PrintEvent('Search_=' & strSearchString)
        !DBG.PrintEvent('Replace_=' & strReplaceString)
        RETURN
         
!---------------------------------------------------------------------------------------------------------------

SaveConfigFile      PROCEDURE
!// Save the config file variables back to the file
i                       LONG,AUTO
n                       LONG,AUTO
loc:searchstring        CSTRING(255)
loc:replacestring       CSTRING(255)
    CODE
        PUTINI('Fixer',   ,           ,                                strIniFileName)  ! delete the entire section
        PUTINI('Fixer',   'Extensions', strBrowseExtensions,           strIniFileName)
        PUTINI('Fixer',   'Project',    strBrowseBase,                 strIniFileName)
        
        PUTINI('FixerSR', , ,                                          strIniFileName)  ! delete the entire section
        n = 0
        PUTINI('FixerSR', 'FindCount',       RECORDS(qqSearchReplace), strIniFileName)
        LOOP i = 1 to RECORDS(qqSearchReplace)
            GET(qqSearchReplace,i)                                                      ! Get the data from the queue
            IF ERRORCODE()
                STOP(ERROR())
            END
            loc:searchstring = qqSearchReplace.qSearchString                            ! Save it locally
            loc:replacestring = qqSearchReplace.qReplaceString 
            IF LEN(CLIP(loc:searchstring)) > 0                                          ! Only valid searches 
                n += 1                                                                  ! increment n
                PUTINI('FixerSR', 'Find_' & CLIP(n), loc:searchstring,  strIniFileName)
                !DBG.PrintEvent('Find_' & CLIP(n) & ' ' & loc:searchstring)
                PUTINI('FixerSR', 'Repl_' & CLIP(n), loc:replacestring, strIniFileName)
                !DBG.PrintEvent('Repl_' & CLIP(n) & ' ' & loc:replacestring)
            END ! LEN
        END ! LOOP i
        IF n <> RECORDS(qqSearchReplace)                                                ! One or more invalid searches
            PUTINI('FixerSR', 'FindCount',           n,                 strIniFileName) ! Update FindCount
        END ! n
        RETURN
!---------------------------------------------------------------------------------------------------------------

GetAllFiles         PROCEDURE(STRING pDir, clsNameQ pDirQ)
!// Procedure to find all the matching files to be processed
!   Heavily borrowed from C:\Users\Public\Documents\SoftVelocity\Clarion10\Examples\SRC\SHOWIMG
!
ffq                     QUEUE                               ! Required structure for DIRECTORY function
Name                        STRING(FILE:MaxFileName)
fName                       STRING(13)
Date                        LONG
Time                        LONG
Size                        LONG
Attrib                      BYTE
                        END
loc:filename            CSTRING(FILE:MaxFileName)
loc:extension           CSTRING(FILE:MaxFileName)
i                       LONG,AUTO

    CODE
        loc:filename = CLIP(pDir)
        MyWindow{PROP:StatusText} = pDir
        DISPLAY
        DIRECTORY(ffq, CLIP(pDir) & '*.*', ff_:NORMAL)                    ! Load the directory into ffq
        LOOP i = 1 to RECORDS(ffq)
            GET(ffq, i)
            loc:filename = CLIP(ffq.Name)
            loc:extension = CLIP(ExtractFileExtension(loc:filename)) ! get the extension
            IF MATCH(loc:extension, strBrowseExtensions, Match:Regular+Match:NoCase)! Find matching file extension
                pDirQ:qFullFileName  = CLIP(pDir) & loc:filename
                pDirQ:qShortFileName = loc:filename
                ADD(pDirQ)                                          ! Add the filename to my queue
                MyWindow{PROP:StatusText} = CLIP(pDir) & loc:filename     ! Show the full file name
            END
        END
        FREE(ffq)
        DIRECTORY(ffq, CLIP(pDir) & '*.*', ff_:DIRECTORY)                 ! Recurse to subfolders
        LOOP i = 1 to RECORDS(ffq)
            GET(ffq, i)
            IF BAND(ffq.Attrib,ff_:DIRECTORY) AND ffq.Name <> '..' AND ffq.Name <> '.' THEN
                GetAllFiles(CLIP(pDir) & CLIP(ffq.Name) & '\', pDirQ)     ! Add files from subfolders
            END
        END

!---------------------------------------------------------------------------------------------------------------

Fix_Path            FUNCTION (STRING pPath)
!// Check path for trailing \ and add it if necessary
!   Written by Graham Smith as part of gsTools (c) WatchManager.net
loc:path                CSTRING(FILE:MaxFilePath)
    CODE                                                    ! Begin processed code
        loc:path = CLIP(pPath)
        !
        IF loc:Path <> '' THEN                              ! Is it a valid path
            if SUB(loc:Path, LEN(loc:Path), 1) <> '\' THEN  ! Trailing \?
                loc:Path = loc:Path & '\'                   ! Add the trailing \
            end
        END
        !
        RETURN loc:Path                                     ! Return the result
        
!---------------------------------------------------------------------------------------------------------------
         
ExtractFileExtension  FUNCTION (STRING pPathFileName)  
!// Get the FileName extension, including the dot
!
loc:filename                CSTRING(FILE:MaxFilePath)
loc:extension               CSTRING(FILE:MaxFileName)
n                           SHORT,AUTO
    CODE                                                    ! Begin processed code              
        loc:filename = '\' & pPathFileName       
        n = INSTRING('\',loc:filename,-1,LEN(loc:filename)) ! find the \ in the file path
        loc:filename = SUB(loc:filename,n+1,LEN(loc:filename)) ! exclude the path

        n = INSTRING('.',loc:filename,-1,LEN(loc:filename)) ! find the dot in the filename (not in the path)
        IF n > 0
            loc:extension = SUB(loc:filename,n,LEN(CLIP(loc:filename))-n+1) ! get the extension
        ELSE
            loc:extension = ''
        END
        !
        RETURN loc:extension                                ! Return the result
        
!---------------------------------------------------------------------------------------------------------------

! Part of the Debuger code
! https://github.com/MarkGoldberg/ClarionCommunity
ODS                 PROCEDURE(STRING Msg)  !Clarionized OutputDebugString, the ` is to aid Filtering in DbgView
szMsg                   CSTRING(SIZE(Msg) + 4)  ! 4 = 1 (for '`') + 2 (for '<13,10>) + 1 (for <0> terminator)
    CODE  
        szMsg = '`' & MSG & '<13,10>' !and an implied <0>
        OutputDebugString(szMsg)  
        RETURN
        
!---------------------------------------------------------------------------------------------------------------