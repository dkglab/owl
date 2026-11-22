SHELL := /usr/bin/env bash

# eye, riot, arq and shacl are on the PATH in the devcontainer image
# (ghcr.io/dkglab/shacl-and-owl-dev, built from dkglab/shacl-and-owl).
# rules/ is the SHACL and OWL assignment's set of rules.
RULES := $(sort $(wildcard rules/*.n3))
ARQ := arq --data

.PHONY: all clean \
  birthplace-is-denmark has-a-dane-ancestor danes lagottos \
  same-as inverse-functional sameness-shapes \
  two-parents all-different sexes counting-shapes danish-lagottos

all: all.ttl

clean:
	rm -rf inferred.ttl all.ttl build

# Dogs and the ontology ------------------------------------------------------

# What the ontology and the rules add to dogs.ttl.
inferred.ttl: $(RULES) ontology.ttl dogs.ttl
	eye --quiet --nope $^ --pass-only-new \
	| riot --syntax=ttl --formatted=ttl - > $@

# dogs.ttl and the ontology plus everything inferred.
all.ttl: ontology.ttl dogs.ttl inferred.ttl
	riot --quiet --formatted=ttl $^ > $@

birthplace-is-denmark: all.ttl
	@$(ARQ) $< --query queries/birthplace-is-denmark.rq

has-a-dane-ancestor: all.ttl
	@$(ARQ) $< --query queries/has-a-dane-ancestor.rq

danes: all.ttl
	@$(ARQ) $< --query queries/danes.rq

lagottos: all.ttl
	@$(ARQ) $< --query queries/lagottos.rq

# Sameness (19 Nov) ----------------------------------------------------------
#
# A second source, sameness/registry.ttl, names two of our dogs its own way.
# Each target reasons over the dogs, the ontology and the registry plus one
# more file, then asks who Demetrio's mother is (and her microchip), and
# which names name the same thing.

# With an owl:sameAs we asserted.
same-as:
	@if ./reason.sh build/same-as.ttl ontology.ttl dogs.ttl \
	  sameness/registry.ttl sameness/same-as.ttl; then \
	  $(ARQ) build/same-as.ttl --query queries/demetrios-mother.rq; \
	  $(ARQ) build/same-as.ttl --query queries/same-as.rq; fi

# With no owl:sameAs, but microchips and an inverse functional property.
inverse-functional:
	@if ./reason.sh build/inverse-functional.ttl ontology.ttl dogs.ttl \
	  sameness/registry.ttl sameness/chips.ttl; then \
	  $(ARQ) build/inverse-functional.ttl --query queries/demetrios-mother.rq; \
	  $(ARQ) build/inverse-functional.ttl --query queries/same-as.rq; fi

# The same expectations as shapes, with no inference: each source on its
# own, then the two together.
sameness-shapes:
	@mkdir -p build
	@echo "== sameness/registry.ttl"
	@shacl validate --shapes sameness/shapes.ttl --data sameness/registry.ttl --text
	@echo "== dogs.ttl and sameness/chips.ttl"
	@riot --quiet --output=nt dogs.ttl sameness/chips.ttl > build/ours.nt
	@shacl validate --shapes sameness/shapes.ttl --data build/ours.nt --text
	@echo "== both sources together"
	@riot --quiet --output=nt dogs.ttl sameness/chips.ttl sameness/registry.ttl > build/both.nt
	@shacl validate --shapes sameness/shapes.ttl --data build/both.nt --text

# Counting (24 Nov) ----------------------------------------------------------
#
# Each target reasons over the dogs and the ontology plus the counting files
# named, then lists the Lagotto Romagnolos again.

# Dogs have exactly two parents.
two-parents:
	@if ./reason.sh build/two-parents.ttl ontology.ttl dogs.ttl \
	  counting/two-parents.ttl; then \
	  $(ARQ) build/two-parents.ttl --query queries/lagottos.rq; fi

# ... and the fourteen dogs are all different.
all-different:
	@if ./reason.sh build/all-different.ttl ontology.ttl dogs.ttl \
	  counting/two-parents.ttl counting/all-different.ttl; then \
	  $(ARQ) build/all-different.ttl --query queries/lagottos.rq; fi

# ... or, instead, mothers are female, fathers are male, and nothing is both.
sexes:
	@if ./reason.sh build/sexes.ttl ontology.ttl dogs.ttl \
	  counting/two-parents.ttl counting/sexes.ttl; then \
	  $(ARQ) build/sexes.ttl --query queries/lagottos.rq; fi

# The same expectations as shapes, with no inference.
counting-shapes:
	@shacl validate --shapes counting/shapes.ttl --data dogs.ttl --text

# Lagotto Romagnolos who are Danes: an intersection, without counting and
# then with it.
danish-lagottos:
	@echo "== without counting"
	@if ./reason.sh build/sets.ttl ontology.ttl dogs.ttl counting/sets.ttl; then \
	  $(ARQ) build/sets.ttl --query queries/danish-lagottos.rq; fi
	@echo "== with two-parents.ttl and all-different.ttl"
	@if ./reason.sh build/sets-counting.ttl ontology.ttl dogs.ttl counting/sets.ttl \
	  counting/two-parents.ttl counting/all-different.ttl; then \
	  $(ARQ) build/sets-counting.ttl --query queries/danish-lagottos.rq; fi
