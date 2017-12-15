###############################################################################
#	(c) Copyright holder 2012-2017 PokeMMO.eu <linux@pokemmo.eu>
#	- The permitted usage of the PokeMMO game client is defined by
#	a non-free license. Visit https://pokemmo.eu/tos
#
#	(c) Copyright 2017 Launcher created by Carlos Donizete Froes
#	This is free software, licensed under the GPL-3 license.
###############################################################################

EXE = pokemmo
SRCDIR = src
PREFIX = $(DESTDIR)/usr
GAMEDIR = $(PREFIX)/games
STARTUP = $(GAMEDIR)/$(EXE)
ICNDIR = $(PREFIX)/share/pixmaps
APPDIR = $(PREFIX)/share/applications

SCRIPT = pokemmo.sh
DATA = pokemmo_bootstrapper.jar
ICON = pokemmo.png
DESKTOP = pokemmo.desktop

CP = cp -r
RM = rm -r
MD = mkdir -p
ECHO = echo
CHMOD = chmod 755 -R

all:
	@$(CP) "$(SRCDIR)/$(SCRIPT)" "$(EXE)"
	@$(CHMOD) "$(EXE)"

clean:
	@$(RM) pokemmo

.PHONY: all clean install uninstall
