// moderating analyses




//reg ambi_comm_z ambi_social_conn_i##broker age sex n_size mean_comm mmse i.township
reg ambi_comm_z ambi_social_conn_i##broker
margins, at(ambi_social_conn_i=(0,1) broker=(0,1)) vsquish
marginsplot, xdim(broker ambi_social_conn_i ) recast(bar) xlabel(1 "Conn < Median" 2 "Conn ≥ Median" 3 "Conn < Median" 4 "Conn ≥ Median", labsize(big)) ylabel(0 "-1" 0.5 "-0.5" 1 "0" 1.5 "0.5" 2 "1", labsize(big)) xtitle(" " "Structural Closure                            Structural Brokerage", size(big)) plotopts(barw(.6)) title("(a) Ambivalence score (z)", size(huge)) ytitle("") name(g1)

reg sd_comm_z sd_social_conn_i##broker
margins, at(sd_social_conn_i=(0,1) broker=(0,1)) vsquish
marginsplot, xdim(broker sd_social_conn_i ) recast(bar) xlabel(1 "Conn < Median" 2 "Conn ≥ Median" 3 "Conn < Median" 4 "Conn ≥ Median", labsize(big)) ylabel(0 "-1" 0.5 "-0.5" 1 "0" 1.5 "0.5" 2 "1", labsize(big)) xtitle(" " "Structural Closure                            Structural Brokerage", size(big)) plotopts(barw(.6)) title("(b) Standard deviation (z)", size(huge)) ytitle("") name(g2)

graph combine g1 g2, col(1)
graph display, xsize(1) ysize(1.5)

graph drop g1 g2

graph export "moderating.png", as(png) name("Graph")