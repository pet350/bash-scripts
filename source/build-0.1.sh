# Define Static Variables
export PREFIX="/usr"

# Only Define Static Variables IF they don't exist
if [ ${#RUNDIR}		-eq 0 ]; then export RUNDIR="/run";			fi
if [ ${#MANDIR}		-eq 0 ]; then export MANDIR="/usr/share/man";		fi
if [ ${#DATADIR}	-eq 0 ]; then export DATADIR="/usr/share";		fi
if [ ${#DOCDIR}		-eq 0 ]; then export DOCDIR="/usr/share/doc";		fi
if [ ${#BINDIR}		-eq 0 ]; then export BINDIR="/usr/bin";			fi
if [ ${#LIBDIR}		-eq 0 ]; then export LIBDIR="/usr/lib64";		fi
if [ ${#LIBEXECDIR}	-eq 0 ]; then export LIBEXECDIR="/usr/libexec";		fi
if [ ${#SYSCONFDIR}	-eq 0 ]; then export SYSCONFDIR="/etc";			fi
if [ ${#LOCALSTATEDIR}	-eq 0 ]; then export LOCALSTATEDIR="/var"; 		fi

# Define BUILD_OPTS based on the above Variables
export BUILD_OPTS="--prefix=$PREFIX --mandir=$MANDIR --docdir=$DOCDIR --bindir=$BINDIR --libexecdir=$LIBEXECDIR --sysconfdir=$SYSCONFDIR --localstatedir=$LOCALSTATEDIR"
