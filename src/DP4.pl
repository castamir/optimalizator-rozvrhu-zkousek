:- use_module(library(clpfd)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(time)).
:- use_module(library(lists)).

% DayID, FormatedDay
:- dynamic day/2.

% From, To
:- dynamic dayhours/2.

% Name, Duration, RequestedCapacity
:- dynamic subject/3.

% Name, Capacity
:- dynamic room/2.

% Name
:- dynamic teacher/1.

% TName, SName
:- dynamic teacher_subject/2.

% Name, FormatedDay, [hours]
:- dynamic room_off/3.

% TName, Date
:- dynamic teacher_off/2.

% FormatedDay
:- dynamic day_off/1.

% SName1, SName2, Collisions
:- dynamic subject_pair/3.

% SName1, SName2, SName3, Collisions
:- dynamic subject_triple/4.

% RoomNamePS, RoomCapPS, MaxCap, RoomCount
:- dynamic room_data/9.

% minimal period betbeen 2 exams from the same subject
:- dynamic minimal_days_between_exams/1.

% minimal days to evaluate Term-th term of an exam
% Subject, Term, Days
:- dynamic minimal_days_for_exam_correction/3.

% Name, Term, Day, Start, NumOfRooms, RoomsCap
:- dynamic fixed_exam/6.

% Min, Max
:- dynamic penale_limits/2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cartproduct(L1,L2,Res) :- bagof([X,Y],(member(X,L1),member(Y,L2)),Res).

powerset([], []).
powerset([X|[]], [[],[X]]):- !.
powerset([E|Tail], Z):-
	powerset(Tail, X),
	maplist(powerset_(E), X, Y),
	append(X, Y, Z).
powerset_(Element, SubSetItem, Unioned):-
	append([Element], SubSetItem, Unioned).

list_keys([],[],[]).
list_keys([K-V|KVs],[K|Ks],[V|Vs]):-
	list_keys(KVs,Ks,Vs).

expand_tupple([A, B], A, B).
expand_tupple([A, B, C], A, B, C).
expand_tupple([A, B, C, D], A, B, C, D).
expand_tupple([A, B, C, D, E], A, B, C, D, E).

make_two_domains([H], H).
make_two_domains([H | T], '\\/'(H, TDomain)) :-
	make_two_domains(T, TDomain).

length_(Length, List) :- length(List, Length).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% constraints
	
c_hours(Duration,Start1,Start2,Start3):-
	dayhours(From,To),
	TTo is To - Duration,
	[Start1,Start2,Start3] ins From .. TTo.

c_exam_to_exam(Schedule):-  
	maplist(c_exam_to_exam(Schedule),Schedule),!.
c_exam_to_exam(As,B):-
	maplist(c_exam_to_exam_(B), As).
c_exam_to_exam_(A,B):-
	c5_same_day(A,B),
	c6_same_student_or_teacher(A,B).

c0_examination_period(DayVar1,DayVar2,DayVar3,TotalDays):-
	[DayVar1,DayVar2,DayVar3] ins 1 .. TotalDays.

c1_days_between_exams(DayVar1, DayVar2, Subject, AfterTerm):-
	(
		minimal_days_for_exam_correction(Subject, AfterTerm, CorDays),
		DayVar2 - DayVar1 #>= CorDays
	;
		minimal_days_between_exams(MinDays),
		DayVar2 - DayVar1 #>= MinDays
	),!.
	
c2_holidays(DayVar1,DayVar2,DayVar3,Holiday):-
	DayVar1 #\= Holiday,
	DayVar2 #\= Holiday,
	DayVar3 #\= Holiday.
	
c3_fixed_exam(exam(Name,Term,DayVar,StartVar,_,_CapacityVar,_RoomCountVar,_)):-
	!,
	(
	fixed_exam(Name, Term, Day, Start, _RoomCount, _Capacity),
	day(DayId, Day),
	DayVar #= DayId,
	StartVar #= Start
	;
	true).
	
c4_exam_total_capacity(A,B,C,Capacity):-
	A = exam(_,_,_,_,_,CapacityVar1,_,RoomListVar1),
	B = exam(_,_,_,_,_,CapacityVar2,_,RoomListVar2),
	C = exam(_,_,_,_,_,CapacityVar3,_,RoomListVar3), 
	room_data(_, _, _, _, _, CapPairs, CapSet, _, _),

	CapacityVar1 #>= Capacity,
	CapacityVar2 #>= Capacity,
	CapacityVar3 #>= Capacity,

	make_two_domains(CapSet, CapDomain),
	[CapacityVar1,CapacityVar2,CapacityVar3] ins CapDomain,
	
	tuples_in([[RoomListVar1,CapacityVar1]],CapPairs),
	tuples_in([[RoomListVar2,CapacityVar2]],CapPairs),
	tuples_in([[RoomListVar3,CapacityVar3]],CapPairs).

c5_same_day(A,B):-
	!,	  
	(
		A = exam(E1Name,_,E1Day,E1Start,E1Duration,E1Capacity,_RoomCountVar1,_RoomListVar1),
		B = exam(E2Name,_,E2Day,E2Start,E2Duration,E2Capacity,_RoomCountVar2,_RoomListVar2),
		E1Name \= E2Name,	  
		room_data(_, _, MaxCap, _RoomCount, _Pairs, _, _,_,_), 
		((E1Day #= E2Day #/\ E1Capacity + E2Capacity #> MaxCap) #==> (E2Start + E2Duration #=< E1Start #\/ E1Start + E1Duration #=< E2Start)),
		/*
		tuples_in([[RL1,RL2]], Pairs),
		(E1Day #= E2Day #/\ (E1Start #=< E2Start #/\ E2Start #=< E1Start + E1Duration)) #<==> RoomListVar1 #= RL1 #/\ RoomListVar2 #= RL2,
		(E1Day #= E2Day #/\ (E2Start #=< E1Start #/\ E1Start #=< E2Start + E2Duration)) #<==> RoomListVar1 #= RL1 #/\ RoomListVar2 #= RL2,
		*/
		true
	;
		true
	), 
	true.

c6_same_student_or_teacher(A,B):-
	!,
	A = exam(E1Name,_,E1Day,E1Start,E1Duration,_,_,_),
	B = exam(E2Name,_,E2Day,E2Start,E2Duration,_,_,_),
	(
		E1Name \= E2Name, 
		(
			subject_pair(E1Name,E2Name,_)
		;
			teacher_subject(Teacher,E1Name),
			teacher_subject(Teacher,E2Name)
		),!,		   
		(E1Day #= E2Day  #==> (E2Start + E2Duration #=< E1Start #\/ E1Start + E1Duration #=< E2Start))
	;
		true
	).

c8_teacher_off(A,B,C,DayID):-
	!,
	(
		A = exam(Name,_,DayVar1,_,_,_,_,_),
		B = exam(Name,_,DayVar2,_,_,_,_,_),
		C = exam(Name,_,DayVar3,_,_,_,_,_),
		DayVar1 #\= DayID,
		DayVar2 #\= DayID,
		DayVar3 #\= DayID
	;
		true
	).

get_penale(MinPenale, MaxPenale, Exams, Penale):-
	Penale in MinPenale .. MaxPenale,
	maplist(s1_penale(Exams,Exams),Exams,PenaleT),
	append(PenaleT, PenaleList),	  
	sum(PenaleList, #=, Penale),
	!.
	
s1_penale(As, Bs, C, PenaleTuple):-
	maplist(s1_penale_(C, As), Bs, PenaleTupleTuple),
	append(PenaleTupleTuple, PenaleTuple), !.
s1_penale_(C, _, B, [Penale]):-
	C = exam(E1Name,_,E1Day,_,_E1Duration,_,_,_),
	B = exam(E2Name,_,E2Day,_,_E2Duration,_,_,_),
	Penale in 0..1, 
	(
		E1Name @< E2Name,
		subject_pair(E1Name,E2Name,_),
		(E1Day #= E2Day #==> Penale #= 1)
	;
		Penale #= 0
	),!.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% +TotalDays: total number of days
% +subject(Name,Duration,Capacity)
init_exams( TotalDays, 
			subject(Name,Duration,Capacity), 
			[A, B, C]) :-
	A = exam(Name,1,DayVar1,Start1,Duration,_,_,_),
	B = exam(Name,2,DayVar2,Start2,Duration,_,_,_),
	C = exam(Name,3,DayVar3,Start3,Duration,_,_,_),
	c0_examination_period(DayVar1,DayVar2,DayVar3,TotalDays),
	c1_days_between_exams(DayVar1,DayVar2,Name,1),
	c1_days_between_exams(DayVar2,DayVar3,Name,2),
	findall(DayID, (day_off(D), day(DayID,D)), Holidays),
	maplist(c2_holidays(DayVar1,DayVar2,DayVar3),Holidays),
	findall(DayID, (teacher_subject(Teacher,Name),teacher_off(Teacher, Date), day(DayID,Date)), TeacherOff),
	maplist(c8_teacher_off(A,B,C),TeacherOff),
	c3_fixed_exam(A),
	c3_fixed_exam(B),
	c3_fixed_exam(C),
	c4_exam_total_capacity(A,B,C,Capacity),
	c_hours(Duration,Start1,Start2,Start3).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

play :-
	play(0, 5, 300).
play(MinPenale, MaxPenale) :-
	play(MinPenale, MaxPenale, 300).
play(MinPenale, MaxPenale, _TimeLimit) :-
	initschedule,
	(
		/*catch(call_with_time_limit(TimeLimit, find_schedule(MinPenale, MaxPenale, Schedule, Penale)), 
			time_limit_exceeded, fail),*/
		find_schedule(MinPenale, MaxPenale, Schedule, Penale),
		findall(D-E, (member(E,Schedule),E = exam(_,_,D,_,_,_,_,_)), ScheduleAssoc),
		keysort(ScheduleAssoc,SortedScheduleAssoc),
		
		forall(member(_-A, SortedScheduleAssoc), (print_exam(A))),
		message("Celkova penalizace", Penale)
		;
		message("Rozvrh nenalezen")
	),!.

% -Schedule: list of exams
% -Penale: penalized quality of schedule	
find_schedule(Schedule, Penale) :-
	find_schedule(0, 1000, Schedule, Penale).

% +MinPenale
% +MaxPenale
% -Schedule: list of exams
% -Penale: penalized quality of schedule	
find_schedule(_MinPenale, _MaxPenale, Schedule, Penale) :-
	message("Inicializace faktu - OK"),
	findall(day(A,B), day(A,B), Days),
	findall(subject(C,D,E), subject(C,D,E), Subjects),
	length(Days,TotalDays),
	maplist(init_exams(TotalDays),Subjects,ExamT),
	append(ExamT, Schedule),
	message("Inicializace promennych - OK"),
	c_exam_to_exam(Schedule),
	message("Vazby mezi zkouskami - OK"),
	maplist(arg(3), Schedule, DayVars),
	maplist(arg(4), Schedule, StartVars),
	maplist(arg(6), Schedule, CapVars),
/*	maplist(arg(8), Schedule, RLVars),*/
	append([DayVars,StartVars,CapVars/*,RLVars*/], Vars),
	!, 
	message("Hledani reseni zacalo"),
	penale_limits(MinPenale,MaxPenale),
	get_penale(MinPenale, MaxPenale, Schedule, Penale),
	append([[Penale],Vars], AVars),
	labeling([ff,min(Penale)],AVars),
	/*find_solution(Schedule, Vars, MinPenale, MaxPenale, Penale),*/
	message("Reseni nalezeno"),!.
	
find_solution(Schedule, Vars, MinPenale, MaxPenale, Penale):-
	message("Zkousim penale",MinPenale),
	MinPenale =< MaxPenale,
	(
		get_penale(MinPenale, MaxPenale, Schedule, P), 
		append([[P],Vars], AVars),
		/*catch(call_with_time_limit(TimeLimit, labeling([],AVars)), 
			time_limit_exceeded, 
			(message("time_limit_exceeded"),fail)),*/
		labeling([min(P),leftmost,enum],AVars),
		Penale = P,
		!
	;
		NMP is MinPenale + 50,
		find_solution(Schedule, Vars, NMP, MaxPenale, Penale)
	).
	
	
print_exam(exam(Name, Term, Day, Start, Duration, _, _, _RoomListIndex)):-
	day(Day,Date),
	number_codes(Term, STerm),
	number_codes(Start, SStart),
	End is Start + Duration,
	number_codes(End, SEnd),
	((Start < 10 -> Sep = " "); Sep = ""),
	writef('Rozvrh %s %s. termin: %s %s%s:00-%s:00\n', [Name,STerm,Date,Sep,SStart,SEnd]).
/*	room_data(RoomNamePS, _, _, _, _, _, _,_,_),
	nth1(RoomListIndex,RoomNamePS,RoomList),
	concatRoomList(RoomList, SRooms),
	writef('Rozvrh %s %s. termin: %s %s%s:00-%s:00 v %s\n', [Name,STerm,Date,Sep,SStart,SEnd,SRooms]).*/
	
concatRoomList([Room|[]],Room).
concatRoomList([Room1,Room2|[]],RoomListString):-
	append([Room1, " a ", Room2], RoomListString).
concatRoomList([Room|RLT],RoomListString):-
	concatRoomList(RLT,NRoomListString),
	append([Room, ", ", NRoomListString], RoomListString).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addday(ID, Date) :- 
	assertz(day(ID, Date)),
	Mod is ((ID - 1) mod 7) + 1,
	(   
	(Mod == 6; Mod == 7), setholiday(Date) ; true
	).
adddayhours(From, To) :- assert(dayhours(From, To)).
addsubject(Name, Duration, RequestedCapacity) :-
	assert(subject(Name, Duration, RequestedCapacity)).
addroom(Name, Capacity) :- assert(room(Name, Capacity)).
addteacher(Name) :- assert(teacher(Name)).
addteachersubject(Teacher, Subject) :- 
	teacher(Teacher),
	subject(Subject, _, _),
	assert(teacher_subject(Teacher, Subject)).

setroomoff(Room, Day, Hours) :-
	room(Room, _),
	day(_, Day),
	is_set(Hours),
	dayhours(From, To),
	numlist(From, To, Range),
	intersection(Range, Hours, HoursSet),
	(
	room_off(Room, Day, H),
		retract(room_off(Room, Day, H)),
		union(HoursSet, H, HH),
		assert(room_off(Room, Day, HH))
	;
	assert(room_off(Room, Day, HoursSet))	
	).
setholiday(Day) :-
	day(_, Day),
	(   
	day_off(Day)
	;   
	assert(day_off(Day)),
		dayhours(From, To),
		numlist(From, To, Hours),
		setholiday(Day, Hours)
	).
setholiday(Day, Hours) :-
	forall(
		room(Room, _),
		setroomoff(Room, Day, Hours)
		).

create_room_sets :-
	findall(RoomName-RoomCap, room(RoomName, RoomCap), RoomNameCapList),
	list_keys(RoomNameCapList, RoomNameList, RoomCapList),
	powerset(RoomNameList, RoomNamePS),
	powerset(RoomCapList, PSC),
	maplist(sum_list, PSC, RoomCapPS),
	max_member(MaxCap,RoomCapPS),
	list_to_set(RoomCapPS,RoomCapPSSet),
	length(RoomNameList, RoomCount),
	
	length(RoomNamePS, L),
	numlist(2, L, I),
	cartproduct(I,I,Product),
	findall([IA,IB],(
		member([IA,IB],Product),
		nth1(IA,RoomNamePS,A),
		nth1(IB,RoomNamePS,B),
		intersection(A,B,[])
	),Pairs),

	numlist(1, L, II),	
	maplist(map_rooms_cap_count_pairs, RoomCapPS, II, CapPairs),

	retractall(room_data(_, _, _, _, _, _, _, _, _)),
	assert(room_data(RoomNamePS, RoomCapPS, MaxCap, RoomCount, Pairs, CapPairs, RoomCapPSSet,_,_)),
	true.

map_rooms_cap_count_pairs(Cap, I, [I,Cap]).

set_penale_limits(Min,Max) :-
	retractall(penale_limits(_,_)),
	assert(penale_limits(Min,Max)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
initschedule :-
	retractall(fixed_exam(_,_,_,_,_,_)),
	retractall(minimal_days_for_exam_correction(_,_,_)),
	retractall(minimal_days_between_exams(_)),
	retractall(room_data(_,_,_,_,_,_,_,_,_)),
	retractall(subject_triple(_,_,_,_)),
	retractall(subject_pair(_,_,_)),
	retractall(day_off(_)),
	retractall(room_off(_,_,_)),
	retractall(teacher_off(_,_)),
	retractall(teacher_subject(_,_)),
	retractall(teacher(_)),
	retractall(room(_,_)),
	retractall(subject(_,_,_)),
	retractall(dayhours(_,_)),
	retractall(day(_,_)),
	
	set_penale_limits(0,50),

	consult(dpdata),
	init_conflicts,
	findall(SB,subject(SB,_,_),Subjects),
	length(Subjects,SL),
	message("Pocet predmetu",SL), 

	create_room_sets,

	true.

get_time(H,M,S):-
	get_time(TimeStamp),
	stamp_date_time(TimeStamp, DateTime, 'UTC'),
	date_time_value('time', DateTime, time(HH,M,SS)),
	S is integer(SS),
	H is HH + 2.
print_time:-
	get_time(H,M,S),
	writef("%d:%d:%d\n",[H,M,S]).

message(Message):-
	get_time(H,M,S),
	writef("%d:%d:%d - %s\n",[H,M,S,Message]).
message(Message,Value):-
	get_time(H,M,S),
	writef("%d:%d:%d - %s: %d\n",[H,M,S,Message,Value]).
	
	
prolog :-
	(
		time(once(play(0,100,900)))
	; true
	),
	halt.


