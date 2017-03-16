option mprint spool nocenter ls = max ps = 25;
/*Specify the path to My bag of sas lifehacks repository*/
%global path_to_repository;
%let path_to_repository =  C:\Users\DHasan\Documents\GitHub\My-bag-of-SAS-lifehacks ;


/*Specify where you would like to store the datasets*/
libname lib "&path_to_repository.\SAS dataset";

/* Include APPENDIX*/
%include "&path_to_repository.\Appendix.sas";

/* Include macro proramm SmokeOnTheWater*/
%include "&path_to_repository.\SmokeOnTheWater.sas";

/*read raw data*/
%read_csv;

/* Keep only needed VAEs*/
%keep_VAERS;

proc sql FEEDBACK noprint;

   create table VAERS_IDS as
      select data.* ,  case when .<vac.N_TAKEN_V <=1 then 'One' else 'Multiple' end as TAKEN, 
             input(calculated TAKEN, ? obs_taken.) as N_TAKEN
    from lib.vaccine2014_2017  as data
         natural left join
         ( select VAERS_ID, YEAR, count( distinct DISEASE) as N_TAKEN_V 
             from lib.vaccine2014_2017 group by VAERS_ID, YEAR 
         ) vac ;


   create table SE_TAB as        
    select YEAR, EMERGENT , DISEASE,  
	       count(distinct case when TAKEN = 'One'  then  VAERS_ID else . end) as ONE label = "ONE ",
           count(distinct case when TAKEN = 'Multiple' then  VAERS_ID else . end) as MUL label = "MULTIPLE"	 
	from VAERS_IDS    
    group by 1,2 ,3 
    order by 1,2;
 
quit;

proc sql noprint; 
   select distinct DISEASE into : All_VV separated by '" "' from SE_TAB where ONE>= 5 and MUL>= 5;
quit;
data MEET_VAC;
   set VAERS_IDS (where = (DISEASE in ("&All_VV")));
run;

data SAMPLE;
   set MEET_VAC;
COMMENT - Delete duplicated vaccines for one VAE;
proc sort dupout = DUP_VAC nodupkey;
   by DISEASE VAERS_ID;
proc freq noprint;
   by DISEASE;
   table N_TAKEN*EMERGENT_N /chisq relrisk;
   output out = TESTS chisq RELRISK;
run;

%macro check_dup_vac; 
   proc sql noprint;
      select count(*) into : _data_issue from dup_vac ;
   quit;
   %if &_data_issue %then %SmokeOnTheWater;
   %put &_data_issue;
%mend check_dup_vac;

%check_dup_vac;

data chisq_odds;
   set TESTS (keep = DISEASE _PCHI_ P_PCHI _CRAMV_ _RROR_ L_RROR U_RROR);
   length col1- col5 $100;
   col1 = strip(DISEASE); col2 = put(round(_PCHI_,.01), 8.2 -c);
   col3 = put(round(_CRAMV_,.01), 8.2 -c);
   col4 = put( _RROR_ , ODDSR8.3 -r)||' ('||put( L_RROR , ODDSR8.3 -c)||','||put( U_RROR , ODDSR8.3 -c)||')' ;
   col5 = put(round(P_PCHI,.01), PVALUE6.4 -l);
   label col1 = "Vaccines" col2 = 'Chi-Square' col3 = "Cramer's V%sysfunc(byte(178))" col4 = "Odds Ratio%sysfunc(byte(179)) ( 95% CI )" col5 = "p-value%sysfunc(byte(185)) ";
run;
title1 "Association between emergent VAERS and number of taken vaccinations.";
title2 "Populations infants in age 12-23 month.";
footnote1 "%sysfunc(byte(185))Corresponding p-value for Chi-Square statistic.";
footnote2 "%sysfunc(byte(178))the strenght measure of the assosiations that the Chi-Square test detected.";
footnote3 "%sysfunc(byte(179))the odds of emergent vaccination when it was received multiple vaccines to one vaccine.";
proc print data = chisq_odds  L;
   var col1-col5;
run;


%SmokeOnTheWater;
