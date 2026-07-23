		rdrobust log_hog_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(1)

		
		
		
	mean log_pob_ccpp_2013 if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) vce(cl cluster_dist) 

		rdrobust log_pob_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(log_pob_ccpp_2007) p(1)
		
		rdrobust log_pob_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(1)
		
		rdrobust log_pob_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(2)
		
		rdrobust log_pob_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(3)
		
		rdrobust log_pob_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(4)		
		
		
		
		
	mean log_hog_ccpp_2013 if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) vce(cl cluster_dist) 

		rdrobust log_hog_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(log_hog_ccpp_2007) p(1)
		
		rdrobust log_hog_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(1)
		
		rdrobust log_hog_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(2)
		
		rdrobust log_hog_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(3)
		
		rdrobust log_hog_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(4)				
		
		
		
		
	mean log_pob_ccpp_2017 if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_17) vce(cl cluster_dist) 

		rdrobust log_pob_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(log_pob_ccpp_2007) p(1)
		
		rdrobust log_pob_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(1)
		
		rdrobust log_pob_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(2)
		
		rdrobust log_pob_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(3)
		
		rdrobust log_pob_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(4)		
		
		
		
		
	mean log_hog_ccpp_2017 if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_17) vce(cl cluster_dist) 

		rdrobust log_hog_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(log_hog_ccpp_2007) p(1)
		
		rdrobust log_hog_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(1)
		
		rdrobust log_hog_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(2)
		
		rdrobust log_hog_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(3)
		
		rdrobust log_hog_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(altitude_msnm log_distancia_capital ///
		log_hog_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010) p(4)				
				
		
		
		
		
		
		
		
		
		
		