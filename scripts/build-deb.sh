#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 <Nitrux Latinoamericana S.C. <hello@nxos.org>>


# -- Exit on errors.

set -e


# -- Download Source

git clone --depth 1 --branch "$MAUIKIT_TERMINAL_BRANCH" https://invent.kde.org/maui/mauikit-terminal.git

rm -rf mauikit-terminal/{examples,LICENSE,README.md}

if ! grep -Eq 'find_package\(Qt.*REQUIRED COMPONENTS.*Qml' mauikit-terminal/CMakeLists.txt; then
  sed -i '/find_package(Qt.*REQUIRED COMPONENTS/ s/Core/& Qml/' mauikit-terminal/CMakeLists.txt
fi

if grep -qE '^[[:space:]]*qt_policy\(SET QTP0004 NEW\)' mauikit-terminal/CMakeLists.txt; then
  sed -i '/^[[:space:]]*qt_policy(SET QTP0004 NEW)/c\
if(QT_VERSION VERSION_GREATER_EQUAL "6.8.0")\
  qt_policy(SET QTP0004 NEW)\
endif()' mauikit-terminal/CMakeLists.txt
fi


# -- Compile Source

mkdir -p build && cd build

HOST_MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH)

cmake \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DENABLE_BSYMBOLICFUNCTIONS=OFF \
	-DQUICK_COMPILER=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_SYSCONFDIR=/etc \
	-DCMAKE_INSTALL_LOCALSTATEDIR=/var \
	-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_INSTALL_RUNSTATEDIR=/run "-GUnix Makefiles" \
	-DCMAKE_VERBOSE_MAKEFILE=ON \
	-DCMAKE_INSTALL_LIBDIR="/usr/lib/${HOST_MULTIARCH}" \
	../mauikit-terminal/

make -j"$(nproc)"

make install


# -- Run checkinstall and Build Debian Package

>> description-pak printf "%s\n" \
	'A free and modular front-end framework for developing user experiences.' \
	'' \
	'MauiKit Terminal Components.' \
	'' \
	'Maui stands for Multi-Adaptable User Interface and allows ' \
	'any Maui app to run on various platforms + devices,' \
	'like Linux Desktop and Phones, Android, or Windows.' \
	'' \
	'This package contains the MauiKit terminal shared library, the MauiKit terminal qml module' \
	'and the MauiKit terminal development files.' \
	'' \
	''

checkinstall -D -y \
	--install=no \
	--fstrans=yes \
	--pkgname=mauikit-terminal \
	--pkgversion="$PACKAGE_VERSION" \
	--pkgarch="$(dpkg --print-architecture)" \
	--pkgrelease="1" \
	--pkglicense=LGPL-3 \
	--pkggroup=libs \
	--pkgsource=mauikit-terminal \
	--pakdir=. \
	--maintainer=uri_herrera@nxos.org \
	--provides=mauikit-terminal \
	--requires="libc6,libkf6coreaddons6,libkf6i18n6,libkf6iconthemes6,libkf6pty6,libqt6core5compat6,libqt6core6,libqt6gui6,libqt6qml6,libqt6quick6,libqt6quickcontrols2-6,qt6-declarative,mauikit \(\>= 4.0.2\),qml6-module-org-kde-kirigami,qml6-module-qtquick-controls,qml6-module-qtquick-shapes" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes
