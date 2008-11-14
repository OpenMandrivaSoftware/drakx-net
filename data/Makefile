DESKTOP_IN := $(wildcard *.desktop.in)
DESKTOP = $(DESKTOP_IN:.desktop.in=.desktop)

all: $(DESKTOP)

clean:
	rm -f $(DESKTOP)

%.desktop:   %.desktop.in
	intltool-merge --utf8 -d ../po $< $@ -c ../po/.intltool-merge-cache
