#!/bin/sh
green='\033[0;32m'
red='\033[0;31m'
nocolor='\033[0m'
deps="meson ninja patchelf unzip curl pip flex bison zip"
workdir="$(pwd)/panfrostmali.zip"
magiskdir="$workdir/panfrost_mali"
clear



echo "Checking system for required Dependencies ..."
for deps_chk in $deps;
	do 
		sleep 0.25
		if command -v $deps_chk >/dev/null 2>&1 ; then
			echo -e "$green - $deps_chk found $nocolor"
		else
			echo -e "$red - $deps_chk not found, can't countinue. $nocolor"
			deps_missing=1
		fi;
	done
	
	if [ "$deps_missing" == "1" ]
		then echo "Please install missing dependencies" && exit 1
	fi



echo "Installing python Mako dependency (if missing) ..." $'\n'
pip install mako &> /dev/null
apt-get install libdrm-dev


echo "Creating and entering to work directory ..." $'\n'
mkdir -p $workdir && cd $workdir



echo "Downloading android-ndk from google server (~506 MB) ..." $'\n'
curl https://dl.google.com/android/repository/android-ndk-r25b-linux.zip --output android-ndk-r25b-linux.zip &> /dev/null
###
echo "Exracting android-ndk to a folder ..." $'\n'
unzip android-ndk-r25b-linux.zip  &> /dev/null



echo "Downloading mesa source (~30 MB) ..." $'\n'
curl https://gitlab.freedesktop.org/mesa/mesa/-/archive/main/mesa-main.zip --output mesa-main.zip &> /dev/null
###
echo "Exracting mesa source to a folder ..." $'\n'
unzip mesa-main.zip &> /dev/null
cd mesa-main



echo "Creating meson cross file ..." $'\n'
ndk="$workdir/android-ndk-r25b/toolchains/llvm/prebuilt/linux-x86_64/bin"
cat <<EOF >"android-aarch64"
[binaries]
ar = '$ndk/llvm-ar'
c = ['ccache', '$ndk/aarch64-linux-android31-clang']
cpp = ['ccache', '$ndk/aarch64-linux-android31-clang++', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-static-libstdc++']
c_ld = 'lld'
cpp_ld = 'lld'
strip = '$ndk/aarch64-linux-android-strip'
pkgconfig = ['env', 'PKG_CONFIG_LIBDIR=/usr/lib/pkgconfig', '/usr/bin/pkg-config']
[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF



echo "Generating build files ..." $'\n'
meson build-android-aarch64 --cross-file $workdir/mesa-main/android-aarch64 -Dbuildtype=debug -Dplatforms=android -Dplatform-sdk-version=31 -Dandroid-stub=true -Dgallium-drivers= -Dvulkan-drivers=panfrost -Db_lto=true



echo "Compiling build files ..." $'\n'
ninja -C build-android-aarch64



#echo "Using patchelf to match soname ..."  $'\n'
cp $workdir/mesa-main/build-android-aarch64/src/freedreno/vulkan/libvulkan_freedreno.so $workdir
cd $workdir
#patchelf --set-soname vulkan.adreno.so libvulkan_freedreno.so
#mv libvulkan_freedreno.so vulkan.adreno.so



if ! [ -a libvulkan_freedreno.so ]; then
	echo -e "$red Build failed! $nocolor" && exit 1
fi



echo "Prepare magisk module structure ..." $'\n'
p1="system/vendor/lib64/hw"
mkdir -p $magiskdir/$p1
cd $magiskdir



meta="META-INF/com/google/android"
mkdir -p $meta



cat <<EOF >"$meta/update-binary"
#################
# Initialization
#################
umask 022
# echo before loading util_functions
ui_print() { echo "\$1"; }
require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v20.4+! "
  ui_print "*******************************"
  exit 1
}
#########################
# Load util_functions.sh
#########################
OUTFD=\$2
ZIPFILE=\$3
[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ \$MAGISK_VER_CODE -lt 20400 ] && require_new_magisk
install_module
exit 0
EOF



cat <<EOF >"$meta/updater-script"
#MAGISK
EOF



cat <<EOF >"module.prop"
id=panfrost
name=Mesa Panfrost Debug
version=v23.0.0
versionCode=1
author=Rofik/XiaomiPocoMod
description=Panfrost is an open-source vulkan driver for devices with MALI GPUs.
EOF



cat <<EOF >"customize.sh"
set_perm \$MODPATH/$p1/libvulkan_freedreno.so 0 0 0644
EOF



echo "Copy necessary files from work directory ..." $'\n'
cp $workdir/libvulkan_freedreno.so $magiskdir/$p1



echo "Packing files in to magisk module ..." $'\n'
zip -r $workdir/panfrostmali.zip * &> /dev/null
if ! [ -a $workdir/panfrostmali.zip ];
	then echo -e "$red-Packing failed!$nocolor" && exit 1
	else echo -e "$green-All done, you can take your module from here;$nocolor" && echo $workdir/panfrostmali.zip
fi
