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
BINDIR = $(PREFIX)/games
GAMEDIR = $(PREFIX)/share/games
ICNDIR = $(PREFIX)/share/pixmaps
APPDIR = $(PREFIX)/share/applications

SCRIPT = pokemmo.sh
DATA = pokemmo_bootstrapper.jar
ICON = pokemmo.png
DESKTOP = pokemmo.desktop

CP = cp -f
RM = rm -f
MD = mkdir -p
ECHO = echo
CHMOD = chmod 755

all:
	@$(CP) "$(SRCDIR)/$(SCRIPT)" "$(EXE)"
	@$(CHMOD) "$(EXE)"
	@$(ECHO) "Created executable script successfully"

clean:
	@$(RM) $(EXE)
	@$(ECHO) "Removed script executable successfully"

install: all
	@$(MD) "$(BINDIR)"
	@$(CP) "$(EXE)" "$(BINDIR)"
	@$(MD) "$(GAMEDIR)/$(EXE)"
	@$(CP) "$(SRCDIR)/$(DATA)" "$(GAMEDIR)/$(EXE)"
	@$(MD) "$(ICNDIR)"
	@$(CP) "$(SRCDIR)/$(ICON)" "$(ICNDIR)"
	@$(MD) "$(APPDIR)"
	@$(CP) "$(SRCDIR)/$(DESKTOP)" "$(APPDIR)"
	@$(ECHO) "Installed the files successfully"

uninstall: clean
	@$(RM) "$(BINDIR)/$(EXE)"
	@$(RM) "$(GAMEDIR)/$(EXE)"
	@$(RM) "$(ICNDIR)/$(ICON)"
	@$(RM) "$(APPDIR)/$(DESKTOP)"
	@$(ECHO) "Successfully removed"

.PHONY: all clean install uninstall
