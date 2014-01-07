//
IMPORT PBblas;
EXPORT Types := MODULE
  EXPORT t_time_ord := UNSIGNED4;
  EXPORT t_value := PBblas.Types.value_t;
  EXPORT t_value_set := PBblas.Types.matrix_t;
  EXPORT UniObservation := RECORD
    t_time_ord period;
    t_value dependent;
  END;
  EXPORT CorrRec := RECORD
    UNSIGNED2 lag;
    REAL8 corr;     // auto correlation or partial auto correlation
    REAL8 t_like;   // Similar to t statistic, Box-Jenkins
  END;
  EXPORT PACF_ACF := RECORD
    UNSIGNED2 lag;
    REAL8 ac;           // Auto corr, k
    REAL8 ac_t_like;    // t like Box Jenkins statistic
    REAL8 pac;          // partial auto corr, kk
    REAL8 pac_t_like;   // t-like Box-Jenkins statistic
  END;
  EXPORT Model_Parameters := RECORD
    UNSIGNED1 ar_terms;
    UNSIGNED1 ma_terms;
    UNSIGNED2 degree;
    t_value_set  ar_param;
    t_value_set ma_params;
  END;
END;
