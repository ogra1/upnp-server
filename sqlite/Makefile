SQLITEVER=3130000
ARCH=x86_64-linux-gnu

all: build

build:
	wget https://www.sqlite.org/2016/sqlite-autoconf-3130000.tar.gz
	tar xf sqlite-autoconf-$(SQLITEVER).tar.gz
	(cd sqlite-autoconf-$(SQLITEVER); ./configure; patch -p1 <../sqlite.patch; make)

install:
	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/lib/$(ARCH)
	install -m755 sqlite-autoconf-$(SQLITEVER)/sqlite3 $(DESTDIR)/usr/bin/sqlite3
	cp -d sqlite-autoconf-$(SQLITEVER)/.libs/libsqlite3.so* $(DESTDIR)/usr/lib/$(ARCH)/
