all: build

build:
	git clone -b v1_1_6 git://git.code.sf.net/p/minidlna/git minidlna-git
	(cd minidlna-git; ./autogen.sh; ./configure; patch -p1 <../minidlna.patch; make)
	gcc -o getip getip.c

install:
	install -m755 minidlna-git/minidlnad $(DESTDIR)
	install -m755 getip $(DESTDIR)
