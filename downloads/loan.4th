\ loan.4th
\
\ Loan calculator -- calculates monthly payment to pay off a loan with
\   a fixed interest rate for a fixed number of years.
\
\ This program is useful for calculating payments for fixed interest 
\ mortgage loans (not including taxes and insurance). User can adjust 
\ the loan amount, number of years, and interest rate to calculate 
\ "what if?" scenarios.
\
\ Copyright (c) 2002 Krishna Myneni
\ May be distributed in accordance with the GNU General Public License
\
\ ---------------------------------------

variable interest_rate	6500 interest_rate !	\ annual rate of 6.5%
variable months		180 months !
variable amount		100000 amount !

\ ---------------------------------------

variable principal
variable interest
variable balance

: monthly_interest ( -- n | calculate monthly interest on balance )
	balance @ s>d interest_rate @ 1200000 m*/ drop ;

\ Calculate number of months required to payoff loan with monthly payment of n
	
: months_to_payoff ( n -- m )
	amount @ balance !
	dup monthly_interest <= if drop -1 exit then  \ will never payoff
	0
	begin
	  monthly_interest balance +!		\ accrue interest
	  over negate balance +!   		\ apply payment
	  1+           				\ next month
	  \ dup 4 .r 2 spaces balance @ 6 .r cr 
	  balance @ 0 <=			\ are we paid off?
	until
	1- swap drop ;


create last_monthlys  4 cells allot

: ?converged ( payment nmonths -- flag | have values been seen before )
	2dup last_monthlys 2@ d= -rot
	last_monthlys 2 cells + 2@ d= or ; 

: update_last_monthlys ( payment nmonths -- )
	last_monthlys 2 cells + 2@ last_monthlys 2!
	last_monthlys 2 cells + 2! ;
	
: monthly_payment ( -- n | determine the monthly payment )
	amount @ months @ / dup 40 * 100 / +  ( order of mag estimate )
	begin
	  dup months_to_payoff
	  dup -1 = 
	while
	  drop dup 10 / +
	repeat

	\ ( -- payment nmonths )

	0 0 update_last_monthlys 0 0 update_last_monthlys

	begin
	  months @ - dup
	while
	  0> if 1+ else 1- then  
	  dup months_to_payoff
	  2dup ?converged if drop exit then
	  2dup update_last_monthlys	  
	repeat
	drop ;


 50000 constant chart-amount1
210000 constant chart-amount2
 10000 constant chart-delta-amount

 5000  constant chart-interest1
10000  constant chart-interest2
  500  constant chart-delta-interest


\ Display a chart of monthly principal and interest payments
\   for an n-year, fixed-rate mortgage.

: chart ( nmonths -- | print the chart for a payment period of nmonths )
	dup months ! cr
	." Monthly payments for" 4 .r ."  months " 
	." (excluding taxes and insurance)" cr cr
	." amount" 2 spaces
	chart-interest2 chart-interest1 ?do
	  i 10 / s>d <# [char] % hold # # [char] . hold # 
	  2dup d0= if bl hold else # then bl hold #> type 
	chart-delta-interest +loop cr cr

	chart-amount2 chart-amount1 ?do
	  i dup amount ! 6 .r 2 spaces
	  chart-interest2 chart-interest1 ?do
	    i interest_rate !
	    monthly_payment 7 .r
	  chart-delta-interest +loop cr
	chart-delta-amount +loop cr
;
 
: chart360 ( -- )	360 chart ;
: chart180 ( -- )	180 chart ;

create input_string 16 allot

: #in ( -- n )
	input_string 16 accept input_string swap evaluate ;

: loan ( -- )
	." Enter whole numbers only (no decimal):" cr cr
	." Amount of loan:       " 		#in  amount ! cr 
	." Number of years:      " 		#in  12 * months ! cr
	." Yearly interest rate (% x 1000): "	#in  interest_rate ! cr
	cr
	monthly_payment
	." Your monthly payment is about " .
	."  (excluding taxes and insurance)." cr	
;

