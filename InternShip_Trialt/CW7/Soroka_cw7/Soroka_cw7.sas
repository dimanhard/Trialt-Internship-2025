ods noproctitle;

/*import data start**************************************************************************************************/
libname Soroka "/home/u64271711/InternShip/Soroka_cw7";
options validvarname=v7;
proc import datafile="/home/u64271711/InternShip/Soroka_cw7/titanic.csv"
	dbms=csv replace out=titanic;
		guessingrows=max;
run;
/*import data end**************************************************************************************************/

/* start macro programs *******************************************************************************************************/
%macro totobs(mydata);
	%let mydataID=%sysfunc(OPEN(&mydata.,IN));
	%let NOBS=%sysfunc(ATTRN(&mydataID,NOBS));
	%let RC=%sysfunc(CLOSE(&mydataID));
	&NOBS
%mend;
/* end macro programs *******************************************************************************************************/

/*creating format start**************************************************************************************************/
proc format;
	value cls 
	1='First'
	2='Second'
	3='Third';
	value sur 
	1='Survived'
	0='Died';
	value geosur 
	1='Survived (GeoMean)'
	0='Died (GeoMean)';
run;
/*creating format end**************************************************************************************************/

/*creating aditionat tables start**************************************************************************************************/
data titanic_log;
	set titanic;
	if age > 0 then ln_age=log(age);
run;
proc sort data=titanic_log out=titanic_sort;
	by class survived;
run;
proc means data=titanic_sort noprint;
	class class survived;
	var ln_age;
	output out=meansout(drop=_type_ _freq_ where=(class is not missing
  and survived is not missing)) mean=Gmean;
run;
proc means data=titanic_sort noprint;
  class class survived;
  var age;
  output out=basic_means(drop=_type_ _freq_ where=(class is not missing
  and survived is not missing)) mean=Bmean;
run;
data all_mean(drop=Gmean);
	merge basic_means(in=main_tab)
	meansout;
	by class survived;
	if main_tab;
	geo_mean=round(exp(Gmean), 0.01);
	Bmean = round(Bmean, 0.01);
	if survived = 1 then do;
		BmeanS = Bmean;
		GmeanS = geo_mean;
	end;
	else if survived = 0 then do;
		BmeanD = Bmean;
		GmeanD = geo_mean;
	end;
run;
data titanic_out;
	merge titanic_sort(in=main_tab)
	all_mean;
	by class survived;
	if main_tab;
	Surviving = Survived;
run;
/*creating aditionat tables end**************************************************************************************************/

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

/*creating report**************************************************************************************************/
ods rtf file="/home/u64271711/InternShip/Soroka_cw7/f1_Soroka.rtf"
	style=intern startpage=never bodytitle nogtitle nogfootnote;
	options nodate nonumber 
	orientation=landscape papersize=(11in 8.5in)
	topmargin=1.25in bottommargin=0.8in 
	leftmargin=1in rightmargin=0.6in;
%let date = %sysfunc(date(),  DATE9.);
%let time = %sysfunc(time(), time5.);
%let tot = %totobs(titanic_out);
title justify=right 'Soroka Dmytro';
title2 justify=right "&date &time";
title3 justify=center "Passengers on Titanic (N=&tot.)";
title4 'Figure 1. Distribution of age by class and survival status';
footnote justify=left 'Note: The plot displays Age'
	'values for the full dataset without percentile '
	'filtering. Diamonds indicate the geometric mean for Age>0.';
/*start sgplot**************************************************************************************************/
ods graphics / height=4.5in width=7.765in;
proc sgplot  data=titanic_out noautolegend noborder;
	format class cls. survived sur. Surviving geosur.;
	vbox age / group=survived category=class
			boxwidth=0.3  meanattrs=(size=0)
			name="boxes" outlierattrs=(symbol=circle);
	xaxis label="Pclass";
    yaxis label="Age" grid;
	scatter x=Class y=BmeanD /
            markerattrs=(symbol=circle)
            discreteoffset=-0.18
            nomissinggroup group=Survived;
    scatter x=Class y=BmeanS /
            markerattrs=(symbol=plus)
            discreteoffset=0.18
            nomissinggroup group=Survived ;
    scatter x=Class y=GmeanD /
            markerattrs=(symbol=diamondfilled size=5)
            discreteoffset=-0.18 datalabel
            nomissinggroup group=Surviving
            datalabelattrs=(Color=black weight=bold size=0.15in) datalabelpos=left;
    format GmeanS 8.2;
    scatter x=Class y=GmeanS /
            markerattrs=(symbol=diamondfilled size=5)
            discreteoffset=0.18 datalabel	
            nomissinggroup group=Surviving
            datalabelattrs=(Color=black weight=bold size=0.15in) datalabelpos=right
            name="geo";
     
     keylegend "boxes" "geo"  / noborder;
run;
  ods graphics off;
/*end sgplot**************************************************************************************************/

ods rtf close;
/*close report**************************************************************************************************/

ods proctitle;