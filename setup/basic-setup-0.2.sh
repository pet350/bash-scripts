#!/bin/bash
# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"
ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

INIT_COLOR_SHORTHAND

# Define RUN_CMD and VERSION
export RUN_CMD="$(basename $0)"
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2021-12-20, 2021-12-26"

# Self explanitory function
function SHOW_HEADER()
{
  printf "%s: " "$(SHOW_DATE_TIME)";    CLB_TEXT; printf "%s:\t" "$RUN_CMD";    CLG_TEXT; printf "Version: ";  CY_TEXT;  printf "%s\t" "$VERSION";      CLG_TEXT; printf "By: "; CLR_TEXT
  printf "%s " "$AUTHOR";               CLG_TEXT; printf "Dated: ";             CLR_TEXT; printf "%s\n" "$MODIFIED"
  printf "%s: " "$(SHOW_DATE_TIME)";    CLB_TEXT; printf "%s:\t" "$BASH_BIN";   CLG_TEXT; printf "Version: ";  CY_TEXT;  printf "%s\n" "${BASH_VERSINFO[5]^^}"; CN_TEXT
  return $SUCCESS
};

case "${BASH_VERSINFO[5],,}" in
  'x86_64-suse-linux')		declare -i BOL_OPENSUSE=$TRUE;		export SETUP_BIN="$ZYPPER_BIN";;
  *)	SHOW_HEADER; echo "Unsupported O/S"; exit $SUCCESS;;
esac

declare -a ADDITIONAL=();
declare -i LENGTH=${#ADDITIONAL[@]}
declare -x PT="in -t pattern"
declare -x IN="in"
declare -x AR="ar"

for OPTION in $@; do
  case ${OPTION,,} in
    --version)			SHOW_HEADER;				exit $SUCCESS;;
    --verbose | -v)		declare -i BOL_VERBOSE=$TRUE;;
    --test | -t)		declare -i BOL_TEST=$TRUE;		export SETUP_BIN="$TRUE_BIN";;
    --patterns)			declare -i BOL_PATTERN_INSTALL=$TRUE;;
    --packages)                 declare -i BOL_PACKAGE_INSTALL=$TRUE;;
    --repos)			declare -i BOL_REPO_INSTALL=$TRUE;;
    --no-patterns)		declare -i BOL_PATTERN_INSTALL=$FALSE;;
    --no-packages)		declare -i BOL_PACKAGE_INSTALL=$FALSE;;
    --no-repos)                  declare -i BOL_REPO_INSTALL=$FALSE;;
    *) LENGTH=${#ADDITIONAL[@]};	ADDITIONAL[$((LENGTH))]=$OPTION;;
  esac
done

# Boolean Definitions, if they don't already exist
if [ ${#BOL_PACKAGE_INSTALL}	-eq 0 ]; then declare -i BOL_PACKAGE_INSTALL=$TRUE;	fi
if [ ${#BOL_PATTERN_INSTALL}	-eq 0 ]; then declare -i BOL_PATTERN_INSTALL=$TRUE;	fi
if [ ${#BOL_REPO_INSTALL}	-eq 0 ]; then declare -i BOL_REPO_INSTALL=$TRUE;	fi

# Array Definitions
declare -a INSTALL_LIST=();
declare -a INSTRUCTION_ARRAY=();
declare -a ENABLE_INSTRUCTION_ARRAY=();
declare -a INSTALL_REPO_ARRAY=( "https://download.opensuse.org/repositories/home:ecsos:server/openSUSE_Tumbleweed/home:ecsos:server.repo\n"					\
				"-f -n packman http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman\n" );

declare -a INSTALL_PATTERN_ARRAY=( \
	"network_admin\n"	"non_oss\n"		"office\n"		"openSUSEway\n"			"print_server\n"						\
	"microos_hardware\n"	"microos_cockpit\n"	"microos_cloud\n"	"microos_base_zypper\n"		"microos_base_packagekit\n"					\
	"microos_base\n"	"lamp_server\n"		"kvm_tools\n"		"kvm_server\n"			"file_server\n"			"devel_yast\n"			\
	"devel_web\n"		"devel_tcl\n"		"devel_ruby\n"		"devel_rpm_build\n"		"devel_qt5\n"			"devel_python3\n"		\
	"devel_perl\n"		"devel_osc_build\n"	"devel_mono\n"		"devel_kernel\n"		"devel_java\n"			"devel_basis\n"			\
	"devel_C_C++\n"		"console\n" );

declare -a INSTALL_PACKAGE_ARRAY=( \
	"mediainfo\n"		"libqt5-qttranslations\n" 			"javapackages-filesystem\n"	"libqt5-qtdoc-devel\n"		"ipcalc\n"			\
	"qemu-ivshmem-tools\n"	"qemu-testsuite\n"	"os-autoinst-qemu-kvm\n"				"qemu-hw-display-virtio-vga\n"  "qemu-chardev-baum\n"		\
	"qemu-block-ssh\n"	"qemu-block-curl\n"	"qemu-audio-pa\n"	"qemu-audio-alsa\n"		"qemu-accel-qtest\n"		"qemu-tools\n"			\
	"os-autoinst-qemu-x86\n"			"qemu-ui-opengl\n"	"qemu-ui-spice-core\n"		"qemu-hw-display-virtio-gpu\n"	"qemu-hw-s390x-virtio-gpu-ccw\n" \
	"qemu\n"		"qemu-ppc\n"		"qemu-accel-tcg-x86\n"	"qemu-ovmf-x86_64\n"		"qemu-audio-jack\n"		"qemu-block-iscsi\n"		\
	"qemu-ovmf-ia32\n"	"qemu-hw-display-virtio-gpu-pci\n"		"qemu-microvm\n"		"qemu-ksm\n"			"qemu-sgabios\n"		\
	"qemu-uefi-aarch64\n"	"qemu-lang\n"		"qemu-uefi-aarch32\n"	"qemu-hw-usb-host\n"		"libvirt-daemon-driver-qemu\n"	"system-user-qemu\n"		\
	"qemu-block-rbd\n"	"qemu-ui-spice-app\n"	"qemu-audio-spice\n"	"qemu-ui-curses\n"		"qemu-vhost-user-gpu\n"		"qemu-hw-display-qxl\n"		\
	"qemu-block-dmg\n"	"qemu-hw-usb-smartcard\n"			"qemu-ui-gtk\n"			"qemu-guest-agent\n"		"qemu-block-gluster\n"		\
	"qemu-block-nfs\n"	"qemu-x86\n"		"qemu-arm\n"		"qemu-kvm\n"			"qemu-s390x\n"			"qemu-extra\n"			\
	"libvirt-daemon-qemu\n"	"qemu-chardev-spice\n"	"qemu-hw-usb-redirect"	"qemu-ipxe\n"			"qemu-linux-user\n"		"qemu-seabios\n"		\
	"qemu-skiboot\n"	"qemu-vgabios\n"  	"tomcat\n"		"xrdp\n"			"cmake\n"			"mariadb\n"			\
	"mariadb-client\n"	"mariadb-java-client\n" "mariadb-tools\n"	"mariadb-rpm-macros\n"		"libvirt-libs\n"		"ruby3.0-rubygem-fog-libvirt\n" \
	"python38-libvirt-python\n"			"vagrant-libvirt\n"	"system-user-libvirt-dbus\n"	"libvirt-devel\n"		"libvirt-daemon-driver-lxc\n"	\
	"ruby3.0-rubygem-ruby-libvirt\n"		"libvirt-daemon-driver-nwfilter\n"			"libvirt-daemon-driver-qemu\n"	"system-group-libvirt\n"	\
	"libvirt-daemon-driver-storage-rbd\n"		"libvirt-daemon-hooks\n"				"libvirt-daemon-driver-storage-iscsi-direct\n"			\
	"libvirt-daemon-driver-storage-iscsi\n"		"libvirt-daemon-driver-storage-mpath\n"			"libvirt-daemon-driver-storage-gluster\n"			\
	"libvirt-daemon-driver-storage-logical\n"	"libvirt-daemon-driver-storage-core\n"			"libvirt-glib\n"		"libvirt-nss\n"			\
	"libvirt-daemon-driver-secret\n"		"libvirt-daemon-driver-storage\n"			"libvirt\n"			"libvirt-client\n"		\
	"libvirt-daemon\n"				"libvirt-daemon-driver-interface\n"			"libvirt-daemon-driver-libxl4\n"				\
	"libvirt-daemon-driver-network\n"		"libvirt-daemon-config-network\n"			"libvirt-daemon-driver-nodedev\n"				\
	"libvirt-daemon-driver-storage-scsi\n"		"libvirt-daemon-config-nwfilter\n"			"libvirt-daemon-lxc\n"						\
	"libvirt-daemon-driver-storage-disk\n"		"libvirt-daemon-qemu\n"					"libvirt-daemon-xen"						\
	"ocaml-libvirt\n"	 "libvirt-sandbox\n"	"ocaml-libvirt-devel\n" "libvirt-dbus\n"		"wireshark-plugin-libvirt\n"					\
	"bumblebee-status-module-libvirt\n"		"python38-opengl-accelerate-3.1.5-2.4.x86_64 		python38-loguru-0.5.3-4.1.noarch\n"				\
	"python36-freeipa\n"	"freeipa-client-common\n"			 "freeipa-common\n"		"freeipa-client\n"		"freeipa-client-samba\n"	\
	"freeipa-client-epn\n"																			\
	"shared-python-startup-0.1-6.5.noarch python38-charset-normalizer-2.0.9-1.1.noarch python38-PyYAML-6.0-1.1.x86_64 python38-yarl-1.7.2-1.1.x86_64\n"			\
	"python38-pyspnego-0.3.1-2.1.noarch python38-typed-ast-1.5.1-1.1.x86_64 python38-curses-3.8.12-3.1.x86_64 python38-power-1.4-3.8.noarch\n"				\
	"python36-sphinxcontrib-httpdomain-1.8.0-2.1.noarch libpython3_8-1_0-3.8.12-3.1.x86_64 python38-ipaddr-2.2.0-1.11.noarch python-2.7.18-14.1.x86_64\n"			\
	"python39-dragonmapper-0.2.6-2.1.noarch python38-Automat-20.2.0-2.1.noarch python38-ordered-set-4.0.2-1.2.noarch python38-appdirs-1.4.4-3.2.noarch\n"			\
	"python38-setuptools-57.4.0-1.2.noarch python38-pip-20.2.4-2.1.noarch python38-rpm-4.17.0-2.1.x86_64 python3-solv-0.7.20-1.1.x86_64\n"					\
	"python38-importlib-metadata-4.8.2-1.1.noarch python36-base-3.6.15-7.1.x86_64 python39-base-3.9.9-2.1.x86_64 python38-zhon-1.1.5-3.5.noarch\n" 				\
	"python38-six-1.16.0-2.2.noarch python38-pycurl-7.43.0.6-3.2.x86_64 python38-ply-3.11-3.17.noarch python38-iniconfig-1.1.1-1.5.noarch python38-idna-3.3-1.1.noarch\n"	\
	"python38-decorator-5.1.0-1.1.noarch python38-colorama-0.4.4-1.5.noarch python38-cmdln-2.0.0-3.5.noarch python38-certifi-2021.5.30-1.2.noarch\n"			\
	"python38-cached-property-1.5.2-1.5.noarch python38-apipkg-2.1.0-1.1.noarch python38-PySocks-1.7.1-1.9.noarch python3-tevent-0.11.0-1.1.x86_64\n"			\
	"python3-tdb-1.4.4-1.1.x86_64 python3-talloc-2.3.3-1.1.x86_64 python3-nftables-1.0.0-1.2.x86_64 python3-ldb-2.4.1-1.1.x86_64 python3-createrepo_c-0.17.3-1.2.x86_64\n"	\
	"python3-apparmor-3.0.3-5.1.x86_64 python36-3.6.15-7.1.x86_64 python38-hanzidentifier-1.0.2-2.2.noarch python38-slip-0.6.5-6.9.noarch\n"				\
	"python38-pyudev-0.22.0-4.5.noarch python38-linux-procfs-0.6-2.7.noarch python38-configobj-5.0.6-3.12.noarch python38-cffi-1.15.0-1.1.x86_64\n"				\
	"python36-loguru-0.5.3-4.1.noarch python38-py-1.10.0-1.5.noarch python3-ipalib-4.8.0+git598.65674a840-75.64.noarch python38-distlib-0.3.4-1.1.noarch\n"			\
	"python38-lexicon-2.0.1-2.1.noarch python38-brotlipy-0.7.0-5.9.x86_64 python39-lexicon-2.0.1-2.1.noarch python38-urllib3-1.26.7-1.1.noarch\n"				\
	"yast2-python3-bindings-4.4.2-1.1.x86_64 python38-tk-3.8.12-3.1.x86_64 python38-requests-2.26.0-1.1.noarch python38-mysqlclient-2.0.3-2.2.x86_64\n"			\
	"python38-SecretStorage-3.3.1-1.6.noarch python38-packaging-21.3-1.1.noarch python38-lxml-4.6.4-1.1.x86_64 python38-pyOpenSSL-21.0.0-2.1.noarch\n"			\
	"python39-loguru-0.5.3-4.1.noarch python36-snowballstemmer-2.2.0-1.1.noarch python3-ipaclient-4.8.0+git598.65674a840-75.64.noarch\n"					\
	"python36-dragonmapper-0.2.6-2.1.noarch python36-dbm-3.6.15-7.1.x86_64 python36-pyOpenSSL-21.0.0-2.1.noarch python38-3.8.12-3.1.x86_64\n"				\
	"python38-psutil-5.8.0-3.1.x86_64 python39-dbus-python-1.2.18-1.2.x86_64 python38-dbus-python-1.2.18-1.2.x86_64 python38-slip-dbus-0.6.5-6.9.noarch\n"			\
	"python38-notify2-0.3.1-4.5.noarch python3-firewall-1.0.2-1.1.noarch python38-dragonmapper-0.2.6-2.1.noarch python38-devel-3.8.12-3.1.x86_64\n"				\
	"python36-prettytable-2.4.0-1.1.noarch python39-pycparser-2.21-1.1.noarch python39-dbm-3.9.9-2.1.x86_64 python36-cryptography-36.0.0-1.1.x86_64\n"			\
	"python39-importlib-metadata-4.8.2-1.1.noarch python38-docopt-0.6.2-7.12.noarch python38-pycups-2.0.1-1.6.x86_64 python39-3.9.9-2.1.x86_64\n"				\
	"python3-cupshelpers-1.5.15-2.1.noarch python36-curses-3.6.15-7.1.x86_64 samba-libs-python3-4.15.2+git.193.a4d6307f1fd-1.1.x86_64\n"					\
	"libsamba-policy0-python3-4.15.2+git.193.a4d6307f1fd-1.1.x86_64 python38-entrypoints-0.3-2.7.noarch python38-python-mimeparse-1.6.0-4.8.noarch\n"			\
	"python36-importlib-metadata-4.8.2-1.1.noarch samba-python3-4.15.2+git.193.a4d6307f1fd-1.1.x86_64 python38-linecache2-1.0.0-5.8.noarch\n"				\
	"python38-traceback2-1.4.0-6.8.noarch python38-libvirt-python-7.10.0-1.1.x86_64 python3-sss-murmur-2.6.1-1.1.x86_64 python39-qt5-sip-12.9.0-2.2.x86_64\n"		\
	"python36-dbus-python-1.2.18-1.2.x86_64 python36-qtwebengine-qt5-5.15.5-1.2.x86_64 python38-pyusb-1.2.1-1.1.noarch python39-PyQt6-sip-13.2.0-1.1.x86_64\n"		\
	"python38-pycairo-1.20.1-2.4.x86_64 gimp-plugins-python-2.10.28-2.2.x86_64 python36-qt5-sip-12.9.0-2.2.x86_64 python38-PyAudio-0.2.11-2.10.x86_64\n"			\
	"sudo-plugin-python-1.9.8p2-1.1.x86_64 python38-extras-1.0.0-5.6.noarch python38-trio-0.19.0-1.1.noarch python38-MarkupSafe-2.0.1-1.2.x86_64\n"				\
	"python38-async_generator-1.10-2.6.noarch python38-attrs-21.2.0-1.2.noarch python38-augeas-0.5.0-3.12.noarch python38-ecdsa-0.17.0-1.1.noarch\n"			\
	"python38-gssapi-1.6.12-1.6.x86_64 python38-more-itertools-8.10.0-1.1.noarch python38-netifaces-0.11.0-1.2.x86_64 python38-olefile-0.46-3.2.noarch\n"			\
	"python38-pyasn1-0.4.8-2.2.noarch python38-python-dateutil-2.8.2-1.2.noarch python38-pytz-2021.3-1.1.noarch python38-sniffio-1.2.0-4.4.noarch\n"			\
	"python38-sortedcontainers-2.4.0-1.2.noarch python38-wrapt-1.13.3-1.1.x86_64 python38-outcome-1.1.0-1.1.noarch python38-zipp-3.6.0-1.1.noarch\n"			\
	"python38-Pillow-8.4.0-1.1.x86_64 python38-pyasn1-modules-0.2.8-1.9.noarch python38-Babel-2.9.1-3.1.noarch python38-python-yubico-1.3.3-2.2.noarch\n"			\
	"python38-importlib-resources-5.4.0-1.1.noarch python38-qrcode-7.3.1-1.1.noarch python38-Jinja2-3.0.3-1.1.x86_64 python38-dnspython-2.1.0-1.7.noarch\n"			\
	"python38-netaddr-0.8.0-2.1.noarch python38-jwcrypto-1.0-27.2.noarch python38-pykerberos-1.2.1-1.14.x86_64 python38-pycryptodome-3.12.0-1.1.x86_64\n"			\
	"python38-docker-5.0.3-1.1.noarch python38-async_timeout-3.0.1-2.5.noarch python38-backports.entry_points_selectable-1.1.0-2.1.noarch python38-click-8.0.3-1.1.noarch\n"\
	"python38-simplejson-3.17.6-1.1.x86_64 python38-Deprecated-1.2.13-1.1.noarch libpeas-loader-python3-1.30.0-2.1.x86_64 python38-hiredis-1.1.0-1.5.x86_64\n"		\
	"python39-charset-normalizer-2.0.9-1.1.noarch python36-simplejson-3.17.6-1.1.x86_64 python38-redis-3.5.3-3.2.noarch python3-cepces-0.3.4-4.1.noarch\n"			\
	"python38-PyQt6-6.2.2-1.1.x86_64 python38-PyQt6-WebEngine-6.2.1-1.2.x86_64 python38-aiohttp_cors-0.7.0-2.1.x86_64 python38-cryptography-36.0.0-1.1.x86_64\n"		\
	"python38-requests-kerberos-0.14.0-1.1.noarch python38-websockify-0.10.0-2.1.noarch python38-gobject-cairo-3.42.0-1.3.x86_64 python38-PyQt6-sip-13.2.0-1.1.x86_64\n"	\
	"python38-libxml2-2.9.12-2.1.x86_64 python38-testtools-2.5.0-1.1.noarch python38-fixtures-3.0.0-6.4.noarch python38-sgmllib3k-1.0.0-2.4.noarch\n"			\
	"python36-qt5-5.15.6-2.2.x86_64 python39-qt5-5.15.6-2.2.x86_64 python39-PyQt6-6.2.2-1.1.x86_64 python39-qtwebengine-qt5-5.15.5-1.2.x86_64\n"				\
	"python39-PyQt6-WebEngine-6.2.1-1.2.x86_64 python38-i3ipc-2.2.1-3.5.noarch python38-filelock-3.0.12-2.8.noarch python38-gunicorn-20.1.0-2.1.noarch\n"			\
	"python38-mccabe-0.6.1-2.11.noarch python38-multidict-5.1.0-1.7.x86_64 python38-mypy_extensions-0.4.3-1.8.noarch python38-pathspec-0.8.1-2.2.noarch\n"			\
	"python38-platformdirs-2.4.0-1.1.noarch python38-pluggy-1.0.0-1.1.noarch python38-pycares-4.0.0-1.2.x86_64 python38-pycodestyle-2.8.0-1.1.noarch\n"			\
	"python38-pyflakes-2.4.0-1.1.noarch python38-regex-2021.7.6-1.2.x86_64 python38-toml-0.10.2-2.5.noarch python38-typing_extensions-3.10.0.2-1.1.noarch\n"		\
	"python38-wcwidth-0.2.5-3.2.noarch python38-aiodns-3.0.0-1.2.noarch python38-flake8-4.0.1-2.1.noarch patterns-devel-python-devel_python3-20180125-4.5.x86_64\n"		\
	"python38-pbr-5.8.0-1.1.noarch python38-future-0.18.2-3.4.noarch python38-ldap3-2.9.1-1.2.noarch python38-ldapdomaindump-0.9.3-1.7.noarch\n"				\
	"python36-ordered-set-4.0.2-1.2.noarch python36-appdirs-1.4.4-3.2.noarch python36-setuptools-57.4.0-1.2.noarch python36-pip-20.2.4-2.1.noarch\n"			\
	"python36-zope.interface-5.4.0-2.1.x86_64 python36-zhon-1.1.5-3.5.noarch python36-typing_extensions-3.10.0.2-1.1.noarch python36-six-1.16.0-2.2.noarch\n"		\
	"python36-charset-normalizer-2.0.9-1.1.noarch python36-roman-3.3-1.6.noarch python36-pytz-2021.3-1.1.noarch python36-pyserial-3.5-1.6.noarch\n"				\
	"python36-pycurl-7.43.0.6-3.2.x86_64 python36-pyasn1-0.4.8-2.2.noarch python36-olefile-0.46-3.2.noarch python36-more-itertools-8.10.0-1.1.noarch\n"			\
	"python36-iniconfig-1.1.1-1.5.noarch python36-immutables-0.15-2.2.x86_64 python36-imagesize-1.2.0-1.7.noarch python36-idna-3.3-1.1.noarch\n"				\
	"python36-hyperframe-6.0.1-1.2.noarch python36-hpack-4.0.0-1.6.noarch python36-greenlet-1.1.2-1.1.x86_64 python39-cryptography-36.0.0-1.1.x86_64\n"			\
	"python36-constantly-15.1.0-2.16.noarch python36-colorama-0.4.4-1.5.noarch python36-certifi-2021.5.30-1.2.noarch python36-cached-property-1.5.2-1.5.noarch\n"		\
	"python36-attrs-21.2.0-1.2.noarch python36-apipkg-2.1.0-1.1.noarch python36-alabaster-0.7.12-1.10.noarch python36-Whoosh-2.7.4-5.6.noarch\n"				\
	"python36-Pygments-2.9.0-2.1.noarch python36-PySocks-1.7.1-1.9.noarch python36-PyHamcrest-2.0.2-1.10.noarch python36-PrettyTable-2.4.0-1.1.noarch\n"			\
	"python36-MarkupSafe-2.0.1-1.2.x86_64 python36-hanzidentifier-1.0.2-2.2.noarch python36-Babel-2.9.1-3.1.noarch python36-cffi-1.15.0-1.1.x86_64\n"			\
	"python36-pyasn1-modules-0.2.8-1.9.noarch python36-Pillow-8.4.0-1.1.x86_64 python36-zipp-3.6.0-1.1.noarch python36-contextvars-2.4-2.2.noarch\n"			\
	"python36-hyperlink-21.0.0-1.5.noarch python36-h2-4.0.0-2.4.noarch python36-tornado5-5.1.1-6.1.x86_64 python36-py-1.10.0-1.5.noarch python36-Jinja2-3.0.3-1.1.x86_64\n"	\
	"python36-pycares-4.0.0-1.2.x86_64 python39-docker-5.0.3-1.1.noarch python36-brotlipy-0.7.0-5.9.x86_64 python36-bcrypt-3.2.0-3.10.x86_64\n"				\
	"python36-docutils-0.16-3.7.noarch python36-aiocontextvars-0.2.2-2.3.x86_64 python36-Sphinx-4.3.1-1.1.noarch python36-urllib3-1.26.7-1.1.noarch\n"			\
	"python36-service_identity-18.1.0-3.8.noarch python36-incremental-21.3.0-1.2.noarch python36-requests-2.26.0-1.1.noarch\n"						\
	"python36-sphinxcontrib-websupport-1.2.4-1.5.noarch python36-sphinxcontrib-serializinghtml-1.1.5-1.2.noarch python36-sphinxcontrib-qthelp-1.0.3-1.6.noarch\n"		\
	"python36-sphinxcontrib-htmlhelp-2.0.0-1.2.noarch python36-sphinxcontrib-jsmath-1.0.1-2.7.noarch python36-sphinxcontrib-devhelp-1.0.2-1.6.noarch\n"			\
	"python36-sphinxcontrib-applehelp-1.0.2-1.6.noarch python36-sphinx_rtd_theme-1.0.0-1.1.noarch python3-bind-9.16.23-1.1.noarch python38-websockets-10.0-3.1.x86_64\n"	\
	"python39-gobject-cairo-3.42.0-1.3.x86_64 python38-PyNaCl-1.4.0-2.1.x86_64 python38-bcrypt-3.2.0-3.10.x86_64 python38-chardet-4.0.0-2.1.noarch\n"			\
	"python38-cssselect-1.1.0-1.8.noarch python38-docker-pycreds-0.4.0-1.11.noarch python38-fluidity-sm-0.2.0-1.12.noarch python38-jeepney-0.7.1-1.2.noarch\n"		\
	"python38-ptyprocess-0.7.0-1.6.noarch python38-pygit2-1.7.0-1.2.x86_64 python38-python-xlib-0.29-2.2.noarch python38-suntime-1.2.5-1.8.noarch\n"			\
	"python3-ipa_hbac-2.6.1-1.1.x86_64 python38-tzlocal-2.1-2.2.noarch python38-websocket-client-0.58.0-2.1.noarch python38-xkbgroup-0.2.0-3.2.noarch\n"			\
	"python38-pexpect-4.8.0-3.2.noarch python38-feedparser-6.0.8-1.2.noarch python38-keyring-23.2.1-1.1.noarch python38-invoke-1.6.0-1.2.noarch\n"				\
	"yast2-adcommon-python-1.6-1.4.noarch python38-paramiko-2.8.0-1.1.noarch python38-hexdump-3.3-2.8.noarch nbdkit-python-plugin-1.29.4-1.1.x86_64\n"			\
	"python38-evtx-0.7.4-3.1.noarch python38-gobject-3.42.0-1.3.x86_64 python38-dbm-3.8.12-3.1.x86_64 python36-SQLAlchemy-1.4.27-1.1.x86_64\n"				\
	"python38-Twisted-21.7.0-4.1.x86_64 python39-gobject-3.42.0-1.3.x86_64 python38-pycparser-2.21-1.1.noarch python38-pysmbc-1.0.23-2.1.x86_64\n"				\
	"python3-vapoursynth-54-1.3.x86_64 python38-virtualenv-20.10.0-1.1.noarch python38-numpy-1.21.4-2.1.x86_64 libpython3_6m1_0-3.6.15-7.1.x86_64\n"			\
	"python36-wcwidth-0.2.5-3.2.noarch python36-pycparser-2.21-1.1.noarch libpython3_9-1_0-3.9.9-2.1.x86_64 python-rpm-macros-20211022.38e7c70-1.1.noarch\n"		\
	"python-rpm-generators-20211022.38e7c70-1.1.noarch rpm-build-python-4.17.0-2.1.x86_64 libpython2_7-1_0-2.7.18-205.2.x86_64 python-base-2.7.18-205.2.x86_64\n"		\
	"python-devel-2.7.18-205.2.x86_64 patterns-openSUSE-devel_python-20170206-664.1.x86_64 python38-requests-toolbelt-0.9.1-5.1.noarch\n"					\
	"python39-pyOpenSSL-21.0.0-2.1.noarch python3-sssd-config-2.6.1-1.1.x86_64 python38-prettytable-2.4.0-1.1.noarch python36-pyparsing-3.0.6-1.1.noarch\n"			\
	"python36-Automat-20.2.0-2.1.noarch python36-gobject-3.42.0-1.3.x86_64 python38-pytest-6.2.5-1.1.noarch python38-tox-3.24.4-1.1.noarch\n"				\
	"python38-aiohttp-3.7.4-5.1.x86_64 python38-black-20.8b1-2.8.noarch python-gobject2-2.28.7-3.10.x86_64 python2-pycairo-1.18.1-5.11.x86_64\n"				\
	"python-gtk-2.24.0-21.5.x86_64 python39-pyparsing-3.0.6-1.1.noarch python-xml-2.7.18-205.2.x86_64 python38-gobject-Gdk-3.42.0-1.3.x86_64\n"				\
	"python38-pyparsing-3.0.6-1.1.noarch python39-curses-3.9.9-2.1.x86_64 python39-ordered-set-4.0.2-1.2.noarch python39-appdirs-1.4.4-3.2.noarch\n"			\
	"python39-packaging-21.3-1.1.noarch python39-setuptools-57.4.0-1.2.noarch python39-pip-20.2.4-2.1.noarch python38-tornado6-6.1-4.1.x86_64\n"				\
	"python39-zhon-1.1.5-3.5.noarch python39-wcwidth-0.2.5-3.2.noarch python39-six-1.16.0-2.2.noarch python39-pyrsistent-0.18.0-1.1.x86_64\n"				\
	"python39-pyasn1-0.4.8-2.2.noarch python39-ptyprocess-0.7.0-1.6.noarch python39-more-itertools-8.10.0-1.1.noarch python39-iniconfig-1.1.1-1.5.noarch\n"			\
	"python39-idna-3.3-1.1.noarch python39-fluidity-sm-0.2.0-1.12.noarch python39-docopt-0.6.2-7.12.noarch python39-distro-1.6.0-3.1.noarch\n"				\
	"python39-decorator-5.1.0-1.1.noarch python39-colorama-0.4.4-1.5.noarch python39-click-8.0.3-1.1.noarch python39-chardet-4.0.0-2.1.noarch\n"				\
	"python39-certifi-2021.5.30-1.2.noarch python39-cached-property-1.5.2-1.5.noarch python39-attrs-21.2.0-1.2.noarch python39-apipkg-2.1.0-1.1.noarch\n"			\
	"python39-PyYAML-6.0-1.1.x86_64 python39-PySocks-1.7.1-1.9.noarch python39-hanzidentifier-1.0.2-2.2.noarch python39-texttable-1.6.3-1.5.noarch\n"			\
	"python39-prettytable-2.4.0-1.1.noarch python39-websocket-client-0.58.0-2.1.noarch python39-docker-pycreds-0.4.0-1.11.noarch python39-cffi-1.15.0-1.1.x86_64\n"		\
	"python39-pexpect-4.8.0-3.2.noarch python39-zipp-3.6.0-1.1.noarch python39-gssapi-1.6.12-1.6.x86_64 python36-packaging-21.3-1.1.noarch\n"				\
	"python39-python-dotenv-0.15.0-1.6.noarch python39-py-1.10.0-1.5.noarch python36-gobject-cairo-3.42.0-1.3.x86_64 python39-brotlipy-0.7.0-5.9.x86_64\n"			\
	"python39-bcrypt-3.2.0-3.10.x86_64 python39-PyNaCl-1.4.0-2.1.x86_64 python39-invoke-1.6.0-1.2.noarch python39-paramiko-2.8.0-1.1.noarch\n"				\
	"python39-jsonschema-3.2.0-5.1.noarch python39-urllib3-1.26.7-1.1.noarch python39-requests-2.26.0-1.1.noarch python39-dockerpty-0.4.1-4.11.noarch\n"			\
	"python39-docker-compose-1.28.5-1.5.noarch python38-protobuf-3.17.3-2.4.x86_64 python38-PyHamcrest-2.0.2-1.10.noarch python38-constantly-15.1.0-2.16.noarch\n"		\
	"python38-greenlet-1.1.2-1.1.x86_64 python38-hpack-4.0.0-1.6.noarch python38-hyperframe-6.0.1-1.2.noarch python38-hyperlink-21.0.0-1.5.noarch\n"			\
	"python38-pyserial-3.5-1.6.noarch python38-pyxdg-0.27-2.2.noarch python38-qt5-sip-12.9.0-2.2.x86_64 python38-service_identity-18.1.0-3.8.noarch\n"			\
	"python38-zope.event-4.5.0-2.1.noarch python38-zope.interface-5.4.0-2.1.x86_64 python38-h2-4.0.0-2.4.noarch python38-gevent-21.1.2-3.2.x86_64\n"			\
	"python38-qt5-5.15.6-2.2.x86_64 python3-openshot-0.2.7-1.2.x86_64 python38-incremental-21.3.0-1.2.noarch python38-qtwebengine-qt5-5.15.5-1.2.x86_64\n"			\
	"python38-pyzmq-22.2.1-1.7.x86_64 python38-ldap-3.4.0-1.1.x86_64 python38-opengl-3.1.5-2.4.noarch python38-base-3.8.12-3.1.x86_64 python36-Twisted-21.7.0-4.1.x86_64\n"	\
	"texlive-pythonhighlight-doc-2021.186.svn43191-46.3.noarch texlive-pythontex-doc-2021.186.0.0.17svn52174-46.3.noarch\n"							\
	"texlive-pythontex-bin-2021.20210325.svn31638-77.3.x86_64 texlive-pythontex-2021.186.0.0.17svn52174-46.3.noarch texlive-pythonhighlight-2021.186.svn43191-46.3.noarch\n"\
	);
#Python pachages
#python38-opengl-accelerate-3.1.5-2.4.x86_64 python38-loguru-0.5.3-4.1.noarch shared-python-startup-0.1-6.5.noarch python38-charset-normalizer-2.0.9-1.1.noarch python38-PyYAML-6.0-1.1.x86_64 python38-yarl-1.7.2-1.1.x86_64 python38-pyspnego-0.3.1-2.1.noarch python38-typed-ast-1.5.1-1.1.x86_64 python38-curses-3.8.12-3.1.x86_64 python38-power-1.4-3.8.noarch python36-sphinxcontrib-httpdomain-1.8.0-2.1.noarch libpython3_8-1_0-3.8.12-3.1.x86_64 python38-ipaddr-2.2.0-1.11.noarch python-2.7.18-14.1.x86_64 python39-dragonmapper-0.2.6-2.1.noarch python38-Automat-20.2.0-2.1.noarch python38-ordered-set-4.0.2-1.2.noarch python38-appdirs-1.4.4-3.2.noarch python38-setuptools-57.4.0-1.2.noarch python38-pip-20.2.4-2.1.noarch python38-rpm-4.17.0-2.1.x86_64 python3-solv-0.7.20-1.1.x86_64 python38-importlib-metadata-4.8.2-1.1.noarch python36-base-3.6.15-7.1.x86_64 python39-base-3.9.9-2.1.x86_64 python38-zhon-1.1.5-3.5.noarch python38-six-1.16.0-2.2.noarch python38-pycurl-7.43.0.6-3.2.x86_64 python38-ply-3.11-3.17.noarch python38-iniconfig-1.1.1-1.5.noarch python38-idna-3.3-1.1.noarch python38-decorator-5.1.0-1.1.noarch python38-colorama-0.4.4-1.5.noarch python38-cmdln-2.0.0-3.5.noarch python38-certifi-2021.5.30-1.2.noarch python38-cached-property-1.5.2-1.5.noarch python38-apipkg-2.1.0-1.1.noarch python38-PySocks-1.7.1-1.9.noarch python3-tevent-0.11.0-1.1.x86_64 python3-tdb-1.4.4-1.1.x86_64 python3-talloc-2.3.3-1.1.x86_64 python3-nftables-1.0.0-1.2.x86_64 python3-ldb-2.4.1-1.1.x86_64 python3-createrepo_c-0.17.3-1.2.x86_64 python3-apparmor-3.0.3-5.1.x86_64 python36-3.6.15-7.1.x86_64 python38-hanzidentifier-1.0.2-2.2.noarch python38-slip-0.6.5-6.9.noarch python38-pyudev-0.22.0-4.5.noarch python38-linux-procfs-0.6-2.7.noarch python38-configobj-5.0.6-3.12.noarch python38-cffi-1.15.0-1.1.x86_64 python36-loguru-0.5.3-4.1.noarch python38-py-1.10.0-1.5.noarch python3-ipalib-4.8.0+git598.65674a840-75.64.noarch python38-distlib-0.3.4-1.1.noarch python38-lexicon-2.0.1-2.1.noarch python38-brotlipy-0.7.0-5.9.x86_64 python39-lexicon-2.0.1-2.1.noarch python38-urllib3-1.26.7-1.1.noarch yast2-python3-bindings-4.4.2-1.1.x86_64 python38-tk-3.8.12-3.1.x86_64 python38-requests-2.26.0-1.1.noarch python38-mysqlclient-2.0.3-2.2.x86_64 python38-SecretStorage-3.3.1-1.6.noarch python38-packaging-21.3-1.1.noarch python38-lxml-4.6.4-1.1.x86_64 python38-pyOpenSSL-21.0.0-2.1.noarch python39-loguru-0.5.3-4.1.noarch python36-snowballstemmer-2.2.0-1.1.noarch python3-ipaclient-4.8.0+git598.65674a840-75.64.noarch python36-dragonmapper-0.2.6-2.1.noarch python36-dbm-3.6.15-7.1.x86_64 python36-pyOpenSSL-21.0.0-2.1.noarch python38-3.8.12-3.1.x86_64 python38-psutil-5.8.0-3.1.x86_64 python39-dbus-python-1.2.18-1.2.x86_64 python38-dbus-python-1.2.18-1.2.x86_64 python38-slip-dbus-0.6.5-6.9.noarch python38-notify2-0.3.1-4.5.noarch python3-firewall-1.0.2-1.1.noarch python38-dragonmapper-0.2.6-2.1.noarch python38-devel-3.8.12-3.1.x86_64 python36-prettytable-2.4.0-1.1.noarch python39-pycparser-2.21-1.1.noarch python39-dbm-3.9.9-2.1.x86_64 python36-cryptography-36.0.0-1.1.x86_64 python39-importlib-metadata-4.8.2-1.1.noarch python38-docopt-0.6.2-7.12.noarch python38-pycups-2.0.1-1.6.x86_64 python39-3.9.9-2.1.x86_64 python3-cupshelpers-1.5.15-2.1.noarch python36-curses-3.6.15-7.1.x86_64 samba-libs-python3-4.15.2+git.193.a4d6307f1fd-1.1.x86_64 libsamba-policy0-python3-4.15.2+git.193.a4d6307f1fd-1.1.x86_64 python38-entrypoints-0.3-2.7.noarch python38-python-mimeparse-1.6.0-4.8.noarch python36-importlib-metadata-4.8.2-1.1.noarch samba-python3-4.15.2+git.193.a4d6307f1fd-1.1.x86_64 python38-linecache2-1.0.0-5.8.noarch python38-traceback2-1.4.0-6.8.noarch python38-libvirt-python-7.10.0-1.1.x86_64 python3-sss-murmur-2.6.1-1.1.x86_64 python39-qt5-sip-12.9.0-2.2.x86_64 python36-dbus-python-1.2.18-1.2.x86_64 python36-qtwebengine-qt5-5.15.5-1.2.x86_64 python38-pyusb-1.2.1-1.1.noarch python39-PyQt6-sip-13.2.0-1.1.x86_64 python38-pycairo-1.20.1-2.4.x86_64 gimp-plugins-python-2.10.28-2.2.x86_64 python36-qt5-sip-12.9.0-2.2.x86_64 python38-PyAudio-0.2.11-2.10.x86_64 sudo-plugin-python-1.9.8p2-1.1.x86_64 python38-extras-1.0.0-5.6.noarch python38-trio-0.19.0-1.1.noarch python38-MarkupSafe-2.0.1-1.2.x86_64 python38-async_generator-1.10-2.6.noarch python38-attrs-21.2.0-1.2.noarch python38-augeas-0.5.0-3.12.noarch python38-ecdsa-0.17.0-1.1.noarch python38-gssapi-1.6.12-1.6.x86_64 python38-more-itertools-8.10.0-1.1.noarch python38-netifaces-0.11.0-1.2.x86_64 python38-olefile-0.46-3.2.noarch python38-pyasn1-0.4.8-2.2.noarch python38-python-dateutil-2.8.2-1.2.noarch python38-pytz-2021.3-1.1.noarch python38-sniffio-1.2.0-4.4.noarch python38-sortedcontainers-2.4.0-1.2.noarch python38-wrapt-1.13.3-1.1.x86_64 python38-outcome-1.1.0-1.1.noarch python38-zipp-3.6.0-1.1.noarch python38-Pillow-8.4.0-1.1.x86_64 python38-pyasn1-modules-0.2.8-1.9.noarch python38-Babel-2.9.1-3.1.noarch python38-python-yubico-1.3.3-2.2.noarch python38-importlib-resources-5.4.0-1.1.noarch python38-qrcode-7.3.1-1.1.noarch python38-Jinja2-3.0.3-1.1.x86_64 python38-dnspython-2.1.0-1.7.noarch python38-netaddr-0.8.0-2.1.noarch python38-jwcrypto-1.0-27.2.noarch python38-pykerberos-1.2.1-1.14.x86_64 python38-pycryptodome-3.12.0-1.1.x86_64 python38-docker-5.0.3-1.1.noarch python38-async_timeout-3.0.1-2.5.noarch python38-backports.entry_points_selectable-1.1.0-2.1.noarch python38-click-8.0.3-1.1.noarch python38-simplejson-3.17.6-1.1.x86_64 python38-Deprecated-1.2.13-1.1.noarch libpeas-loader-python3-1.30.0-2.1.x86_64 python38-hiredis-1.1.0-1.5.x86_64 python39-charset-normalizer-2.0.9-1.1.noarch python36-simplejson-3.17.6-1.1.x86_64 python38-redis-3.5.3-3.2.noarch python3-cepces-0.3.4-4.1.noarch python38-PyQt6-6.2.2-1.1.x86_64 python38-PyQt6-WebEngine-6.2.1-1.2.x86_64 python38-aiohttp_cors-0.7.0-2.1.x86_64 python38-cryptography-36.0.0-1.1.x86_64 python38-requests-kerberos-0.14.0-1.1.noarch python38-websockify-0.10.0-2.1.noarch python38-gobject-cairo-3.42.0-1.3.x86_64 python38-PyQt6-sip-13.2.0-1.1.x86_64 python38-libxml2-2.9.12-2.1.x86_64 python38-testtools-2.5.0-1.1.noarch python38-fixtures-3.0.0-6.4.noarch python38-sgmllib3k-1.0.0-2.4.noarch python36-qt5-5.15.6-2.2.x86_64 python39-qt5-5.15.6-2.2.x86_64 python39-PyQt6-6.2.2-1.1.x86_64 python39-qtwebengine-qt5-5.15.5-1.2.x86_64 python39-PyQt6-WebEngine-6.2.1-1.2.x86_64 python38-i3ipc-2.2.1-3.5.noarch python38-filelock-3.0.12-2.8.noarch python38-gunicorn-20.1.0-2.1.noarch python38-mccabe-0.6.1-2.11.noarch python38-multidict-5.1.0-1.7.x86_64 python38-mypy_extensions-0.4.3-1.8.noarch python38-pathspec-0.8.1-2.2.noarch python38-platformdirs-2.4.0-1.1.noarch python38-pluggy-1.0.0-1.1.noarch python38-pycares-4.0.0-1.2.x86_64 python38-pycodestyle-2.8.0-1.1.noarch python38-pyflakes-2.4.0-1.1.noarch python38-regex-2021.7.6-1.2.x86_64 python38-toml-0.10.2-2.5.noarch python38-typing_extensions-3.10.0.2-1.1.noarch python38-wcwidth-0.2.5-3.2.noarch python38-aiodns-3.0.0-1.2.noarch python38-flake8-4.0.1-2.1.noarch patterns-devel-python-devel_python3-20180125-4.5.x86_64 python38-pbr-5.8.0-1.1.noarch python38-future-0.18.2-3.4.noarch python38-ldap3-2.9.1-1.2.noarch python38-ldapdomaindump-0.9.3-1.7.noarch python36-ordered-set-4.0.2-1.2.noarch python36-appdirs-1.4.4-3.2.noarch python36-setuptools-57.4.0-1.2.noarch python36-pip-20.2.4-2.1.noarch python36-zope.interface-5.4.0-2.1.x86_64 python36-zhon-1.1.5-3.5.noarch python36-typing_extensions-3.10.0.2-1.1.noarch python36-six-1.16.0-2.2.noarch python36-charset-normalizer-2.0.9-1.1.noarch python36-roman-3.3-1.6.noarch python36-pytz-2021.3-1.1.noarch python36-pyserial-3.5-1.6.noarch python36-pycurl-7.43.0.6-3.2.x86_64 python36-pyasn1-0.4.8-2.2.noarch python36-olefile-0.46-3.2.noarch python36-more-itertools-8.10.0-1.1.noarch python36-iniconfig-1.1.1-1.5.noarch python36-immutables-0.15-2.2.x86_64 python36-imagesize-1.2.0-1.7.noarch python36-idna-3.3-1.1.noarch python36-hyperframe-6.0.1-1.2.noarch python36-hpack-4.0.0-1.6.noarch python36-greenlet-1.1.2-1.1.x86_64 python39-cryptography-36.0.0-1.1.x86_64 python36-constantly-15.1.0-2.16.noarch python36-colorama-0.4.4-1.5.noarch python36-certifi-2021.5.30-1.2.noarch python36-cached-property-1.5.2-1.5.noarch python36-attrs-21.2.0-1.2.noarch python36-apipkg-2.1.0-1.1.noarch python36-alabaster-0.7.12-1.10.noarch python36-Whoosh-2.7.4-5.6.noarch python36-Pygments-2.9.0-2.1.noarch python36-PySocks-1.7.1-1.9.noarch python36-PyHamcrest-2.0.2-1.10.noarch python36-PrettyTable-2.4.0-1.1.noarch python36-MarkupSafe-2.0.1-1.2.x86_64 python36-hanzidentifier-1.0.2-2.2.noarch python36-Babel-2.9.1-3.1.noarch python36-cffi-1.15.0-1.1.x86_64 python36-pyasn1-modules-0.2.8-1.9.noarch python36-Pillow-8.4.0-1.1.x86_64 python36-zipp-3.6.0-1.1.noarch python36-contextvars-2.4-2.2.noarch python36-hyperlink-21.0.0-1.5.noarch python36-h2-4.0.0-2.4.noarch python36-tornado5-5.1.1-6.1.x86_64 python36-py-1.10.0-1.5.noarch python36-Jinja2-3.0.3-1.1.x86_64 python36-pycares-4.0.0-1.2.x86_64 python39-docker-5.0.3-1.1.noarch python36-brotlipy-0.7.0-5.9.x86_64 python36-bcrypt-3.2.0-3.10.x86_64 python36-docutils-0.16-3.7.noarch python36-aiocontextvars-0.2.2-2.3.x86_64 python36-Sphinx-4.3.1-1.1.noarch python36-urllib3-1.26.7-1.1.noarch python36-service_identity-18.1.0-3.8.noarch python36-incremental-21.3.0-1.2.noarch python36-requests-2.26.0-1.1.noarch python36-sphinxcontrib-websupport-1.2.4-1.5.noarch python36-sphinxcontrib-serializinghtml-1.1.5-1.2.noarch python36-sphinxcontrib-qthelp-1.0.3-1.6.noarch python36-sphinxcontrib-htmlhelp-2.0.0-1.2.noarch python36-sphinxcontrib-jsmath-1.0.1-2.7.noarch python36-sphinxcontrib-devhelp-1.0.2-1.6.noarch python36-sphinxcontrib-applehelp-1.0.2-1.6.noarch python36-sphinx_rtd_theme-1.0.0-1.1.noarch python3-bind-9.16.23-1.1.noarch python38-websockets-10.0-3.1.x86_64 python39-gobject-cairo-3.42.0-1.3.x86_64 python38-PyNaCl-1.4.0-2.1.x86_64 python38-bcrypt-3.2.0-3.10.x86_64 python38-chardet-4.0.0-2.1.noarch python38-cssselect-1.1.0-1.8.noarch python38-docker-pycreds-0.4.0-1.11.noarch python38-fluidity-sm-0.2.0-1.12.noarch python38-jeepney-0.7.1-1.2.noarch python38-ptyprocess-0.7.0-1.6.noarch python38-pygit2-1.7.0-1.2.x86_64 python38-python-xlib-0.29-2.2.noarch python38-suntime-1.2.5-1.8.noarch python3-ipa_hbac-2.6.1-1.1.x86_64 python38-tzlocal-2.1-2.2.noarch python38-websocket-client-0.58.0-2.1.noarch python38-xkbgroup-0.2.0-3.2.noarch python38-pexpect-4.8.0-3.2.noarch python38-feedparser-6.0.8-1.2.noarch python38-keyring-23.2.1-1.1.noarch python38-invoke-1.6.0-1.2.noarch yast2-adcommon-python-1.6-1.4.noarch python38-paramiko-2.8.0-1.1.noarch python38-hexdump-3.3-2.8.noarch nbdkit-python-plugin-1.29.4-1.1.x86_64 python38-evtx-0.7.4-3.1.noarch python38-gobject-3.42.0-1.3.x86_64 python38-dbm-3.8.12-3.1.x86_64 python36-SQLAlchemy-1.4.27-1.1.x86_64 python38-Twisted-21.7.0-4.1.x86_64 python39-gobject-3.42.0-1.3.x86_64 python38-pycparser-2.21-1.1.noarch python38-pysmbc-1.0.23-2.1.x86_64 python3-vapoursynth-54-1.3.x86_64 python38-virtualenv-20.10.0-1.1.noarch python38-numpy-1.21.4-2.1.x86_64 libpython3_6m1_0-3.6.15-7.1.x86_64 python36-wcwidth-0.2.5-3.2.noarch python36-pycparser-2.21-1.1.noarch libpython3_9-1_0-3.9.9-2.1.x86_64 python-rpm-macros-20211022.38e7c70-1.1.noarch python-rpm-generators-20211022.38e7c70-1.1.noarch rpm-build-python-4.17.0-2.1.x86_64 libpython2_7-1_0-2.7.18-205.2.x86_64 python-base-2.7.18-205.2.x86_64 python-devel-2.7.18-205.2.x86_64 patterns-openSUSE-devel_python-20170206-664.1.x86_64 python38-requests-toolbelt-0.9.1-5.1.noarch python39-pyOpenSSL-21.0.0-2.1.noarch python3-sssd-config-2.6.1-1.1.x86_64 python38-prettytable-2.4.0-1.1.noarch python36-pyparsing-3.0.6-1.1.noarch python36-Automat-20.2.0-2.1.noarch python36-gobject-3.42.0-1.3.x86_64 python38-pytest-6.2.5-1.1.noarch python38-tox-3.24.4-1.1.noarch python38-aiohttp-3.7.4-5.1.x86_64 python38-black-20.8b1-2.8.noarch python-gobject2-2.28.7-3.10.x86_64 python2-pycairo-1.18.1-5.11.x86_64 python-gtk-2.24.0-21.5.x86_64 python39-pyparsing-3.0.6-1.1.noarch python-xml-2.7.18-205.2.x86_64 python38-gobject-Gdk-3.42.0-1.3.x86_64 python38-pyparsing-3.0.6-1.1.noarch python39-curses-3.9.9-2.1.x86_64 python39-ordered-set-4.0.2-1.2.noarch python39-appdirs-1.4.4-3.2.noarch python39-packaging-21.3-1.1.noarch python39-setuptools-57.4.0-1.2.noarch python39-pip-20.2.4-2.1.noarch python38-tornado6-6.1-4.1.x86_64 python39-zhon-1.1.5-3.5.noarch python39-wcwidth-0.2.5-3.2.noarch python39-six-1.16.0-2.2.noarch python39-pyrsistent-0.18.0-1.1.x86_64 python39-pyasn1-0.4.8-2.2.noarch python39-ptyprocess-0.7.0-1.6.noarch python39-more-itertools-8.10.0-1.1.noarch python39-iniconfig-1.1.1-1.5.noarch python39-idna-3.3-1.1.noarch python39-fluidity-sm-0.2.0-1.12.noarch python39-docopt-0.6.2-7.12.noarch python39-distro-1.6.0-3.1.noarch python39-decorator-5.1.0-1.1.noarch python39-colorama-0.4.4-1.5.noarch python39-click-8.0.3-1.1.noarch python39-chardet-4.0.0-2.1.noarch python39-certifi-2021.5.30-1.2.noarch python39-cached-property-1.5.2-1.5.noarch python39-attrs-21.2.0-1.2.noarch python39-apipkg-2.1.0-1.1.noarch python39-PyYAML-6.0-1.1.x86_64 python39-PySocks-1.7.1-1.9.noarch python39-hanzidentifier-1.0.2-2.2.noarch python39-texttable-1.6.3-1.5.noarch python39-prettytable-2.4.0-1.1.noarch python39-websocket-client-0.58.0-2.1.noarch python39-docker-pycreds-0.4.0-1.11.noarch python39-cffi-1.15.0-1.1.x86_64 python39-pexpect-4.8.0-3.2.noarch python39-zipp-3.6.0-1.1.noarch python39-gssapi-1.6.12-1.6.x86_64 python36-packaging-21.3-1.1.noarch python39-python-dotenv-0.15.0-1.6.noarch python39-py-1.10.0-1.5.noarch python36-gobject-cairo-3.42.0-1.3.x86_64 python39-brotlipy-0.7.0-5.9.x86_64 python39-bcrypt-3.2.0-3.10.x86_64 python39-PyNaCl-1.4.0-2.1.x86_64 python39-invoke-1.6.0-1.2.noarch python39-paramiko-2.8.0-1.1.noarch python39-jsonschema-3.2.0-5.1.noarch python39-urllib3-1.26.7-1.1.noarch python39-requests-2.26.0-1.1.noarch python39-dockerpty-0.4.1-4.11.noarch python39-docker-compose-1.28.5-1.5.noarch python38-protobuf-3.17.3-2.4.x86_64 python38-PyHamcrest-2.0.2-1.10.noarch python38-constantly-15.1.0-2.16.noarch python38-greenlet-1.1.2-1.1.x86_64 python38-hpack-4.0.0-1.6.noarch python38-hyperframe-6.0.1-1.2.noarch python38-hyperlink-21.0.0-1.5.noarch python38-pyserial-3.5-1.6.noarch python38-pyxdg-0.27-2.2.noarch python38-qt5-sip-12.9.0-2.2.x86_64 python38-service_identity-18.1.0-3.8.noarch python38-zope.event-4.5.0-2.1.noarch python38-zope.interface-5.4.0-2.1.x86_64 python38-h2-4.0.0-2.4.noarch python38-gevent-21.1.2-3.2.x86_64 python38-qt5-5.15.6-2.2.x86_64 python3-openshot-0.2.7-1.2.x86_64 python38-incremental-21.3.0-1.2.noarch python38-qtwebengine-qt5-5.15.5-1.2.x86_64 python38-pyzmq-22.2.1-1.7.x86_64 python38-ldap-3.4.0-1.1.x86_64 python38-opengl-3.1.5-2.4.noarch python38-base-3.8.12-3.1.x86_64 python36-Twisted-21.7.0-4.1.x86_6

# Integer Definitions
declare -i INSTALL_PATTERN_ARRAY_LENGTH=${#INSTALL_PATTERN_ARRAY[@]}
declare -i INSTALL_PACKAGE_ARRAY_LENGTH=${#INSTALL_PACKAGE_ARRAY[@]}
declare -i INSTALL_REPO_ARRAY_LENGTH=${#INSTALL_REPO_ARRAY[@]}
declare -i INDEX=-1;

while [ $INDEX -lt $((INSTALL_REPO_ARRAY_LENGTH-1)) ]; do
  ((INDEX++))
  INSTRUCTION_ARRAY[$((INDEX))]="$AR"
  if [ $BOL_REPO_INSTALL     -eq $TRUE ]; then ENABLE_INSTRUCTION[$((INDEX))]=$TRUE; else ENABLE_INSTRUCTION[$((INDEX))]=$FALSE; fi
done

# Set Enable/Disable of Pattern Installations
while [ $INDEX -lt $((INSTALL_REPO_ARRAY_LENGTH+INSTALL_PATTERN_ARRAY_LENGTH-1)) ]; do
  ((INDEX++))
  INSTRUCTION_ARRAY[$((INDEX))]="$PT"
  if [ $BOL_PATTERN_INSTALL 	-eq $TRUE ]; then ENABLE_INSTRUCTION[$((INDEX))]=$TRUE; else ENABLE_INSTRUCTION[$((INDEX))]=$FALSE; fi
done

# Set Enable/Disable of Package Installations
while [ $INDEX -lt $((INSTALL_REPO_ARRAY_LENGTH+INSTALL_PATTERN_ARRAY_LENGTH+INSTALL_PACKAGE_ARRAY_LENGTH-2)) ]; do
  ((INDEX++))
  INSTRUCTION_ARRAY[$((INDEX))]="$IN"
  if [ $BOL_PACKAGE_INSTALL	-eq $TRUE ]; then ENABLE_INSTRUCTION[$((INDEX))]=$TRUE; else ENABLE_INSTRUCTION[$((INDEX))]=$FALSE; fi
done

# Assembal INSTALL_LIST from INSTALL_PATTERN_ARRAY and from INSTALL_PACKAGE_ARRAY
INDEX=-1
while IFS= read PACKAGE; do
  ((INDEX++))
  INSTALL_LIST[$((INDEX))]="$PACKAGE"
done < <(echo -e "${INSTALL_REPO_ARRAY[@]} ${INSTALL_PATTERN_ARRAY[@]} ${INSTALL_PACKAGE_ARRAY[@]}")
unset INDEX

function SETUP()
{
  declare -i INDEX=-1
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i RETVAL=$SUCCESS;

  for ENABLE in ${ENABLE_INSTRUCTION[@]}; do
    ((INDEX++))
    case $ENABLE in
      $TRUE)
	export COMMAND="($INDEX) $SETUP_BIN ${INSTRUCTION_ARRAY[$((INDEX))]} ${ADDITIONAL[@]} ${INSTALL_LIST[$((INDEX))]}"
        $SETUP_BIN ${INSTRUCTION_ARRAY[$((INDEX))]} ${ADDITIONAL[@]} ${INSTALL_LIST[$((INDEX))]}
	RETVAL=$?
	SHOW_DATE_TIME; LOG_RESULTS
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
	;;
    esac
  done
  unset COMMAND
  unset RETVAL
  return $FUNCTION_RETURN
};

if [ $BOL_OPENSUSE -eq $TRUE ]; then
  SETUP
  export RETVAL=$?
fi

LOG_RESULTS
exit $RETVAL
