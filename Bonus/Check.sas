/*Just coppy the program to the location where your log file is located */
/*Call a macro listed belowe with specifing name = name of your program  e.g:
   %pgm_log_SoundCheck(name= t_aae)
  Run the program and it'll create a new file with all founded errors. If there is no errors you'll heare the music.  
*/
%macro pgm_log_SoundCheck(name=);

data temp;
  infile "&name..log" missover  pad;
  input word $100.;
run;
 
data log_scan;
  set  temp (where=(
        index(upcase(word),'WARNING')>0 or
        index(upcase(word),"ERROR:")>0 or
        index(upcase(word),'OUTSIDE THE AXIS RANGE')>0 or
        index(upcase(word),"RETURNING PREMATURELY")>0 or
        index(upcase(word),'UNKNOWN MONTH FOR')>0 or
        index(upcase(word),'QUERY DATA') >0 or
        index(upcase(word),'??')>0 or
        index(upcase(word),'QUESTIONABLE')>0 or
        index(upcase(word),"UNINITIALIZED")>0 or
        index(upcase(word),"NOTE: MERGE")>0 or
		index(upcase(word),"NOTE: INVALID ARGUMENT TO FUNCTION INPUT")>0 or
		index(upcase(word),"NOTE: MISSING VALUES WERE GENERATED AS A RESULT OF PERFORMING AN OPERATION ON ")>0 or
        index(upcase(word), "MORE THAN ONE DATA SET WITH REPEATS OF BY")>0)) end=last;

  file print;

if index(word,'Unable to copy SASUSER registry to WORK registry') >0 then delete;
if index(word, ' put /') >0 then delete;
if index(word, 'The Base Product product with which')>0 then delete;
if index(word, 'expire within') > 0 then delete;


  put word;
  output;
  title "&sysdate &systime";
  title " LOG SCAN OF &name..log";
run;
proc sql noprint;
   select count(*) into : play from log_scan;
quit;

%if &play eq 0 %then %sevennationarmy;

%mend pgm_log_SoundCheck;

%macro SevenNationArmy;
   data _null_;
      do i = 1 to 4;
        CALL SOUND(329.628,390); CALL SOUND(329.628,175);
        CALL SOUND(391.995,230); CALL SOUND(329.628,180);
	    CALL SOUND(296.665,145); CALL SOUND(261.626,418);
	    CALL SOUND(246.942,425); CALL SOUND(0,15);
	   end;
    run; 
 %mend SevenNationArmy;
 
%pgm_log_SoundCheck(name=MAIN_PROGRAM);
