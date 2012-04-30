NAME = drakx-net
VERSION = 1.10

DESTDIR=
libdir=/usr/lib
bindir=/usr/bin
sbindir=/usr/sbin
desktopdir=/usr/share/applications
autostartdir=/etc/xdg/autostart
iconsdir=/usr/lib/libDrakX/icons
pixmapsdir=/usr/share/libDrakX/pixmaps
pamdir=/etc/pam.d
consoleappsdir=/etc/security/console.apps

BIN_TOOLS= net_applet
SBIN_TOOLS=drakconnect drakfirewall drakgw drakhosts drakids drakinvictus draknetprofile draknfs drakproxy drakroam draksambashare drakvpn draknetcenter

all:
	(find lib -name '*.pm'; find bin -type f) | xargs perl -pi -e 's/\s*use\s+(diagnostics|vars|strict).*//g'
	make -C po
	make -C data

check:
	@for p in `find lib -name *.pm`; do perl -cw -I$(libdir)/libDrakX $$p || exit 1; done
	@for p in bin/*; do perl -cw $$p || exit 1; done

install:
	install -d $(DESTDIR){$(libdir),$(bindir),$(sbindir),$(desktopdir),$(autostartdir),$(iconsdir),$(pixmapsdir),$(pamdir),$(consoleappsdir)}
	cp -a lib/* $(DESTDIR)$(libdir)/libDrakX/
	find $(DESTDIR) -name .perl_checker -exec rm {} \;
	(cd bin; \
	  install -m755 $(BIN_TOOLS) $(DESTDIR)$(bindir); \
	  install -m755 $(SBIN_TOOLS) $(DESTDIR)$(sbindir); \
	)
	install -m644 $(wildcard data/*.desktop) $(DESTDIR)$(desktopdir)
	install -m644 $(wildcard data/icons/*.png) $(DESTDIR)$(iconsdir)
	install -m644 $(wildcard data/pixmaps/*.png) $(DESTDIR)$(pixmapsdir)
	perl -pe 's/\s+--force//g' $(DESTDIR)$(desktopdir)/net_applet.desktop > $(DESTDIR)$(autostartdir)/net_applet.desktop
	make -C po install

cleandist:
	rm -rf $(NAME)-$(VERSION) ../$(NAME)-$(VERSION).tar*

dist: cleandist
	rm -rf ../$(NAME)-$(VERSION).tar*
	@if [ -e ".svn" ]; then \
		$(MAKE) dist-svn; \
	elif [ -e ".git" ]; then \
		$(MAKE) dist-git; \
	else \
		echo "Unknown SCM (not SVN nor GIT)";\
		exit 1; \
	fi;
	$(info $(NAME)-$(VERSION).tar.xz is ready)


dist-svn:
	svn export -q -rBASE . $(NAME)-$(VERSION)
	tar cfa ../$(NAME)-$(VERSION).tar.xz $(NAME)-$(VERSION)
	rm -rf $(NAME)-$(VERSION)

dist-git: cleandist
	git archive --prefix $(NAME)-$(VERSION)/ HEAD | xz -9 > ../$(NAME)-$(VERSION).tar.xz

clean:
	make -C po clean

.PHONY: ChangeLog log changelog

log: ChangeLog

changelog: ChangeLog

ChangeLog:
	svn2cl --accum --authors ../../soft/common/username.xml
	rm -f *.bak
