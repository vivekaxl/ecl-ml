// Model Identification.  Produces Autocorrelation function and
//the partial autocorrelation function datasets.
IMPORT PBblas;
Layout_Cell := PBblas.Types.Layout_Cell;
IMPORT TS.Types;
IMPORT TS;
ObsRec := Types.UniObservation;
EXPORT Identification(DATASET(Types.UniObservation) obs,
                      UNSIGNED degree=0) := MODULE
  SHARED post_difference := TS.DifferenceSeries(obs, degree);
  SHARED LagRec := RECORD
    Types.t_time_ord period;
    Types.t_time_ord lag_per;
    Types.t_value v;
    UNSIGNED2 k;
  END;
  EXPORT DATASET(Types.PACF_ACF) Correlations(UNSIGNED2 lags) := FUNCTION
    z_bar := AVE(post_difference, dependent);
    N := MAX(post_difference, period);
    LagRec explode(ObsRec rec, UNSIGNED c) := TRANSFORM
      k := (c-1) DIV 2;
      adj := (c-1) % 2;
      SELF.period := IF(rec.period + k <= N, rec.period, SKIP);
      SELF.lag_per := rec.period + k + IF(k=0, 0, adj);
      SELF.v := rec.dependent - z_bar;
      SELF.k := k;
    END;
    exploded := NORMALIZE(post_difference, 2*(lags+1), explode(LEFT, COUNTER));
    s_exploded := SORT(exploded, k, lag_per, period);
    LagRec mult(LagRec prev, LagRec curr) := TRANSFORM
      SELF.v := IF(prev.v <> 0.0, prev.v * curr.v, curr.v);
      SELF := curr;
    END;
    products := ROLLUP(s_exploded, mult(LEFT,RIGHT), k, lag_per);
    r_k_denom := products(k=0)[1].v;
    Types.PACF_ACF makeACF(LagRec rec, REAL8 denom) := TRANSFORM
      SELF.lag := rec.k;
      SELF.ac := rec.v / denom;
      SELF := [];
    END;
    rk_pre_t := PROJECT(products(k>0), makeACF(LEFT, r_k_denom));
    // Now calculate the partials
    MatrixRec := RECORD
      PBblas.Types.dimension_t num_rows;
      PBblas.Types.dimension_t num_cols;
      Types.t_value_set matrix;
    END;
    MatrixRec cells2vector(DATASET(Layout_Cell) cells) := TRANSFORM
      SELF.num_rows := lags;
      SELF.num_cols := 1;
      SELF.matrix := PBblas.MakeR8Set(lags,1,1,1,cells, 0, 0.0);
    END;
    Layout_Cell cvt2Cell(Types.PACF_ACF acf) := TRANSFORM
      SELF.x := acf.lag;
      SELF.y := acf.lag;
      SELF.v := acf.ac;
    END;
    rk_cells := GROUP(PROJECT(rk_pre_t, cvt2Cell(LEFT)),TRUE);
    rk_vector := ROLLUP(rk_cells, GROUP, cells2vector(ROWS(LEFT)));
    Types.t_value_set popBlock(PBblas.Types.dimension_t m) := BEGINC++
      #body
      __lenResult = m * m * sizeof(double);
      __isAllResult = false;
      double *rslt = new double[m*m];
      __result = (void*) rslt;
      for (int i=0; i<m*m; i++) rslt[i] = 0.0;
      for (int i=0; i<m*m; i+=m+1) rslt[i] = 1.0;
    ENDC++;
    MatrixRec makeInitial() := TRANSFORM
      SELF.num_rows := lags;
      SELF.num_cols := lags;
      SELF.matrix := popBlock(lags); // identity matrix
    END;
    init_partial := DATASET([makeInitial()]);
    // loop_body(DATASET(ParRec) work, UNSIGNED i) := FUNCTION

    // END;
    // partials := LOOP(init_partial, lags, loop_body(ROWS(LEFT), COUNTER));
    rslt := rk_pre_t;
    RETURN rslt;
  END;
  EXPORT DATASET(Types.CorrRec) ACF(UNSIGNED2 lags) := FUNCTION
    RETURN PROJECT(Correlations(lags),
                   TRANSFORM(Types.CorrRec, SELF.lag:=LEFT.lag,
                             SELF.corr:=LEFT.ac, SELF.t_like:=LEFT.ac_t_like));
  END;
  EXPORT DATASET(Types.CorrRec) PACF(UNSIGNED2 lags) := FUNCTION
    RETURN PROJECT(Correlations(lags),
                   TRANSFORM(Types.CorrRec, SELF.lag:=LEFT.lag,
                            SELF.corr:=LEFT.pac, SELF.t_like:=LEFT.pac_t_like));
  END;
END;