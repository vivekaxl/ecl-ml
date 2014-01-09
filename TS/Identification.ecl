// Model Identification.  Produces autocorrelation function and
//the partial autocorrelation function datasets.
IMPORT PBblas;
Cell := PBblas.Types.Layout_Cell;
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
  SHARED ACF_Rec := RECORD
    UNSIGNED2 k;
    REAL8 ac;           // Auto corr, k
    REAL8 sq;
    REAL8 sum_sq;       // sum of r-squared, k-1 of them
  END;
  // Formulae from Bowerman & O'Connell, Forecasting and Time Series, 1979
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
    ACF_Rec makeACF(LagRec rec, REAL8 denom) := TRANSFORM
      SELF.k := rec.k;
      SELF.ac := rec.v / denom;
      SELF.sq := (rec.v*rec.v) / (denom*denom);
      SELF.sum_sq := 0.0;
    END;
    pre_sumsq := PROJECT(products(k>0), makeACF(LEFT, r_k_denom));
    ACF_Rec accum_sq(ACF_rec prev, ACF_rec curr) := TRANSFORM
      SELF.sum_sq := prev.sum_sq + prev.sq;
      SELF := curr;
    END;
    r_k := ITERATE(pre_sumsq, accum_sq(LEFT,RIGHT));
    // Now calculate the partials
    Cell cvt2Cell(ACF_Rec acf) := TRANSFORM
      SELF.x := acf.k;
      SELF.y := 1;
      SELF.v := acf.ac;
    END;
    Cell mult_k_kj(Cell r_k, Cell r_kj) := TRANSFORM
      SELF.v := r_k.v * r_kj.v;
      SELF.x := r_kj.x + 1;
      SELF.y := r_kj.x + 1;
    END;
    Cell make_rkk(Cell r_k, DATASET(Cell) pairs) := TRANSFORM
      SELF.v := (r_k.v - SUM(pairs, v)) / (1.0 - SUM(pairs, v));
      SELF.x := r_k.x;
      SELF.y := r_k.x;
    END;
    Cell reverse_j(Cell r_kj, Cell r_kk) := TRANSFORM
      SELF.v := r_kj.v * r_kk.v;
      SELF.x := r_kj.x;
      SELF.y := r_kj.x+1 - r_kj.y;  // reverse the entries
    END;
    Cell reduce_kj(Cell r_kj, Cell r_p) := TRANSFORM
      SELF.v := r_kj.v - r_p.v;
      SELF.x := r_kj.x + 1;
      SELF.y := r_kj.y;
    END;
    rk_cells := PROJECT(r_k, cvt2Cell(LEFT));
    init_partial := DATASET([], Cell);
    loop_body(DATASET(Cell) work, UNSIGNED i) := FUNCTION
      work_pairs := JOIN(rk_cells(x<i), work(x=i-1),
                        LEFT.x=i-RIGHT.y,
                        mult_k_kj(LEFT,RIGHT), LOOKUP);
      r_kk := DENORMALIZE(rk_cells(x=i), work_pairs, LEFT.x=RIGHT.x, GROUP,
                          make_rkk(LEFT, ROWS(RIGHT)));
      r_kj_r_kk := JOIN(work(x=i-1), r_kk, TRUE,
                          reverse_j(LEFT, RIGHT), ALL);
      r_kj := JOIN(work(x=i-1), r_kj_r_kk, LEFT.x=RIGHT.x AND LEFT.y=RIGHT.y,
                   reduce_kj(LEFT,RIGHT), LOOKUP);
      RETURN work & r_kk & r_kj;
    END;
    partials := LOOP(init_partial, lags, loop_body(ROWS(LEFT), COUNTER));
    Types.PACF_ACF calc_t(ACF_Rec acf, Cell pacf) := TRANSFORM
      work := 1 / SQRT(N);
      SELF.lag := acf.k;
      SELF.ac := acf.ac;
      SELF.pac := pacf.v;
      SELF.ac_t_like := acf.ac/(SQRT(1+2*acf.sum_sq) * work);
      SELF.pac_t_like := pacf.v / work;;
    END;
    rslt := JOIN(r_k, partials(x=y), LEFT.k=RIGHT.x,
                 calc_t(LEFT, RIGHT), LOOKUP);
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