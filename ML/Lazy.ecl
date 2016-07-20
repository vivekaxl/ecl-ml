IMPORT ML;
/*
Instance-based learning
From Wikipedia, the free encyclopedia http://en.wikipedia.org/wiki/Instance-based_learning
In machine learning, instance-based learning or memory-based learning is a family of learning algorithms that, 
instead of performing explicit generalization, compare new problem instances with instances seen in training, 
which have been stored in memory. Instance-based learning is a kind of lazy learning.
*/
EXPORT Lazy:= MODULE
  SHARED l_result := ML.Types.l_result;
  // General KNN Classifier
  EXPORT KNN(CONST ML.Types.t_count NN_count=5) := MODULE,VIRTUAL
    EXPORT MajorityVote(DATASET(ML.NearestNeighborsSearch.NN) NNeighbors ,DATASET(ML.Types.DiscreteField) depData):= FUNCTION
      allClass:=JOIN(depData, NNeighbors, LEFT.id=RIGHT.id, TRANSFORM(ML.Types.NumericField, SELF.id:= RIGHT.qp_id, SELF.number:=LEFT.number, SELF.value:= LEFT.value));
      cntclass:= TABLE(allClass,{id, number, value, cnt:= COUNT(GROUP)}, id, number, value);
      dedupClass:= DEDUP(SORT(cntClass, id, -cnt), id);
      RETURN PROJECT(dedupClass, TRANSFORM(l_result, SELF.conf:= LEFT.cnt/NN_count, SELF:=LEFT));
    END;
    EXPORT ClassifyC(DATASET(ML.Types.NumericField) indepData , DATASET(ML.Types.DiscreteField) depData ,DATASET(ML.Types.NumericField) queryPointsData):= DATASET([],l_result);
    EXPORT TestC(DATASET(ML.Types.NumericField) indepData, DATASET(ML.Types.DiscreteField) depData) := FUNCTION
			res := ClassifyC(indepData, depData, indepData);
			RETURN ML.Classify.COmpare(depData, res);
		END;
  END; // End of General KNN Classifier
  
  // Particular KNN Classifier => using KDTree Nearest Neighbors Search
  EXPORT KNN_KDTree(CONST ML.Types.t_count NN_count=5, ML.Types.t_level Depth=10,ML.Types.t_level MedianDepth=15):= MODULE(KNN(NN_count))
    KNNSearch:= ML.NearestNeighborsSearch.KDTreeNNSearch(NN_count, Depth, MedianDepth);
    EXPORT ClassifyC(DATASET(ML.Types.NumericField) indepData , DATASET(ML.Types.DiscreteField) depData ,DATASET(ML.Types.NumericField) queryPointsData):= FUNCTION
      Neighbors:= KNNSearch.SearchC(indepData , queryPointsData);
      RETURN  MajorityVote(Neighbors, depData);
    END;
  END;
END;
