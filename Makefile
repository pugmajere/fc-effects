build:
	/bin/true

LIB = /usr/lib/fc-effects/
PERLLIB = /usr/share/perl5/

EFFECTS = $(patsubst effects/%.pl,$(DESTDIR)/$(LIB)/%.pl, $(wildcard effects/*.pl))

PERL_LIB_TARGETS = $(patsubst lib/%.pm,$(DESTDIR)/$(PERLLIB)/%.pm, $(wildcard lib/*.pm))

$(DESTDIR)/$(LIB)/%.pl: effects/%.pl
	mkdir -p $(DESTDIR)/$(LIB)
	cp $< $@

$(DESTDIR)/$(PERLLIB)/%.pm: lib/%.pm
	mkdir -p $(DESTDIR)/$(PERLLIB)
	cp $< $@

install: $(EFFECTS) $(SYSTEMD) $(PERL_LIB_TARGETS)
	mkdir -p $(DESTDIR)/lib/systemd/system/
	cp systemd/random-lights.service $(DESTDIR)/lib/systemd/system/
