ods noproctitle;

/* start macro variables *******************************************************************************************************/
%let pth = /home/u64271711/InternShip/Soroka_cw6;
/* end macro variables *******************************************************************************************************/

/* start format *******************************************************************************************************/
proc format;
	value YN_F
	1 = 'Yes'
	0 = 'No';
run;
/* end format *******************************************************************************************************/

/* start Create libref *******************************************************************************************************/
libname Soroka "&pth";
/* end Create libref *******************************************************************************************************/

/* start Import *******************************************************************************************************/
options validvarname=v7;
proc import datafile="&pth/test.csv"
	 		dbms=csv out=test replace;
	guessingrows=max;
run;
proc import datafile="&pth/titanic.csv"
	 		dbms=csv out=titanic replace;
	guessingrows=max;
run;
proc import datafile="&pth/titanic3.csv"
	 		dbms=csv out=titanic3 replace;
	guessingrows=max;
run;
proc import datafile="&pth/train.csv"
	 		dbms=csv out=train replace;
	guessingrows=max;
run;
/* end Import *******************************************************************************************************/

/* start creating merge var *******************************************************************************************************/
data train_test;
	set train test;
	if name ^= '' then name_nq = compress(name, '"');
	if age ^= . then age_r = round(age);
run;
data titanic;
	set titanic;
	if name ^= '' then name_nq = compress(name, '"');
	if age ^= . then age_r = round(age);
run;
data titanic3;
	set titanic3;
	where name is not missing;
	if name ^= '' then name_nq = compress(name, '"');
	if age ^= . then age_r = round(age);
run;
/* end creating merge var *******************************************************************************************************/

/* start data sorting *******************************************************************************************************/
proc sort data=titanic out=titanic_srt;by name_nq age_r ;run;
proc sort data=titanic3 out=titanic3_srt;by name_nq age_r ;run;
proc sort data=train_test out=train_test_srt;by name_nq age_r ;run;
/* end data sorting *******************************************************************************************************/

/* start merging *******************************************************************************************************/
data Titanic_full(drop=name_nq age_r);
	merge titanic_srt(in=in_main)
	train_test_srt(keep=name_nq age_r passengerid)
	titanic3_srt(keep=name_nq age_r embarked home_dest);
	by name_nq age_r;
	if in_main;
run;
/* end merging *******************************************************************************************************/

/* start adding var *******************************************************************************************************/
data Titanic_full_v1(drop=home_dest);
	length embarked $ 200 dmy $ 200 Home $ 200 Destination $ 200 
	name $ 200 gender $ 200 Title $ 200 AgeGroup $ 200;
	format embarked $20.;
	set Titanic_full;
	if Embarked in ('S', 'C') then Dmy=cat('10APR1912','(','14APR1912'd - '10APR1912'd, ')');
	else if Embarked='Q' then Dmy=cat('11APR1912','(','14APR1912'd - '11APR1912'd, ')');
	if embarked = 'C' then embarked = 'Cherbourg';
	else if embarked = 'S' then embarked = 'Southampton';
	else if embarked = 'Q' then embarked = 'Queenstown';
	PassengerID_Class = cat(passengerid,'-',Class);
	Title = scan(name, 2, ',.');
	if 0 <= Age <= 12 then AgeGroup = 'Child';
	else if 13 <= Age <= 18 then AgeGroup = 'Teen';
	else if 19 <= Age then AgeGroup = 'Adult';
	else agegroup = 'Unknowm';
	Home = scan(home_dest, 1, '/');
	Destination = scan(home_dest, -1, '/');
run;
/* end adding var *******************************************************************************************************/

/* start final table *******************************************************************************************************/
proc sort data=Titanic_full_v1 out=Titanic_full_v1_srt(drop=PassengerID);
	by Class PassengerID;
run;
data Soroka.l16_Soroka(drop=PassengerID_Class Age gender dmy survived Title AgeGroup Home Destination);
	length var1-var9 $ 200;
	set Titanic_full_v1_srt(keep=PassengerID_Class Age gender dmy survived Title AgeGroup Home Destination class);
	 var1 = PassengerID_Class;
	 var2 = cats(put(Age, best12.));
	 if gender = 'male' then var3 = 'M';
	 else if gender = 'female' then var3 = 'F';
	 var4 = cat(substr(dmy, 1, 9),' ',substr(dmy, 10, 3));
	 var5 = cats(put(survived, YN_f.));
	 var6 = Title;
	 var7 = AgeGroup;
	 var8 = Home;
	 var9 = Destination;
run;
/* end final table *******************************************************************************************************/

/* start creating template *******************************************************************************************************/
proc template;
	define style intern;
		parent=styles.rtf;

	style Table from output /
		background=_undef_
		Rules=groups
		Frame=hsides
		textalign=center
		font=("Courier New", 9pt)
		cellpadding = 0pt
		cellspacing = 0pt
		borderwidth = 0.25pt 
		width = 100%
		asis = on;
	style fonts from fonts /
		'docFont' = ("Courier New", 9pt); 
	style rowheader /
		background=white
		font=("Courier New", 9pt)
		asis=on;

	style header /
		font=("Courier New", 9pt)
		textalign=center
		verticalalign=center
		asis=on
		background=white;

	style systemtitle /
		font=("Courier New", 9pt);
	style systemfooter /
		font=("Courier New", 9pt)
		asis=on;
	style data from data /
		font=("Courier New", 9pt)
		verticalalign = m
		asis=on
		marginbottom = 0.8pt
		margintop = 1.25pt;
	replace Body from Document /
		 marginleft=1in
	     marginright=0.6in;
	end;
run;
/* end creating template *******************************************************************************************************/

/* start creating report *******************************************************************************************************/
ods escapechar='^';
ods rtf file="&pth/l16_Soroka.rtf" 
	style=intern startpage=never;
	options nodate nonumber 
	orientation=landscape papersize=(11in 8.5in)
	topmargin=1.25in bottommargin=0.8in 
	leftmargin=1in rightmargin=0.6in;
%let date = %sysfunc(date(),  DATE9.);
%let time = %sysfunc(time(), time5.);
title justify=right 'Page ^{thispage} of ^{lastpage}';
title2 justify=right "&date &time";
title3 justify=center 'Listing 16. Passenger Demographics,'
	'Travel Information, and Survival';
title4 'Status from the Titanic Dataset';
options nobyline;
title5 justify=left 'Class: #byval(Class)';
footnote justify=left "_____________________________________________________________________________________________________________________________";
footnote2 justify=left "&pth/Soroka_cw6.sas ran on &date at &time Programmer: Soroka Dmytro";
/* start proc report *******************************************************************************************************/
proc report data=Soroka.l16_Soroka style(header)=[vjust=bottom] style(column)=[height=40];
	by class;
	column var1-var9;
	define var1 / display 'PassengerID ^n^{unicode 002F} Class' left style(column)=[cellwidth=50] style(header)=[just=left];
	define var2 / display 'Age ^n(years) ' center style(column)=[cellwidth=30];
	define var3 / display 'Sex' center style(column)=[cellwidth=15];
	define var4 / display 'Boarding ^ndate (Days ^nat Sea)' left style(column)=[cellwidth=50] style(header)=[just=left];
	define var5 / display 'Did the Passenger ^nSurvive?' center style(column)=[cellwidth=80];
	define var6 / display 'Passenger ^nTitle' center style(column)=[cellwidth=70];
	define var7 / display 'AgeGroup' center style(column)=[cellwidth=70];
	define var8 / display 'Home' left style(column)=[cellwidth=75];
	define var9 / display 'Destination' left style(column)=[cellwidth=75];
run;
/* end proc report *******************************************************************************************************/
ods rtf close;
/* end creating report *******************************************************************************************************/

ods proctitle;
