IMPORT ML;
IMPORT ML.Mat AS Mat;
IMPORT ML.DMat AS DMat;
IMPORT PBblas;
IMPORT ML.Classify AS Classify;
IMPORT ML.SVM AS SVM;

a := DATASET('~lsa::train_b_bbc.mtx', Mat.Types.Element, CSV);
a_rows := MAX(a, x);
a_cols := MAX(a, y);
a_map := PBblas.Matrix_Map(a_rows, a_cols, MIN(PBblas.Constants.Block_Vec_Rows, a_rows), a_cols);
Da := DMat.Converted.FromElement(a, a_map);
decomp := ML.LSA.lsa.StandardSVD(a_map, Da, 50);

Q := DATASET('~lsa::train_q_bbc.mtx', Mat.Types.Element, CSV);
U1 := Mat.Mul(Q, Mat.MU.From(decomp, 1));
decomp1 := Mat.MU.To(U1, 1) + decomp(no=2) + decomp(no=3);

V1 := Mat.MU.From(decomp, 3);
V2 := Mat.Sub(V1, Mat.Repmat(Mat.Has(V1).MeanCol, Mat.Has(V1).Stats.XMax, 1));
V3 := Mat.Each.Mul(V2, Mat.Repmat(Mat.Each.Reciprocal(Mat.Has(V1).SDCol), Mat.Has(V1).Stats.XMax, 1));
V := ML.Types.FromMatrix(V3);

labels := DATASET('~lsa::bbc_train.classes', {UNSIGNED4 value}, CSV);
L := PROJECT(labels, TRANSFORM(ML.Types.DiscreteField, SELF.id := COUNTER; SELF.number := 1; SELF.value := LEFT.value + 1));

test := DATASET('~lsa::test_bbc.mtx', Mat.Types.Element, CSV);
test_Q := ML.LSA.lsa.ComputeQueryVectors(decomp1, test);
test_V2 := Mat.Sub(test_Q, Mat.Repmat(Mat.Has(test_Q).MeanCol, Mat.Has(test_Q).Stats.XMax, 1));
test_V3 := Mat.Each.Mul(test_V2, Mat.Repmat(Mat.Each.Reciprocal(Mat.Has(test_Q).SDCol), Mat.Has(test_Q).Stats.XMax, 1));
test_V := ML.Types.FromMatrix(test_V3);

test_labels := DATASET('~lsa::bbc_test.classes', {UNSIGNED4 value}, CSV);
test_L := PROJECT(test_labels, TRANSFORM(ML.Types.DiscreteField, SELF.id := COUNTER; SELF.number := 1; SELF.value := LEFT.value + 1));

Centroids := V(id IN [1, 500, 1000, 1500, 2000]);
KMeans:= ML.Cluster.KMeans(V,Centroids,50,0.0,ML.Cluster.DF.Tanimoto);  
KMeans.Convergence;                                      
KMeans.Allegiances();

