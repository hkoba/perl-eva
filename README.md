EVA -- visual-stack based evaluator for perl expressions.
====================

Note: This code is not maintained now. I placed this here just for reference.
Feel free to fork this.

EVA is a Perl/Tk script which is intended to serve as an
environment for your "casual" programming life.

To install EVA, simply

    git clone https://github.com/hkoba/perl-eva.git
    ln -s perl-eva/eva  YOUR_BINDIR/eva

To get usage,

    perldoc eva


Changes
----------

Changes in 1.2.2.2:
 * RCS-Id of Most modules are re-numbered.

 * Now works in Tk800* (both Unix & Win32).
   (INSTALL.PL does not work for Win32.)

Changes in 1.1.1.24:
 * Now Tk-b11 is recommended. (but may work with b9)
 
 * Now LWP-b8 or after is recommended.
 
 * 'File Load/Save' operation becomes more careful.

Changes in 1.1.1.13:
Bug fixes:
 * 'Open' on package name, now 'Open' the package correctly.
         # No need for libwww
 
 * 'create polygon' entry in 'Inspect/Canvas' menu now works.
 
 * Self Referencing data-structure, now viewed safely in RefListbox.

New (experimental) features:
 * $_ holds X-Selection at each evaluation. This is useful
         when:
   [1] you want to count ',' in Selection, type:
            tr/,/,/
   [2] you want to obtain list of words, type:
            m/(\w+)/g
       or
            split /\s+/
 
       and <Control-Return> (Say, 'Commit').
 
 * $eva->configure(-nearest_cpan => $your_favorite)
 
 * 'Find ISA Hierarchy' in 'Inspect' menu retrieves class 
   hierarchy and push it on stack. # So you can 'Open' it.
