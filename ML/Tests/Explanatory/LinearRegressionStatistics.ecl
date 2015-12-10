/*
R Code for Testing :

Code :

A <- matrix(c(1,0.13197,25.114,3,0.94205,72.009,5,0.95613,71.9,7,0.57521,97.906,9,0.05978,102.2,
11,0.23478,118.48,13,0.35316,145.83,15,0.82119,181.51,17,0.015403,197.38,19,0.043024,214.03,
21,0.16899,216.61,23,0.64912,270.63,25,0.73172,281.17,27,0.64775,295.11,29,0.45092,314.04,
31,0.54701,331.86,33,0.29632,345.95,35,0.74469,385.31,37,0.18896,390.91,39,0.68678,423.49), nrow = 20, ncol = 3, byrow=TRUE);

Y <- A[, 3];
X1 <- A[, 1];
X2 <- A[, 2];
model <- lm(Y ~ 1 + X1 + X2);
summary(model)

Output :
Residuals:
        Min          1Q      Median          3Q         Max 
-11.2473853  -5.1166972   0.4066936   3.0663545  13.3339088 

Coefficients:
              Estimate Std. Error  t value   Pr(>|t|)    
(Intercept) 11.6216846  4.2395234  2.74127  0.0139203 *  
X1          10.1230313  0.1471263 68.80502 < 2.22e-16 ***
X2          21.6110019  5.6660185  3.81414  0.0013876 ** 
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

Residual standard error: 7.585232 on 17 degrees of freedom
Multiple R-squared:  0.9964462, Adjusted R-squared:  0.9960281 
F-statistic: 2383.296 on 2 and 17 DF,  p-value: < 2.2204e-16

Code : confint(model, level=0.95)
Output :
               2.5 %   97.5 %
(Intercept) 2.677072 20.56630
X1          9.812622 10.43344
X2          9.656748 33.56526

Code : confint(model, level =0.99)
Output:
                 0.5 %   99.5 %
(Intercept) -0.6654315 23.90880
X1           9.6966253 10.54944
X2           5.1895742 38.03243

*/

  IMPORT ML;
   value_record := RECORD
   UNSIGNED rid;
   UNSIGNED X_1;
   REAL X_2;
   REAL Y;
   END;
   d := DATASET([{1,1,0.13197,25.114},  {2,3,0.94205,72.009}, {3,5,0.95613,71.9}, {4,7,0.57521,97.906},
    {5,9,0.05978,102.2},  {6,11,0.23478,118.48},  {7,13,0.35316,145.83},  {8,15,0.82119,181.51},
    {9,17,0.015403,197.38}, {10,19,0.043024,214.03},{11,21,0.16899,216.61}, {12,23,0.64912,270.63},
    {13,25,0.73172,281.17}, {14,27,0.64775,295.11}, {15,29,0.45092,314.04},{16,31,0.54701,331.86},
    {17,33,0.29632,345.95},{18,35,0.74469,385.31},{19,37,0.18896,390.91},{20,39,0.68678,423.49}],value_record);
   ML.ToField(d,o);
   X := O(Number = 1 OR Number = 2); // Pull out the X
   Y := O(Number = 3); // Pull out the Y
   model := ML.Regression.sparse.OLS_LU(X,Y);
   model.Betas;
   model.var_covar;
   model.SE;
   model.tStat;
   model.pVal;
   model.Anova;
   model.FTest;
   model.RSquared;
   model.AdjRSquared;
   model.confInt(95);
   model.confInt(99);
   
   model_dense := ML.Regression.Dense.OLS_LU(X, Y);
   model_dense.Betas;
   model_dense.var_covar;
   model_dense.SE;
   model_dense.tStat;
   model_dense.pVal;
   model_dense.Anova;
   model.FTest;
   model_dense.RSquared;
   model_dense.AdjRSquared;
   model.confInt(95);
   model.confInt(99);