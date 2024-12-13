---
title: "Filling in temperature data gaps"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Temperature Regression}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



# Regression Analysis for Water Temperature Data

The goal of this analysis is to fill in data gaps where temperature data are missing or the time series is incomplete in order to make the dataset more useful for SR JPE modeling. Temperature is an important covariate in understanding juvenile production though the completeness of these data vary by location.

Currently this analysis relies on a regression model and is performed for the Feather River and Yuba River. The resulting dataset with predicted values is saved and integrated in the development of a water temperature dataset.

## Data used to build models: Butte Creek

Butte Creek is used to build the regression models because the time series is complete and the data are high quality.

  * Date range covered in the Butte Creek temperature data is 1999 - 2024
  
## Overall approach for water temperature regression:

1. Prepare datasets for regression analysis (dataset with no missing data is used to train the model and dataset with missing data are predicted using the model)

2. Fit and evaluate linear regression models for mean, min, and max temperatures 

3. Make predictions for missing data using the fitted models

4. Combine predictions with actual measurements

5. Visualize the predicted and actual temperature over time to asses model performance trends



## Feather River

### Data Preparation and Approach

1. Pull in gage data from CDEC (GRL will represent the High Flow Channel (HFC) and FRA will represent the Low Flow Channel (LFC))
* GRL (2003-03-05 to 2007-06-01 H; 2020-01-04 to present): located after Thermalito Afterbay
* FRA (2002-01-01 to present): located between Lake Oroville and Thermalito Afterbay

2. Prepare datasets for regression analysis
* Dataset with no missing data to train and test the model (Butte Creek and Feather River)
* Dataset with missing data to make predictions (Feather River)

3. Use data where there are no missing data from either dataset for regression modeling

4. Use the regression model to make predictions from the testing dataset and evaluate

5. Use the model to make predictions for missing data
 



### Low Flow Channel (LFC)



#### Exploratory analysis

Before we developed any models, we explored the relationship between water temperature at each location. There is a linear correlation between mean, min, and max water temperature on Butte Creek and Feather River LFC. For example, the plot below suggests a strong linear relationship between the mean water temperatures of Butte Creek and Feather River LFC. The positive slope of the linear trend line implies that higher water temperatures in Butte Creek are associated with higher water temperatures in Feather River LFC. These visual representations support the results of the linear regression analysis, which identified a statistically significant relationship between the mean, max and min water temperatures of these two locations.

*Plot of mean temp for Feather River LFC and Butte Creek*

![plot of chunk unnamed-chunk-17](figure/unnamed-chunk-17-1.png)

#### Building regression models

We built 3 regression models for Feather River LFC - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.08488823, which means the model's predictions are off by about 8.49% on average. 
- MAPE for the min model: 0.08800298, which means the model's predictions are off by about 8.80% on average. 
- MAPE for the max model: 0.07784735, which means the model's predictions are off by about 7.78% on average. 


```
## 
## Call:
## lm(formula = temp ~ date + butte_temp, data = train)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -4.9044 -0.8355  0.0208  0.7930  5.9243 
## 
## Coefficients:
##               Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -5.404e+00  9.323e-01  -5.796    8e-09 ***
## date         6.763e-04  4.933e-05  13.710   <2e-16 ***
## butte_temp   4.167e-01  5.780e-03  72.093   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 1.361 on 1804 degrees of freedom
##   (1 observation deleted due to missingness)
## Multiple R-squared:  0.7551,	Adjusted R-squared:  0.7549 
## F-statistic:  2782 on 2 and 1804 DF,  p-value: < 2.2e-16
```

```
## [1] 0.07731664
```


```
## 
## Call:
## lm(formula = temp ~ date + butte_temp, data = train)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -4.7027 -0.7850  0.0289  0.7544  5.9528 
## 
## Coefficients:
##               Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -3.344e+00  8.909e-01  -3.753  0.00018 ***
## date         5.674e-04  4.712e-05  12.041  < 2e-16 ***
## butte_temp   3.901e-01  6.144e-03  63.487  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 1.307 on 1805 degrees of freedom
## Multiple R-squared:  0.7039,	Adjusted R-squared:  0.7036 
## F-statistic:  2146 on 2 and 1805 DF,  p-value: < 2.2e-16
```

```
## [1] NA
```
  

```
## 
## Call:
## lm(formula = temp ~ date + butte_temp, data = train)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -5.3774 -0.7691  0.0186  0.8444  5.6530 
## 
## Coefficients:
##               Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -6.401e+00  9.611e-01  -6.659 3.64e-11 ***
## date         7.231e-04  5.077e-05  14.245  < 2e-16 ***
## butte_temp   4.390e-01  5.419e-03  81.023  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 1.4 on 1805 degrees of freedom
## Multiple R-squared:  0.7929,	Adjusted R-squared:  0.7926 
## F-statistic:  3455 on 2 and 1805 DF,  p-value: < 2.2e-16
```

```
## [1] NA
```

#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Feather River LFC over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-21](figure/unnamed-chunk-21-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Feather River LFC over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.


```
## Rows: 27,261
## Columns: 7
## Groups: stream, date, statistic, gage_agency, gage_number, site_group [27,261]
## $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 200…
## $ stream      [3m[38;5;246m<chr>[39m[23m "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "feather r…
## $ site_group  [3m[38;5;246m<chr>[39m[23m "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper …
## $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
## $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
## $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "m…
## $ value       [3m[38;5;246m<dbl>[39m[23m 4.006174, 3.629404, 4.745432, 4.076298, 4.069149, 4.550961, 3.809598, 3.762557, 4.161453, 3.940490, 4.026693, 4.…
```

![plot of chunk unnamed-chunk-24](figure/unnamed-chunk-24-1.png)




### HFC



#### Exploratory analysis

There is a linear correlation between mean, min, and max water temperature on Butte Creek and Feather River HFC. For example, the plot below suggests a strong linear relationship between the mean water temperatures of Butte Creek and Feather River HFC. The positive slope of the linear trend line implies that higher water temperatures in Butte Creek are associated with higher water temperatures in Feather River HFC. These visual representations support the results of the linear regression analysis, which identified a statistically significant relationship between the mean, max and min water temperatures of these two locations.

*Plot of mean temp for Feather River HFC and Butte Creek*

![plot of chunk unnamed-chunk-27](figure/unnamed-chunk-27-1.png)

#### Building regression models

We built 3 regression models for Feather River HFC - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.1252, which means the model's predictions are off by about 12.52% on average. 
- MAPE for the min model: 0.0973, which means the model's predictions are off by about 9.73% on average. 
- MAPE for the max model: 0.1364, which means the model's predictions are off by about 13.64% on average. 







#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Feather River HFC over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-31](figure/unnamed-chunk-31-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Feather River HFC over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.


```
## Rows: 27,297
## Columns: 7
## Groups: stream, date, statistic, gage_agency, gage_number, site_group [27,297]
## $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 200…
## $ stream      [3m[38;5;246m<chr>[39m[23m "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "feather r…
## $ site_group  [3m[38;5;246m<chr>[39m[23m "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper …
## $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
## $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
## $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "m…
## $ value       [3m[38;5;246m<dbl>[39m[23m 10.791141, 11.249714, 10.290183, 10.898081, 11.850457, 9.950046, 10.482031, 11.428449, 9.270540, 10.683325, 11.7…
```

![plot of chunk unnamed-chunk-34](figure/unnamed-chunk-34-1.png)



## Yuba River

### Data Prepartion and Approach

1. Pull in gage data from YR7 CDEC gage.

* Note that this gage only contains data from 2020 onwards. Originally we included temperature data collected during RST data collection for this analysis; however, due to inconsistencies in using two different data sources the resulting predicted mean values were lower than the min values as the RST data only has mean data. We then decided to just rely on the gage data despite the small time period.

2. Prepare datasets for regression analysis
* Dataset with no missing data to train (Butte Creek and Yuba River)
* Dataset with missing data to predict (Yuba River)

3. Combine datasets with no missing data, and missing data

4. Identify gaps to predict

5. Use data where there are no missing data for either dataset for regression modeling





#### Exploratory analysis

There is a linear correlation between mean, min, and max water temperature on Butte Creek and Yuba River. For example, the plot below suggests a strong linear relationship between the mean water temperatures of Butte Creek and Yuba River. The positive slope of the linear trend line implies that higher water temperatures in Butte Creek are associated with higher water temperatures in Yuba River. These visual representations support the results of the linear regression analysis, which identified a statistically significant relationship between the mean, max and min water temperatures of these two locations.

*Plot of mean temp for Yuba River and Butte Creek*

![plot of chunk unnamed-chunk-38](figure/unnamed-chunk-38-1.png)

#### Building regression models

We built 3 regression models for Yuba River - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.0844, which means the model's predictions are off by about 8.44% on average. 
- MAPE for the min model: 0.0838, which means the model's predictions are off by about 8.38% on average. 
- MAPE for the max model: 0.078, which means the model's predictions are off by about 7.80% on average. 


  

  


#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Yuba River over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-42](figure/unnamed-chunk-42-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Yuba River over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.
  

```
## Rows: 27,261
## Columns: 6
## Groups: stream, date, statistic, gage_agency, gage_number [27,261]
## $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 200…
## $ stream      [3m[38;5;246m<chr>[39m[23m "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", …
## $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
## $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
## $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "m…
## $ value       [3m[38;5;246m<dbl>[39m[23m 12.75593, 11.85311, 13.01006, 12.85400, 12.49271, 12.74185, 12.47422, 12.04446, 12.20594, 12.65851, 12.42810, 12…
```

![plot of chunk unnamed-chunk-45](figure/unnamed-chunk-45-1.png)


