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

![plot of chunk unnamed-chunk-5](figure/unnamed-chunk-5-1.png)

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
## -4.8852 -0.8200  0.0265  0.7908  5.9166 
## 
## Coefficients:
##               Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -5.335e+00  1.003e+00  -5.318 1.19e-07 ***
## date         6.707e-04  5.325e-05  12.597  < 2e-16 ***
## butte_temp   4.209e-01  5.907e-03  71.251  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 1.365 on 1720 degrees of freedom
## Multiple R-squared:  0.7571,	Adjusted R-squared:  0.7568 
## F-statistic:  2680 on 2 and 1720 DF,  p-value: < 2.2e-16
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
## -4.7112 -0.8051  0.0568  0.7808  6.1542 
## 
## Coefficients:
##               Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -4.595e+00  9.675e-01  -4.749 2.21e-06 ***
## date         6.323e-04  5.134e-05  12.317  < 2e-16 ***
## butte_temp   3.918e-01  6.306e-03  62.131  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 1.319 on 1720 degrees of freedom
## Multiple R-squared:  0.7074,	Adjusted R-squared:  0.707 
## F-statistic:  2079 on 2 and 1720 DF,  p-value: < 2.2e-16
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
## -5.4296 -0.7767  0.0265  0.8239  6.0625 
## 
## Coefficients:
##               Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -8.5171637  1.0557731  -8.067 1.34e-15 ***
## date         0.0008342  0.0000561  14.868  < 2e-16 ***
## butte_temp   0.4420780  0.0056697  77.973  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 1.434 on 1720 degrees of freedom
## Multiple R-squared:  0.7927,	Adjusted R-squared:  0.7925 
## F-statistic:  3289 on 2 and 1720 DF,  p-value: < 2.2e-16
```

```
## [1] NA
```

#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Feather River LFC over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-9](figure/unnamed-chunk-9-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Feather River LFC over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.


```
## Rows: 26,943
## Columns: 7
## Groups: stream, date, statistic, gage_agency, gage_number, site_group [26,943]
## $ date        <date> 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 2000-01-03, 2…
## $ stream      <chr> "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "fe…
## $ site_group  <chr> "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lfc", "upper feather lf…
## $ gage_agency <chr> "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpola…
## $ gage_number <chr> "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpola…
## $ statistic   <chr> "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max…
## $ value       <dbl> 4.033480, 2.743974, 4.213195, 4.104299, 3.186887, 4.017944, 3.834899, 2.878266, 3.626808, 3.967098, 3.144347, 3.705794, 4.…
```

![plot of chunk unnamed-chunk-12](figure/unnamed-chunk-12-1.png)




### HFC



#### Exploratory analysis

There is a linear correlation between mean, min, and max water temperature on Butte Creek and Feather River HFC. For example, the plot below suggests a strong linear relationship between the mean water temperatures of Butte Creek and Feather River HFC. The positive slope of the linear trend line implies that higher water temperatures in Butte Creek are associated with higher water temperatures in Feather River HFC. These visual representations support the results of the linear regression analysis, which identified a statistically significant relationship between the mean, max and min water temperatures of these two locations.

*Plot of mean temp for Feather River HFC and Butte Creek*

![plot of chunk unnamed-chunk-15](figure/unnamed-chunk-15-1.png)

#### Building regression models

We built 3 regression models for Feather River HFC - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.1252, which means the model's predictions are off by about 12.52% on average. 
- MAPE for the min model: 0.0973, which means the model's predictions are off by about 9.73% on average. 
- MAPE for the max model: 0.1364, which means the model's predictions are off by about 13.64% on average. 







#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Feather River HFC over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-19](figure/unnamed-chunk-19-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Feather River HFC over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.


```
## Rows: 26,979
## Columns: 7
## Groups: stream, date, statistic, gage_agency, gage_number, site_group [26,979]
## $ date        <date> 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 2000-01-03, 2…
## $ stream      <chr> "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "feather river", "fe…
## $ site_group  <chr> "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hfc", "upper feather hf…
## $ gage_agency <chr> "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpola…
## $ gage_number <chr> "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpola…
## $ statistic   <chr> "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max…
## $ value       <dbl> 10.356820, 11.144952, 10.640620, 10.468916, 11.744550, 10.301175, 10.033710, 11.323428, 9.623246, 10.244546, 11.682857, 9.…
```

![plot of chunk unnamed-chunk-22](figure/unnamed-chunk-22-1.png)



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

![plot of chunk unnamed-chunk-26](figure/unnamed-chunk-26-1.png)

#### Building regression models

We built 3 regression models for Yuba River - one each for mean, min, and max water temperature relationships. We evaluated the models using the Mean Absolute Percentage Error (MAPE). The MAPE for all three models indicated good predictive accuracy.

- MAPE for the mean model: 0.0844, which means the model's predictions are off by about 8.44% on average. 
- MAPE for the min model: 0.0838, which means the model's predictions are off by about 8.38% on average. 
- MAPE for the max model: 0.078, which means the model's predictions are off by about 7.80% on average. 


  

  


#### Predictions

  * Combine predictions (mean, min, max data frames into one)
  * Reshape data

The plot shows the predicted mean temperature of the Yuba River over time (which is similar for min and max predictions as well). The line represents the trend of the predicted mean temperatures, indicating how they change as the date progresses. This visualization helps to identify any patterns or trends in the mean water temperature over the observed period.

![plot of chunk unnamed-chunk-30](figure/unnamed-chunk-30-1.png)





#### Full dataset

  * Join with original data (merge combined predictions with the original dataset that includes gage agency and gage number)
  * Visualize combined data
  
The plot below shows how the mean, min, and max temperatures for the Yuba River over time. Interpolated values are seamlessly integrated where observed data is missing, ensuring a continuous temperature dataset. Each water temperature type (mean, min, max) is represented with a different color to help in distinguishing the temperature trends and understanding the temperature fluctuations.
  

```
## Rows: 26,943
## Columns: 6
## Groups: stream, date, statistic, gage_agency, gage_number [26,943]
## $ date        <date> 1999-12-31, 1999-12-31, 1999-12-31, 2000-01-01, 2000-01-01, 2000-01-01, 2000-01-02, 2000-01-02, 2000-01-02, 2000-01-03, 2…
## $ stream      <chr> "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba river", "yuba rive…
## $ gage_agency <chr> "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpola…
## $ gage_number <chr> "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpolated", "interpola…
## $ statistic   <chr> "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max", "min", "mean", "max…
## $ value       <dbl> 15.70107, 14.58739, 16.13424, 15.79850, 15.21854, 15.86559, 15.41936, 14.77563, 15.32920, 15.60278, 15.15406, 15.43538, 15…
```

![plot of chunk unnamed-chunk-33](figure/unnamed-chunk-33-1.png)


