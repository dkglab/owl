SHELL := /usr/bin/env bash

# eye, riot, arq and shacl are on the PATH in the devcontainer image
# (ghcr.io/dkglab/shacl-and-owl-dev, built from dkglab/shacl-and-owl).
# rules/ is the SHACL and OWL assignment's set of rules.
RULES := $(sort $(wildcard rules/*.n3))
ARQ := arq --data

.PHONY: all clean \
  birthplace-is-denmark has-a-dane-ancestor danes lagottos \
  same-as inverse-functional sameness-shapes lagottos-counting

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

lagottos-counting:
	@if ./reason.sh build/counting.ttl ontology.ttl counting.ttl dogs.ttl; then \
	  $(ARQ) build/counting.ttl --query queries/lagottos.rq; fi
