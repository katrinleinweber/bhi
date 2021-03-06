##################################
## fisheries
## MRF Feb 17 2016
##################################
library(dplyr)
library(tidyr)
library(readr)
library(stringr)

## Directories
dir_baltic = '~/github/bhi/baltic2015'
dir_layers = file.path(dir_baltic, 'layers')
dir_prep   = file.path(dir_baltic, 'prep')
dir_fis = file.path(dir_prep, 'FIS')
dir_np  = file.path(dir_prep, 'NP')


###########################################################################

## prepare layers for FIS and NP goals.
  ## FIS stocks: cod_2224, cod_2532, her_3a22, her_2532, her_riga, her_30
  ## NP  stocks: spr_2232 # sprat is fished, but not for human consumption. NP goal.
  # unique(scores$stock)
  # cod_2224 cod_2532 her_3a22 her_2532 her_riga her_30   spr_2232


## Read in data layers ----
## filter layers for FIS and NP, save.

goal_stocks = c('FIS', 'NP')
for (g in goal_stocks) { # g = 'FIS' g = 'NP'

  scores <- read.csv(file.path(dir_fis, 'data/FIS_scores.csv')) %>%
    mutate(stock = as.character(stock)) %>%
    dplyr::rename(rgn_id = region_id)

  landings <- read.csv(file.path(dir_fis,'data/FIS_landings.csv')) %>%
    dplyr::rename(rgn_id=region_id)


  ## select the stocks appropriate to the goal
  if (g == 'FIS') {

    scores = scores %>%
      filter(!stock == 'spr_2232') # only select cod and herring

    landings = landings %>%
      filter(!stock == 'spr_2232') # only select cod and herring

  } else if (g == 'NP') {

    scores = scores %>%
      filter(stock == 'spr_2232') # only select sprat

    landings = landings %>%
      filter(stock == 'spr_2232') # only select sprat

  }



  ## separate objects for bbmsy and ffmsy
  scores.bbmsy = scores %>%
    filter(metric == "bbmsy") %>%
    select(-metric)

  scores.ffmsy = scores %>%
    filter(metric == "ffmsy") %>%
    select(-metric)


  ## save to layers folder
  if (g == 'FIS') {

    write.csv(scores.bbmsy, file.path(dir_layers, 'fis_bbmsy_bhi2015.csv'),    row.names=FALSE)
    write.csv(scores.ffmsy, file.path(dir_layers, 'fis_ffmsy_bhi2015.csv'),    row.names=FALSE)
    write.csv(landings,     file.path(dir_layers, 'fis_landings_bhi2015.csv'), row.names=FALSE)

  } else if (g == 'NP') {

    write.csv(scores.bbmsy, file.path(dir_layers, 'np_bbmsy_bhi2015.csv'),    row.names=FALSE)
    write.csv(scores.ffmsy, file.path(dir_layers, 'np_ffmsy_bhi2015.csv'),    row.names=FALSE)
    write.csv(landings,     file.path(dir_layers, 'np_landings_bhi2015.csv'), row.names=FALSE)

  }

}


##################################################################

## NING TODO: generalize this to visualize NP data too

### save for VISUALIZE
fis_bbmsy_time_data = scores.bbmsy %>%
                           select(year,
                                  value = score,
                                  ices = stock)%>%
                           distinct()%>%
                           mutate(unit = NA,
                                  data_descrip= "B/Bmsy",
                                  bhi_goal="FIS")

fis_ffmsy_time_data = scores.ffmsy %>%
  select(year,
         value = score,
         ices = stock)%>%
  distinct()%>%
  mutate(unit = NA,
         data_descrip= "F/Fmsy",
         bhi_goal="FIS")

fis_landings_time_data = landings%>%
                         select(-rgn_id)%>%
                          dplyr::rename(ices = stock,
                                       value = landings)%>%
                        distinct()%>%
                         mutate(unit= "tonnes",
                                bhi_goal = "FIS",
                                data_descrip = "ICES area landings")

write.csv(fis_bbmsy_time_data, file.path(dir_baltic,'visualize/fis_bbmsy_time_data.csv'),row.names = FALSE)
write.csv(fis_ffmsy_time_data, file.path(dir_baltic,'visualize/fis_ffmsy_time_data.csv'),row.names = FALSE)
write.csv(fis_landings_time_data, file.path(dir_baltic,'visualize/fis_landings_time_data.csv'),row.names = FALSE)


##########################################################################



##########################################################################
## STATUS AND TREND CALCULATIONS
##########################################################################
#### The code below is now incorporated into functions.r


scores <- read.csv(file.path(dir_fis,
                             'data/FIS_scores.csv')) %>%
  filter(!stock == 'spr_2232') %>%
  spread(metric, score)

###########################################################################
## STEP 1: converting B/Bmsy and F/Fmsy to F-scores
## see plot describing the relationship between these variables and scores
## this may need to be adjusted:
###########################################################################
F_scores <- scores %>%
  mutate(score = ifelse(bbmsy < 0.8 & ffmsy >= (bbmsy+1.5), 0, NA),
         score = ifelse(bbmsy < 0.8 & ffmsy < (bbmsy - 0.2), ffmsy/(bbmsy-0.2), score),
         score = ifelse(bbmsy < 0.8 & ffmsy >= (bbmsy + 0.2) & ffmsy < (bbmsy + 1.5), (bbmsy + 1.5 - ffmsy)/1.5, score),
         score = ifelse(bbmsy < 0.8 & ffmsy >= (bbmsy - 0.2) & ffmsy < (bbmsy + 0.2), 1, score)) %>%
  mutate(score = ifelse(bbmsy >= 0.8 & ffmsy < 0.8, ffmsy/0.8, score),
         score = ifelse(bbmsy >= 0.8 & ffmsy >= 0.8 & ffmsy < 1.2, 1, score),
         score = ifelse(bbmsy >= 0.8 & ffmsy >= 1.2, (2.5 - ffmsy)/1.3, score)) %>%
  mutate(score = ifelse(score <= 0, 0.1, score)) %>%
  mutate(score_type = "F_score")
### NOTE: The reason the last score is 0.1 rather than zero is because
### scores can't be zero if using a geometric mean because otherwise, 1 zero
### results in a zero score.

###########################################################################
## STEP 2: converting B/Bmsy to B-scores
###########################################################################
B_scores <- scores %>%
  mutate(score = ifelse(bbmsy < 0.8 , bbmsy/0.8, NA),
         score = ifelse(bbmsy >= 0.8 & bbmsy < 1.5, 1, score),
         score = ifelse(bbmsy >= 1.5, (3.35 - bbmsy)/1.8, score)) %>%
  mutate(score = ifelse(score <= 0.1, 0.1, score)) %>%
  mutate(score = ifelse(score > 1, 1, score))%>%
  mutate(score_type = "B_score")

# to see what relationship between B/Bmsy and B_score looks like:
plot(score ~ bbmsy, data=B_scores, type="p")
###########################################################################
## STEP 3: Averaging the F and B-scores to get the stock status score
###########################################################################
scores <- rbind(B_scores, F_scores) %>%
  group_by(region_id, stock, year) %>%
  summarize(score = mean(score, na.rm=TRUE)) %>%
  data.frame()

#############################################
## STEP 4: calculating the weights.
#############################################

landings <- read.csv(file.path(dir_fis,'data/FIS_landings.csv')) %>%
  filter(!stock == 'spr_2232')

##### Subset the data to include only the most recent 10 years
landings <- landings %>%
  filter(year %in% (max(landings$year)-9):max(landings$year))


## we use the average catch for each stock/region across all years
## to obtain weights
weights <- landings %>%
  group_by(region_id, stock) %>%
  mutate(avgCatch = mean(landings)) %>%
  ungroup() %>%
  data.frame()

## each region/stock will have the same average catch across years:
filter(weights, region_id==3)

## determine the total proportion of catch each stock accounts for:
weights <- weights %>%
  group_by(region_id, year) %>%
  mutate(totCatch = sum(avgCatch)) %>%
  ungroup() %>%
  mutate(propCatch = avgCatch/totCatch)

#### The total proportion of landings for each region/year will sum to one:
filter(weights, region_id ==3, year==2014)

############################################################
#####  STEP 5: Join scores and weights to calculate status
############################################################

status <- weights %>%
  left_join(scores, by=c('region_id', 'year', 'stock')) %>%
  filter(!is.na(score)) %>%                    # remove missing data
  select(region_id, year, stock, propCatch, score)        # cleaning data


### Geometric mean weighted by proportion of catch in each region
status <- status %>%
  group_by(region_id, year) %>%
  summarize(status = prod(score^propCatch)) %>%
  ungroup() %>%
  data.frame()

### To get trend, get slope of regression model based on most recent 5 years
### of data

trend_years <- (max(status$year)-4):max(status$year)

trend <- status %>%
  group_by(region_id) %>%
  filter(year %in% trend_years) %>%
  do(mdl = lm(status ~ year, data=.)) %>%
  summarize(region_id = region_id,
            trend = coef(mdl)['year'] * 5) %>%  ## trend multiplied by 5 to get prediction 5 years out
  ungroup() %>%
  mutate(trend = round(trend, 2))

# can do a check to make sure it looks right:
data.frame(filter(status, region_id==3))
lm(c(0.8209574,0.9523321,0.9685960, 0.8845136, 0.8571231) ~ trend_years)
0.0004513 * 5
## results match....looks like everything went well!

### final formatting of status data:
status <- status %>%
  filter(year == max(year)) %>%
  mutate(status = round(status * 100, 1)) %>%
  select(region_id, status)


##### save the data (eventually these steps will be incorporated into the OHI toolbox)
write.csv(status, file.path(dir_fis ,'data/FIS_status.csv'), row.names=FALSE)
write.csv(trend,  file.path(dir_fis ,'data/FIS_trend.csv'), row.names = FALSE)



##############################################
## PLOT RESULTS
library(ggplot2)

##-----------------------------------------------##
## FINAL STATUS AND TREND
## Read in the status and trend csv for plotting
status = read.csv(file.path(dir_fis,
                   'data/FIS_status.csv'))
trend = read.csv(file.path(dir_fis,
                            'data/FIS_trend.csv'))


## Plot FIS status and trend by BHI region
# windows()
par(mfrow=c(1,2), mar=c(1,1,1,1), oma=c(2,2,2,2))
plot(status~region_id, data=status, pch=19, cex=1,
     xlim=c(0,43), ylim=c(0,100),
     ylab="Status", xlab="")

par(new=FALSE)
plot(trend~region_id, data=trend, pch=19, cex=1,
     xlim=c(0,43), ylim=c(-1,1),
     ylab="Trend", xlab="")
abline(h=0)

mtext("BHI region", side=1, line=1, outer=TRUE)
mtext("FIS Status and Trend - All Stocks", side=3, line=.5, outer=TRUE, cex=1.5)
##-----------------------------------------------##
##-----------------------------------------------##
## INITIAL SCORES
## Read in initial scores (code line 14-16) and plot

scores <- read.csv(file.path(dir_fis,
                             'data/FIS_scores.csv')) %>%
  spread(metric, score)

## BBMSY
ggplot(scores) + geom_point(aes(year,bbmsy), color="black") +
  facet_wrap(~stock)

##FFMSY
ggplot(scores) + geom_point(aes(year,ffmsy), color="black") +
  facet_wrap(~stock)
##-----------------------------------------------##
##-----------------------------------------------##
## SCORES based on BBMSY and FFMSY OVER TIME
## Run code up to lines 23-31 and plot rescaled scores
ggplot(scores)+ geom_point(aes(year,score), color="black") +
  facet_wrap(~stock)

##-----------------------------------------------##
##-----------------------------------------------##
## STATUS weighted by propCatch Over time
## Run up to line 83 in the code

ggplot(status)+ geom_point(aes(year,status)) +
  facet_wrap(~region_id)+
  xlim(c(2005,2015)) +
  theme(axis.text.x = element_text(colour="grey20", size=8, angle=90,
                                   hjust=.5, vjust=.5))


##### Compare FIS status and trend with and without sprat -  9.13.2016

## read in files

status_old <- read_csv(file.path(dir_fis, 'data', 'FIS_status_6.2016.csv')) %>%
  dplyr::rename(with_sprat = status) #head(status_old)
trend_old <-  read_csv(file.path(dir_fis, 'data', 'FIS_trend_6.2016.csv')) %>%
  dplyr::rename(with_sprat = trend)
status_new <- read_csv(file.path(dir_fis, 'data', 'FIS_status.csv')) %>%
  dplyr::rename(without_sprat = status)
trend_new <- read_csv(file.path(dir_fis, 'data', 'FIS_trend.csv')) %>%
  dplyr::rename(without_sprat = trend)

## combine old and new
status_all <- full_join(status_old, status_new, by = "region_id") %>%
  gather(key = type, value = status, 2:3 )

trend_all <- full_join(trend_old, trend_new, by = 'region_id') %>%
  gather(key = type, value = trend, 2:3)

## plot comparison
ggplot(status_all, aes(region_id, status, fill = type)) +
  geom_bar(position = 'dodge', stat = 'identity') +
  labs(title = 'Comparison of FIS status with and without sprat')

ggplot(trend_all, aes(region_id, trend, fill = type)) +
  geom_bar(position = 'dodge', stat = 'identity') +
  labs(title = 'Comparison of FIS trend with and without sprat')

#### comparing FP scores with and without sprat

fp_old = read_csv(file.path(dir_baltic, 'scores_old.csv')) %>%
  filter(goal == "FP",
         dimension %in% c("status", "trend")) %>%
  mutate(dimension = str_replace_all(dimension, "status", "old_status"),
         dimension = str_replace_all(dimension, "trend", "old_trend"))

fp_new = read_csv(file.path(dir_baltic, 'scores.csv')) %>%
  filter(goal == "FP",
         dimension %in% c("status", "trend")) %>%
  mutate(dimension = str_replace_all(dimension, "status", "new_status"),
         dimension = str_replace_all(dimension, "trend", "new_trend"))

fp_all = rbind(fp_old, fp_new)

status = fp_all %>%
  filter(dimension %in% c("old_status", "new_status"))

trend = fp_all %>%
  filter(dimension %in% c("old_trend", "new_trend"))

# plot
ggplot(status, aes(region_id, score, fill = dimension)) +
  geom_bar(position = 'dodge', stat = 'identity')

ggplot(trend, aes(region_id, score, fill = dimension)) +
  geom_bar(position = 'dodge', stat = 'identity')
