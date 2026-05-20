#!/bin/sh

testdir="tests"
tests="bad fsm installation"
CUR=`pwd`

export ACCPATH="$CUR/$testdir/testarea"
export ACCTMP="$CUR/$testdir/testarea/tmp"

STOPONFAIL="no"
STOPONSKIP="no"
if [ "$1" = "-s" ]; then
	shift
	STOPONFAIL="yes"
fi
if [ "$1" = "-S" ]; then
	shift
	STOPONFAIL="yes"
	STOPONSKIP="yes"
fi
if [ ! -z "$1" ]; then
        tests="$1"
fi

if [ ! -d "$testdir" ]; then
	echo "Couldn't find '$testdir' directory"
	exit 1
fi

if [ ! -x "./install.py" ]; then
	echo "Couldn't find install.py"
	exit 1
fi

skipped=0
errors=0
numtests=0
for class in $tests
do
	for d in `ls -d -1 $testdir/$class/* 2>/dev/null`
	do
		if [ $skipped -gt 0 ]; then
			if [ "$STOPONSKIP" = "yes" ]; then
				echo ""
				echo "STOPONSKIP set, exiting on skip"
				exit 1
			fi
		fi
		thistest=`basename $d`
		echo ""
		echo "Performing tests '$class/$thistest'"

		if [ ! -x "$CUR/$testdir/$class/$thistest/runtest.sh" ]; then
			skipped=$(($skipped + 1)) 
			echo "    WARNING: couldn't find '$CUR/$testdir/$class/$thistest/runtest.sh' (skipping)"
			continue
		fi
			
		echo "- installing"
		if [ -d "$testdir/testarea" ]; then
			rm -rf $testdir/testarea
		fi

		mkdir -p $testdir/testarea/usr/sbin $testdir/testarea/etc/pam.d $testdir/testarea/tmp || exit 1
		./install.py --prefix="$CUR/$testdir/testarea/usr" --config-prefix="$CUR/$testdir/testarea/etc" > /dev/null
		if [ "$?" != "0" ]; then
			exit 1
		fi

		# this is to allow root to run the tests without error.  I don't
		# like building things as root, but some people do...
		sed -i 's/^insecure = False$/insecure = True/' $testdir/testarea/usr/sbin/auth-client-config

		# need to clear this out since tests provide it
		rm -rf $testdir/testarea/etc/*
		cp -rL $testdir/$class/$thistest/orig/* $testdir/testarea/etc || exit 1
		cp -f $testdir/$class/$thistest/runtest.sh $testdir/testarea || exit 1

		echo "- result: "
		numtests=$(($numtests + 1))
		# now run the test
		$CUR/$testdir/testarea/runtest.sh
		if [ "$?" != "0" ];then
			echo "    ** FAIL **"
			errors=$(($errors + 1))
		else
			if [ ! -f "$ACCTMP/result" ]; then
				skipped=$(($skipped + 1)) 
				echo "    WARNING: couldn't find '$ACCTMP/result' (skipping)"
				continue
			else
				# fix discrepencies between python versions
				sed -i 's/^usage:/Usage:/' $ACCTMP/result
				sed -i 's/^options:/Options:/' $ACCTMP/result
			fi
			if [ ! -f "$testdir/$class/$thistest/result" ]; then
				skipped=$(($skipped + 1)) 
				echo "    WARNING: couldn't find '$testdir/$class/$thistest/result' (skipping)"
				continue
			fi
			diffs=`diff -Naur $testdir/$class/$thistest/result $ACCTMP/result`
			if [ -z "$diffs" ]; then
				echo "    PASS"
			else
				errors=$(($errors + 1))
				echo "    FAIL:"
				echo "$diffs"
			fi
		fi
		if [ $errors -gt 0 ]; then
			if [ "$STOPONFAIL" = "yes" ]; then
				echo ""
				echo "FAILED $testdir/$class/$thistest -- result found in $ACCTMP/result"
				if [ ! -z "$diffs" ]; then
					echo "Update with:"
					echo "cp $ACCTMP/result $testdir/$class/$thistest"
				fi
				exit 1
			fi
		fi
	done
done

if [ -d "$testdir/testarea" ]; then
	rm -rf $testdir/testarea
fi

echo ""
echo "-------"
echo "Results"
echo "-------"
echo "Attempts:      $numtests"
echo "Skipped:       $skipped"
echo "Errors:        $errors"

if [ "$errors" != "0" ]; then
	exit 1
fi
if [ "$skipped" != "0" ]; then
	exit 2
fi

exit 0

