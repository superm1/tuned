NAME = tuned
VERSION = $(shell awk '/^Version:/ {print $$2}' tuned.spec)
RELEASE = $(shell awk '/^Release:/ {print $$2}' tuned.spec)
VERSIONED_NAME = $(NAME)-$(VERSION)

DESTDIR = /
PYTHON_SITELIB = /usr/lib/python2.7/site-packages
TUNED_PROFILESDIR = /usr/lib/tuned

archive: clean
	mkdir -p $(VERSIONED_NAME)

	cp AUTHORS COPYING INSTALL README $(VERSIONED_NAME)

	cp tuned.py tuned.spec tuned.service tuned.tmpfiles Makefile $(VERSIONED_NAME)
	cp -a doc experiments man profiles systemtap tuned $(VERSIONED_NAME)

	tar cjf $(VERSIONED_NAME).tar.bz2 $(VERSIONED_NAME)

srpm: archive
	mkdir rpm-build-dir
	rpmbuild --define "_sourcedir `pwd`/rpm-build-dir" --define "_srcrpmdir `pwd`/rpm-build-dir" \
		--define "_specdir `pwd`/rpm-build-dir" --nodeps -ts $(VERSIONED_NAME).tar.bz2

build:
	# nothing to build

install:
	mkdir -p $(DESTDIR)

	# library
	mkdir -p $(DESTDIR)$(PYTHON_SITELIB)
	cp -a tuned $(DESTDIR)$(PYTHON_SITELIB)/tuned

	# binaries
	mkdir -p $(DESTDIR)/usr/sbin
	install -m 0755 tuned.py $(DESTDIR)/usr/sbin/tuned
	for file in systemtap/*; do \
		install -m 0755 $$file $(DESTDIR)/usr/sbin/; \
	done

	# configuration files
	mkdir -p $(DESTDIR)/etc/tuned
	echo -n default > $(DESTDIR)/etc/tuned/active_profile

	# profiles
	mkdir -p $(DESTDIR)$(TUNED_PROFILESDIR)
	cp -a profiles/* $(DESTDIR)$(TUNED_PROFILESDIR)/

	# log dir
	mkdir -p $(DESTDIR)/var/log/tuned

	# runtime directory
	mkdir -p $(DESTDIR)/var/run/tuned
	mkdir -p $(DESTDIR)/etc/tmpfiles.d
	install -m 0644 tuned.tmpfiles $(DESTDIR)/etc/tmpfiles.d/tuned.conf

	# systemd units
	mkdir -p $(DESTDIR)/lib/systemd/system
	install -m 0644 tuned.service $(DESTDIR)/lib/systemd/system

	# manual pages
	mkdir -p $(DESTDIR)/usr/share/man/man8
	for file in man/*.8; do \
		install -m 0644 $$file $(DESTDIR)/usr/share/man/man8; \
	done

	# documentation
	mkdir -p $(DESTDIR)/usr/share/doc/$(VERSIONED_NAME)
	cp -a doc/* $(DESTDIR)/usr/share/doc/$(VERSIONED_NAME)
	cp AUTHORS COPYING README $(DESTDIR)/usr/share/doc/$(VERSIONED_NAME)

clean:
	find -name "*.pyc" | xargs rm -f
	rm -rf $(VERSIONED_NAME) rpm-build-dir

.PHONY: clean archive srpm tag

