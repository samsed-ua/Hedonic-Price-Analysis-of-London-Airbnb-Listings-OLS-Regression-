
* 1_Setup, data loading, inspection, and working copy


clear all
set more off

cd "C:\Users\su00314\OneDrive - University of Surrey\Desktop\clean_stata"

log using "01_data_inspection.log", replace text

use "C:\Users\su00314\OneDrive - University of Surrey\Desktop\MANM526-FINAL PROJECT DATA-2025-26-Feb (1).dta", clear

describe
summarize
misstable summarize

tab room_type
tab listing_subregion
tab host_is_superhost
tab instant_bookable
tab host_identity_verified

save "MANM526_working_data.dta", replace

log close


* 2_Variable creation, encoding, and labels


use "MANM526_working_data.dta", clear

* Create log variables required by the project guideline
gen ln_price = ln(price)
gen ln_host_total_listings = ln(host_total_listings)
gen ln_number_of_reviews = ln(number_of_reviews)

* Create Central London dummy for descriptive analysis
gen central_london = (listing_subregion == "Central London")

* Create squared term for quadratic professionalisation model
gen ln_host_total_listings_sq = ln_host_total_listings^2

* Encode string categorical variables for regression and graphs
encode room_type, gen(room_type_num)
encode listing_subregion, gen(subregion_num)

* Add readable variable labels for exported tables
label variable price "Listed price"
label variable ln_price "Log listed price"
label variable host_is_superhost "Superhost"
label variable review_scores_rating "Review rating"
label variable host_total_listings "Host total listings"
label variable ln_host_total_listings "Log host total listings"
label variable ln_host_total_listings_sq "Log host total listings squared"
label variable hosting_years "Hosting years"
label variable host_has_profile_pic "Host profile picture"
label variable host_identity_verified "Host identity verified"
label variable accommodates "Accommodation capacity"
label variable beds "Beds"
label variable bathrooms "Bathrooms"
label variable bathroom_is_private "Private bathroom"
label variable instant_bookable "Instant bookable"
label variable number_of_reviews "Number of reviews"
label variable ln_number_of_reviews "Log number of reviews"
label variable central_london "Central London"
label variable room_type_num "Room type"
label variable subregion_num "London subregion"

* Check newly created variables
summarize ln_price ln_host_total_listings ln_number_of_reviews central_london ln_host_total_listings_sq

tab central_london
tab room_type_num
tab subregion_num

save "MANM526_working_data.dta", replace

 
* 3_Table 1: Descriptive Statistics


use "MANM526_working_data.dta", clear

log using "02_descriptive_statistics.log", replace text

eststo clear

estpost summarize ln_price host_is_superhost review_scores_rating ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified accommodates beds bathrooms instant_bookable ln_number_of_reviews
eststo total

estpost summarize ln_price host_is_superhost review_scores_rating ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified accommodates beds bathrooms instant_bookable ln_number_of_reviews if central_london == 1
eststo central

estpost summarize ln_price host_is_superhost review_scores_rating ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified accommodates beds bathrooms instant_bookable ln_number_of_reviews if central_london == 0
eststo noncentral

esttab total central noncentral using "Table_1_Descriptive_Statistics.rtf", replace rtf cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3))") label nonumber title("Table 1. Descriptive Statistics") mtitles("Full sample" "Central London" "Non-Central London")

log close


* 4_Table 2: Correlation Matrix


use "MANM526_working_data.dta", clear

log using "03_correlation_matrix.log", replace text

eststo clear

estpost corr ln_price host_is_superhost review_scores_rating ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified accommodates beds bathrooms instant_bookable ln_number_of_reviews, matrix

eststo c1

esttab c1 using "Table_2_Correlation_Matrix.rtf", replace rtf label unstack not title("Table 2. Correlation Matrix")

log close

*5_ANOVA test and subregion graph


use "MANM526_working_data.dta", clear

log using "04_anova_subregion.log", replace text

oneway ln_price subregion_num, tabulate


log close

*6_Exploratory graphs


use "MANM526_working_data.dta", clear


histogram price, frequency title("Distribution of Listed Price") xtitle("Listed price") ytitle("Frequency")
graph export "Figure_1_Price_Distribution.png", replace

graph box ln_price, over(subregion_num) title("Log Listed Price by London Subregion") ytitle("Log listed price")
graph export "Figure_2_Listed_Price_by_London_Subregion.png", replace

histogram ln_price, frequency title("Distribution of Log Listed Price") xtitle("Log listed price") ytitle("Frequency")
graph export "Figure_3_Log_Price_Distribution.png", replace

graph box ln_price, over(room_type_num) title("Log Listed Price by Room Type") ytitle("Log listed price")
graph export "Figure_4_Listed_Price_by_Room_Type.png", replace

twoway (scatter ln_price ln_host_total_listings) (lowess ln_price ln_host_total_listings), title("Log Price and Host Professionalisation") xtitle("Log host total listings") ytitle("Log listed price")
graph export "Figure_5_Log_Price_by_Host_Total_Listings.png", replace

twoway (scatter ln_price review_scores_rating) (lowess ln_price review_scores_rating), title("Log Price and Review Rating") xtitle("Review rating") ytitle("Log listed price")
graph export "Figure_6_Log_Price_by_Review_Rating.png", replace


*7_Regression models: baseline, interaction, quadratic, robust


use "MANM526_working_data.dta", clear

log using "05_regression_models.log", replace text

eststo clear

* Model 1: Baseline OLS
reg ln_price host_is_superhost review_scores_rating ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified i.room_type_num accommodates beds bathrooms instant_bookable ln_number_of_reviews i.subregion_num
eststo m1

esttab m1 using "Table_3_Model_1_Baseline.rtf", replace rtf b(3) se(3) r2(3) ar2(3) label compress title("Table 3. Model 1 Baseline OLS Regression for Log Listed Price") mtitles("Model 1 Baseline") star(* 0.05 ** 0.01 *** 0.001)
eststo m1

* Model 2: Interaction 
reg ln_price host_is_superhost c.review_scores_rating##i.room_type_num ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified accommodates beds bathrooms instant_bookable ln_number_of_reviews i.subregion_num
eststo m2
esttab m2 using "Table_3_Model_2_Interaction.rtf", replace rtf b(3) se(3) r2(3) ar2(3) label compress title("Table 3. Model 2 Interaction Regression for Log Listed Price") mtitles("Model 2 Interaction") star(* 0.05 ** 0.01 *** 0.001)

*Model 3: Quadratic

reg ln_price host_is_superhost review_scores_rating ln_host_total_listings ln_host_total_listings_sq hosting_years host_has_profile_pic host_identity_verified i.room_type_num accommodates beds bathrooms instant_bookable ln_number_of_reviews i.subregion_num
eststo m3
esttab m3 using "Table_3_Model_3_Quadratic.rtf", replace rtf b(3) se(3) r2(3) ar2(3) label compress title("Table 3. Model 3 Quadratic Professionalisation Regression") mtitles("Model 3 Quadratic") star(* 0.05 ** 0.01 *** 0.001)

* Model 4: Robust

reg ln_price host_is_superhost review_scores_rating ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified i.room_type_num accommodates beds bathrooms instant_bookable ln_number_of_reviews i.subregion_num, vce(robust)
eststo m4
esttab m4 using "Table_3_Model_4_Robust.rtf", replace rtf b(3) se(3) r2(3) ar2(3) label compress title("Table 3. Model 4 Baseline Regression with Robust Standard Errors") mtitles("Model 4 Robust SE") star(* 0.05 ** 0.01 *** 0.001)



esttab m1 m2 m3 m4 using "Table_3_Combined_Regression_Results.rtf", replace rtf b(3) se(3) r2(3) ar2(3) label compress title("Table 3. Regression Results for Log Listed Price") mtitles("Model 1 Baseline" "Model 2 Interaction" "Model 3 Quadratic" "Model 4 Robust SE") star(* 0.05 ** 0.01 *** 0.001)

log close

*8_Margins and margin plot

use "MANM526_working_data.dta", clear

log using "06_margins.log", replace text

reg ln_price host_is_superhost review_scores_rating ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified i.room_type_num accommodates beds bathrooms instant_bookable ln_number_of_reviews i.subregion_num

margins room_type_num

marginsplot, title("Predicted Log Listed Price by Room Type") ytitle("Predicted log listed price") xtitle("Room type")

graph export "Figure_7_Margins_Room_Type.png", replace

reg ln_price host_is_superhost c.review_scores_rating##i.room_type_num ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified accommodates beds bathrooms instant_bookable ln_number_of_reviews i.subregion_num
margins room_type_num, at(review_scores_rating=(3 4 5))
marginsplot, title("Review Rating and Predicted Log Price by Room Type") ytitle("Predicted log listed price") xtitle("Review rating")

graph export "Figure_8_Interaction_Review_Room_Type.png", replace

log close

* 9_Diagnostics: VIF and heteroskedasticity


use "MANM526_working_data.dta", clear

log using "07_diagnostics.log", replace text

reg ln_price host_is_superhost review_scores_rating ln_host_total_listings hosting_years host_has_profile_pic host_identity_verified i.room_type_num accommodates beds bathrooms instant_bookable ln_number_of_reviews i.subregion_num

estat vif

predict fitted, xb
predict resid, residual

rvfplot, yline(0) title("Residuals versus Fitted Values") ytitle("Residuals") xtitle("Fitted values")

graph export "Figure_9_Residuals_vs_Fitted.png", replace

estat hettest

imtest, white

log close












