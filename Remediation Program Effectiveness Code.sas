Libname JBlib '\\lansaspd1\Research\Jill Budden\JillB\Remediation';
data work.analyses;
	set JBlib.Licensure_recidivism_Data_SAS;

/* Analysis variable names

jurisdiction
ExpirationDate_ANALYSIS_VARIABLE (license expiration date)
ExpiredLicence_y_n_ANALYSIS_VARI (license expired - yes vs no)
DateForAnayses_Completion_And_Da (Date of discipline or date recidivism program completed)
SubsequentComplants_y_n_ANALYSIS (recidivism - yes vs no)
SubsequentNum_ANALYSIS_VARIABLE  (number of recidivisms: 0 - 4)
SubsequentDate1_ANALYSIS_VARIABL (date of first recidivism)

SubsequentComplants_y_n_Nursys
Nursys_Subsequent_Date	
Nursys_SubsequentDate_None

EmploymentStatusAtTimeReferal_NC

*/

/* clean data */
if ExpiredLicence_y_n_ANALYSIS_VARI = "Not expired" then ExpiredLicence_y_n_ANALYSIS_VARI = "not expired";

if EmploymentStatusAtTimeReferal_NC = "Termiated contract" then EmploymentStatusAtTimeReferal_NC = "Terminated";
if EmploymentStatusAtTimeReferal_NC = "Terminiated contract" then EmploymentStatusAtTimeReferal_NC = "Terminated";
if EmploymentStatusAtTimeReferal_NC = "Terminiated" then EmploymentStatusAtTimeReferal_NC = "Terminated";
if EmploymentStatusAtTimeReferal_NC = "contract terminiated" then EmploymentStatusAtTimeReferal_NC = "Terminated";

if Nursys_SubsequentDate_None = " " and SubsequentComplants_y_n_ANALYSIS = "Yes" then Nursys_SubsequentDate_None = "NursysDate";

/* remove individuals who did not complete B's remediation program */
if DateForAnayses_Completion_And_Da = " " then delete;

/* create censor variables for time series */
if ExpiredLicence_y_n_ANALYSIS_VARI = "not expired" then censor_licensure = 0;
if ExpiredLicence_y_n_ANALYSIS_VARI = "expired" then censor_licensure = 1;

if SubsequentDate1_ANALYSIS_VARIABL NOT in (2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016) then censor_recidivism1 = 0;
if SubsequentDate1_ANALYSIS_VARIABL in (2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016) then censor_recidivism1 = 1;

if SubsequentComplants_y_n_Nursys = "No" then censor_recidivism2 = 0;
if SubsequentComplants_y_n_Nursys = "Yes" then censor_recidivism2 = 1;

/* create days variables for time series */
days_licensure = ExpirationDate_ANALYSIS_VARIABLE - DateForAnayses_Completion_And_Da;

start_year_for_recidivism = YEAR(DateForAnayses_Completion_And_Da);
years_recidivism = SubsequentDate1_ANALYSIS_VARIABL - start_year_for_recidivism;
days_recidivism1 = (years_recidivism * 365);

days_recidivism2 = Nursys_Subsequent_Date - DateForAnayses_Completion_And_Da;

/* remove negative days */
if days_licensure < 0 then days_licensure = .;
if days_recidivsm1 < 0 then days_recidivsm = .;
if days_recidivsm2 < 0 then days_recidivsm = .;

/****************ANALYSES******************/

/* Chi-square analyses - expired vs not expired license by state */
ods graphics on;
proc freq data=analyses;
	tables (ExpiredLicence_y_n_ANALYSIS_VARI)*(jurisdiction) / chisq
 	plots=(freqplot(twoway = grouphorizontal scale = percent));
run;
ods graphics off;

/* Chi-square analyses - recidivism yes vs no by state */
ods graphics on;
proc freq data=analyses;
	tables (SubsequentComplants_y_n_ANALYSIS)*(jurisdiction) / chisq
 	plots=(freqplot(twoway = grouphorizontal scale = percent));
run;
ods graphics off;

ods graphics on;
proc freq data=analyses;
	tables (SubsequentComplants_y_n_Nursys)*(jurisdiction) / chisq
 	plots=(freqplot(twoway = grouphorizontal scale = percent));
run;
ods graphics off;

/* Survival analysis for days to licensure lapse by state */

ods graphics on;
proc lifetest data=analyses plots=s;
	time days_licensure * censor_licensure(0); 
	strata jurisdiction;
run; 
ods graphics off;

/* Survival analysis for days to recidivism by state */

ods graphics on;
proc lifetest data=analyses plots=s;
	time days_recidivism1 * censor_recidivism1(0); 
	strata jurisdiction;
run; 
ods graphics off; 

ods graphics on;
proc lifetest data=analyses plots=s;
	time days_recidivism2 * censor_recidivism2(0); 
	strata jurisdiction;
run; 
ods graphics off; 

/* Descriptive */

PROC SQL;
	CREATE VIEW WORK.SORT1 AS
		SELECT EmploymentStatusAtTimeReferal_NC
	FROM WORK.analyses;
QUIT;

Title 'NC Terminated at Time of Referal';
PROC FREQ DATA = WORK.SORT1
	ORDER=INTERNAL;
	TABLES EmploymentStatusAtTimeReferal_NC / NOROW NOCUM SCORES=TABLE;
RUN;

PROC SQL;
	CREATE VIEW WORK.SORT2 AS
		SELECT Nursys_SubsequentDate_None
	FROM WORK.analyses;
QUIT;

Title 'NC Nursys with Recidivsm - No Public Data in Nursys';
PROC FREQ DATA = WORK.SORT2
	ORDER=INTERNAL;
	TABLES Nursys_SubsequentDate_None / NOROW NOCUM SCORES=TABLE;
RUN;



