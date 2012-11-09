/** <module> Site spidering utility

Usage

swipl -s load.pl
?-spider('http://somesite.com/', Uris).

?- spider_to_file('http://somesite.com/', 'myuris.pl').
myuris.pl will have a bare list in it, you'll have to wrap it manually
to load it.

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

 anchor links are ignored without adding to the list

*/

:-module(load, [spider/2]).

:- use_module(library(uri)).
:- use_module(library(http/http_client)).
:- use_module(library(dcg/basics)).

spider_to_file(Root, FileName) :-
	spider(Root, Uris),
	open(FileName, write, Stream, []),
	writeq(Stream, Uris),
	close(Stream).

progress_format(Format, Args) :-
	format(Format, Args).

spider(Root, Uris) :-
	uri_components(Root, Components),
	uri_data(authority, Components, Authority),
	spider(Authority, [Root], [], Uris).

% done
spider(_, [], Visited, Visited).

%DEBUG
/*
spider(_, [Todo|_], _, _) :-
	progress_format('~w ||| ', [Todo]),
	flush,
	fail.
*/
% visited
spider(Authority, [Todo|TBD], Visited, Uris) :-
	member(_-Todo, Visited),
	spider(Authority, TBD, Visited, Uris).

% assets
spider(Authority, [Todo|TBD], Visited, Uris) :-
	asset(A),
	atom_concat(_, A, Todo),
	!,
	progress_format('asset ~w~n', [Todo]),
	spider(Authority, TBD, [asset-Todo|Visited], Uris).

% anchor
% we don't add them to visited, just ignore them
spider(Authority, [Todo|TBD], Visited, Uris) :-
	atom_concat('#', _, Todo),
	spider(Authority, TBD, Visited, Uris).

% misformed urls
spider(Authority, [Todo|TBD], Visited, Uris) :-
	uri_is_global(Todo),
	uri_components(Todo, Components),
	uri_data(authority, Components, TodoAuthority),
	var(TodoAuthority),
	!,
	progress_format('misformed ~w~n', [Todo]),
	spider(Authority, TBD, [misformed-Todo|Visited], Uris).

% not http
spider(Authority, [Todo|TBD], Visited, Uris) :-
	uri_is_global(Todo),
	uri_components(Todo, Components),
	uri_data(scheme, Components, Scheme),
	Scheme \= http,
	!,
	progress_format('not_http ~w~n', [Todo]),
	spider(Authority, TBD, [not_http-Todo|Visited], Uris).

% external site
spider(Authority, [Todo|TBD], Visited, Uris) :-
	uri_is_global(Todo),
	uri_components(Todo, Components),
	uri_data(authority, Components, TodoAuthority),
	TodoAuthority \= Authority,
	!,
	progress_format('external ~w~n', [Todo]),
	spider(Authority, TBD, [external-Todo|Visited], Uris).

% internal
spider(Authority, [Todo|TBD], Visited, Uris) :-
	atomic_list_concat(['http://', Authority, '/'], Base),
	uri_resolve(Todo, Base, Global),
	progress_format('internal ~w~n', [Global]),
	get_hrefs(Global, Hrefs),
	append(Hrefs, TBD, NewTBD),
	spider(Authority, NewTBD, [internal-Todo|Visited], Uris).

% stumped
spider(Authority, [Todo|TBD], Visited, Uris) :-
	progress_format('stumped ~w~n', [Todo]),
	!,
	spider(Authority, TBD, [misformed-Todo|Visited], Uris).


get_hrefs(URI, Hrefs) :-
	catch(
	     http_get(URI, Data, [timeout(3), to(codes)]),
	     _,
	     Data = ""),
	debug(hrefs, 'checking ~w', [URI]),
	phrase(hrefs_of(Hrefs), Data),
	debug(hrefs, 'got ~w~n', [Hrefs]).

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
asset('.txt').
asset('.doc').
asset('.docx').
asset('.xml').
asset('.j2k').
asset('.tga').





