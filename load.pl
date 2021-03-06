/** <module> Site spidering utility

Usage

swipl -s load.pl
?-spider('http://somesite.com/', Uris).

?- spider_to_file('http://somesite.com/', 'myuris.pl').

myuris.pl will have a list in it with the fact spidered_uris/1
whose arg is the list, and spidered_links/1, a list of From-To links

either way, the list contains entries of form

type-uri
where both are atoms
type is one of

 * asset Something like an image or css file that we don't inspect
 * misformed this url is misformed (currently spiderman has rather
 strict ideas about what's misformed. http:www.google.com is misformed.
 www.google.com is a local link.
 * not_http  we don't follow file: mailto: etc etc
 * external a link (not followed) to an external site
 * internal a link within the site
'
 anchor links are ignored without adding to the list

 querying assert_from_list (from analyze.pl) when swipl_spider exists
 causes the endpoints to be asserted as facts endpoint(_,_).

 At this point you're ready to use the tools in analyze.pl

 @author Anne Ogborn
 @license LGPL

*/

% :-module(load, [spider/2, spider_to_file/2]).

:- use_module(library(uri)).
:- use_module(library(http/http_client)).
:- use_module(library(dcg/basics)).
:- ensure_loaded(analyze).

respider :-
	spider_to_file('http://127.0.0.1:3040/', 'swipl_spider.pl'),
	retractall(endpoint(_,_)),
	consult(swipl_spider),
	assert_from_list.

spider_to_file(Root, FileName) :-
	spider(Root, Uris, Links),
	open(FileName, write, Stream, []),
	write(Stream, 'spidered_uris('),
	writeq(Stream, Uris),
	write(Stream, ').'),
	nl(Stream),
	write(Stream, 'spidered_links('),
	writeq(Stream, Links),
	write(Stream, ').'),
	nl(Stream),
	close(Stream).

progress_format(Format, Args) :-
	format(Format, Args).

spider(Root, Uris, Links) :-
	uri_components(Root, Components),
	uri_data(authority, Components, Authority),
	spider(Authority, [Root], [], Uris, Links).

% done
spider(_, [], Visited, Visited, []).

%DEBUG
/*
spider(_, [Todo|_], _, _) :-
	progress_format('~w ||| ', [Todo]),
	flush,
	fail.
*/

spider('127.0.0.1:3040', ['http://127.0.0.1:3040'|TBD], Visited, Uris, Links) :-
	spider('127.0.0.1:3040', TBD, Visited, Uris, Links).

spider('127.0.0.1:3040', [Todo|TBD], Visited, Uris, Links) :-
	atom_concat('http://www.swi-prolog.org', Rest, Todo),
	atom_concat('http://127.0.0.1:3040', Rest, NewTodo),
	spider('127.0.0.1:3040', [NewTodo|TBD], Visited, Uris, Links).

% visited
spider(Authority, [Todo|TBD], Visited, Uris, Links) :-
	member(_-Todo, Visited),
	spider(Authority, TBD, Visited, Uris, Links).

% assets
spider(Authority, [Todo|TBD], Visited, Uris, Links) :-
	asset(A),
	atom_concat(_, A, Todo),
	!,
	progress_format('asset ~w~n', [Todo]),
	spider(Authority, TBD, [asset-Todo|Visited], Uris, Links).

% anchor
% we don't add them to visited, just ignore them
spider(Authority, [Todo|TBD], Visited, Uris, Links) :-
	atom_concat('#', _, Todo),
	spider(Authority, TBD, Visited, Uris, Links).

% misformed urls
spider(Authority, [Todo|TBD], Visited, Uris, Links) :-
	uri_is_global(Todo),
	uri_components(Todo, Components),
	uri_data(authority, Components, TodoAuthority),
	var(TodoAuthority),
	!,
	progress_format('misformed ~w~n', [Todo]),
	spider(Authority, TBD, [misformed-Todo|Visited], Uris, Links).

% not http
spider(Authority, [Todo|TBD], Visited, Uris, Links) :-
	uri_is_global(Todo),
	uri_components(Todo, Components),
	uri_data(scheme, Components, Scheme),
	Scheme \= http,
	!,
	progress_format('not_http ~w~n', [Todo]),
	spider(Authority, TBD, [not_http-Todo|Visited], Uris, Links).

% external site
spider(Authority, [Todo|TBD], Visited, Uris, Links) :-
	uri_is_global(Todo),
	uri_components(Todo, Components),
	uri_data(authority, Components, TodoAuthority),
	Authority \= TodoAuthority,
	!,
	progress_format('external ~w~n', [Todo]),
	spider(Authority, TBD, [external-Todo|Visited], Uris, Links).

% internal
spider(Authority, [Todo|TBD], Visited, Uris, NewLinks) :-
	atomic_list_concat(['http://', Authority, '/'], Base),
	uri_resolve(Todo, Base, Global),
	progress_format('internal ~w~n', [Global]),
	(   Global = 'http://127.0.0.1:3040' -> gtrace ; true),
	get_hrefs(Global, Hrefs),
	append(Hrefs, TBD, NewTBD),
	maplist(kv(Todo), Hrefs, KVRefs),
	spider(Authority, NewTBD, [internal-Todo|Visited], Uris, Links),
	append(KVRefs, Links, NewLinks).

% stumped
spider(Authority, [Todo|TBD], Visited, Uris, Links) :-
	progress_format('stumped ~w~n', [Todo]),
	!,
	spider(Authority, TBD, [misformed-Todo|Visited], Uris, Links).

kv(K, V, K-V).

get_hrefs(URI, ContextHrefs) :-
	catch(
	     http_get(URI, Data, [timeout(3), to(codes)]),
	     _,
	     format(codes(Data), ' href="404?uri=~w" ', [URI])),
	debug(hrefs, 'checking ~w', [URI]),
	phrase(hrefs_of(Hrefs), Data),
	path_context(URI, Context),
	maplist(contextualize(Context), Hrefs, ContextHrefs),
	debug(hrefs, 'got ~w~n', [ContextHrefs]).

path_context(URI, Context) :-
	uri_components(URI,
		       uri_components(Scheme, Authority, Path, _Search, _Frag)),
	trim_path(Path, TrimPath),
	uri_components(Context,
		       uri_components(Scheme, Authority , TrimPath, _ , _)).

trim_path(Path, TrimPath) :-
	trim_path_(Path, TrimPath),
	atom_concat(_, '/', TrimPath),!.
trim_path(Path, TrimPath) :-
	trim_path_(Path, TrimPathNS),
	atom_concat(TrimPathNS, '/', TrimPath).

trim_path_(Path, TrimPath) :-
	atom_concat(TrimPath, Rest, Path),
	atom_concat('/', Noslash, Rest),
	atom_codes(Noslash, C),
	\+ memberchk(0'/ , C),!.
% no / in path
trim_path_(_, '').

contextualize(_, Href, Href) :-
	atom_concat('#', _, Href).
contextualize(_Context, Href, Href) :-
	atom_concat('/', _, Href),!.
contextualize(_, Href, Href) :-
	uri_is_global(Href).
contextualize(Context, Href, ContextHref) :-
	atom_concat(Context, Href, ContextHref).

hrefs_of([Href|T]) -->
	string(_),
	"href",
	blanks,
	"=",
	(   """"  ;   "'"),
	!,
	string_without("""'", CHref),
	{
	    atom_codes(Href, CHref)
	},
	hrefs_of(T).

hrefs_of([]) --> string(_).

asset('.ico').
asset('.png').
asset('.gif').
asset('.bmp').
asset('.mp4').
asset('.pdf').
asset('.css').
asset('.swf').
asset('.jpg').
asset('.jpeg').
asset('.psd').
asset('.xls').
% asset('.txt').  turns out swipl site serves html from tghese
asset('.doc').
asset('.docx').
asset('.xml').
asset('.j2k').
asset('.tga').
asset('.odt').
asset('.ppt').
asset('.bib').
asset('.tgz').





