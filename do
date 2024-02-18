clear all

cd  "*" //location 

clear all
use final.dta
xtset id year

*0 global varlabels set
global depvar "logNGPExport"
global depvar_r "logNGPQty"

global iv "logGdensity"
global indpvar "GCI_stdv"

global cotrol_fix "logIESize logIEInno logLogis logFDI logDIG logGovern logOpeness" 
global cotrol_fix2 "logOpeness logGNP logFDI logDIG logLogis"
global cotrol_add "logIESize logIEInno logLogis logFDI logDIG logGovern logOpeness logPatMarketing logIndustryCluster logPAT logGNP"

*1 Descriptive statistics
sum2docx $depvar $indpvar $iv logPAT  logLCIStruct  logER logGreenLoan $cotrol_fix using      ///
        1.docx, replace stats(N mean(%9.2f) sd(%9.2f) min(%9.2f) max(%9.2f)) title("Table 1 Descriptive statistics")

*2 Benchmark regression
reghdfe $depvar $indpvar $cotrol_fix, absorb(id year) vce(cluster id)
estimates store a1
ivreghdfe $depvar $cotrol_fix ( $indpvar = $iv ),a(id year) cluster(id)  endog($indpvar) first savefirst savefprefix(f)
estimates store a2
estadd scalar F = `e(widstat)' : fGCI_stdv
esttab fGCI_stdv a2 using basic.doc, scalar(F) replace drop($ctrl)

local s "using Table 2.rtf" 
//add   using ols.rtf                  
esttab   a1 a2  `s',  title("BASIC RG") ///
         cells(b(star fmt(%9.3f)) se(par)) ///
         stats(FE FE N r2 F, fmt(%9.0f %9.0g) label("ID_FE" "YEAR_FE" "N" "R^2" "F")) ///
         legend collabels(none) varlabels(_cons Constant) ///
		 keep($indpvar $iv $cotrol_fix) order($indpvar $iv $cotrol_fix) ///
		 star(* 0.1 ** 0.05 *** 0.01) 	
	 
*3 Robustness test
*3.1*Replacing the explained variable	 
reghdfe $depvar_r $indpvar $cotrol_fix, absorb(id year) vce(cluster id)
estimates store b1
ivreghdfe $depvar_r $cotrol_fix ( $indpvar = $iv ),a(id year) cluster(id) first endog($indpvar)
estimates store b2
*3.2*Adding control variables                                        
reghdfe $depvar $indpvar $cotrol_add, absorb(id year) vce(cluster id)
estimates store b3
ivreghdfe $depvar $cotrol_add ( $indpvar = $iv ),a(id year) cluster(id) first
estimates store b4
*3.3*Excluding municipalities
drop if id == 1 | id == 2 | id == 9 | id == 22
reghdfe $depvar $indpvar $cotrol_fix, absorb(id year) vce(cluster id)
estimates store b5
ivreghdfe $depvar $cotrol_fix ( $indpvar = $iv ),a(id year) cluster(id) first endog($indpvar)
estimates store b6
local s "using Table Robustness.rtf" 
//add   using ols.rtf                  
esttab   b1 b2 b3 b4 b5 b6  `s',  title("BASIC RG") ///
         cells(b(star fmt(%9.3f)) se(par)) ///
         stats(FE FE N r2 F, fmt(%9.0f %9.0g) label("ID_FE" "YEAR_FE" "N" "R^2" "F")) ///
         legend collabels(none) varlabels(_cons Constant) ///
		 keep($indpvar $iv $cotrol_add) order($indpvar $iv $cotrol_add) ///
		 star(* 0.1 ** 0.05 *** 0.01) 	
*3.4*winsor
clear all
use final.dta
xtset id year

winsor2 $depvar , replace cuts(1 99) trim
winsor2 $indpvar , replace cuts(1 99) trim
winsor2 $cotrol_fix, replace cuts(1 99) trim
winsor2 $iv, replace cuts(1 99) trim
reghdfe $depvar $indpvar $cotrol_fix, absorb(id year) vce(cluster id)
estimates store b7
ivreghdfe $depvar $cotrol_fix ( $indpvar = $iv ),a(id year) cluster(id) first
estimates store b8

local s "using winsor.rtf"                 
esttab   b7 b8 `s',  title("BASIC RG") ///
         cells(b(star fmt(%9.3f)) se(par)) ///
         stats(Controls FE FE N r2 F, fmt(%9.0f %9.0g) label("Controls" "ID_FE" "YEAR_FE" "N" "R^2" "F")) ///
         legend collabels(none) varlabels(_cons Constant) ///
		 keep($indpvar $iv) order($indpvar $iv) ///
		 star(* 0.1 ** 0.05 *** 0.01) 
		 
clear all
use final.dta
xtset id year

winsor2 $depvar , replace cuts(5 95) trim
winsor2 $indpvar , replace cuts(5 95) trim
winsor2 $cotrol_fix, replace cuts(5 95) trim
winsor2 $iv, replace cuts(5 95) trim
reghdfe $depvar $indpvar $cotrol_fix, absorb(id year) vce(cluster id)
estimates store b9
ivreghdfe $depvar $cotrol_fix ( $indpvar = $iv ),a(id year) cluster(id) first
estimates store b10

local s "using winsor2.rtf"                 
esttab   b9 b10 `s',  title("BASIC RG") ///
         cells(b(star fmt(%9.3f)) se(par)) ///
         stats(Controls FE FE N r2 F, fmt(%9.0f %9.0g) label("Controls" "ID_FE" "YEAR_FE" "N" "R^2" "F")) ///
         legend collabels(none) varlabels(_cons Constant) ///
		 keep($indpvar) order($indpvar) ///
		 star(* 0.1 ** 0.05 *** 0.01) 
		 
*4 Discussing endogenous reciprocal causation
clear all
use final.dta
xtset id year
encode Region,gen(Region2)
rangestat(mean) GCI_stdv,interval(year 0 0) by(Region2) excludeself
ivreghdfe $depvar $cotrol_fix ($indpvar= $iv GCI_stdv_mean), absorb(id year) cluster (id) endog($indpvar) first savefirst savefprefix(f)
eststo
estadd scalar F = `e(widstat)' : fGCI_stdv
esttab fGCI_stdv est1 using iv.doc, scalar(F) replace drop($ctrl)




*5 Driving channel test
clear all
use final.dta
xtset id year
est clear

global media "logKLStruct "
reg3 ($depvar $media $cotrol_fix i.id ) ($media $indpvar $cotrol_fix i.id)($indpvar $iv $cotrol_fix i.id)
estimates store m1

global media "logLCIStruct "
reg3 ($depvar $media $cotrol_fix i.id ) ($media $indpvar $cotrol_fix i.id)($indpvar $iv $cotrol_fix i.id)
estimates store m2

global media "logIMStruct_pca "
reg3 ($depvar $media $cotrol_fix i.id ) ($media $indpvar $cotrol_fix i.id)($indpvar $iv $cotrol_fix i.id)
estimates store m3

global media "logPAT"
reg3 ($depvar $media $cotrol_fix i.id ) ($media $indpvar $cotrol_fix i.id)($indpvar $iv $cotrol_fix i.id)
estimates store m4

outreg2 [m4 m2] using Table 3 Driving channel test.doc , e(r2_a,F) bdec(4) sdec(2)

*6 Moderating effect test
clear all
use final.dta
xtset id year
est clear
*6.1*Main effects
reghdfe $depvar $indpvar $cotrol_fix, absorb(id year) vce(cluster id)
estimates store m1
*Moderation by environmental regulation
global tiaojie "logER"
reghdfe $depvar $tiaojie c.$tiaojie#c.$indpvar $indpvar $cotrol_fix, absorb(id year) vce(cluster id)
est sto regression 
*6.2*Loops and margins need to be executed together
foreach v of var $tiaojie $indpvar {
  su `v' if e(sample)
  local low_`v'=r(mean)-r(sd)
  display `low_`v''
  local high_`v'=r(mean)+r(sd)
  display `high_`v''
}
est restore regression //Pulling saved regression results
margins , at($indpvar = (`low_GCI_stdv' `high_GCI_stdv') ///
             $tiaojie = (`low_logER' `high_logER'))  //Calculation of marginal effects, x before mediation)
marginsplot , xlabel(-1.5 " " `low_GCI_stdv' "Low IV" `high_GCI_stdv' "High IV" 1.5 " ")  ///
              ytitle("logNGPExport")       ///
			  xtitle("GCI_stdv")   ///
              ylabel(5(1)11, angle(0) nogrid) ///
              legend(order(1 "Low_logER" 2 "High_logER") ///
			  position(3) col(1) stack)   ///
              title("") noci ///
			  scheme(lean1)			  

graph export margin_er.tif, replace

*6.3*Moderation by green credit
global tiaojie "logGreenLoan" 
reghdfe $depvar $tiaojie c.$tiaojie#c.$indpvar $indpvar $cotrol_fix, absorb(id year) vce(cluster id)
est sto regression2 
foreach v of var $tiaojie $indpvar {
  su `v' if e(sample)
  local low_`v'=r(mean)-r(sd)
  display `low_`v''
  local high_`v'=r(mean)+r(sd)
  display `high_`v''
}
est restore regression2 
margins , at($indpvar = (`low_GCI_stdv' `high_GCI_stdv') ///
             $tiaojie = (`low_logGreenLoan' `high_logGreenLoan'))  
marginsplot , xlabel(-1.5 " " `low_GCI_stdv' "Low IV" `high_GCI_stdv' "High IV" 1.5 " ")  ///
              ytitle("logNGPExport")       ///
			  xtitle("GCI_stdv")   ///
              ylabel(5(1)11, angle(0) nogrid) ///
              legend(order(1 "Low_logGreenLoan" 2 "High_logGreenLoan") ///
			  col(1) pos(3) stack )   ///
              title("") noci ///
			  scheme(lean1)			  

graph export margin_gl.tif, replace

local s "using Table 4 Moderating effect test.rtf"                 
esttab   m1 regression regression2 `s',  title("RG") ///
         cells(b(star fmt(%9.3f)) se(par)) ///
         stats(Controls FE FE N r2 F, fmt(%9.0f %9.0g) label("Controls" "ID_FE" "YEAR_FE" "N" "R^2" "F")) ///
         legend collabels(none) varlabels(_cons Constant) ///
		 keep(GCI_stdv logER c.logER#c.GCI_stdv logGreenLoan c.logGreenLoan#c.GCI_stdv) order(GCI_stdv logER c.logER#c.GCI_stdv logGreenLoan c.logGreenLoan#c.GCI_stdv) ///
		 star(* 0.1 ** 0.05 *** 0.01) 
		 


		 
		 
*7 Heterogeneity test
clear all
use final.dta
xtset id year
est clear

xthreg $depvar  $cotrol_fix , rx($indpvar) qx($indpvar)  thnum(2) bs(300 300) trim(0.01 0.01) grid(100)
_matplot e(LR21),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("First Threshold")recast(line)name(LR1)scheme(lean1)
_matplot e(LR22),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("Second Threshold")recast(line)name(LR2)scheme(lean1)
graph combine LR1 LR2 ,  cols(1) scheme(lean1)
graph export mx_1.tif, replace 

*n/a
xthreg $depvar  logIESize logIEInno  logFDI logDIG logGovern logOpeness , rx($indpvar) qx(logLogis)  thnum(3) bs(300 300 300) trim(0.05 0.05 0.05) grid(100)



clear all
use final.dta
xtset id year
est clear

xthreg $depvar  logLogis logIESize logIEInno logDIG logGovern logOpeness, rx($indpvar) qx(logFDI)  thnum(2) bs(300 300) trim(0.01 0.01) grid(100)
_matplot e(LR21),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("First Threshold")recast(line)name(LR1)scheme(lean1)
_matplot e(LR22),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("Second Threshold")recast(line)name(LR2)scheme(lean1)
graph combine LR1 LR2 ,  cols(1) scheme(lean1)
graph export mx_2.tif, replace 



clear all
use final.dta
xtset id year
est clear
xthreg $depvar  logIESize logIEInno logLogis logFDI  logGovern logOpeness , rx($indpvar) qx(logDIG)  thnum(2) bs(300 300) trim(0.01 0.01) grid(100)
_matplot e(LR21),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("First Threshold")recast(line)name(LR1)scheme(lean1)
_matplot e(LR22),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("Second Threshold")recast(line)name(LR2)scheme(lean1)
graph combine LR1 LR2 ,  cols(1) scheme(lean1)
graph export mx_3.tif, replace 



clear all
use final.dta
xtset id year
est clear
xthreg $depvar  logIESize logIEInno logLogis logFDI logDIG  logOpeness , rx($indpvar) qx(logGovern)  thnum(1) bs(300) trim(0.01) grid(100)
_matplot e(LR),yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("First Threshold")recast(line)name(R)scheme(lean1)
graph export mx_4.tif, replace


clear all
use final.dta
xtset id year
est clear
xthreg $depvar  logIESize logIEInno logLogis logFDI logDIG logGovern  , rx($indpvar) qx(logOpeness)  thnum(3) bs(300 300 300) trim(0.01 0.01 0.01) grid(100)
_matplot e(LR21),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("First Threshold")recast(line)name(LR1)scheme(lean1)
_matplot e(LR22),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(0)mlabs(zero)ytitle("LR Statistics")xtitle("Second Threshold")recast(line)name(LR2)scheme(lean1)
_matplot e(LR3),columns(1 2)yline(7.35,lpattern(dash))connect(direct)msize(small) mlabp(O)mlabs(zero)ytitle("LR Statistics")xtitle("Third Threshold")recast(line)name(LR3)scheme(lean1)
graph combine LR1 LR2 LR3 ,  cols(1) scheme(lean1)
graph export mx_5.tif, replace



clear all
use final.dta
xtset id year
est clear
xthreg $depvar  $cotrol_fix , rx($indpvar) qx($indpvar)  thnum(2) bs(300 300) trim(0.01 0.01) grid(100)
est sto mx1
xthreg $depvar  logLogis logIESize logIEInno logDIG logGovern logOpeness, rx($indpvar) qx(logFDI)  thnum(2) bs(300 300) trim(0.01 0.01) grid(100)
est sto mx2
xthreg $depvar  logIESize logIEInno logLogis logFDI  logGovern logOpeness , rx($indpvar) qx(logDIG)  thnum(2) bs(300 300) trim(0.01 0.01) grid(100)
est sto mx3
xthreg $depvar  logIESize logIEInno logLogis logFDI logDIG  logOpeness , rx($indpvar) qx(logGovern)  thnum(1) bs(300) trim(0.01) grid(100)
est sto mx4
xthreg $depvar  logIESize logIEInno logLogis logFDI logDIG logGovern  , rx($indpvar) qx(logOpeness)  thnum(3) bs(300 300 300) trim(0.01 0.01 0.01) grid(100)
est sto mx5

local s "using Table 8 Threshold existence test results.rtf"                 
esttab   mx1 mx2 mx3 mx4 mx5  `s',  title("RG") ///
         cells(b(star fmt(%9.3f)) se(par)) ///
         stats(Controls FE FE N r2 F, fmt(%9.3g %9.3f) label("Controls" "ID_FE" "YEAR_FE" "N" "R^2" "F")) ///
         legend collabels(none) varlabels(_cons Constant) ///
		 star(* 0.1 ** 0.05 *** 0.01)
