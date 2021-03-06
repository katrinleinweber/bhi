##----------------------------------------##
## FILE:  raw_pcb_data_prep.r
##----------------------------------------##

## This file is to prep raw PCB data from ICES and IVL so there will be consistent data for the database at level 1

##----------------------------------------##
## LIBRARIES

library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(RMySQL)
library(stringr)
library(tools)
library(rprojroot)

##----------------------------------------##
##FILE PATHS
## rprojroot
root <- rprojroot::is_rstudio_project

## make_path() function to
make_path <- function(...) rprojroot::find_root_file(..., criterion = is_rstudio_project)

dir_layers = make_path('baltic2015/layers') # replaces  file.path(dir_baltic, 'layers')

source('~/github/bhi/baltic2015/prep/common.r')
dir_cw    = file.path(dir_prep, 'CW')
dir_con    = file.path(dir_prep, 'CW/contaminants')


########################################################################################
## PCB ##
########################################################################################

##----------------------------------------##
## Read in ICES data
##----------------------------------------##
ices_raw = read.csv(file.path(dir_con, '/raw_prep/ICES_herring_pcb_dowload_22april2016_cleaned.csv'),
                   sep=";")
head (ices_raw)
dim(ices_raw)
str(ices_raw)


##----------------------------------------##
## Read in unit conversion lookup
##----------------------------------------##
unit_lookup = read.csv(file.path(dir_con,'unit_conversion_lookup.csv'),sep=";")
unit_lookup

#----------------------------------------##
## ICES Check number of dates and years sample by country
##----------------------------------------##

ices_country_year = ices_raw %>%
                    select(Country,year) %>%
                    distinct(.) %>%
                    arrange(Country,year)
ices_country_year

## get last year for each country

ices_country_year %>% group_by(Country) %>% summarise(last(year)) %>% ungroup()
# Country last(year)
# (fctr)      (dbl)
# 1 Estonia       2008
# 2 Finland       2012
# 3 Germany       2013
# 4  Latvia       2002
# 5  Poland       2014
# 6  Sweden       2013

##----------------------------------------##
## ICES data cleaning and manipulations
##----------------------------------------##

##----------------------------------------##
## ICES change column names
## ICES column name descriptor(http://dome.ices.dk/Download/Contaminants%20and%20effects%20of%20contaminants%20in%20biota.pdf)
##----------------------------------------##

ices1 = ices_raw %>% dplyr::rename(monit_program =MPROG, monit_purpose = PURPM,
                                country=Country, report_institute =RLABO,
                                station=STATN, monit_year=MYEAR, date_ices =DATE,
                                day=day, month=month,year=year,date=date,
                                latitude=Latitude, longitude = Longitude,
                                species=Species, sex_specimen=SEXCO,num_indiv_subsample=NOINP,
                                matrix_analyzed=MATRX,not_used_in_datatype=NODIS,
                                param_group=PARGROUP,variable=PARAM, basis_determination=BASIS, qflag=QFLAG,
                                value=Value,unit = MUNIT, vflag=VFLAG, detect_lim = DETLI,
                                quant_lim = LMQNT, uncert_val = UNCRT, method_uncert=METCU,
                                analyt_lab=ALABO, ref_source = REFSK, method_storage =METST,
                                method_pretreat = METPT,method_pur_sep = METPS, method_chem_fix= METFP,
                                method_chem_extract =METCX,method_analysis =METOA, formula_calc=FORML,
                                test_organism=Test.Organism, sampler_type =SMTYP, sub_samp_id =SUBNO,
                                bulk_id = BULKID, factor_compli_interp = FINFL,
                                analyt_method_id = tblAnalysisID, measurement_ref = tblParamID,
                                sub_samp_ref = tblBioID, samp_id= tblSampleID)

colnames(ices1)

##Key columns
##basis_determination : L = lipid weight, D=dry weight, W = wet weight

## Improve clarity of column content

ices2 = ices1 %>%
  mutate(basis_determination = ifelse(basis_determination =="L", "lipid weight",
                               ifelse(basis_determination =="W", "wet weight",
                               ifelse(basis_determination =="D", "dry weight",""))),
         matrix_analyzed = ifelse(matrix_analyzed =="LI", "liver",
                                       ifelse(matrix_analyzed =="MU", "muscle",
                                              ifelse(matrix_analyzed =="WO", "whole organism",""))))

## which ids are most unique
length(unique(ices2$sub_samp_id)) #2123
length(unique(ices2$bulk_id)) #1
length(unique(ices2$sub_samp_ref)) #5105
length(unique(ices2$samp_id)) #558
length(unique(ices2$measurement_ref)) #51441

##----------------------------------------##
## ICES restrict data to >= 2000 , perhaps more consistent data
##----------------------------------------##

ices3 = ices2 %>% filter(year >= 2000)
dim(ices2); dim(ices3)


##----------------------------------------##
## ICES parameters & conversion
## lipid v. weight weight, units
##----------------------------------------##

##What are the specific parameters
 ##unique parameter groups and associated variables
ices3 %>% select(param_group,variable) %>% distinct(.) %>% arrange(param_group, variable)
    ## lipid content, etc. needed to convert lipid basis samples into the wet weight are in the B-BIO column

    ## Links to B-BIO variable code:  http://vocab.ices.dk/?ref=78
    ## Linkes to OC-CB variable codes: http://vocab.ices.dk/?ref=37

## Remove specific variables
## remove PCB, SCB , SCB7 - these are summarized data or depreciated codes
ices3 = ices3 %>% filter(variable != "PCB" & variable != "SCB")
    ##check
    ##ices3 %>% select(param_group,variable) %>% distinct(.) %>% arrange(param_group, variable)


## remove liver samples, keep muscle and whole organism measurements

ices3 = ices3 %>%
        filter(matrix_analyzed !="liver") ## remove samples for liver tissue, keep muscle and whole organism (this is for length, weight)


## Align all measurements with sub_samp_ref (most unqiue)
## check, any observations do not have sub_samp_ref?
ices3 %>% filter(is.na(sub_samp_ref))  ## all observations have a subsample ref

ices3 %>% filter(vflag !="A") %>% select(vflag) %>%distinct(.)  ## A = acceptable, all others are blank, no problems

##----------------------------------------##
##----------------------------------------##
## ICES separate data into 3 objects
##----------------------------------------##

##----------------------------------------##
## Look-up methods
ices_lookup= ices3 %>%
  select(c(monit_program:not_used_in_datatype,analyt_lab:samp_id, param_group,variable,qflag,detect_lim,quant_lim,uncert_val,method_uncert))
str(ices_lookup)

##save ices lookup
#write.csv(ices_lookup, file.path(dir_con, 'raw_prep/ices_lookup_unique_measurements.csv'))

##----------------------------------------##



##----------------------------------------##
## b-bio data
## These data are length, weight, fat and lipid content
##----------------------------------------##
ices3_bbio = ices3 %>%
  select(c(station,latitude,longitude,date,sub_samp_ref,sub_samp_id,samp_id,param_group,matrix_analyzed,basis_determination,variable,unit,value))%>% ## reorder columns, identifiers first, only variables and values
  filter(param_group == "B-BIO") %>% ## select only B-BIO
  mutate(variable = paste(variable,unit,sep="_"))  %>%  #combine variable with measurement unit
  select(-unit)%>% ## no longer needed
  arrange(station,date,sub_samp_ref)

## DUPLICATE PROBLEMS (data year >= 2000)
dim(ices3_bbio) #12698    11
ices3_bbio %>% select(-value)%>% distinct(.) %>% nrow()#12674; 24 duplicate rows


## find duplicates, look at sub_samp_ref and variable
ices3_bbio %>% group_by(station,date,sub_samp_ref,variable, matrix_analyzed)%>%summarise(n=n()) %>% ungroup()%>% filter(n>1) ## 24 unique sub_samp_ref & variables

  ## Duplicated sub_samp_ref IDs
  duplicated_1 = ices3_bbio %>% group_by(station,date,sub_samp_ref,variable)%>%summarise(n=n()) %>% ungroup() %>% filter(n>1) %>% select(sub_samp_ref) %>% distinct(.)

    dim(duplicated_1)  #24 total duplicated IDs
    duplicated_1 = duplicated_1$sub_samp_ref


    ## explore duplicates in ices3
           ## duplicated records
      duplicated_1_records = ices3 %>%
                              filter(sub_samp_ref %in% duplicated_1) %>%
                              select(country,date,matrix_analyzed,sub_samp_ref,sub_samp_id,measurement_ref, param_group,basis_determination,variable,value)%>%
                              arrange(sub_samp_ref,variable, measurement_ref)
      duplicated_1_records  ## All duplicates are two measurement of LIPIDWT% per sample, all from 2014  ## same tissue, no basis_determination entered

      ## countries
      duplicated_1_records %>% select(country) %>% distinct(.)  #Poland


## take the average LIPIDWT% per sample for the duplicates
      ices3_bbio= ices3_bbio %>%
                    group_by(station,latitude,longitude,date,sub_samp_ref,sub_samp_id,samp_id,param_group,matrix_analyzed,variable ) %>% # group by all columns except value
                    mutate(value= mean(value)) %>% ## value is equal to the mean value for each sample for each variable
                    ungroup() %>%
                    distinct(.)  ## retain ony distinct rows
      dim(ices3_bbio) #12674    11

##check for unique variables and matrix_analyzed
      ices3_bbio %>% select(matrix_analyzed,basis_determination,variable) %>% distinct(.) %>% arrange(variable)
      ## unique combination of variables and matrix_analyzed


##remove basis_determination  ##it is more important for the occb data, is haphazardly entered here.
      ## LIPIDWT%_%  appears to be recorded as both wet weight and lipid weight but we do not use this column
    ices3_bbio = ices3_bbio %>% select(-basis_determination)

    ## b-bio data wide format
      ices3_bbio_wide = ices3_bbio %>%
                        select(-matrix_analyzed) %>%
                        group_by(station,latitude,longitude,date,sub_samp_ref,sub_samp_id,samp_id,param_group) %>%
                        spread(variable,value) %>%
                        ungroup()%>%
                        dplyr::rename(param_bbio = param_group)


      dim(ices3_bbio_wide); length(unique(ices3_bbio_wide$sub_samp_ref))  ## 1 row for every subsample ref.
##----------------------------------------##




##----------------------------------------##
## oc-cb data
## This is congener concentration data
##----------------------------------------##
ices3_occb = ices3 %>%
  select(c(station,latitude,longitude,date,sub_samp_ref,sub_samp_id,samp_id,param_group,matrix_analyzed,basis_determination,variable,unit,value))%>% ## reorder columns, identifiers first, only variables and values
  filter(param_group == "OC-CB") %>% ## select only OC-CB
  arrange(station,date,sub_samp_ref)

dim(ices3_occb)
head(ices3_occb)
str(ices3_occb)

## DUPLICATE PROBLEMS (data year >= 2000)
dim(ices3_occb) #17593    11
ices3_occb %>% select(-value)%>% distinct(.) %>% nrow()#17593; appears to be no duplicates

## Any congeners with lipid weight
ices3_occb %>% select(basis_determination) %>% distinct(.)
ices3_occb %>% filter(basis_determination == "lipid weight")
##YES

ices3_occb %>% filter(basis_determination == "lipid weight") %>% select(sub_samp_ref) %>% distinct(.) %>% nrow()


## Convert to shared units  (then will only have one column for each congener)

    ## different units for the data
    ices3_occb %>% select(unit) %>%distinct(.)  # ug/kg, mg/kg, pg/g, ng/g
    ices3_occb %>% select(variable,unit) %>%distinct(.)

    ## convert all to ug/kg (this is unit for the non-dioxin PCB GES boundary)

    ## select only the part of the unit look up needed, all converstions to ug/kg
    unit_lookup_ug_kg = unit_lookup %>% filter(ConvertUnit == "ug/kg")


    ices3_occb = ices3_occb %>%
                left_join(., unit_lookup_ug_kg, by=c("unit" = "OriginalUnit")) %>%  ## combine data with the conversion factor
                mutate(value2 = value*ConvertFactor) ## calculate value in ug/kg

    ices3_occb

    ##save unit conversion data for reference
    #write.csv(ices3_occb, file.path(dir_con, 'raw_prep/ices_congener_unit_conversion.csv'))


## Remove the original values and merge the congener with the unit

    ices3_occb = ices3_occb %>%
                select(-value,-unit, -ConvertFactor)%>%  ##remove columns not needed
                mutate(variable = paste(variable,ConvertUnit,sep="_")) %>% ## now variable and unit single text
                select(-ConvertUnit) %>%  ## column not needed
                dplyr::rename(value=value2)

    #check unique variables
      ices3_occb %>% select(variable) %>% distinct(.)


## Then spread data
ices3_occb_wide = ices3_occb %>%
  select(-matrix_analyzed) %>%
  group_by(station,latitude,longitude,date,sub_samp_ref,sub_samp_id,samp_id,param_group, basis_determination) %>%
  spread(variable,value) %>%
  dplyr::rename(param_occb = param_group) %>%
  ungroup() %>%
  arrange(station, date, sub_samp_ref)

dim(ices3_occb_wide) #2468   25
ices3_occb_wide %>% select(sub_samp_ref)%>%distinct(.) %>% nrow()#2468  ## one row for every unique sub_samp_ref


##----------------------------------------##
## Join ices3_occb_wide with ices3_bbio_wide
## do this so can convert from wet weight to lipid weight
##----------------------------------------##

ices4 = left_join(ices3_occb_wide, ices3_bbio_wide,
                  by=c("station","latitude","longitude",
                       "date","sub_samp_ref","sub_samp_id", "samp_id"))


head(ices4)
colnames(ices4)
dim(ices4) ##2468   39   ## same number of rows as occb
ices4 %>% select(sub_samp_ref) %>% distinct(.) %>% nrow()

## save unconverted, merged data
#write.csv(ices4, file.path(dir_con,'raw_prep/ices_congener_biodata_weight_basis_unconverted.csv'))

##----------------------------------------##
## CONVERT lipid weight measurements to wet weight
## multiple the congener concentration (if lipid based) by (EXLIP%_% / 100)
##----------------------------------------##
ices5 = ices4 %>%
        ##group_by(c(station:basis_determination, param_bbio:WTMIN_g)) %>% ## group by all id and bbio variable
        gather(congener, value,`CB101_ug/kg`:`CB77_ug/kg`) %>%
        arrange(station,date, sub_samp_ref) %>%##long data format
        mutate(value2 = ifelse(basis_determination=="lipid weight", (value* (`EXLIP%_%`/100)),value)) ## create new value column, if value is lipid weight convert, otherwise keep value
dim(ices5) #39488    26


## plot data to see if reasonable
ggplot(ices5) + geom_point(aes(date,value2, colour=latitude))+
  facet_wrap(~congener, scales="free_y")

## which are the CB153 high values
ices5 %>% filter(congener == "CB153_ug/kg", value2 > 50) %>% select(station,date, sub_samp_ref,basis_determination,congener,value2) %>% arrange(date,sub_samp_ref)
  ices_lookup %>% filter(date =="2014-09-15" | date =="2014-08-28" ) %>% filter(station == "LKOL" | station == "LWLA")%>%
      select(country, station, date,sub_samp_ref,variable, qflag) %>% mutate(variable = as.character(variable))%>%
        filter(variable == "CB153")%>% arrange(date,sub_samp_ref)
    ## need to check later for station type (eg. reference site, polluted site)
    ## these outliers not due to converting wet weight


## clean data set so only values based on wet weight
ices5 = ices5 %>%
        select(-value, -param_occb,-param_bbio) %>%
       dplyr::rename(basis_determination_orginaldata = basis_determination,
                      value=value2) %>%
      filter(!is.na(value)) %>% ## remove the congeners not measured
      arrange(station, date, sub_samp_ref)
dim(ices5) #16732    23


##----------------------------------------##
## combine harmonized data with ices_lookup
##do this so have country and monitoring program info, and qflaugs
##----------------------------------------##

## reduce ices_lookup to only relevant columns
ices_lookup = ices_lookup %>%
              select(-sex_specimen,-matrix_analyzed, -not_used_in_datatype, -analyt_lab,-ref_source,
                     -method_storage, -method_pretreat,-method_pur_sep,-method_chem_fix,-method_chem_extract,
                     -method_analysis,-formula_calc,-test_organism,-sampler_type,-factor_compli_interp,
                     -analyt_method_id,-measurement_ref) %>%
              filter(param_group == "OC-CB") %>% ## only select lookup info about congener variables
              select(-param_group)%>% ## don't need param_group
              mutate(congener_unit = paste(variable, "_ug/kg", sep=""))%>% ## this column will match the congener column in ices5
              select(-variable) %>% ##no longer need this column
              arrange(station, date, sub_samp_ref)

dim(ices_lookup) #17593    25


## join ices5 and ices_lookup
ices6 = left_join(ices5,
                  ices_lookup,
                  by=c("station","date","latitude","longitude","sub_samp_id",
                                           "sub_samp_ref","samp_id", "congener"="congener_unit") )%>%
        mutate(basis_determination_converted = "wet weight") %>%  ## add column to have current basis clear
        select(country,monit_program,monit_purpose,report_institute,station,
                latitude,longitude, date, monit_year,date_ices,day, month, year,species,
                sub_samp_ref,sub_samp_id, samp_id,num_indiv_subsample, bulk_id,
                basis_determination_orginaldata,basis_determination_converted,
                AGMAX_y,AGMEA_y, AGMIN_y,`DRYWT%_%`, `EXLIP%_%`,`FATWT%_%`,`LIPIDWT%_%`,
               LNMAX_cm,LNMEA_cm,LNMIN_cm, WTMAX_g,WTMEA_g ,WTMIN_g ,
               qflag, detect_lim, quant_lim,uncert_val,method_uncert,congener, value) %>%  ## reorder columns
        dplyr::rename(basis_determination_originalcongener = basis_determination_orginaldata) %>%
        arrange(station,date, sub_samp_ref)

dim(ices6) #16732    41
dim(ices5) #16732    23


## do not want to spread the data because the qflag, detli etc is unique to each congener

## save and export
write.csv(ices6, file.path(dir_con, "raw_prep/ices_herring_pcb_cleaned.csv"))



##----------------------------------------##
############################################
##----------------------------------------##


########################################################################################
## ICES DIOXIN ##
########################################################################################








############################################################
## OLD CODE
## if work with IVL data, would start here
##----------------------------------------##
## Read in IVL data
##----------------------------------------##
ivl_raw = read.csv(file.path(dir_con, '/raw_prep/IVL_herring_pcb_download_21april2016_cleaned.csv'),
                   sep=";")
head (ivl_raw)
dim(ivl_raw)
str(ivl_raw)


##----------------------------------------##
## IVL data cleaning and manipulations
##----------------------------------------##

## Add unique key for each sample

ivl1 = ivl_raw %>% mutate(id = seq(1,nrow(ivl_raw),1))

## Separate data into congener and qflag datasets

ivlcon = ivl1 %>% select(-c(PCB_sum_qflag              ,
                            PCB_sum_packad_kolonn_qflag,
                            PCB101_qflag               ,
                            PCB105_qflag               ,
                            PCB110_qflag               ,
                            PCB118_qflag               ,
                            PCB126_qflag               ,
                            PCB138_qflag               ,
                            PCB149_qflag               ,
                            PCB153_qflag               ,
                            PCB156_qflag               ,
                            PCB157_qflag               ,
                            PCB158_qflag               ,
                            PCB167_qflag               ,
                            PCB169_qflag               ,
                            PCB180_qflag               ,
                            PCB28_qflag                ,
                            PCB31_qflag                ,
                            PCB52_qflag                ,
                            PCB77_qflag   ))

ivlqflag = ivl1 %>% select(id               ,
                           ProvId           ,
                           lon              ,
                           lat              ,
                           Laen             ,
                           Laenskod         ,
                           Program          ,
                           station          ,
                           Kommun           ,
                           Datum            ,
                           Orginal_id       ,
                           Species          ,
                           Stat_id          ,
                           Count            ,
                           Alder            ,
                           Organ            ,
                           Extrlip_percent  ,
                           Individvikt_g    ,
                           Torrvikt_percent ,
                           Laengd_cm        ,
                           Provvikt_g       ,
                           Unit           ,
                           PCB_sum_qflag              ,
                           PCB_sum_packad_kolonn_qflag,
                           PCB101_qflag               ,
                           PCB105_qflag               ,
                           PCB110_qflag               ,
                           PCB118_qflag               ,
                           PCB126_qflag               ,
                           PCB138_qflag               ,
                           PCB149_qflag               ,
                           PCB153_qflag               ,
                           PCB156_qflag               ,
                           PCB157_qflag               ,
                           PCB158_qflag               ,
                           PCB167_qflag               ,
                           PCB169_qflag               ,
                           PCB180_qflag               ,
                           PCB28_qflag                ,
                           PCB31_qflag                ,
                           PCB52_qflag                ,
                           PCB77_qflag)

## gather data
### IVL con, one column for congener, 1 for value
ivlcon2 = ivlcon %>% group_by(id               ,
                         ProvId           ,
                         lon              ,
                         lat              ,
                         Laen             ,
                         Laenskod         ,
                         Program          ,
                         station          ,
                         Kommun           ,
                         Datum            ,
                         Orginal_id       ,
                         Species          ,
                         Stat_id          ,
                         Count            ,
                         Alder            ,
                         Organ            ,
                         Extrlip_percent  ,
                         Individvikt_g    ,
                         Torrvikt_percent ,
                         Laengd_cm        ,
                         Provvikt_g       ,
                         Unit                                 ) %>%
  gather(key=congener, value= pcb_value,c(
    PCB_SUM               ,
    PCB_sum_packad_kolonn ,
    PCB101                ,
    PCB105                ,
    PCB110                ,
    PCB118                ,
    PCB126                ,
    PCB138                ,
    PCB149                ,
    PCB153                ,
    PCB156                ,
    PCB157                ,
    PCB158                ,
    PCB167                ,
    PCB169                ,
    PCB180                ,
    PCB28                 ,
    PCB31                 ,
    PCB52                 ,
    PCB77                 ))%>%ungroup() %>% arrange(id)


## IVL qflag, group by qflag con and flag

ivlqflag2 =ivlqflag %>% group_by(id               ,
                                  ProvId           ,
                                  lon              ,
                                  lat              ,
                                  Laen             ,
                                  Laenskod         ,
                                  Program          ,
                                  station          ,
                                  Kommun           ,
                                  Datum            ,
                                  Orginal_id       ,
                                  Species          ,
                                  Stat_id          ,
                                  Count            ,
                                  Alder            ,
                                  Organ            ,
                                  Extrlip_percent  ,
                                  Individvikt_g    ,
                                  Torrvikt_percent ,
                                  Laengd_cm        ,
                                  Provvikt_g       ,
                                  Unit                                 ) %>%
  gather(key=qflag_congener, value= qflag,c(PCB_sum_qflag              ,
                                            PCB_sum_packad_kolonn_qflag,
                                            PCB101_qflag               ,
                                            PCB105_qflag               ,
                                            PCB110_qflag               ,
                                            PCB118_qflag               ,
                                            PCB126_qflag               ,
                                            PCB138_qflag               ,
                                            PCB149_qflag               ,
                                            PCB153_qflag               ,
                                            PCB156_qflag               ,
                                            PCB157_qflag               ,
                                            PCB158_qflag               ,
                                            PCB167_qflag               ,
                                            PCB169_qflag               ,
                                            PCB180_qflag               ,
                                            PCB28_qflag                ,
                                            PCB31_qflag                ,
                                            PCB52_qflag                ,
                                            PCB77_qflag)) %>%
  ungroup()%>% arrange(id)
