IMPORT ML;
IMPORT $;
//NaiveBayes classifier
trainer:= ML.Classify.NaiveBayes();

// Monk Dataset - Discrete dataset 124 instances x 6 attributes + class
MonkData:= ML.Tests.Explanatory.MonkDS.Train_Data;
ML.ToField(MonkData, fullmds, id);
full_mds:=PROJECT(fullmds, TRANSFORM(ML.Types.DiscreteField, SELF:= LEFT));
indepDataD:= full_mds(number>1);
depDataD := full_mds(number=1);
// Learning Phase
D_Model:= trainer.LearnD(indepDataD, depDataD);
dmodel:= trainer.Model(D_model);
// Classification Phase
D_classDist:= trainer.ClassProbDistribD(indepDataD, D_Model); // Class Probalility Distribution
D_results:= trainer.ClassifyD(indepDataD, D_Model);
// Performance Metrics
D_compare:= ML.Classify.Compare(depDataD, D_results);   // Comparing results with original class
AUC_D0:= ML.Classify.AUC_ROC(D_classDist, 0, depDataD); // Area under ROC Curve for class "0"
AUC_D1:= ML.Classify.AUC_ROC(D_classDist, 1, depDataD); // Area under ROC Curve for class "1"
// OUPUTS
OUTPUT(MonkData, NAMED('MonkData'), ALL);
OUTPUT(SORT(dmodel, id), ALL, NAMED('DiscModel'));
OUTPUT(D_classDist, ALL, NAMED('DisClassDist'));
OUTPUT(D_results, NAMED('DiscClassifResults'), ALL);
OUTPUT(SORT(D_compare.CrossAssignments, c_actual, c_modeled), NAMED('DiscCrossAssig'), ALL); // Confusion Matrix
OUTPUT(AUC_D0, ALL, NAMED('AUC_D0'));
OUTPUT(AUC_D1, ALL, NAMED('AUC_D1'));

