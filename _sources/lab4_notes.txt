Lab 3: Valgrind
===============


Question 1: bitmap.c
--------------------

The goal of this question is to execice the following valgrind commands:

 - memcheck
 - sgcheck
 - massiv

We first need to compile the test program ``bitmap.C`` ::

    $ gcc -Wall -g -o bitmap bitmap.C -lstdc++
    
the **-Wall** option turn on all warnings. The **-g** option enable to produce the debug symbol that will be processed by *valgrind*. The **-o** options enable to specify the output file name. the **-lstd++** specify to link the executable against C++ runtime library.

1) memcheck
^^^^^^^^^^^

Then we can run *valgrind* on the compliated program::

    $ valgrind --tool=memcheck ./bitmap
    ==7246== Memcheck, a memory error detector
    ==7246== Copyright (C) 2002-2013, and GNU GPL'd, by Julian Seward et al.
    ==7246== Using Valgrind-3.10.0.SVN and LibVEX; rerun with -h for copyright info
    ==7246== Command: ./bitmap
    ==7246== 
    ==7246== Invalid read of size 1
    ==7246==    at 0x400B2C: steganographyEncrypt(char const*, char const*, char const*) (bitmap.C:163)
    ==7246==    by 0x4007D4: main (bitmap.C:68)
    ==7246==  Address 0x5b1e26e is 2 bytes after a block of size 1,132 alloc'd
    ==7246==    at 0x4C2B800: operator new[](unsigned long) (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==7246==    by 0x400A7A: steganographyEncrypt(char const*, char const*, char const*) (bitmap.C:137)
    ==7246==    by 0x4007D4: main (bitmap.C:68)
    ==7246== 
    ==7246== 
    ==7246== HEAP SUMMARY:
    ==7246==     in use at exit: 4,200 bytes in 1 blocks
    ==7246==   total heap usage: 536 allocs, 535 frees, 1,026,724 bytes allocated
    ==7246== 
    ==7246== LEAK SUMMARY:
    ==7246==    definitely lost: 4,200 bytes in 1 blocks
    ==7246==    indirectly lost: 0 bytes in 0 blocks
    ==7246==      possibly lost: 0 bytes in 0 blocks
    ==7246==    still reachable: 0 bytes in 0 blocks
    ==7246==         suppressed: 0 bytes in 0 blocks
    ==7246== Rerun with --leak-check=full to see details of leaked memory
    ==7246== 
    ==7246== For counts of detected and suppressed errors, rerun with: -v
    ==7246== ERROR SUMMARY: 240 errors from 1 contexts (suppressed: 0 from 0)
    
As *valgrind* recommend to re-run it with the **--leak-check=full** option, lets do it::

    $ valgrind --tool=memcheck  --leak-check=full ./bitmap
    ==7248== Memcheck, a memory error detector
    ==7248== Copyright (C) 2002-2013, and GNU GPL'd, by Julian Seward et al.
    ==7248== Using Valgrind-3.10.0.SVN and LibVEX; rerun with -h for copyright info
    ==7248== Command: ./bitmap
    ==7248== 
    ==7248== Invalid read of size 1
    ==7248==    at 0x400B2C: steganographyEncrypt(char const*, char const*, char const*) (bitmap.C:163)
    ==7248==    by 0x4007D4: main (bitmap.C:68)
    ==7248==  Address 0x5b1e26e is 2 bytes after a block of size 1,132 alloc'd
    ==7248==    at 0x4C2B800: operator new[](unsigned long) (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==7248==    by 0x400A7A: steganographyEncrypt(char const*, char const*, char const*) (bitmap.C:137)
    ==7248==    by 0x4007D4: main (bitmap.C:68)
    ==7248== 
    ==7248== 
    ==7248== HEAP SUMMARY:
    ==7248==     in use at exit: 4,200 bytes in 1 blocks
    ==7248==   total heap usage: 536 allocs, 535 frees, 1,026,724 bytes allocated
    ==7248== 
    ==7248== 4,200 bytes in 1 blocks are definitely lost in loss record 1 of 1
    ==7248==    at 0x4C2B800: operator new[](unsigned long) (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==7248==    by 0x4008EA: steganographyEncrypt(char const*, char const*, char const*) (bitmap.C:109)
    ==7248==    by 0x4007D4: main (bitmap.C:68)
    ==7248== 
    ==7248== LEAK SUMMARY:
    ==7248==    definitely lost: 4,200 bytes in 1 blocks
    ==7248==    indirectly lost: 0 bytes in 0 blocks
    ==7248==      possibly lost: 0 bytes in 0 blocks
    ==7248==    still reachable: 0 bytes in 0 blocks
    ==7248==         suppressed: 0 bytes in 0 blocks
    ==7248== 
    ==7248== For counts of detected and suppressed errors, rerun with: -v
    ==7248== ERROR SUMMARY: 241 errors from 2 contexts (suppressed: 0 from 0)


This reports two error: 

 - An invalid read, it means an array has been exceeded at line 163.
 - A memory leak, from the memory allocated at line 109. 
 
The loop surrounding line 163 is going one pixel to far. So we should correct the line 161 to:

.. code-block:: c

    for (j=0; j<(widthLoop+1); j=j+1, hiddenText.p_rgb++)
    {
    ...
    }
  
And the memory allocated at line 109 is not freed.  So we need to free it at the end of the functions.
For this, the following instrctuion was added after line 189::

    delete [] bitmap.p_buffer;

A *diff* of the file will show::

    $ diff -u bitmap.orig bitmap.C
    --- bitmap.orig	2015-11-10 10:41:58.757686283 +0100
    +++ bitmap.C	2015-11-10 11:10:05.617762542 +0100
    @@ -158,7 +158,7 @@
     
     
     	     unsigned short j;
    -	     for (j=0; j<(widthLoop+2); j=j+1, hiddenText.p_rgb++)
    +	     for (j=0; j<(widthLoop+1); j=j+1, hiddenText.p_rgb++)
                  {
                      if ((hiddenText.p_rgb->Blue != WHITE) ||
                          (hiddenText.p_rgb->Green!= WHITE) ||
    @@ -187,6 +187,8 @@
     	{
                 delete [] *bitmap.p_row;
     	}
    +	delete [] bitmap.p_buffer;
    +	
     	fclose(pFileSource);
     	fclose(pFileDest);
     }

Now the same check shows no error::

    $ valgrind --tool=memcheck  --leak-check=full ./bitmap
    ==7478== Memcheck, a memory error detector
    ==7478== Copyright (C) 2002-2013, and GNU GPL'd, by Julian Seward et al.
    ==7478== Using Valgrind-3.10.0.SVN and LibVEX; rerun with -h for copyright info
    ==7478== Command: ./bitmap
    ==7478== 
    ==7478== 
    ==7478== HEAP SUMMARY:
    ==7478==     in use at exit: 0 bytes in 0 blocks
    ==7478==   total heap usage: 536 allocs, 536 frees, 1,026,724 bytes allocated
    ==7478== 
    ==7478== All heap blocks were freed -- no leaks are possible
    ==7478== 
    ==7478== For counts of detected and suppressed errors, rerun with: -v
    ==7478== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)


2) sgcheck
^^^^^^^^^^

The *sgcheck* show no error on the program::

    $ valgrind --tool=exp-sgcheck ./bitmap
    ==7485== exp-sgcheck, a stack and global array overrun detector
    ==7485== NOTE: This is an Experimental-Class Valgrind Tool
    ==7485== Copyright (C) 2003-2013, and GNU GPL'd, by OpenWorks Ltd et al.
    ==7485== Using Valgrind-3.10.0.SVN and LibVEX; rerun with -h for copyright info
    ==7485== Command: ./bitmap
    ==7485== 
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    --7485-- warning: evaluate_Dwarf3_Expr: unhandled DW_OP_ 0x93
    ==7485== 
    ==7485== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 4 from 4)


3) massif
^^^^^^^^^

.. code-**block:: shell

    $ valgrind --tool=massif --time-unit=B ./bitmap
    ==7499== Massif, a heap profiler
    ==7499== Copyright (C) 2003-2013, and GNU GPL'd, by Nicholas Nethercote
    ==7499== Using Valgrind-3.10.0.SVN and LibVEX; rerun with -h for copyright info
    ==7499== Command: ./bitmap
    ==7499== 
    ==7499== 
    $ ms_print massif.out.7499 


