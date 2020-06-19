/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Solving Sudoku with Prolog
   https://www.metalevel.at/sudoku/

   Written Feb. 2008 by Markus Triska  (triska@metalevel.at)
   Public domain code. Tested with Scryer Prolog.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

:- use_module(library(clpz)).
:- use_module(library(lists)).
:- use_module(library(format)).
:- use_module(library(dcgs)).
:- use_module(library(freeze)).
:- use_module(library(charsio)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Constraint posting
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sudoku(Rows) :-
        length(Rows, 9), maplist(same_length(Rows), Rows),
        append(Rows, Vs), Vs ins 1..9,
        maplist(all_distinct, Rows),
        transpose(Rows, Columns), maplist(all_distinct, Columns),
        Rows = [As,Bs,Cs,Ds,Es,Fs,Gs,Hs,Is],
        blocks(As, Bs, Cs), blocks(Ds, Es, Fs), blocks(Gs, Hs, Is).

blocks([], [], []).
blocks([N1,N2,N3|Ns1], [N4,N5,N6|Ns2], [N7,N8,N9|Ns3]) :-
        all_distinct([N1,N2,N3,N4,N5,N6,N7,N8,N9]),
        blocks(Ns1, Ns2, Ns3).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Animation.

   A frozen goal for each variable emits PostScript instructions to
   draw a number. On backtracking, the field is cleared.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

animate(Rows) :- animate(Rows, 1).

animate([], _).
animate([Row|Rows], N) :-
        animate(Row, 1, N),
        N1 #= N + 1,
        animate(Rows, N1).

animate([], _, _).
animate([C|Cs], Col, Row) :-
        freeze(C, label(Col, Row, C)),
        Col1 #= Col + 1,
        animate(Cs, Col1, Row).

label(Col, Row, N) :- format("(~w) ~w ~w num\n", [N,Col,Row]).
label(Col, Row, _) :- format("~w ~w clear\n", [Col,Row]), false.

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   PostScript definitions. Place a number N and clear a cell with:

   (N) Col Row num
   Col Row clear
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

postscript -->
        "/Palatino-Bold findfont 5 scalefont setfont \
        320 9 div dup scale 0 setlinewidth -0.9 -0.9 translate \
        /num { gsave 10 exch sub translate 0.5 0.25 translate 0.16 dup scale \
             dup stringwidth pop -2 div 0 moveto show grestore } bind def \
        /clear { gsave 10 exch sub translate 1 setgray 0.1 dup 0.8 \
             dup rectfill grestore } bind def \
        1 1 10 { gsave dup 1 moveto 10 lineto stroke grestore } for \
        1 1 10 { gsave dup 1 exch moveto 10 exch lineto stroke grestore } for \
        1 3 9 { 1 3 9 { 1 index gsave translate 0.05 setlinewidth \
             0 0 3 3 rectstroke grestore } for pop } for\n".

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Set up communication with gs.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

show(Options, Rows) :-
        sudoku(Rows),
        phrase(postscript, Ps),
        format("~s", [Ps]),
        append(Rows, Vs),
        animate(Rows),
        labeling(Options, Vs),
        get_single_char(_),
        false.
show(_, _) :- halt.