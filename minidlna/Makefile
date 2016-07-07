all: build

build:
	git clone git://git.code.sf.net/p/minidlna/git minidlna-git
	([ -e /usr/bin/cc ] || ln -s /usr/bin/gcc-5 /usr/bin/cc)
	([ -e /usr/bin/gcc ] || ln -s /usr/bin/gcc-5 /usr/bin/gcc)
	(cd minidlna-git; ./autogen.sh; ./configure; patch -p1 <../minidlna.patch; make)
	gcc -o getip getip.c

install:
	install -m755 minidlna-git/minidlnad $(DESTDIR)
	install -m755 getip $(DESTDIR)
