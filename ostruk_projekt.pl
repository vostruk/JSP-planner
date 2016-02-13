%Przyklady wywolan:
%plan([ on( b4, p1), on( b1, b4), on( b3, b1), on( b2, p3), clear(b3), clear(b2), clear(p2), clear(p4) ], [on(b3, b2), on(b1, b3) ], Plan, FinalState).
%plan([ on( b4, p1), on( b1, b4), on( b3, b1), on( b2, p3), clear(b3), clear(b2),  clear(p2), clear(p4) ], [on(b3,b2)], Plan, FinalState).
 
:- [sledzenie].
 
plan(State, Goals, Plan, FinalState) :-
	generateNum(1, 50, N),
    plan(State, Goals, [], Plan, FinalState, 0, N).

plan(_, _, _, FinalState) :-
 nl, printDebug('Cel nieosiagniety przy zadnym limicie <= 50', '', FinalState).
 
plan(State, Goals, _, [], State, RLevel, _):- 
   printDebug('Goals CHECK', '', RLevel),
   goals_achieved(Goals, State),
   printDebug('Some goals achieved', Goals, RLevel). 
 
plan(InitState, Goals, Protected, Plan, FinalState, RLevel, N):- 
  generateNum(0,N, N1),
  NewRLevel is RLevel + 1,
  choose_goal(Goal, Goals, RestGoals, InitState), 
  printDebug('Choosed goal', Goal, RLevel),
  achieves( Goal, Action), 
  printDebug('Action:',Action,RLevel),
  requires(Action, CondGoals, Conditions), 
  printDebug('CondGoals:',CondGoals, RLevel),
  printDebug('Conditions:',Conditions,RLevel),
  plan(InitState, CondGoals, Protected, PrePlan, State1, NewRLevel, N1), 
  inst_action(Action, Conditions,State1, InstAction), 
  printDebug('InAction:',InstAction,RLevel),
  preserves(Action, Protected),
  perform_action(State1, InstAction, State2),
  addAchievedGoals(Action, Protected, NewProtected),  
  N2 is N - N1 - 1,
  plan(State2, RestGoals, NewProtected, PostPlan, FinalState, NewRLevel, N2),  
  conc(PrePlan, [ InstAction | PostPlan ], Plan).




  
  
  
  
  
%=================================goals_achieved ====================================%
%                   checks if our state contains all parts of goals    %

%fact to match for goals_chieved
goals_achieved([], _).
goals_achieved([Goal|RestGoals], State) :-
	my_member(Goal, State),
	goals_achieved(RestGoals, State).

my_member(clear(X/Y), State) :-
	nonvar(Y),
	member(clear(X), State),
	my_member(Y, State).
my_member(on(X, Y/Z), State) :-
	nonvar(Z),
	member(on(X, Y), State),
	my_member(Z, State).
my_member(clear(X), State) :-
	var(X),
	member(clear(X), State).
my_member(clear(X), State) :-
	X \= _/_,
	member(clear(X), State).
my_member(on(X,Y), State) :-
	var(Y),
	member(on(X,Y), State).
my_member(on(X,Y), State) :-
	Y \= _/_,
	member(on(X,Y), State).
my_member(diff(X, Y), _) :-
    var(X),
	var(Y),
	X \= Y.
my_member(diff(X, Y), _) :-
    X \= _/_ ,
    Y \= _/_ ,
	X \= Y.
my_member(diff(X, Y), _) :-
    X \= _/_,
	var(Y),
	X \= Y.
my_member(diff(X, Y), _) :-
    var(X),
	Y \= _/_,
	X \= Y.
my_member(diff(X/Z, Y), State) :-
	X \= Y,
	my_member(Z, State).
my_member(diff(X, Y/Z), State) :-
	X \= Y,
	my_member(Z, State).

	
	
	
	
	
	
%=========================  choose_goal ========================================%
%      chooses the next goal for future processing(from start list of goasl) %

choose_goal([], [], [], _).
choose_goal(G, Goals, RestGoals, InitState) :-
	my_delete(G, Goals, RestGoals),
	\+my_member(G, InitState).

my_delete(X, [X|R], R).
my_delete(X, [Y|R], [Y|R1]) :-
	my_delete(X, R, R1).

%=================================   achieves ==================================%
% 		        Action leads to the change of states.                           %
% 	  predicate says if our goal is in the set of states achieved by the action %
% 			ps: action can be only move(clear is a coal, not action)

%Fact for goals_from_action to match:
achieves(on(Block,To), move(Block,From/on(Block,From),To)).
achieves(clear(From), move(Block/on(Block,From),From,To)):-
	dif(From,To).

%=============================== requires ==============================
% to perform the action we need some goals and 
% we need come conditions to be fulfilled(clear block we want to take, 
% clear block we want to put on etc.)

%fact for requires (must match the variables from "wywolanie")
% Action -> move(Block, From, To)
% condGoals -> "Block" stays on the "From" block, otherwise we must 
% put it there. No blocks stays on "Block" and "To" blocks, if not - make them clear.
% conditions -> conditions about the action arguments(no goals, just check)
requires(move(Block, From/on(Block, From), To), [clear(Block), clear(To)] , [on(Block, From)]).
requires(move(Block/on(Block, From), From, To), [clear(Block/on(Block, From))] , [clear(To), diff(Block/on(Block,From), To)]).
requires(move(Block, _, To), [clear(Block), clear(To)], []).

 
% robi z akcji nieukonkretnionej akcje ukonkretrniona korzystajac 
% z warunkow i zmieniajac przy tym stan
% InstAction akcja ukonkretniona przed wykonaniem stan posredni 1, 
% osiagany po wykonaniu preplanu 

%=============================== inst_action =========================
inst_action(move(X, Y, Z), Conditions, State, move(X1, Y1, Z1)) :-
	goals_achieved(Conditions, State),
	expand(X, X1),
	expand(Y, Y1),
	expand(Z, Z1).

	
	
	
	
	
%=============================== perform_action =============================
%Przyklad do sprawdzenia:
%performAction([ on( b4, p1), on( b1, b4), on( b3, b1), on( b2, p3), clear(b3), clear(b2),  clear(p2), clear(p4) ], move(b3, b1, b2), State2).
perform_action(State1, move(Block, From, To), [on(Block,To), clear(From)|State2]) :-
	member(clear(To),State1),
	member(clear(Block),State1),
    subtract(State1, [on(Block,From), clear(To)], State2).



%=============================== other help procedurs ==========================	
expand(A, A) :-
	A \= _/_.
expand(A/_, A) :-
	A \= _/_.
	
conc([], List, List).
conc([X|RestList1], List2, [X|List3]) :-
	conc(RestList1, List2, List3).

addAchievedGoals(move(X,Y,Z), AchievedGoals, [on(X,Y), clear(Z)|AchievedGoals]). 
%chronimy wstecz - po tym jak cel juz zostal osiagniety, zeby nie byl zniszczony
preserves(move(Block, From, To), Protected):-
  \+member(on(Block,From), Protected),
  \+member(clear(To), Protected).
  
% Generuj limit od Min do Max
generateNum(MinLimit, MaxLimit, MinLimit) :-
	MinLimit < MaxLimit.

generateNum(MinLimit, MaxLimit, CurrentLimit) :-
	NewLimit is MinLimit + 1 ,
	NewLimit < MaxLimit,
	generateNum(NewLimit, MaxLimit, CurrentLimit).

%NOTATKI:
%POSTAC CELOW:
% on(b4, b2); 
% clear(b4); 
% clear(X2/on(X2,b4));
% Clear(X3/on(X3, X3/on(X2, b4)));
%POSTAC WARUNKOW: 
% on(b4, Y); 
% Clear(Z2);
% Diff(Z2, X2/on(X2, b4));
% Diff(Z3, X3/on(X3, X2/on(X2, b4)));
%POSTAC AKCJI:
% move(b4, Y/on(b4, Y1), b2);  
% move(X2/on(X2, b4), b4, Z2); 
% move(X3/on(X3, X2/on(X2,b4)),X2/on(X2, b4), Z3)
