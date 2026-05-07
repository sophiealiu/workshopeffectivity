**************************************************************
Author: Sophie A. Liu
Date: 3/17/2026
**************************************************************
AMERICORPS MH DATA ANALYSIS 2.0: 
*************************************************************;
LIBNAME aries '/home/u64467553/sasuser.v94/data/';
PROC IMPORT DATAFILE= '/home/u64467553/sasuser.v94/data/Sewa26_data(neurodiv).csv'
    OUT=work.ND
    DBMS=csv
    REPLACE;
    GETNAMES=YES;
RUN;

PROC IMPORT DATAFILE= '/home/u64467553/sasuser.v94/data/Sewa26_data(gut-brain).csv'
    OUT=work.GB
    DBMS=csv
    REPLACE;
    GETNAMES=YES;
RUN;

PROC IMPORT DATAFILE= '/home/u64467553/sasuser.v94/data/Sewa26_data(tech).csv'
    OUT=work.tech
    DBMS=csv
    REPLACE;
    GETNAMES=YES;
RUN;


/* cleaning */
data ND_cl;
	set ND;
	pre_correct = 0;
	post_correct = 0;
	improve = 0;
	
	if pre_q1 = 'D' then pre_correct + 1; if post_q1 = 'C' then post_correct + 1;
	if pre_q2 = 'D' then pre_correct + 1; if post_q2 = 'C' then post_correct + 1;
	if pre_q3 = 'A' then pre_correct + 1; if post_q3 = 'D' then post_correct + 1;
	
	change_ans = (post_correct - pre_correct);
	improve = change_ans + (post_q4 - pre_q4);
	if Learn = 'yes' then improve + 1;
	
	if improve = . then delete;
	if improve >= 2 then thresh = 1;
		else thresh = 0;
	keep name topic age_group learn improve thresh;

data GB_cl;
	set GB;
	pre_correct = 0;
	post_correct = 0;
	improve = 0;
	
	if pre_q1 = 'D' then pre_correct + 1; if post_q1 = 'C' then post_correct + 1;
	if pre_q2 = 'C' then pre_correct + 1; if post_q2 = 'C' then post_correct + 1;
	if pre_q3 = 'A' then pre_correct + 1; if post_q3 = 'D' then post_correct + 1;
	
	change_ans = (post_correct - pre_correct);
	improve = change_ans + (post_q4 - pre_q4);
	if Learn = 'yes' then improve + 1;
	if post_q4 = . then delete;
	
	if improve >= 2 then thresh = 1;
		else thresh = 0;
	keep name topic age_group learn improve thresh;

data tech_cl;
	set tech;
	pre_correct = 0;
	post_correct = 0;
	improve = 0;
	
	if pre_q1 = 'B' then pre_correct + 1; if post_q1 = 'C' then post_correct + 1;
	if pre_q2 = 'D' then pre_correct + 1; if post_q2 = 'C' then post_correct + 1;
	if pre_q3 = 'D' then pre_correct + 1; if post_q3 = 'D' then post_correct + 1;
	
	change_ans = (post_correct - pre_correct);
	improve = change_ans + (post_q4 - pre_q4);
	if Learn = 'yes' then improve + 1;
	if post_q4 = . then delete;
	
	if improve >= 2 then thresh = 1;
		else thresh = 0;
	keep name topic age_group learn improve thresh;

*******************************************;
/* making an overall dataset */
data agg;
	set ND_cl GB_cl tech_cl;

/* summary stats */
proc sgpie data=ND_cl;
	title2 height=30pt 'Neurodiversity';
	styleattrs backcolor=lightblue;
    pie Learn /
    	datalabelattrs=(size=30 weight=bold);

proc sgpie data=GB_cl;
	title2 height = 30pt 'GBition and the Gut-Brain Connection';
	styleattrs backcolor=lightblue;
    pie Learn /
    	datalabelattrs=(size=30 weight=bold);

proc sgpie data=tech_cl;
	title2 height = 30pt'Technology mental effects';
	styleattrs backcolor=lightblue;
    pie Learn /
    	datalabelattrs=(size=30 weight=bold);


title height=14pt 'Effectivity of Workshops';
title;

proc means data = ND_cl; var improve;
title2 height=12pt 'Neurodiversity';

proc means data = GB_cl; var improve;
title2 height=12pt 'GBition and the gut-brain connection';

proc means data = tech_cl;var improve;
title2 height=12pt 'Technology mental health effects';

proc means data = agg;var improve;
title2 height=12pt 'Overall';

*******************************************;
*/ overall improvement *;
ods graphics on;
proc sgplot data=agg;
    histogram improve / binwidth=1;
    yaxis labelattrs=(size=14pt weight=bold);
    xaxis labelattrs=(size=16pt);
    xaxis values=(-5 to 6 by 1);

*/ by topic improvement */;
proc sgplot data=agg;
    vbox improve / category=topic;
	label improve ="Score change from pre-to-post Survey (by topic)";
    /* Draws a line at 0 on the vertical (value) axis */
    refline 0 / axis=y lineattrs=(pattern=solid color=red); 
    yaxis labelattrs=(size=14pt weight=bold);
    xaxis labelattrs=(size=16pt)
    	valueattrs=(size=14 weight=bold);
run;
    
ods graphics off;

*******************************************;
/* hypothesis testing */
/* do people meet threshold? OVERALL*/
proc freq data=agg;
   tables thresh / binomial(p=0.3) /* ideal 70% improved*/
   exact binomial; 
proc freq data=GB_cl;
   tables thresh / binomial(p=0.3) /* ideal 70% improved*/
   exact binomial; 
proc freq data=tech_cl;
   tables thresh / binomial(p=0.3) /* ideal 70% improved*/
   exact binomial; 

/* does pass rate differ amongst topics? */
proc freq data=agg;
   tables topic*thresh / chisq;
run;

/* regression model */
ods graphics on / reset=all;
title 'Average improvement by topic';
proc glm data=agg plots = diagnostics;
    class topic;
    model improve = topic;
    means topic / tukey;
    
    *making it pretty;
    label topic ="Topic";
    label improve = "Improvement Score";
run;

ods graphics off;
