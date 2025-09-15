ods noproctitle;

/* start macro variables *******************************************************************************************************/
%let pth = /home/u64271711/InternShip/Soroka_cw6;
%let cnow = 1;
/* end macro variables *******************************************************************************************************/

/* start macro programs *******************************************************************************************************/
%macro totobs(mydata);
	%let mydataID=%sysfunc(OPEN(&mydata.,IN));
	%let NOBS=%sysfunc(ATTRN(&mydataID,NOBS));
	%let RC=%sysfunc(CLOSE(&mydataID));
	&NOBS
%mend;
/* end macro programs *******************************************************************************************************/

/* start format *******************************************************************************************************/
proc format;
	value sur
	1 = 'Survived'
	0 = 'Deceased';
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
data Titanic_full_v1(drop=home_dest name survived);
	length embarked $ 200 gender $ 200;
	format embarked $20.;
	set Titanic_full;
	if embarked = 'C' then embarked = 'Cherbourg';
	else if embarked = 'S' then embarked = 'Southampton';
	else if embarked = 'Q' then embarked = 'Queenstown';
	else embarked = 'Missing';
	Survival = put(survived, sur.);
run;
proc sort data=Titanic_full_v1 out=Titanic_full_v1_srt;
	by class;
run;
/* end adding var *******************************************************************************************************/

/* start calculate macro var *******************************************************************************************************/
data _null_;
	set Titanic_full_v1_srt;
	by class;
	retain delta 1;
	if last.class then  do;
		call symputx('c' || cats(put(delta, 8.)), _n_);
		delta + 1;
	end;
run;
/* endalculate macro var *******************************************************************************************************/

/* start for age *******************************************************************************************************/
proc means data=Titanic_full_v1_srt noprint;
	var age;
	by class;
	output out=Titanic_full_age_class(drop=_type_ _freq_) n=n_num mean=Mean_num stddev=SD_num q1=Q1_num median=Median_num q3=Q3_num min=Min_num max=Max_num nmiss=Missing_num;
run;
proc means data=Titanic_full_v1_srt noprint;
	var age;
	output out=Titanic_full_age_total(drop=_type_ _freq_) n=n_num mean=Mean_num stddev=SD_num q1=Q1_num median=Median_num q3=Q3_num min=Min_num max=Max_num nmiss=Missing_num;
run;
data Titanic_full_age;
	set Titanic_full_age_class Titanic_full_age_total;
	if _n_ = %totobs(Titanic_full_age) then class = 4;
run;
data Titanic_full_age_rnd (drop=class n_num Mean_num SD_num Q1_num Median_num Q3_num Min_num Max_num Missing_num);
	length Age $ 200 n $ 200 Mean $ 200 SD $ 200 Q1 $ 200
		Median $ 200 Q3 $ 200 Min $ 200 Max $ 200 Missing $ 200 class_ch $ 200;
	Age = '';
	set Titanic_full_age;
	n = cats(put(n_num, 8.));
	Mean = cats(put(Mean_num, 8.1));
	SD = cats(put(SD_num, 8.3));
	Q1 = cats(put(Q1_num, 8.2));
	Median = cats(put(Median_num, 8.2));
	Q3 = cats(put(Q3_num, 8.2));
	Min = cats(put(Min_num, 8.1));
	Max = cats(put(Max_num, 8.1));
	Missing = cats(put(Missing_num, 8.));
	class_ch = cats(put(class, 8.));
run;
proc sort data=Titanic_full_age_rnd out=Titanic_full_age_srt;
	by class_ch Age n Mean SD Q1 Median Q3 Min Max Missing;
run;
proc transpose data=Titanic_full_age_srt out=Titanic_full_age_pre prefix=Class_;
	id class_ch;
	var Age n Mean SD Q1 Median Q3 Min Max Missing;
run;
data Titanic_full_age_out;
	length _name_ $ 200 Class_1 $ 200 Class_2 $ 200 Class_3 $ 200 Class_4 $ 200 now 8;
	set Titanic_full_age_pre;
	now = &cnow;
	%let cnow = &cnow + 1;
	if _n_ = %totobs(Titanic_full_age_out) then do;
		Class_1 = '  ' || Class_1;
		Class_2 = '  ' || Class_2;
		Class_3 = '  ' || Class_3;
		Class_4 = '  ' || Class_4;
	end;
run;
/* end for age *******************************************************************************************************/

/* start for gender *******************************************************************************************************/
proc freq data=Titanic_full_v1_srt noprint order=data;
	table Gender*class / out=Titanic_full_Gender ;
run;
data Titanic_full_Gender_frm(drop=count percent class);
	length gender $ 200 class_ch $ 200 fq_pt $ 200;
	set Titanic_full_Gender;	
	fq_pt = cat(cats(put(count, 15.)), ' (', cats(put(percent, 15.1)), '%)');
	class_ch = cats(put(class, 8.));
run;
proc sort data=Titanic_full_Gender_frm out=Titanic_full_Gender_sort;
	by gender class_ch fq_pt;  
run;
proc transpose data=Titanic_full_Gender_sort out=Titanic_full_Gender_tst1(drop=_name_) prefix=Class_;
	id class_ch;
	by gender;
	var fq_pt;
run;
data Titanic_full_Gender_tst2;
	set Titanic_full_Gender_tst1;
	Class_4 = cat(cats(put(input(scan(Class_1, 1, '(%)'), 15.) + input(scan(Class_2, 1, '(%)'), 15.) + input(scan(Class_3, 1, '(%)'), 15.), 15.)),
		' (',cats(put(input(scan(Class_1, 2, '(%)'), 15.1) + input(scan(Class_2, 2, '(%)'), 15.1) + input(scan(Class_3, 2, '(%)'), 15.1), 15.1)),
		'%)');
run;
proc sort data=Titanic_full_Gender_tst2 out=Titanic_full_Gender_sort2;
	by descending gender;
run;
data Titanic_full_Gender_out;
	length gender $ 200 Class_1 $ 200 Class_2 $ 200 Class_3 $ 200 Class_4 $ 200 now 8;
	if _n_ = 1 then gender = "Gender";
	now = &cnow;
	output;
	set Titanic_full_Gender_sort2;
	rename gender=_name_;
	now = &cnow;
	%let cnow = &cnow + 1;
run;
/* end for gender *******************************************************************************************************/

/* start for survival *******************************************************************************************************/
proc freq data=Titanic_full_v1_srt noprint order=data;
	table survival*class / out=Titanic_full_survival ;
run;
data Titanic_full_survival_frm(drop=count percent class);
	length survival $ 200 class_ch $ 200 fq_pt $ 200;
	set Titanic_full_survival;	
	fq_pt = cat(cats(put(count, 15.)), ' (', cats(put(percent, 15.1)), '%)');
	class_ch = cats(put(class, 8.));
run;
proc sort data=Titanic_full_survival_frm out=Titanic_full_survival_sort;
	by survival class_ch fq_pt;  
run;
proc transpose data=Titanic_full_survival_sort out=Titanic_full_survival_tst1(drop=_name_) prefix=Class_;
	id class_ch;
	by survival;
	var fq_pt;
run;
data Titanic_full_survival_tst2;
	set Titanic_full_survival_tst1;
	Class_4 = cat(cats(put(input(scan(Class_1, 1, '(%)'), 15.) + input(scan(Class_2, 1, '(%)'), 15.) + input(scan(Class_3, 1, '(%)'), 15.), 15.)),
		' (',cats(put(input(scan(Class_1, 2, '(%)'), 15.1) + input(scan(Class_2, 2, '(%)'), 15.1) + input(scan(Class_3, 2, '(%)'), 15.1), 15.1)),
		'%)');
run;
proc sort data=Titanic_full_survival_tst2 out=Titanic_full_survival_sort2;
	by descending survival;
run;
data Titanic_full_survival_out;
	length survival $ 200 Class_1 $ 200 Class_2 $ 200 Class_3 $ 200 Class_4 $ 200 now 8;
	if _n_ = 1 then survival = "survival";
	now = &cnow;
	output;
	set Titanic_full_survival_sort2;
	rename survival=_name_;
	now = &cnow;
	%let cnow = &cnow + 1;
run;
/* end for survival *******************************************************************************************************/

/* start for fare *******************************************************************************************************/
proc means data=Titanic_full_v1_srt noprint;
	var fare;
	by class;
	output out=Titanic_full_fare_class(drop=_type_ _freq_) n=n_num mean=Mean_num stddev=SD_num q1=Q1_num median=Median_num q3=Q3_num min=Min_num max=Max_num nmiss=Missing_num;
run;
proc means data=Titanic_full_v1_srt noprint;
	var fare;
	output out=Titanic_full_fare_total(drop=_type_ _freq_) n=n_num mean=Mean_num stddev=SD_num q1=Q1_num median=Median_num q3=Q3_num min=Min_num max=Max_num nmiss=Missing_num;
run;
data Titanic_full_fare;
	set Titanic_full_fare_class Titanic_full_fare_total;
	if _n_ = %totobs(Titanic_full_fare) then class = 4;
run;
data Titanic_full_fare_rnd (drop=class n_num Mean_num SD_num Q1_num Median_num Q3_num Min_num Max_num Missing_num);
	length fare $ 200 n $ 200 Mean $ 200 SD $ 200 Q1 $ 200
		Median $ 200 Q3 $ 200 Min $ 200 Max $ 200 Missing $ 200 class_ch $ 200;
	fare = '';
	set Titanic_full_fare;
	n = cats(put(n_num, 8.));
	Mean = cats(put(Mean_num, 8.1));
	SD = cats(put(SD_num, 8.3));
	Q1 = cats(put(Q1_num, 8.2));
	Median = cats(put(Median_num, 8.2));
	Q3 = cats(put(Q3_num, 8.2));
	Min = cats(put(Min_num, 8.1));
	Max = cats(put(Max_num, 8.1));
	Missing = cats(put(Missing_num, 8.));
	class_ch = cats(put(class, 8.));
run;
proc sort data=Titanic_full_fare_rnd out=Titanic_full_fare_srt;
	by class_ch fare n Mean SD Q1 Median Q3 Min Max Missing;
run;
proc transpose data=Titanic_full_fare_srt out=Titanic_full_fare_pre prefix=Class_;
	id class_ch;
	var fare n Mean SD Q1 Median Q3 Min Max Missing;
run;
data Titanic_full_fare_out;
	length _name_ $ 200 Class_1 $ 200 Class_2 $ 200 Class_3 $ 200 Class_4 $ 200 now 8;
	set Titanic_full_fare_pre;
	now = &cnow;
	%let cnow = &cnow + 1;
	if _n_ = %totobs(Titanic_full_fare_out) then do;
		Class_1 = '  ' || Class_1;
		Class_2 = '  ' || Class_2;
		Class_3 = '  ' || Class_3;
		Class_4 = '  ' || Class_4;
	end;
run;
/* end for fare *******************************************************************************************************/

/* start for Embarked *******************************************************************************************************/
proc freq data=Titanic_full_v1_srt noprint order=data;
	table Embarked*class / out=Titanic_full_Embarked;
run;
data Titanic_full_Embarked_frm(drop=count percent class);
	length Embarked $ 200 class_ch $ 200 fq_pt $ 200;
	set Titanic_full_Embarked;	
	fq_pt = cat(cats(put(count, 15.)), ' (', cats(put(percent, 15.1)), '%)');
	class_ch = cats(put(class, 8.));
run;
proc sort data=Titanic_full_Embarked_frm out=Titanic_full_Embarked_sort;
	by Embarked class_ch fq_pt;  
run;
proc transpose data=Titanic_full_Embarked_sort out=Titanic_full_Embarked_tst1(drop=_name_) prefix=Class_;
	id class_ch;
	by Embarked;
	var fq_pt;
run;
data Titanic_full_Embarked_tst2;
	set Titanic_full_Embarked_tst1;
	Class_4 = cat(cats(put(
	max(0, input(scan(Class_1, 1, '(%)'), 15.))
	+ max(0, input(scan(Class_2, 1, '(%)'), 15.))
	+ max(0, input(scan(Class_3, 1, '(%)'), 15.))
	, 15.)),' (',cats(put(
	max(0, input(scan(Class_1, 2, '(%)'), 15.1))
	+ max(0, input(scan(Class_2, 2, '(%)'), 15.1))
	+ max(0, input(scan(Class_3, 2, '(%)'), 15.1))
	, 15.1)),'%)');
run;
proc sort data=Titanic_full_Embarked_tst2 out=Titanic_full_Embarked_sort2;
	by descending Embarked;
run;
data Titanic_full_Embarked_out;
	length Embarked $ 200 Class_1 $ 200 Class_2 $ 200 Class_3 $ 200 Class_4 $ 200 now 8;
	Embarked = "Port of Embarkation";
	now = &cnow;
	output;
	set Titanic_full_Embarked_tst2;
	do row_index = 1, 3, 4, 2;
    	set Titanic_full_Embarked_tst2 point=row_index;
    	if class_1 = '' or class_1 = '. (.%)' then class_1 = '0 (0)';
    	if class_2 = '' or class_2 = '. (.%)' then class_2 = '0 (0)';
    	if class_3 = '' or class_3 = '. (.%)' then class_3 = '0 (0)';
    	now = &cnow;
    	output;
  	end;
  	rename Embarked=_name_;
	%let cnow = &cnow + 1;
  	stop;
run;
/* end for Embarked *******************************************************************************************************/

/* start creating t14_Soroka *******************************************************************************************************/
proc sort data=Titanic_full_Age_out out=Titanic_full_Age_out_srt;
	by now;
run;	
proc sort data=Titanic_full_Gender_out out=Titanic_full_Gender_out_srt;
	by now;
run;	
proc sort data=Titanic_full_Survival_out out=Titanic_full_Survival_out_srt;
	by now;
run;	
proc sort data=Titanic_full_Fare_out out=Titanic_full_Fare_out_srt;
	by now;
run;	
proc sort data=Titanic_full_Embarked_out out=Titanic_full_Embarked_out_srt;
	by now;
run;	
data Soroka.t14_Soroka(drop=now);
	length _name_ $ 200 class_1 $ 200 class_2 $ 200 class_3 $ 200 class_4 $ 200 tab 8;
	format _name_ $200.; 
 	merge Titanic_full_Age_out_srt
 		Titanic_full_Gender_out_srt
 		Titanic_full_Survival_out_srt
 		Titanic_full_Fare_out_srt
 		Titanic_full_Embarked_out_srt;
 		by now;
 	retain tab 0;
 	_name_ = propcase(_name_);
 	if _name_ = 'N' then _name_ = 'n';
 	if _name_ = 'Age' then _name_ = 'Age (years)';
 	if _name_ = 'Sd' then _name_ = 'SD';
 	if _name_ = 'Fare' then _name_ = 'Fare (pounds)';
 	if class_1 = class_2 = class_3 = class_4 then do;
 		_name_ = cats(_name_);
 		if _n_ ^= 1 then tab + 1;
 	end;
 	else _name_ = '  ' || _name_;
 	rename _name_ = var1
 	class_1 = var2
 	class_2 = var3
 	class_3 = var4
 	class_4 = var5;
run;
/* start creating t14_Soroka *******************************************************************************************************/

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
ods rtf file="&pth/t14_Soroka.rtf"
	style=intern startpage=never;
	options nodate nonumber 
	orientation=landscape papersize=(11in 8.5in)
	topmargin=1.25in bottommargin=0.8in 
	leftmargin=1in rightmargin=0.6in;
%let date = %sysfunc(date(),  DATE9.);
%let time = %sysfunc(time(), time5.);
%let pt1 = %sysevalf(&c2 - &c1);
%let pt2 = %sysevalf(&c3 - &c2);
title justify=right 'Page ^{thispage} of ^{lastpage}';
title2 justify=right "&date &time";
title3 justify=center 'Table 14. Demographic and Survival Characteristics of Titanic ';
title4 'Passengers Stratified by Class';
footnote justify=left "_____________________________________________________________________________________________________________________________";
footnote2 justify=left "N = Number of subjects within class.";
footnote3 justify=left "Reference: Listing 16";
/* start proc report *******************************************************************************************************/
proc report data=Soroka.t14_Soroka nowd spanrows  
	style(header)=[just=left height=0.5in] style(column)=[height=0.23in];
	column var1-var5 tab;
	define var1 / display 'Characteristic^n  Statistic';
	define var2 / display "Сlass 1^n(N=&c1.)" ;
	define var3 / display "Сlass 2^n(N=&pt1.)";
	define var4 / display "Сlass 3^n(N=&pt2.)" ;
	define var5 / display " Total^n(N=&c3.)" ;
	define tab / group noprint;
	compute before tab;
   		line ' ';  
	endcomp; 
run;
/* end proc report *******************************************************************************************************/
ods rtf close;
/* start creating report *******************************************************************************************************/

ods proctitle;
