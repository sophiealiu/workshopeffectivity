**************************************************************
Author: Sophie A. Liu
Date: 3/2/3026
**************************************************************
AMERICORPS MH DATA ANALYSIS: 
*************************************************************;
* LIBNAME myData '/home/u64467553/sasuser.v94/data/';

PROC IMPORT DATAFILE= '/home/u64467553/sasuser.v94/data/Sewa_2026(3).csv'
    OUT=work.Sewa
    DBMS=csv
    REPLACE;
    GETNAMES=YES;
RUN;

*/ cleaning;
data gut_brain01;
	set Sewa;
	where topic = 'Nutrition';
	pre_correct = 0;
	post_correct = 0;
	if pre_q1 = 'D' then pre_correct = pre_correct + 1;
	if post_q1 = 'D' then post_correct = post_correct + 1;
	if pre_q2 = 'C' then pre_correct = pre_correct + 1;
	if post_q2 = 'C' then post_correct = post_correct + 1;
	if pre_q3 = 'A' then pre_correct = pre_correct + 1;
	if post_q3 = 'A' then post_correct = post_correct + 1;
	
	change_ans = (post_correct - pre_correct);
	improvement = change_ans + (post_q4 - pre_q4);
	if Learn = 'yes' then improvement + 1;
	if improvement = . then delete;

data neuro01;
	set Sewa;
	where topic = 'Neurodiversity';
	pre_correct = 0;
	post_correct = 0;
	if pre_q1 = 'D' then pre_correct = pre_correct + 1;
	if post_q1 = 'D' then post_correct = post_correct + 1;
	if pre_q2 = 'D' then pre_correct = pre_correct + 1;
	if post_q2 = 'D' then post_correct = pos	L;correct + 1;
	\\\\\\\\\\\\\\\\\\\\npre_correct = pre_correct + 1;
	if post_q3 = 'A' then post_correct = post_correct + 1;
	
	change_ans = (post_correct - pre_correct);
	improvement = change_ans + (post_q4 - pre_q4);
	if Learn = 'yes' then improvement + 1;
	if improvement = . then delete;
	
data teen02;
	set Sewa;
	where topic = 'Teen MH';
	pre_correct = 0;
	post_correct = 0;
	if pre_q1 = 'D' then pre_correct = pre_correct + 1;
	if post_q1 = 'D' then post_correct = post_correct + 1;
	if pre_q2 = 'C' then pre_correct = pre_correct + 1;
	if post_q2 = 'C' then post_correct = post_correct + 1;
	if pre_q3 = 'A' then pre_correct = pre_correct + 1;
	if post_q3 = 'A' then post_correct = post_correct + 1;
	
	change_ans = (post_correct - pre_correct);
	improvement = change_ans + (post_q4 - pre_q4);
	if Learn = 'yes' then improvement + 1;
	if improvement = . then delete;

*/ generating summary stats;
data aggregate;
	set gut_brain01 neuro01 teen02;

*title height=28pt 'Did you learn something today?';
proc sgpie data=aggregate;
	title2 height=30pt 'Overall';
	styleattrs backcolor=lightblue datacolors=(orange blue);
    pie Learn /
    	datalabelattrs=(size=30 weight=bold);

proc sgpie data=gut_brain01;
	title2 height = 30pt 'Nutrition and the Gut-Brain Connection';
	styleattrs backcolor=lightblue;
    pie Learn /
    	datalabelattrs=(size=30 weight=bold);

proc sgpie data=neuro01;
	title2 height = 30pt'Neurodivergence';
	styleattrs backcolor=lightblue;
    pie Learn /
    	datalabelattrs=(size=30 weight=bold);

proc sgpie data=teen02;
	title2 height = 30pt'Healthy Relationships and Teenage Mental Health';
	styleattrs backcolor=lightblue;
    pie Learn /
    	datalabelattrs=(size=30 weight=bold);

title 'Effectivity of Mental Health Workshops';
ods graphics on;
proc sgplot data=aggregate;
    vbox improvement / category=topic;
	label improvement ="Score change from Pre-to-Post Survey";
    /* Draws a line at 0 on the vertical (value) axis */
    refline 0 / axis=y lineattrs=(pattern=solid color=red); 
    yaxis labelattrs=(size=14pt weight=bold);
    xaxis labelattrs=(size=16pt)
    	valueattrs=(size=14 weight=bold);
run;
ods graphics off;

*************************************************************
*regression model ******************************************;
*cleaning first;
proc means data = aggregate noprint;
	class name;
	var improvement;
	output out=no_reps mean=avg_score;
	
proc sort data = aggregate out = clean_agg nodupkey;
	by name;

/* data final_agg; */
/*     merge clean_agg no_reps; */
/*     by name; */
/*     keep age_group name avg_score; */
/* run; */

/* more summary stats */
proc means data = aggregate;
	class age_group;
	var improvement;
/* proc means data = final_agg; INCORRECT TO AVG!*/
/* 	class age_group; */
/* 	var avg_score; */

*actual model time! yay;
/* proc contents data=final_agg; */
ods graphics on / reset=all;
title 'Average Improvement by Age Group';
proc glm data=aggregate plots = diagnostics;
    class age_group;
    model improvement = age_group;
    means age_group / tukey;
    
    *making it pretty;
    label age_group ="Age Group";
    label improvement = "Improvement Score";
run;

ods graphics off;

/* multivariate analysis */
proc glm data=aggregate plots = diagnostics;
    class age_group topic;
    model improvement = age_group * topic;
