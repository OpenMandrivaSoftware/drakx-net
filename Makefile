NAME = drakx-net
VERSION = 0.74.3

DESTDIR=
libdir=/usr/lib
bindir=/usr/bin
sbindir=/usr/sbin
desktopdir=/usr/share/applications
autostartdir=/usr/share/autostart
autostartgnomedir=/usr/share/gnome/autostart
xinitdir=/etc/X11/xinit.d
iconsdir=/usr/lib/libDrakX/icons
pixmapsdir=/usr/share/libDrakX/pixmaps
pamdir=/etc/pam.d
consoleappsdir=/etc/security/console.apps

BIN_TOOLS= net_applet
SBIN_TOOLS=drakconnect drakfirewall drakgw drakhosts drakids drakinvictus draknetprofile draknfs drakproxy drakroam draksambashare drakvpn net_monitor draknetcenter

all:
	(find lib -name '*.pm'; find bin -type f) | xargs perl -pi -e 's/\s*use\s+(diagnostics|vars|strict).*//g'
	make -C po
	make -C data

check:
	@for p in `find lib -name *.pm`; do perl -cw -I$(libdir)/libDrakX $$p || exit 1; done
	@for p in bin/*; do perl -cw $$p || exit 1; done

install:
	install -d $(DESTDIR){$(libdir),$(bindir),$(sbindir),$(desktopdir),$(autostartdir),$(autostartgnomedir),$(xinitdir),$(iconsdir),$(pixmapsdir),$(pamdir),$(consoleappsdir)}
	cp -a lib/* $(DESTDIR)$(libdir)/libDrakX/
	find $(DESTDIR) -name .perl_checker -exec rm {} \;
	(cd bin; \
	  install -m755 $(BIN_TOOLS) $(DESTDIR)$(bindir); \
	  install -m755 $(SBIN_TOOLS) $(DESTDIR)$(sbindir); \
	)
	install -m755 scripts/net_applet.xinit $(DESTDIR)$(xinitdir)/70net_applet
	install -m644 $(wildcard data/*.desktop) $(DESTDIR)$(desktopdir)
	install -m644 $(wildcard data/icons/*.png) $(DESTDIR)$(iconsdir)
	install -m644 $(wildcard data/pixmaps/*.png) $(DESTDIR)$(pixmapsdir)
	perl -pe 's/\s+--force//g' $(DESTDIR)$(desktopdir)/net_applet.desktop > $(DESTDIR)$(autostartdir)/net_applet.desktop
	perl -pe 's/.*X-KDE.*\n//;s/\s+--force//g' $(DESTDIR)$(desktopdir)/net_applet.desktop > $(DESTDIR)$(autostartgnomedir)/net_applet.desktop
	make -C po install

dis:
	rm -rf $(NAME)-$(VERSION) ../$(NAME)-$(VERSION).tar*
	svn export -q -rBASE . $(NAME)-$(VERSION)
	tar cfj ../$(NAME)-$(VERSION).tar.bz2 $(NAME)-$(VERSION)
	rm -rf $(NAME)-$(VERSION)

clean:
	make -C po clean

.PHONY: ChangeLog log changelog

log: ChangeLog

changelog: ChangeLog

ChangeLog:
	svn2cl --accum --authors ../../soft/common/username.xml
	rm -f *.bak
