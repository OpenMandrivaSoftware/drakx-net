NAME = drakx-net
VERSION = 2.2

DESTDIR=
libdir=/usr/lib
bindir=/usr/bin
sbindir=/usr/sbin
libexecdir=/usr/libexec
desktopdir=/usr/share/applications
autostartdir=/etc/xdg/autostart
iconsdir=/usr/lib/libDrakX/icons
pixmapsdir=/usr/share/libDrakX/pixmaps

USER_TOOLS=net_applet
ROOT_TOOLS=drakconnect drakfirewall drakgw drakhosts drakids drakinvictus draknetprofile draknfs drakproxy drakroam draksambashare drakvpn draknetcenter

all:
	(find lib -name '*.pm'; find bin -type f) | xargs perl -pi -e 's/\s*use\s+(diagnostics|vars|strict).*//g'
	make -C po
	make -C polkit
	make -C data

check:
	@for p in `find lib -name *.pm`; do perl -cw -I$(libdir)/libDrakX $$p || exit 1; done
	@for p in bin/*; do perl -cw $$p || exit 1; done

install:
	install -d $(DESTDIR){$(libdir),$(bindir),$(libexecdir),$(desktopdir),$(autostartdir),$(iconsdir),$(pixmapsdir)}
	cp -a lib/* $(DESTDIR)$(libdir)/libDrakX/
	find $(DESTDIR) -name .perl_checker -exec rm {} \;
	(cd bin && \
	  install -m755 $(USER_TOOLS) $(DESTDIR)$(bindir) && \
	  install -m755 $(ROOT_TOOLS) $(DESTDIR)$(libexecdir) \
	)
	install -m644 $(wildcard data/*.desktop) $(DESTDIR)$(desktopdir)
	install -m644 $(wildcard data/icons/*.png) $(DESTDIR)$(iconsdir)
	install -m644 $(wildcard data/pixmaps/*.png) $(DESTDIR)$(pixmapsdir)
	perl -pe 's/\s+--force//g' $(DESTDIR)$(desktopdir)/net_applet.desktop > $(DESTDIR)$(autostartdir)/net_applet.desktop
	make -C po install
	make -C polkit install

cleandist:
	rm -rf $(NAME)-$(VERSION) ../$(NAME)-$(VERSION).tar*

dist: cleandist
	rm -rf $(NAME)-$(VERSION).tar*
	git archive --prefix $(NAME)-$(VERSION)/ HEAD | xz -9 > $(NAME)-$(VERSION).tar.xz
	$(info $(NAME)-$(VERSION).tar.xz is ready)


clean:
	make -C po clean
	make -C polkit clean

