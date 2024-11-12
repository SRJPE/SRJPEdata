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

![plot of chunk unnamed-chunk-23](figure/unnamed-chunk-23-1.png)

#### Building regression models

We built 3 regression models for Feather River LFC - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.08488823, which means the model's predictions are off by about 8.49% on average. 
- MAPE for the min model: 0.08800298, which means the model's predictions are off by about 8.80% on average. 
- MAPE for the max model: 0.07784735, which means the model's predictions are off by about 7.78% on average. 


```
#> 
#> Call:
#> lm(formula = temp ~ date + butte_temp, data = train)
#> 
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -4.8940 -0.8309  0.0109  0.7919  5.9395 
#> 
#> Coefficients:
#>               Estimate Std. Error t value Pr(>|t|)    
#> (Intercept) -5.835e+00  9.474e-01  -6.159 9.02e-10 ***
#> date         6.976e-04  5.021e-05  13.895  < 2e-16 ***
#> butte_temp   4.175e-01  5.862e-03  71.228  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 1.357 on 1779 degrees of freedom
#>   (1 observation deleted due to missingness)
#> Multiple R-squared:  0.7552,	Adjusted R-squared:  0.7549 
#> F-statistic:  2744 on 2 and 1779 DF,  p-value: < 2.2e-16
#> [1] 0.07945884
```


```
#> 
#> Call:
#> lm(formula = temp ~ date + butte_temp, data = train)
#> 
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -4.6388 -0.7930  0.0411  0.7504  6.1471 
#> 
#> Coefficients:
#>               Estimate Std. Error t value Pr(>|t|)    
#> (Intercept) -3.048e+00  9.024e-01  -3.378 0.000746 ***
#> date         5.514e-04  4.786e-05  11.523  < 2e-16 ***
#> butte_temp   3.910e-01  6.183e-03  63.236  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 1.296 on 1779 degrees of freedom
#>   (1 observation deleted due to missingness)
#> Multiple R-squared:  0.7078,	Adjusted R-squared:  0.7075 
#> F-statistic:  2155 on 2 and 1779 DF,  p-value: < 2.2e-16
#> [1] 0.08611539
```
  

```
#> 
#> Call:
#> lm(formula = temp ~ date + butte_temp, data = train)
#> 
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -5.4038 -0.7970  0.0046  0.8417  6.0514 
#> 
#> Coefficients:
#>               Estimate Std. Error t value Pr(>|t|)    
#> (Intercept) -7.178e+00  9.929e-01  -7.229 7.18e-13 ***
#> date         7.669e-04  5.263e-05  14.571  < 2e-16 ***
#> butte_temp   4.382e-01  5.620e-03  77.970  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 1.425 on 1780 degrees of freedom
#> Multiple R-squared:  0.7859,	Adjusted R-squared:  0.7857 
#> F-statistic:  3267 on 2 and 1780 DF,  p-value: < 2.2e-16
#> [1] NA
```

#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Feather River LFC over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-27](figure/unnamed-chunk-27-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Feather River LFC over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.


```
#> Rows: 27,168
#> Columns: 7
#> Groups: stream, date, statistic, gage_agency, gage_number, site_group [27,168]
#> $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-0…
#> $ stream      [3m[38;5;246m<chr>[39m[23m "feather river", "feather river", "feather river", "feather river", "feather river", "feath…
#> $ site_group  [3m[38;5;246m<chr>[39m[23m "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper …
#> $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolat…
#> $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolat…
#> $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "me…
#> $ value       [3m[38;5;246m<dbl>[39m[23m 3.812061, 3.327297, 4.870194, 3.882347, 3.766244, 4.675253, 3.615131, 3.460284, 4.284821, 3…
```

![plot of chunk unnamed-chunk-30](figure/unnamed-chunk-30-1.png)




### HFC



#### Exploratory analysis

There is a linear correlation between mean, min, and max water temperature on Butte Creek and Feather River HFC. For example, the plot below suggests a strong linear relationship between the mean water temperatures of Butte Creek and Feather River HFC. The positive slope of the linear trend line implies that higher water temperatures in Butte Creek are associated with higher water temperatures in Feather River HFC. These visual representations support the results of the linear regression analysis, which identified a statistically significant relationship between the mean, max and min water temperatures of these two locations.

*Plot of mean temp for Feather River HFC and Butte Creek*

![plot of chunk unnamed-chunk-33](figure/unnamed-chunk-33-1.png)

#### Building regression models

We built 3 regression models for Feather River HFC - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.1252, which means the model's predictions are off by about 12.52% on average. 
- MAPE for the min model: 0.0973, which means the model's predictions are off by about 9.73% on average. 
- MAPE for the max model: 0.1364, which means the model's predictions are off by about 13.64% on average. 







#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Feather River HFC over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-37](figure/unnamed-chunk-37-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Feather River HFC over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.


```
#> Rows: 27,204
#> Columns: 7
#> Groups: stream, date, statistic, gage_agency, gage_number, site_group [27,204]
#> $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-0…
#> $ stream      [3m[38;5;246m<chr>[39m[23m "feather river", "feather river", "feather river", "feather river", "feather river", "feath…
#> $ site_group  [3m[38;5;246m<chr>[39m[23m "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper …
#> $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolat…
#> $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolat…
#> $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "me…
#> $ value       [3m[38;5;246m<dbl>[39m[23m 10.298346, 11.346775, 10.474639, 10.406959, 11.952361, 10.133358, 9.985657, 11.526796, 9.45…
```

![plot of chunk unnamed-chunk-40](figure/unnamed-chunk-40-1.png)



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

![plot of chunk unnamed-chunk-44](figure/unnamed-chunk-44-1.png)

#### Building regression models

We built 3 regression models for Yuba River - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.0844, which means the model's predictions are off by about 8.44% on average. 
- MAPE for the min model: 0.0838, which means the model's predictions are off by about 8.38% on average. 
- MAPE for the max model: 0.078, which means the model's predictions are off by about 7.80% on average. 


  

  


#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Yuba River over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-48](figure/unnamed-chunk-48-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Yuba River over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.
  

```
#> Rows: 27,168
#> Columns: 6
#> Groups: stream, date, statistic, gage_agency, gage_number [27,168]
#> $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-0…
#> $ stream      [3m[38;5;246m<chr>[39m[23m "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba r…
#> $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolat…
#> $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolat…
#> $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "me…
#> $ value       [3m[38;5;246m<dbl>[39m[23m 13.25125, 12.69226, 13.60831, 13.34990, 13.32475, 13.33784, 12.96759, 12.88132, 12.79750, 1…
```

![plot of chunk unnamed-chunk-51](figure/unnamed-chunk-51-1.png)


