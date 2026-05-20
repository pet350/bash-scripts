#!/usr/bin/env python
# -*- coding: utf-8 -*-

###########################################################################
#
# Copyright (C) 2007 Jamie Strandboge <jamie@ubuntu.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published
#    by the Free Software Foundation; either version 2 of the License,
#    or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful, but
#    WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with auth-client-config; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# Based on installation file by Wido Depping <widod@users.sourceforge.net>
# (covered by above license)
#
###########################################################################

import sys
import os.path
import os
from popen2 import Popen3
import py_compile

# This is the prefix directory where auth-client-config will be installed.
prefixDir = os.path.join("usr", "local")
configDir = os.path.join("etc")
destDir   = os.path.join("/")

# Determines if python source files are only compiled and not installed
compileOnly = False


def doImportCheck():
    """ Checks for installed packages which are needed in order to run
    auth-client-config.  Gives only a warning for missing packages.
    """
    
    #print "Check for preinstalled modules:\n"
    # Check for python-foo
    # try:
    #    import foo
    #    vString = "0.1"
    #    print "python-foo is installed..."
    #    print "\tInstalled version: " + foo.__version__
    #    print "\tMinimum version: " + vString
    #    print ""
    #except ImportError:
    #    print """ERROR: python-foo not installed!!!
#You can get the module here: http://www.example.com
#"""
    #print ""

###############################################################################

def doChecks():
    """Checks if prefix directory exists. After that compile and install. 
    Installation fails if prefix directory doesn't exist.
    """

    if not os.path.exists(destDir):
        print "Destination directory does not exist!"
        sys.exit(1)

    installDir = os.path.join(destDir, os.path.basename(prefixDir))
    if not os.path.exists(installDir):
	print "Prefix directory does not exist!"
	sys.exit(1)

    installDir = os.path.join(destDir, os.path.basename(configDir))
    if not os.path.exists(installDir):
	print "Configuration directory does not exist!"
	sys.exit(1)

###############################################################################

def doInstall():
    """Installs compiled sourcefiles to the installation directory.
    """
    
    print "Copy program files...\n"
    
    try:
        a = Popen3("cp -f ./auth-client-config ./sbin")
        while a.poll() == -1:
            pass
        if a.poll() > 0:
            raise "CopyError", "Error!!! Could not copy File to sbin. Maybe wrong permissions?"
	
	print "Updating ./sbin/auth-client-config to use " + configDir
        a = Popen3("sed -i 's%#CONFIG_PREFIX#%" + configDir + "%' ./sbin/auth-client-config")
        while a.poll() == -1:
            pass
        if a.poll() > 0:
            raise "UpdateError", "Error!!! Could not update File. Maybe wrong permissions?"

        a = Popen3("cp -f ./auth-client-config.8 ./share/man/man8")
        while a.poll() == -1:
            pass
        if a.poll() > 0:
            raise "CopyError", "Error!!! Could not copy File to man8. Maybe wrong permissions?"
	
	print "Updating ./share/man/man8/auth-client-config.8 to use " + configDir
        a = Popen3("sed -i 's%#CONFIG_PREFIX#%" + configDir + "%' ./share/man/man8/auth-client-config.8")
        while a.poll() == -1:
            pass
        if a.poll() > 0:
            raise "UpdateError", "Error!!! Could not update File. Maybe wrong permissions?"

	installDir = prefixDir
	if destDir != "/":
		installDir = os.path.join(destDir, os.path.basename(prefixDir))
        for tmpDir in ["./sbin", "./lib", "./share"]:
            a = Popen3("cp -fR " + tmpDir + " " + installDir)
            while a.poll() == -1:
                pass
            if a.poll() > 0:
                raise "CopyError", "Error!!! Could not copy File. Maybe wrong permissions?"
                
	installDir = configDir
	if destDir != "/":
		installDir = os.path.join(destDir, os.path.basename(configDir))
        a = Popen3("cp -fR etc/*" + " " + installDir)
        while a.poll() == -1:
            pass
        if a.poll() > 0:
            raise "CopyError", "Error!!! Could not copy File. Maybe wrong permissions?"

		
        print "Finished copying program files.\n"
        print "auth-client-config installed successfully! :)"
        
    except "CopyError", errorMessage:
        print errorMessage
        sys.exit(1)
    
###############################################################################

def printHelp():
    """Prints a help text for the auth-client-config installation program.
    """
    
    helpString = """Install options:
 --prefix=PATH \t\t Install path (default is /usr/local)
 --config-prefix=PATH \t\t Configuration path (default is /etc)
 --destdir=PATH \t\t Install into this directory instead of '/'
 --compile-only \t Just compile source files. No installation.
 \n"""
 
    print helpString
    
    sys.exit(1)
    
###############################################################################
    
def doCompile():
    """Compiles all source files to python bytecode.
    """
    
    print "Compiling python source files ...\n"
    
    input, output = os.popen2("find ./lib -name \"*.py\"")
    tmpArray = output.readlines()
    fileList = []
    for x in tmpArray:
        if x[:26] == "./lib/auth-client-config/":
            fileList.append(x[:-1])
    for x in fileList:
        print "compiling " + x
        py_compile.compile(x)
        
    print "\nFinished compiling.\n"
         
###############################################################################

def evalArguments():
    """ Evaluate options given to the install script by the user.
    """
    
    if len(sys.argv) == 2:
        printHelp()
        return
        
    for x in sys.argv[1:]:
        if x == "--compile-only":
            global compileOnly
            compileOnly = True
        elif x[:9] == "--prefix=":
            global prefixDir
            prefixDir = x[9:]
            if (prefixDir[-1] == "/") and (len(prefixDir) > 1):
                prefixDir = prefixDir[:-1]
        elif x[:16] == "--config-prefix=":
            global configDir
            configDir = x[16:]
            if (configDir[-1] == "/") and (len(configDir) > 1):
                configDir = configDir[:-1]
        elif x[:10] == "--destdir=":
            global destDir
            destDir = x[10:]
            if (destDir[-1] == "/") and (len(destDir) > 1):
                destDir = destDir[:-1]
        else:
            print "Unknown options. Exiting..."
            sys.exit(1)

###############################################################################


print "auth-client-config (C) 2007 Jamie Strandboge\n"

doImportCheck()
print ""

evalArguments()
doChecks()
    
doCompile()

if not compileOnly:
    # Check if prefixDir exists
    if not(os.path.exists(prefixDir)):
        print "Prefix directory does not exist!"
        sys.exit(1)

    if not(os.path.exists(configDir)):
        print "Configuration directory does not exist!"
        sys.exit(1)

    doInstall()

