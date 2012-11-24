:- dynamic endpoint/2, link/2.

:- discontiguous is/3,ispre/3,value/2,tags/2.


%%	write_graphml
%
%	Writes a file called spider.graphml  that
%	can be opened with yED or similar editor (my system
%	doesn't have enough memory to do much with the swipl site
%	once opened so this is ill tested
%
write_graphml :-
	open('spider.graphml', write, Stream, []),
	write(Stream,
'<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
     http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
  <graph id="G" edgedefault="directed">'),
	spidered_links(L),
	format('making links~n', []),
	nodes_from_links(L, [], X),
	format('writing~n', []),
	write_nodes(Stream, X),
	format('wrote nodes~n', []),
	write_edges(Stream, L),
	write(Stream,
'  </graph>
</graphml>'),
	close(Stream).

nodes_from_links([], X, Clean) :-
	sort(X, Clean).

nodes_from_links([From-To|T], SoFar, X) :-
	nodes_from_links(T, [From, To| SoFar], X).



write_nodes(_, []).
write_nodes(Stream, [Uri|T]) :-
	www_form_encode(Uri, Enc),
	format(Stream, '<node id="~w" />~n', [Enc]),
	write_nodes(Stream, T).
write_edges(_, []).
write_edges(Stream, [From-To|T]) :-
	www_form_encode(From, FE),
	www_form_encode(To, TE),
	format(Stream, '<edge source="~w" target="~w" />~n', [FE, TE]),
	write_edges(Stream, T).
write_edges(Stream, [X|T]) :-
	format('evil ~w~n', [X]),
	write_edges(Stream, T).

%%	assert_from_list
%
%	Causes the spidered uris and links to be asserted as facts.
%
assert_from_list :-
	retractall(endpoint(_,_)),
	retractall(link(_,_)),
	spidered_uris(X),
	assert_all(X),
	spidered_links(L),
	assert_links(L).

assert_links([]).
assert_links([From-To | T]) :-
	assertz(link(From,To)),
	assert_links(T).

assert_all([]).
assert_all([Type-Uri|T]) :-
	assertz(endpoint(Type, Uri)),
	assert_all(T).


local_endpoint(Uri) :-
	endpoint(internal, Uri),
	\+ atom_concat('/', _, Uri).

%%	unknown_endpoint(-Type:uri_type, -Uri:atom) is nondet
%
%	endpoint for which there is no corresponding 'is' clause
%
unknown_endpoint(Type, Uri) :-
	endpoint(Type, Uri),
	\+ is(Type, Uri, _).


is(Type, ContextUri, Msg) :-
	atom_concat('http://127.0.0.1:3040', Rest, ContextUri),
	is(Type, Rest, Msg).

is(misformed, 'http:www.swi-prolog.org', 'Some mistake in site').
is(misformed, X, 'email link') :-
	atom_concat('mailto:', _, X).
is(asset, X, 'publication') :-
	atom_concat(_, '.pdf', X),!.
is(asset, X, 'publication') :-
	atom_concat(_, '.bib', X),!.
is(asset, _, 'true asset').
is(not_http, _, 'mail list link').
is(external, _, 'external link').
is(Type, Uri, Is) :-
	ispre(Type, PreUri, Is),
	atom_concat(PreUri, _, Uri).

ispre(internal, '/wiki_edit?location=', 'wiki edit').
is(internal, '../web', 'Semantic Web').
ispre(internal, '../web', 'Semantic Web').
value('Semantic Web', 1).
ispre(internal, '/web', 'Semantic Web').
tags('Semantic Web', [semweb]).

is(internal, '../pldoc/index.html', 'swipl package index.').
value('swipl package index.', 1).
ispre(internal, 'SamerAbdallah', 'SamerAbdallah - some student?').
is(internal, '/pldoc/doc/home/vnc/prolog/lib/swipl/library/prolog_pack.pl', 'Package Manager').
value('Package Manager', 2).
tags('Package Manager', [pack]).

ispre(internal, '/pldoc/man?predicate=', 'Predicate in manual').
value('Predicate in manual', 1).
tags('Predicate in manual', [pred]).

ispre(internal, '/pldoc/doc/usr/local/lib/', 'Prolog source file').
value('Prolog source file', 1).

ispre(internal, '/pldoc/doc_for?object=', 'Predicate in library').
value('Predicate in library', 1).
tags('Predicate in library', [pred]).

ispre(internal, 'prolog_pack.pl', 'Package manager generated pages internal nav').
tags('Package manager generated pages internal nav', [pack]).

ispre(internal, '/pldoc/doc/swi/library/prolog_pack.pl', 'Package Manager').

ispre(internal, '/pldoc/man?CAPI=', 'C language interface function').
tags('C language interface function', [interface]).

is(internal, '/gxref.html', 'loose manual piece').
tags('/gxref.html', [ide,loose]).
value('loose manual piece', 3).
is(internal, '/profiler.html', 'loose manual piece').
tags('/profiler.html', [ide, loose]).
is(internal, '/gtrace.html', 'loose manual piece').
tags('/gtrace.html', [ide, loose]).
is(internal, '/license.html', 'loose manual piece').
tags('/license.html', [project, loose]).
is(internal, '/Contributors.html', 'loose manual piece').
tags('/Contributors.html', [project, loose]).
is(internal, '/Publications.html', 'loose manual piece').
tags('/Publications.html', [project, academia, loose]).
is(internal, '/Graphics.html', 'loose manual piece').
tags('/Graphics.html', [xpce, loose]).
is(internal, '/IDE.html', 'loose manual piece').
is(internal, '/Contact.html', 'loose manual piece').
is(internal, '/Links.html', 'loose manual piece').
tags('/Links.html', [project, academia, loose]).
is(internal, X, 'loose manual piece') :-
	lmp(X, _).
tags(X, [loose|T]) :-
	lmp(X, T).
lmp('/Support.html', [project]).
lmp('/Mailinglist.html', [project]).
ispre(internal, '/man/clpqr.html', 'clpqr lib').
ispre(internal, '/manclpqr.html', 'clpqr lib').
value('clpqr lib', 3).

%
%  For the moment
ispre(internal, '/man', manual).
value(man, 1).
ispre(internal, '/pldoc', pldoc).
value(pldoc, 1).
ispre(internal, '/FAQ', faq).
value(faq, 1).
% is this truly a top level?
ispre(internal, '/wiki', wiki).
value(wiki, 1).
ispre(internal, '/packages', packages).
value(packages, 1).

is(internal, '/logs/dl-statistics.html', 'Download graph').
value('Download graph', 2).
tags('/logs/dl-statistics.html', [project, loose, stats]).

ispre(internal, '/git', 'Git browser').
value('Git browser', 1).
tags('/git', [project, download, loose, git]).

ispre(internal, '/download/old', 'old downloads').
value('old downloads', 2).
tags('/download/old', [project, loose, download, lost]).

ispre(internal, '/download', 'Download section').
value('Download section', 1).
tags('/download', [project, download, lost]).

ispre(internal, '/howtoPackTodo.txt', 'pack instructions').
value('pack instruction', 3).
tags('/howtoPackTodo.txt', [loose, lost, fixme, download, project]).

ispre(internal, '/howto', 'loose howto page').
value('loose howto page', 1).
tags('/howto', [loose, lost, fixme]).

ispre(internal, '/contrib/SamerAbdallah', 'some contribs by SamerAbdallah').
value('loose contrib page', 1).
tags('/contrib/SamerAbdallah', [contrib, loose, lost, fixme, download, project]).

ispre(internal, '/contrib', 'contrib section').
value('contrib section', 1).
tags('/contrib', [contrib, project, lost, fixme]).

is(internal, '/pack/list', 'list of available packages').
value('list of available packages').
tags('/pack/list', [pack, contrib, project, lost, fixme]).

ispre(internal, '/pack', 'material under pack').
tags('material under pack', [pack, contrib, project, lost, fixme]).

is(internal, '/Triple20.html', '404').

ispre(internal, '/..', 'spare loose page').
ispre(internal, '/Devel/..', 'spare loose page').


ispre(internal, '/build', 'Build instructions').
tags('Build instructions', [download]).


