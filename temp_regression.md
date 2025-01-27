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

![plot of chunk unnamed-chunk-9](figure/unnamed-chunk-9-1.png)

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
#> -4.9108 -0.8108  0.0111  0.7886  5.9965 
#> 
#> Coefficients:
#>               Estimate Std. Error t value Pr(>|t|)    
#> (Intercept) -3.4848245  0.8857650  -3.934 8.66e-05 ***
#> date         0.0005696  0.0000466  12.224  < 2e-16 ***
#> butte_temp   0.4209674  0.0056694  74.252  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 1.343 on 1840 degrees of freedom
#>   (1 observation deleted due to missingness)
#> Multiple R-squared:  0.7563,	Adjusted R-squared:  0.756 
#> F-statistic:  2854 on 2 and 1840 DF,  p-value: < 2.2e-16
#> [1] 0.08111131
```


```
#> 
#> Call:
#> lm(formula = temp ~ date + butte_temp, data = train)
#> 
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -4.6625 -0.7998  0.0140  0.7544  6.1959 
#> 
#> Coefficients:
#>               Estimate Std. Error t value Pr(>|t|)    
#> (Intercept) -1.755e+00  8.466e-01  -2.073   0.0383 *  
#> date         4.784e-04  4.459e-05  10.729   <2e-16 ***
#> butte_temp   3.961e-01  5.965e-03  66.411   <2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 1.278 on 1840 degrees of freedom
#>   (1 observation deleted due to missingness)
#> Multiple R-squared:  0.7131,	Adjusted R-squared:  0.7128 
#> F-statistic:  2286 on 2 and 1840 DF,  p-value: < 2.2e-16
#> [1] 0.08794536
```
  

```
#> 
#> Call:
#> lm(formula = temp ~ date + butte_temp, data = train)
#> 
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -5.4607 -0.7937  0.0155  0.8244  5.9625 
#> 
#> Coefficients:
#>               Estimate Std. Error t value Pr(>|t|)    
#> (Intercept) -4.9808368  0.9429064  -5.282 1.43e-07 ***
#> date         0.0006415  0.0000497  12.908  < 2e-16 ***
#> butte_temp   0.4472413  0.0054496  82.069  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 1.424 on 1840 degrees of freedom
#>   (1 observation deleted due to missingness)
#> Multiple R-squared:  0.7917,	Adjusted R-squared:  0.7915 
#> F-statistic:  3497 on 2 and 1840 DF,  p-value: < 2.2e-16
#> [1] 0.07445138
```

#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Feather River LFC over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-13](figure/unnamed-chunk-13-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Feather River LFC over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.


```
#> Rows: 27,396
#> Columns: 7
#> Groups: stream, date, statistic, gage_agency, gage_number, site_group [27,396]
#> $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 2000-01-03, 2000-01…
#> $ stream      [3m[38;5;246m<chr>[39m[23m "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "feather …
#> $ site_group  [3m[38;5;246m<chr>[39m[23m "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lfc", "u…
#> $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
#> $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
#> $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "mi…
#> $ value       [3m[38;5;246m<dbl>[39m[23m 4.776928, 4.194117, 5.387200, 4.847659, 4.642000, 5.189620, 4.578108, 4.329573, 4.793981, 4.710230, 4.598559, 4.873683, 4.833582…
```

![plot of chunk unnamed-chunk-16](figure/unnamed-chunk-16-1.png)




### HFC



#### Exploratory analysis

There is a linear correlation between mean, min, and max water temperature on Butte Creek and Feather River HFC. For example, the plot below suggests a strong linear relationship between the mean water temperatures of Butte Creek and Feather River HFC. The positive slope of the linear trend line implies that higher water temperatures in Butte Creek are associated with higher water temperatures in Feather River HFC. These visual representations support the results of the linear regression analysis, which identified a statistically significant relationship between the mean, max and min water temperatures of these two locations.

*Plot of mean temp for Feather River HFC and Butte Creek*

![plot of chunk unnamed-chunk-19](figure/unnamed-chunk-19-1.png)

#### Building regression models

We built 3 regression models for Feather River HFC - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.1252, which means the model's predictions are off by about 12.52% on average. 
- MAPE for the min model: 0.0973, which means the model's predictions are off by about 9.73% on average. 
- MAPE for the max model: 0.1364, which means the model's predictions are off by about 13.64% on average. 







#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Feather River HFC over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-23](figure/unnamed-chunk-23-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Feather River HFC over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.


```
#> Rows: 27,432
#> Columns: 7
#> Groups: stream, date, statistic, gage_agency, gage_number, site_group [27,432]
#> $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 2000-01-03, 2000-01…
#> $ stream      [3m[38;5;246m<chr>[39m[23m "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "feather …
#> $ site_group  [3m[38;5;246m<chr>[39m[23m "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hfc", "u…
#> $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
#> $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
#> $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "mi…
#> $ value       [3m[38;5;246m<dbl>[39m[23m 10.557812, 11.055024, 10.343995, 10.664706, 11.667514, 10.001714, 10.249474, 11.237335, 9.317955, 10.450566, 11.604491, 9.453742…
```

![plot of chunk unnamed-chunk-26](figure/unnamed-chunk-26-1.png)



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

![plot of chunk unnamed-chunk-30](figure/unnamed-chunk-30-1.png)

#### Building regression models

We built 3 regression models for Yuba River - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.0844, which means the model's predictions are off by about 8.44% on average. 
- MAPE for the min model: 0.0838, which means the model's predictions are off by about 8.38% on average. 
- MAPE for the max model: 0.078, which means the model's predictions are off by about 7.80% on average. 


  

  


#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Yuba River over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-34](figure/unnamed-chunk-34-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Yuba River over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.
  

```
#> Rows: 27,396
#> Columns: 6
#> Groups: stream, date, statistic, gage_agency, gage_number [27,396]
#> $ date        [3m[38;5;246m<date>[39m[23m 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 2000-01-03, 2000-01…
#> $ stream      [3m[38;5;246m<chr>[39m[23m "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "y…
#> $ gage_agency [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
#> $ gage_number [3m[38;5;246m<chr>[39m[23m "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", …
#> $ statistic   [3m[38;5;246m<chr>[39m[23m "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "mi…
#> $ value       [3m[38;5;246m<dbl>[39m[23m 13.13786, 12.22732, 12.98093, 13.23438, 12.86205, 12.71303, 12.86039, 12.41714, 12.17773, 13.04180, 12.79784, 12.28418, 13.21108…
```

![plot of chunk unnamed-chunk-37](figure/unnamed-chunk-37-1.png)


