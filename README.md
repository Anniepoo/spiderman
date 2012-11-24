spiderman
=========

Site spider in swi-Prolog

At the moment this is fairly basic. It looks
for the string href=" or href=' to find the hrefs.

Usage:

(obsolete, see the source to load.pl)

swipl -s load.pl

spider('http://www.somesite.com/', Uris)

    2 ?- spider('http://www.pathwayslms.com/', Uris).
    internal http://www.pathwayslms.com/
    asset style.css
    asset pathwayslmsmanual.pdf
    asset pathwayspromo.mp4
    external http://slurl.com/secondlife/Belphegor/116/48/71
    not http mailto:annie66us@yahoo.com
    Uris = ['mailto:annie66us@yahoo.com', 'pathwayspromo.mp4', 'pathwayslmsmanual.pdf', 'style.css', 'http://www.pathwayslms.com/'] .

Note that at the moment this has some hard links to the swi-prolog website in the analysis section.
