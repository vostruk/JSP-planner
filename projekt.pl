plan(State, Goals, Plan, FinalState) :-
	limit(1, 100, CurrentLimit),
	plan(State, Goals, Plan, FinalState, [], CurrentLimit).

plan(_, _, _, _) :-
	writeln("Nie osiagnieto celu przy zadanym limicie").

plan(State, Goals, [], State, _, _) :-
%	wypisz_plan("Przed goals achieved", 0, State, Goals),
	goals_achieved(Goals, State).
%	writeln("Goals_achieved TRUE").


plan(InitState, Goals, Plan, FinalState, AchievedGoals, Limit) :-

	choose_goal(Goal, Goals, RestGoals, InitState),
%	writeln("po choose_goal"),
	achieves( Goal, Action),
%	writeln("po achieves"),
	requires(Action, CondGoals, Conditions),
%	wypisz_requires("po Requires: ", Action, CondGoals, Conditions),
	limit(0, Limit, LimitForPrePlan),
%	wypisz_plan("Do preplanu", LimitForPrePlan,
%	InitState,CondGoals),
	plan(InitState, CondGoals, PrePlan, State1, AchievedGoals, LimitForPrePlan),
%	writeln("po preplanie"),
	inst_action(Action, Conditions, State1, InstAction),
	checkAchievedGoals(Action, AchievedGoals),
%	writeln("po inst_action"),
	perform_action(State1, InstAction, State2),
	addAchievedGoals(Action, AchievedGoals, NewAchievedGoals),
%	writeln("po perform_action"),
	LimitForPostPlan is Limit - LimitForPrePlan - 1,
%	writeln(LimitForPostPlan),
%	wypisz_plan("Do postplanu", LimitForPostPlan, State2,
%	RestGoals),
	plan(State2, RestGoals, PostPlan, FinalState, NewAchievedGoals, LimitForPostPlan),
%	writeln("po Postplanie"),
%	wypisz_plan("Po postplanie", PrePlan,[ InstAction | PostPlan ],
%	Plan ),
	conc(PrePlan, [ InstAction | PostPlan ], Plan).
%	writeln("po conc").

checkAchievedGoals(move(X,Y,Z), AchievedGoals) :-
	\+member(on(X,Y), AchievedGoals),
	\+member(clear(Z), AchievedGoals).

addAchievedGoals(move(X,Y,Z), AchievedGoals, [on(X,Y), clear(Z)|AchievedGoals]).

% w tym miejscu o ile dobrze pojmuje trzeba ukonkretnic jaka akcja ma
% zostac wykonana w nastepnej procedurze perform_action

inst_action(move(X, Y, Z), Conditions, State, move(X1, Y1, Z1)) :-
	goals_achieved(Conditions, State),
	expand(X, X1),
	expand(Y, Y1),
	expand(Z, Z1).

expand(A, A) :-
	A \= _/_.
expand(A/_, A) :-
	A \= _/_.

%jedyna mozliwa akcja w tym swiecie jest przenoszenie klockow
% w perform_action bedzie wykonywana raczej (zastanowic sie) dla
% ukonkretnionych akcji wiec procedura w takiej formie powinna spelnic
% swoje zadanie. Akcja przeniesienia zostanie wykonana jezeli miejsce na
% ktore chcemy przeniesc jest wolne i klocek ktory chcemy przeniesc nie
% jest zablokowany. Po akcji w stanie 1 nie powinno juz byc takiego
% klocka a w stanie 2 powinien sie taki pojawic
perform_action(State1, move(A,B,C), [on(A,C), clear(B)|State2]) :-
	member(clear(C),State1),
	member(clear(A),State1),
	subtract(State1, [on(A,B), clear(C)], State2).


goals_achieved([], _).
goals_achieved([G|RestGoals], State) :-
	goal_instate(G, State),
	goals_achieved(RestGoals, State).

goal_instate(clear(X/Y), State) :-
	nonvar(Y),
	member(clear(X), State),
	goal_instate(Y, State).

goal_instate(on(X, Y/Z), State) :-
	nonvar(Z),
	member(on(X, Y), State),
	goal_instate(Z, State).

goal_instate(clear(X), State) :-
	var(X),
	member(clear(X), State).
goal_instate(clear(X), State) :-
	X \= _/_,
	member(clear(X), State).

goal_instate(on(X,Y), State) :-
	var(Y),
	member(on(X,Y), State).
goal_instate(on(X,Y), State) :-
	Y \= _/_,
	member(on(X,Y), State).


goal_instate(diff(X, Y), _) :-
        var(X),
	var(Y),
	X \= Y.

goal_instate(diff(X, Y), _) :-
        X \= _/_ ,
        Y \= _/_ ,
	X \= Y.

goal_instate(diff(X, Y), _) :-
        X \= _/_,
	var(Y),
	X \= Y.

goal_instate(diff(X, Y), _) :-
        var(X),
	Y \= _/_,
	X \= Y.


goal_instate(diff(X/Z, Y), State) :-
	X \= Y,
	goal_instate(Z, State).

goal_instate(diff(X, Y/Z), State) :-
	X \= Y,
	goal_instate(Z, State).



choose_goal([], [], [], _)
.
% :-	writeln("Choose_goal pierwsza klauzula").
choose_goal(G, Goals, RestGoals, InitState) :-
%	write(" wsrod "), writeln(Goals),
	delete1(G, Goals, RestGoals),
	\+goal_instate(G, InitState).
%	write("Wybrany cel "),
%	writeln(G).

delete1(X, [X|R], R).
delete1(X, [Y|R], [Y|R1]) :-
	delete1(X, R, R1).


achieves(on(A, B), move(A, Y/on(A, Y), B)).
achieves(clear(C), move(X/on(X, C), C, Z)) :-
%	writeln(move(X/on(X, C), C, Z)),
	dif(C, Z).

% szukanie warunkow jakie musza zostac spelnione aby podana akcja mogla
% zajsc
requires(move(A, Y/on(A, Y), B), [clear(A), clear(B)], [on(A, Y)]).
requires(move(X/on(X, C), C, Z), [clear(X/on(X, C))], [clear(Z), diff(Z, X/on(X, C))]).
requires(move(A, _, B), [clear(A), clear(B)], []).


limit(MinLimit, MaxLimit, MinLimit) :-
	MinLimit < MaxLimit.

limit(MinLimit, MaxLimit, CurrentLimit) :-
	%write("Podnosze limit"),
	NewLimit is MinLimit + 1 ,
	NewLimit < MaxLimit,
	limit(NewLimit, MaxLimit, CurrentLimit).


conc([], List, List).

conc([X|RestList1], List2, [X|List3]) :-
	conc(RestList1, List2, List3).

wypisz_plan(Info, Limit, State, Goals) :-
	write(Info),
	write(" Limit: "),
	writeln(Limit),
	write("Stan: "),
	writeln(State),
	write("Cele: "),
	writeln(Goals),
	read(_),
	writeln(" ").

wypisz_requires(Info, Limit, State, Goals) :-
	write(Info),
	write(" Akcja: "),
	writeln(Limit),
	write("Goals: "),
	writeln(State),
	write("Cond: "),
	writeln(Goals),
	read(_),
	writeln(" ").
