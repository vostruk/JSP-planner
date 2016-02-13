% ======================================
% zalecenia do sledzenia prowadzacego: nie z debugera - nie bardzo szczegolowe
% 1 procedura sledzaca -> 3 warianty rozniace sie lista argumentow, traceProc(1) traceProc(2), traceProc(3)
% --------------------------------------

printDebug(Msg, Var, Level) :-
    printDebugMargin(Level),
    printDebugLevel(Level),
    write(Msg),
    write(' : '),
    write(Var),
    nl .

printDebugLevel(Level) :-
    write('<'),
    write(Level),
    write('> ').

printDebugMargin(Level) :-
    Level > 0,
    write('   '),
    NewLevel is Level - 1,
    printDebugMargin(NewLevel).

printDebugMargin(0) :-
    write('   ').
