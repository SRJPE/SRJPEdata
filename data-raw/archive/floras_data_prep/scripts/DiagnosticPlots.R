# Diagnostic plots for bayesian survival model

library("rstan")
library("ggplot2")
library("bayesplot")

source("scripts/GetData_flora.R")

# Nov cov model -----------------------------------
load(file="outputs/fit_NoCov.Rdata")

parlist=c("S_bReach","S_bTrib","RE_sd","RE_sdT","pred_pcap","pred_surv","SurvWoodSac","TribSurvForecast","pred_survT") 
print(summary(fit,pars=parlist)$summary)

rhats <- rhat(fit)
mcmc_rhat(rhats)

posterior <- as.array(fit)
np <- nuts_params(fit)
head(np)

pdf(file = "figures/pcapHist_Nocov.pdf",onefile = TRUE) 

for(i in 1:length(Year_all)){
  pars <- c(paste0("pred_pcap[",i,",1]"),paste0("pred_pcap[",i,",2]"),
            paste0("pred_pcap[",i,",3]"),paste0("pred_pcap[",i,",4]"))
  
  Histplot <- mcmc_pairs(posterior, np = np, pars = pars, 
                       off_diag_args = list(size = 0.75),
                       grid_args = list(top=paste0("No Cov model - Year = ",Year_all[i])))
  
  print(Histplot)
}

dev.off()


pdf(file = "figures/psurvHist_Nocov.pdf",onefile = TRUE) 

for(i in 1:dim(rgwy.df)[1]){
  pars <- c(paste0("pred_surv[",i,",1]"),paste0("pred_surv[",i,",2]"),
            paste0("pred_surv[",i,",3]"),paste0("pred_surv[",i,",4]"))
  
  plottitle <-rgwy.df$StudyID[i]
  
  Histplot <- mcmc_pairs(posterior, np = np, pars = pars, 
                         off_diag_args = list(size = 0.75),
                         grid_args = list(top=paste0("No Cov model - ",rgwy.df$StudyID[i])))
  print(Histplot)
}

dev.off()

pdf(file = "figures/pcapTrace_Nocov.pdf",onefile = TRUE) 

for(i in 1:length(Year_all)){
  pars <- c(paste0("pred_pcap[",i,",1]"),paste0("pred_pcap[",i,",2]"),
            paste0("pred_pcap[",i,",3]"),paste0("pred_pcap[",i,",4]"))
  
  Traceplot <- mcmc_trace(fit,pars=pars,n_warmup = 300, facet_args = list(nrow =4))
  Traceplot <- Traceplot + ggtitle(paste0("No Cov model - Year = ",Year_all[i]))
  
  print(Traceplot)
}

dev.off()

# WY2 model ------------------------------------------------
load(file="outputs/fit_CovWY2.Rdata")
parlist=c("S_bReach","S_bTrib","RE_sd","RE_sdT","S_bCov","S_bCovT",
          "pred_pcap","pred_surv","SurvRelSac","SurvWoodSac","TribSurvForecast","pred_survT") 
print(summary(fit,pars=parlist)$summary)

rhats <- rhat(fit)
mcmc_rhat(rhats)

posterior <- as.array(fit)
np <- nuts_params(fit)
head(np)

pdf(file = "figures/pcapHistCovWY2.pdf",onefile = TRUE) 

for(i in 1:length(Year_all)){
  pars <- c(paste0("pred_pcap[",i,",1]"),paste0("pred_pcap[",i,",2]"),
            paste0("pred_pcap[",i,",3]"),paste0("pred_pcap[",i,",4]"))
  
  Histplot <- mcmc_pairs(posterior, np = np, pars = pars, 
                         off_diag_args = list(size = 0.75),
                         grid_args = list(top=paste0("CovWY2 model - Year = ",Year_all[i])))
  
  print(Histplot)
}

dev.off()


pdf(file = "figures/psurvHist_CovWY2.pdf",onefile = TRUE) 

for(i in 1:dim(rgwy.df)[1]){
  pars <- c(paste0("pred_surv[",i,",1]"),paste0("pred_surv[",i,",2]"),
            paste0("pred_surv[",i,",3]"),paste0("pred_surv[",i,",4]"))
  
  plottitle <-rgwy.df$StudyID[i]
  
  Histplot <- mcmc_pairs(posterior, np = np, pars = pars, 
                         off_diag_args = list(size = 0.75),
                         grid_args = list(top=paste0("CovWY2 model - ",rgwy.df$StudyID[i])))
  print(Histplot)
}

dev.off()

pdf(file = "figures/sbCovHist_CovWY2.pdf",onefile = TRUE) 
pars <- c("S_bCov[1]","S_bCov[2]","S_bCovT[1]","S_bCovT[2]")

Histplot <- mcmc_pairs(posterior, np = np, pars = pars, 
                       off_diag_args = list(size = 0.75),
                       grid_args = list(top="CovWY2 model"))

print(Histplot)

dev.off()

pdf(file = "figures/pcapTrace_CovWY2.pdf",onefile = TRUE) 

for(i in 1:length(Year_all)){
  pars <- c(paste0("pred_pcap[",i,",1]"),paste0("pred_pcap[",i,",2]"),
            paste0("pred_pcap[",i,",3]"),paste0("pred_pcap[",i,",4]"))
  
  Traceplot <- mcmc_trace(fit,pars=pars,n_warmup = 300, facet_args = list(nrow =4))
  Traceplot <- Traceplot + ggtitle(paste0("WY2 model - Year = ",Year_all[i]))
  
  print(Traceplot)
}

dev.off()


# WY3 model ------------------------------------------------
load(file="outputs/fit_CovWY3.Rdata")
parlist=c("S_bReach","S_bTrib","RE_sd","RE_sdT","S_bCov","S_bCovT",
          "pred_pcap","pred_surv","SurvRelSac","SurvWoodSac","TribSurvForecast","pred_survT") 
print(summary(fit,pars=parlist)$summary)

rhats <- rhat(fit)
mcmc_rhat(rhats)

posterior <- as.array(fit)
np <- nuts_params(fit)
head(np)

pdf(file = "figures/pcapHistCovWY3.pdf",onefile = TRUE) 

for(i in 1:length(Year_all)){
  pars <- c(paste0("pred_pcap[",i,",1]"),paste0("pred_pcap[",i,",2]"),
            paste0("pred_pcap[",i,",3]"),paste0("pred_pcap[",i,",4]"))
  
  Histplot <- mcmc_pairs(posterior, np = np, pars = pars, 
                         off_diag_args = list(size = 0.75),
                         grid_args = list(top=paste0("CovWY3 model - Year = ",Year_all[i])))
  
  print(Histplot)
}

dev.off()


pdf(file = "figures/psurvHist_CovWY3.pdf",onefile = TRUE) 

for(i in 1:dim(rgwy.df)[1]){
  pars <- c(paste0("pred_surv[",i,",1]"),paste0("pred_surv[",i,",2]"),
            paste0("pred_surv[",i,",3]"),paste0("pred_surv[",i,",4]"))
  
  plottitle <-rgwy.df$StudyID[i]
  
  Histplot <- mcmc_pairs(posterior, np = np, pars = pars, 
                         off_diag_args = list(size = 0.75),
                         grid_args = list(top=paste0("CovWY3 model - ",rgwy.df$StudyID[i])))
  print(Histplot)
}

dev.off()

pdf(file = "figures/sbCovHist_CovWY3.pdf",onefile = TRUE) 
pars <- c("S_bCov[1]","S_bCov[2]","S_bCovT[1]","S_bCovT[2]")

Histplot <- mcmc_pairs(posterior, np = np, pars = pars, 
            off_diag_args = list(size = 0.75),
            grid_args = list(top="CovWY3 model"))

print(Histplot)

dev.off()

pdf(file = "figures/pcapTrace_CovWY3.pdf",onefile = TRUE) 

for(i in 1:length(Year_all)){
  pars <- c(paste0("pred_pcap[",i,",1]"),paste0("pred_pcap[",i,",2]"),
            paste0("pred_pcap[",i,",3]"),paste0("pred_pcap[",i,",4]"))
  
  Traceplot <- mcmc_trace(fit,pars=pars,n_warmup = 300, facet_args = list(nrow =4))
  Traceplot <- Traceplot + ggtitle(paste0("WY3 model - Year = ",Year_all[i]))
  
  print(Traceplot)
}

dev.off()
