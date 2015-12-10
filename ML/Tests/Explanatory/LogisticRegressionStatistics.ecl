/*
R-Code :
"""""""""""""""
B <- matrix(c(1,35,149,0,2,11,138,0,3,12,148,1,4,16,156,0,
                 5,32,152,0,6,16,157,0,7,14,165,0,8,8,152,1,
                 9,35,177,0,10,33,158,1,11,40,166,0,12,28,165,0,  
                 13,23,160,0,14,52,178,1,15,46,169,0,16,29,173,1,
                 17,30,172,0,18,21,163,0,19,21,164,0,20,20,189,1,
                 21,34,182,1,22,43,184,1,23,35,174,1,24,39,177,1,
                 25,43,183,1,26,37,175,1,27,32,173,1,28,24,173,1,
                 29,20,162,0,30,25,180,1,31,22,173,1,32,25,171,1
),nrow = 32, ncol = 4, byrow=TRUE);

Y <- B[, 4];
X1 <- B[, 2];
X2 <- B[, 3];

model <- glm(Y ~X1+X2, family="binomial");
summary(model)
confint.default(model)
""""""""""""""""

Output :
""""""""""""
Call:
glm(formula = Y ~ X1 + X2, family = "binomial")

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-1.7073  -0.9834   0.3804   0.8413   2.0504  

Coefficients:
             Estimate Std. Error z value Pr(>|z|)  
(Intercept) -22.08094    9.03417  -2.444   0.0145 *
X1           -0.03758    0.05049  -0.744   0.4566  
X2            0.13892    0.05870   2.367   0.0179 *
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 44.236  on 31  degrees of freedom
Residual deviance: 34.071  on 29  degrees of freedom
AIC: 40.071

Number of Fisher Scoring iterations: 4
"""""""""""""
"""""""""""""
                  2.5 %      97.5 %
(Intercept) -39.7875820 -4.37430465
X1           -0.1365455  0.06137582
X2            0.0238790  0.25396098
"""""""""""""

Code :
"""""""""""""
modelnull <- glm(Y~1, family="binomial")
anova(modelnull, model, test="Chisq")
"""""""""""""

Output:
""""""""""""""
Analysis of Deviance Table

Model 1: Y ~ 1
Model 2: Y ~ X1 + X2
  Resid. Df Resid. Dev Df Deviance Pr(>Chi)   
1        31     44.236                        
2        29     34.071  2   10.166 0.006202 **
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
""""""""""""""

*/ 

   IMPORT ML;

   value_record := RECORD
         UNSIGNED   rid;
         REAL     age;
         REAL     height;
         integer1   sex; // 0 = female, 1 = male
   END;

   d := DATASET([{1,35,149,0},{2,11,138,0},{3,12,148,1},{4,16,156,0},
                 {5,32,152,0},{6,16,157,0},{7,14,165,0},{8,8,152,1},
                 {9,35,177,0},{10,33,158,1},{11,40,166,0},{12,28,165,0},  
                 {13,23,160,0},{14,52,178,1},{15,46,169,0},{16,29,173,1},
                 {17,30,172,0},{18,21,163,0},{19,21,164,0},{20,20,189,1},
                 {21,34,182,1},{22,43,184,1},{23,35,174,1},{24,39,177,1},
                 {25,43,183,1},{26,37,175,1},{27,32,173,1},{28,24,173,1},
                 {29,20,162,0},{30,25,180,1},{31,22,173,1},{32,25,171,1}]
                 ,value_record);

   ML.ToField(d,flds0);
   f4 := 
      PROJECT(flds0(Number=3)
              ,TRANSFORM(ML.Types.NumericField
                         ,SELF.Number := 4
                         ,SELF.Value := 1-LEFT.Value
                         ,SELF := LEFT
               )
      );
   flds1 := flds0+f4;
   flds := ML.Discretize.ByRounding(flds1);
   LogRegDense := ML.Classify.Logistic(0.0);
   ModelD := LogRegDense.LearnC(flds1(Number<=2),flds(Number=3));
   OUTPUT(LogRegDense.Model(ModelD), NAMED('DenseModel'));
   OUTPUT(LogRegDense.ZStat(ModelD), NAMED('DenseZStat'));
   OUTPUT(LogRegDense.confInt(95, ModelD), NAMED('DenseConfInt'));
   OUTPUT(LogRegDense.ClassifyC(flds1(Number<=2), ModelD), NAMED('DenseClassify'));
   DevD := LogRegDense.DevianceC(flds1(Number<=2),flds(Number=3), ModelD);
   OUTPUT(DevD.ResidDev, NAMED('DenseResidualDev'));
   OUTPUT(DevD.NullDev, NAMED('DenseNullDev'));
   OUTPUT(DevD.AIC, NAMED('DenseAIC'));
   OUTPUT(LogRegDense.AOD(DevD.NullDev, DevD.ResidDev), NAMED('DenseAOD'));
   
   LogRegSparse := ML.Classify.Logistic_sparse(0.0);
   ModelS := LogRegSparse.LearnC(flds1(Number<=2),flds(Number=3));
   OUTPUT(LogRegSparse.Model(ModelS), NAMED('SparseModel'));
   OUTPUT(LogRegSparse.ZStat(ModelS), NAMED('SparseZStat'));
   OUTPUT(LogRegSparse.confInt(95, ModelS), NAMED('SparseConfInt'));
   OUTPUT(LogRegSparse.ClassifyC(flds1(Number<=2), ModelS), NAMED('SparseClassify'));
   DevS := LogRegSparse.DevianceC(flds1(Number<=2),flds(Number=3), ModelS);
   OUTPUT(DevS.ResidDev, NAMED('SparseResidualDev'));
   OUTPUT(DevS.NullDev, NAMED('SparseNullDev'));
   OUTPUT(DevS.AIC, NAMED('SparseAIC'));
   OUTPUT(LogRegSparse.AOD(DevS.NullDev, DevS.ResidDev), NAMED('SparseAOD'));