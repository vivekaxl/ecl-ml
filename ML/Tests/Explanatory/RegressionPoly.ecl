IMPORT ML;
R := RECORD
INTEGER rid;
INTEGER Recs;
INTEGER Pecs;
REAL Time;
END;
d := DATASET([{1,50000, 25, 1.00},{2,500000, 30, 2.29}, {3,5000000,40, 16.15},{4,25000000,50, 80.2},
{5,50000000,60, 163},{6,100000000,70, 316},
{7,10,80, 0.83},{8,1500000,90, 5.63}],R);
ML.ToField(d,flds);
X := flds(number in [1, 2]);
Y := flds(number in [3]);
P := ML.Regress_Poly_X(X,Y,5);
extrapo := sort(P.Extrapolated(X), id);
JOIN(Y,extrapo,LEFT.id=RIGHT.id
         ,transform({UNSIGNED id,REAL actual,REAL extrapo}
                     ,SELF.id:=LEFT.id
                     ,SELF.actual:=LEFT.value
                     ,SELF.extrapo:=RIGHT.value
          )
    );