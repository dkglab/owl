# OWL

Demos for OWL II and OWL III (INLS 620, 19 and 24 Nov). Open a codespace on
this repository: the devcontainer has EYE, Jena and the rules, so there is
nothing to install.

[`dogs.ttl`](dogs.ttl) is our dogs dataset. It doesn't use OWL at all, and
leaves the meanings of its properties and classes unspecified.

[`ontology.ttl`](ontology.ttl) is an OWL ontology that gives some of those
properties and classes a meaning. It also defines new classes, so that we
can infer which dogs are Danes and which are Lagotto Romagnolos.

[`rules/`](rules) holds the rules that do OWL and RDFS reasoning, written in
N3 for the EYE reasoner. They are the same rules as the SHACL and OWL
assignment's. A rule that ends in `=> false` finds a contradiction.

## Restrictions

Run `make` to write:

* `inferred.ttl`, the new triples inferred from the dataset, the ontology
  and the rules, and
* `all.ttl`, all of those together.

Then list the members of a class:

| Command | Lists |
|---|---|
| `make birthplace-is-denmark` | `ex:BirthplaceIsDenmark`, an `owl:hasValue` restriction |
| `make has-a-dane-ancestor` | `ex:HasADaneAncestor`, an `owl:someValuesFrom` restriction |
| `make danes` | `ex:Dane` |
| `make lagottos` | `ex:LagottoRomagnolo`, defined with `owl:hasValue` and `owl:allValuesFrom` |

## Sameness

[`sameness/registry.ttl`](sameness/registry.ttl) is a second source, an
imaginary breed registry that describes two of our dogs with names of its
own. Each target reasons over the dogs, the ontology and the registry, and
one more file. Then it asks who Demetrio's mother is and what her microchip
number is (the registry knows that), and which names name the same thing.

| Command | Adds |
|---|---|
| `make same-as` | [`sameness/same-as.ttl`](sameness/same-as.ttl), an `owl:sameAs` we assert |
| `make inverse-functional` | [`sameness/chips.ttl`](sameness/chips.ttl), our microchip records. `ex:microchip` is an `owl:InverseFunctionalProperty` |
| `make sameness-shapes` | Nothing is inferred: [`sameness/shapes.ttl`](sameness/shapes.ttl) validates each source, then both |

`ex:birthplace` is an `owl:FunctionalProperty`, so watch what happens to the
countries as well as the dogs.

If the rules conclude `false`, `reason.sh` prints the triples that can't all
be true, and nothing else.

## Counting (24 Nov)

Why isn't Demetrio a Lagotto Romagnolo? Each target reasons over the dogs
and the ontology plus files from [`counting/`](counting), then lists the
Lagotto Romagnolos again.

| Command | Adds |
|---|---|
| `make two-parents` | [`counting/two-parents.ttl`](counting/two-parents.ttl): every dog has exactly two parents (`owl:cardinality 2`) |
| `make all-different` | that, and [`counting/all-different.ttl`](counting/all-different.ttl): the fourteen dogs are all different (`owl:AllDifferent`) |
| `make sexes` | `two-parents.ttl`, and [`counting/sexes.ttl`](counting/sexes.ttl) instead of `AllDifferent`: mothers are female, fathers are male, and nothing is both (`owl:disjointWith`) |
| `make danish-lagottos` | [`counting/sets.ttl`](counting/sets.ttl), an `owl:intersectionOf`, without counting and then with it |
| `make counting-shapes` | Nothing is inferred: [`counting/shapes.ttl`](counting/shapes.ttl) validates `dogs.ttl` against the same expectations |

## Trying things

Edit any `.ttl` file and run the target again. `git checkout <file>` puts a
file back the way it was.
