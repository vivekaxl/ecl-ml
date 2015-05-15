// Produce a data set of predictions for each model
IMPORT ML.SVM;
IMPORT ML.SVM.LibSVM;
// aliases
Model := SVM.Types.Model;
SVM_Model := LibSVM.Types.ECL_LibSVM_Model;
SVM_Output:= LibSVM.Types.LibSVM_Output;
SVM_Instance := SVM.Types.SVM_Instance;
SVM_Prediction := SVM.Types.SVM_Prediction;
SVM_Predict := LibSVM.SVM_Predict;
LibSVM_Node := LibSVM.Types.LibSVM_Node;
//
EXPORT predict(DATASET(Model) models, DATASET(SVM_Instance) d) := FUNCTION
  LibSVM.Types.LibSVM_Node cvtNode(SVM.Types.SVM_Feature f) := TRANSFORM
    SELF.indx := f.nominal;
    SELF.value := f.v;
  END;
  Work_SV := RECORD
    UNSIGNED4 v_ord;
    DATASET(LibSVM_Node) nodes;
  END;
  Work_SV cvtSV(SVM.Types.SVM_SV sv_rec) := TRANSFORM
    SELF.v_ord := sv_rec.v_ord;
    SELF.nodes := PROJECT(sv_rec.features, cvtNode(LEFT))
                & DATASET([{-1, 0.0}], LibSVM_Node);
  END;
  Work1 := RECORD(SVM_Model)
    SVM.Types.Model_ID id;
  END;
  LibSVM_Node normN(LibSVM_Node node) := TRANSFORM
    SELF := node;
  END;
  Work1 cvtModel(Model m) := TRANSFORM
    sv := NORMALIZE(PROJECT(m.sv, cvtSV(LEFT)), LEFT.nodes, normN(RIGHT));
    SELF.sv := sv;
    SELF.elements := COUNT(sv);
    SELF.nr_nSV := COUNT(m.nSV);
    SELF.pairs_A := COUNT(m.probA);
    SELF.pairs_B := COUNT(m.probB);
    SELF.nr_label := COUNT(m.labels);
    SELF := m;
  END;
  svm_mdls := PROJECT(models, cvtModel(LEFT));
  SVM_Prediction predict(SVM_Instance inst, Work1 m) := TRANSFORM
    x_nodes := PROJECT(inst.x,cvtNode(LEFT))
             & DATASET([{-1,0.0}], LibSVM_Node);
    SELF.id := m.id;
    SELF.rid := inst.rid;
    SELF.target_y := inst.y;
    SELF.predict_y := SVM_Predict(m, x_nodes, SVM_Output.LABEL_ONLY)[1].v;
  END;
  rslt := JOIN(d, svm_mdls, TRUE, predict(LEFT, RIGHT), ALL);
  RETURN rslt;
END;