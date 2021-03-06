#### ANALYSIS EXAMPLE: RANDOM INTERCEPTS & SLOPES ####
## Description: This file analyzes Zillow dataset assuming random intercept
##              and random slopes for 150 largest metros
## Author: Michael Bader

## SHOW THAT SLOPES DO VARY ACROSS METRO AREAS IN ZILLOW DATA
source('R/01d_randomintercepts_analysis.R')
betas <- by(zillow.long,zillow.long$RegionID,function(d) lm(lnvalue_ti~month,data=d))
slopes <- t(sapply(betas,coef))[,"month"]
qplot(slopes,bins=15)

## Prepare environment
rm(list=ls()[!(ls()%in% "zillow.long")]) ## Removes all variables from
                                         ## environment except zillow.long
source('_functions.R')
library(MASS)
library(lme4)
library(ggplot2)
library(cowplot)

## GATHER THE DATA
## The data are the same as those used in the random intercept model

## DESCRIBE THE DATA
g.sim <- ggplot(zillow.long,aes(x=month,y=lnvalue_ti,group=RegionID)) +
            geom_line()
g.sim

sampsize <- 30
samp <- sample(zillow.long$RegionName,sampsize)
g.samp <- ggplot(zillow.long[zillow.long$RegionName%in%samp,],
                 aes(x=month,y=lnvalue_ti,group=RegionName)) +
            geom_line()
g.samp

## ANALYZE THE DATA
m.ana <- lmer(lnvalue_ti ~ month + (1 + month | RegionID),data=zillow.long)
summary(m.ana)
m.ana.re <- ranef(m.ana)$RegionID

test <- m.ana.re[abs(m.ana.re[,1])<.02,]
zillow.long[zillow.long$RegionID%in%rownames(test),"RegionName"]

## INTERPRET THE DATA
g.pred <- geom_abline(intercept=m.ana@beta[1],slope=m.ana@beta[2],
                      col="orange",size=1.2)
g.ana <- ggplot(data=zillow.long,aes(x=month,y=lnvalue_ti,group=RegionID)) +
            geom_line() +
            g.pred +
            scale_x_continuous(breaks=seq(0,24,1),labels=rep(month.abb,3)[3:27])
g.ana

## Record predicted values and total error
zillow.long$lnvalue_ti_hat <- predict(m.ana,re.form=NA)
zillow.long$e_tot <- zillow.long$lnvalue_ti - zillow.long$lnvalue_ti_hat ## Total error

## Record stochastic components of the model
m.ana.re <- ranef(m.ana)[["RegionID"]]
zillow.long$r_0i <- rep(m.ana.re[,1], each=25)
zillow.long$r_1i <- rep(m.ana.re[,2], each=25)
zillow.long$r_1iXt <- zillow.long$r_1i * zillow.long$month
zillow.long$e_ti <- (zillow.long$e_tot - zillow.long$r_0i - zillow.long$r_1iXt)

## Examine distribution of residuals
g.r0i <- qplot(m.ana.re[,1], bins=10)        ## Distribution of r_0i
g.r1i <- qplot(m.ana.re[,2], bins=10)        ## Distribution of r_1i
g.eti <- qplot(zillow.long$e_ti, bins=1000)  ## Distribution of e_ti
(g.err <- plot_grid(g.r0i, g.r1i, g.eti, ncol=1))

## EXAMPLE METRO-SPECIFIC TRENDS
ex.metros <- c(394640,394974,395012)
zillow.ex.metros <- zillow.long[zillow.long$RegionID%in%ex.metros,]
g.ex <- ggplot(zillow.ex.metros,
       aes(x=month,y=lnvalue_ti,color=RegionName)) +
    geom_line(size=.75,linetype=2) +
    geom_smooth(method="lm",se=FALSE,size=.5) +
    g.pred
g.ex
ggsave("images/0105_randominterceptsslopes_example.png",
       plot=g.ex,height=2.5,width=4,units="in")

(ex.tbl <- zillow.ex.metros[zillow.ex.metros$month==0,c("RegionName","r_0i","r_1i")])

## Ignore Below (used for writing values to my lecture notes)
m.ana.fe <- fixef(m.ana)
f <- file("lecture/_0105-analysis-estimates.tex")
corrcoef <- attr(VarCorr(m.ana)$RegionID, "correlation")
writeLines(c(
    paste0("\\newcommand{\\intercept}{",round(m.ana.fe[1],3),"}"),
    paste0("\\newcommand{\\interceptexp}{", round(exp(m.ana.fe[1])), "}"),
    paste0("\\newcommand{\\slope}{",round(m.ana.fe[2], 5),"}"),
    paste0("\\newcommand{\\slopepct}{",round(m.ana.fe[2]*100, 3),"}"),
    paste0("\\newcommand{\\slopeexp}{", round(exp(m.ana.fe[2]), 2),"}"),
    paste0("\\newcommand{\\tauint}{", round(vcov(m.ana)[1,1], 4), "}"),
    paste0("\\newcommand{\\sqrttauint}{", round(sqrt(vcov(m.ana)[1,1]), 4), "}"),
    paste0("\\newcommand{\\tauintpct}{", round(sqrt(vcov(m.ana)[1,1])*100, 2), "}"),
    paste0("\\newcommand{\\tauslp}{", round(vcov(m.ana)[2,2], 11), "}"),
    paste0("\\newcommand{\\sqrttauslp}{", round(sqrt(vcov(m.ana)[2,2]), 4), "}"),
    paste0("\\newcommand{\\tauslppct}{", round(sqrt(vcov(m.ana)[2,2])*100, 2), "}"),
    paste0("\\newcommand{\\taucor}{", round(vcov(m.ana)[1,2], 6), "}"),
    paste0("\\newcommand{\\sqrttaucor}{", round(corrcoef[1,2], 3), "}"),
    paste0("\\newcommand{\\sigmaparsq}{", round(attr(VarCorr(m.ana), "sc")^2, 6), "}"),
    paste0("\\newcommand{\\sigmapar}{", round(attr(VarCorr(m.ana), "sc"), 4), "}"),
    
    paste0("\\newcommand{\\grarnot}{", round(ex.tbl[1,2], 3), "}"),
    paste0("\\newcommand{\\grarone}{", round(ex.tbl[1,3], 5), "}"),
    paste0("\\newcommand{\\phlrnot}{", round(ex.tbl[2,2], 3), "}"),
    paste0("\\newcommand{\\phlrone}{", round(ex.tbl[2,3], 5), "}"),
    paste0("\\newcommand{\\ralrnot}{", round(ex.tbl[3,2], 3), "}"),
    paste0("\\newcommand{\\ralrone}{", round(ex.tbl[3,3], 5), "}")
    
    
),f)
close(f)

