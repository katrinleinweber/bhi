Carbon Storage (CS) Goal Data Preparation
================

-   [1. Background](#background)
    -   [Goal Description](#goal-description)
    -   [Model & Data](#model-data)
    -   [Reference points](#reference-points)
    -   [Considerations for *BHI 2.0*](#considerations-for-bhi-2.0)
    -   [Other information](#other-information)
-   [2. Data](#data)
    -   [1.1 Download information](#download-information)
    -   [2.2 Additional background](#additional-background)
-   [3. CS goal model overview](#cs-goal-model-overview)
    -   [3.1 Status](#status)
    -   [3.2 Trend](#trend)
-   [4. Layer prep](#layer-prep)
    -   [4.1 Read in data](#read-in-data)
    -   [4.2 Explore and plot data](#explore-and-plot-data)
    -   [4.3 Intersect the BHI shapefiles and zostera data](#intersect-the-bhi-shapefiles-and-zostera-data)
    -   [4.4 Status Calcuation (Can't do... See 4.3 Problem)](#status-calcuation-cant-do...-see-4.3-problem)
-   [Explore Global CS scores for Baltic regions](#explore-global-cs-scores-for-baltic-regions)
    -   [Temperary fix: leave all as NA](#temperary-fix-leave-all-as-na)

1. Background
-------------

### Goal Description

The Carbon Storage goal captures the ability of the coastal habitats to remove carbon given their carbon uptake rate and health conditions. A score of 100 means all habitats that contribute to carbon removal are still intact or have been restored and they can function to their full carbon burial potential. Highly productive coastal wetland ecosystems or seagrass store substantially large amount of carbon have the highest sequestration rates of any habitats on earth. They are also threatened by under-regulated coastal development but are amenable to restoration and conservation efforts. **For the BHI we planned to use seagrass as an indicator for carbon storage. However, due to data limitions, the Carbon Storage goal was assigned as NA.**

### Model & Data

We planned to use seagrass data (*Zostera* species) in the Baltic Sea.

-   [Data were downloaded from the HELCOM Marine Spatial Planning Map Service](http://maps.helcom.fi/website/msp/index.html) &gt; select Marine Spatial Planning - Ecology - Ecosystem Health status
-   [Data layer - "Zostera Meadows" Metadata](http://maps.helcom.fi/website/getMetadata/htm/All/Zostera%20meadows.htm)

*Although these are saved as spatial data, observations are point data, accompanied by either "dense" or "sparse." Therefore the spatial extent of the seagrass meadows is unclear and cannot be used for the BHI goal calculation.*

Related publications:

-   *[Boström et al 2014](http://onlinelibrary.wiley.com/doi/10.1002/aqc.2424/abstract).*

-   *[HELCOM Red List Biotope Information Sheet](http://helcom.fi/Red%20List%20of%20biotopes%20habitats%20and%20biotope%20complexe/HELCOM%20Red%20List%20AA.H1B7,%20AA.I1B7,%20AA.J1B7,%20AA.M1B7.pdf)*

### Reference points

*Not relevant yet.*

### Considerations for *BHI 2.0*

*Other spatial data sources are currently explored.*

### Other information

*external advisors/goalkeepers: Christoffer Boström and Markku Viitasalo.*

2. Data
-------

### 1.1 Download information

[HELCOM Marine Spatial Planning Map Service](http://maps.helcom.fi/website/msp/index.html)
Select - Marine Spatial Planning - Ecology - Ecosystem Health status
Data layer - "Zostera Meadows"
Downloaded on 10 May 2016 by Jennifer Griffiths

[Metadata link](http://maps.helcom.fi/website/getMetadata/htm/All/Zostera%20meadows.htm)

### 2.2 Additional background

*Notes from Joni Kaitaranta (HELCOM)*: According to the Zostera meadows metadata there is many data sources. The dataset was compiled in 2009-2010 for the HOLAS I assessment so the dataset is not very recent. Major source was Boström et al. 2003. In: Spalding et al. World Atlas of Seagrasses but there was also national e.g. from NERI Denmark downloaded in 2009 from a URL that is no longer valid.

*Data Structure*: Is unclear, spatial files need to be reviewed. Is it just points, or does it include areal coverage of Zostera. Data observations are accompanies by either "dense" or "sparse."

3. CS goal model overview
-------------------------

### 3.1 Status

X\_cs\_region = Current\_area\_Zostera\_meadows\_region / Reference\_pt\_region

Reference\_pt\_region = Current\_area\_Zostera\_meadows \* 1.25
This is based upon ["During the last 50 years the distribution of the Zostera marina biotope has declined &gt;25%. The biotope has declined to varying extents in the different Baltic Sea regions."](http://helcom.fi/Red%20List%20of%20biotopes%20habitats%20and%20biotope%20complexe/HELCOM%20Red%20List%20AA.H1B7,%20AA.I1B7,%20AA.J1B7,%20AA.M1B7.pdf)

**If data are not areal coverage**: if data are simply points of presence, need to rethink goal model

### 3.2 Trend

Use the trend of NUT subcomponent for CW goal (e.g. secchi status trend).

Read the file in from 'layers' and resave as the CS trend for layers.

4. Layer prep
-------------

### 4.1 Read in data

``` r
## directory setup

dir_M <- c('Windows' = '//mazu.nceas.ucsb.edu/ohi',
           'Darwin'  = '/Volumes/ohi',    ### connect (cmd-K) to smb://mazu/ohi
           'Linux'   = '/home/shares/ohi')[[ Sys.info()[['sysname']] ]]

if (Sys.info()[['sysname']] != 'Linux' & !file.exists(dir_M)){
  warning(sprintf("The Mazu directory dir_M set in src/R/common.R does not exist. Do you need to mount Mazu: %s?", dir_M))
  # TODO: @jennifergriffiths reset dir_M to be where the SRC hold your shapefiles
}

dir_shp <- file.path(dir_M, 'git-annex/Baltic')
```

### 4.2 Explore and plot data

We explored the Zostera data and see how that matches with the BHI region shape files. They seem to overlap well.

``` r
## read in Zostera data
cs_data <- rgdal::readOGR(dsn = path.expand(file.path(dir_shp, 'Bostera_meadows')),
                          layer = 'Zostera meadows')  
```

    ## OGR data source with driver: ESRI Shapefile 
    ## Source: "/home/shares/ohi/git-annex/Baltic/Bostera_meadows", layer: "Zostera meadows"
    ## with 5960 features
    ## It has 8 fields

``` r
#plot(cs_data, col = cs_data@data$coverage )
#head(cs_data@data) 

#  cs_data@proj4string: 
#  +proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs 

## plot data: bhi regions and Zostera
bhi <- rgdal::readOGR(dsn = path.expand(file.path(dir_shp, 'BHI_MCG_shapefile')),
                      layer = 'BHI_MCG_11052016')
```

    ## OGR data source with driver: ESRI Shapefile 
    ## Source: "/home/shares/ohi/git-annex/Baltic/BHI_MCG_shapefile", layer: "BHI_MCG_11052016"
    ## with 42 features
    ## It has 6 fields

``` r
bhi_transform = spTransform(bhi, cs_data@proj4string) # transform bhi to the same coordinate system; bhi from lsp_prep. need to expand here. 

plot(bhi_transform, col = 'light blue', border = "grey", main = "BHI regions and Meadows intersect"); plot(cs_data, col = 'blue', add = TRUE) 
```

![](cs_prep_files/figure-markdown_github/explore%20data-1.png)

``` r
# system.time({cs_bhi_intersect <- raster::intersect(cs_data, bhi_transform)})
```

### 4.3 Intersect the BHI shapefiles and zostera data

The zostera data contains areal extent that matches well with the BHI regions. The graph below shows overlay of zostera data with BHI region shape file - each blue cross is a sampling site with coordinates and coverage type (dense, sparse, or NA).

**Problem**: The area listed in the Zostera file only contained the location of each sampling point, but not the area of vegetation coverage. The area data seems to be the total area of the BHI region. Therefore, we can't calculate the total area of Zostera as planned.

``` r
cs_bhi_intersect = sp::over(cs_data, bhi_transform)
# head(cs_bhi_intersect)
# plot(cs_bhi_intersect)

cs_bhi_data = cbind(cs_bhi_intersect, cs_data@data) %>%
  dplyr::select(country = rgn_nam, BHI_ID, Area_km2, coverage) %>%
  filter(!is.na(country))

DT::datatable(cs_bhi_data)
```

![](cs_prep_files/figure-markdown_github/intersect%20and%20save%20csv-1.png)

``` r
# save data as csv
# write_csv(cs_bhi_data, file.path(dir_cs, 'cs_bhi_data.csv'))
```

### 4.4 Status Calcuation (Can't do... See 4.3 Problem)

Two appraoches to calculat the status of Carbon storage according to coverage types.

1.  weigh the coverage types: NA, sparse, and dense (as 0, 0.5, and 1), and average the weights
2.  no weights, and all presence (eg sparse or dense) = 1

Original plan to set up the reference point:

"During the last 50 years the distribution of the Zostera marina biotope has declined &gt;25%. The biotope has declined to varying extents in the different Baltic Sea regions. The decline in the southern areas of the Baltic Sea begun almost 100 years ago, however there is not enough reliable information to classify the biotope under A3 which requires data or inference as to the decline in quantity over the last 150 years. There are two alternatives to reference point.

1.  Could use current extent x 1.25 applied equally to all BHI regions as a reference point?'
2.  use the current extent of zostera meadows (total area) in each BHI region. Use status as that extent\*weight of threat level (by BHI region only). Therefore if zostera not threatened in a BHI region - score is 100 because full extent is not threatened. If threatened, score is lower?"

``` r
cov_type_wt = data.frame(coverage = c("NA", "sparse", "dense"), 
                         weight = c(1, 0.5, 1))

cs_with_wt = cs_bhi_data %>%
  full_join(cov_type_wt, 
            by = "coverage")
```

    ## Warning in full_join_impl(x, y, by$x, by$y, suffix$x, suffix$y): joining
    ## factors with different levels, coercing to character vector

``` r
# DT::datatable(cs_with_wt)
```

Explore Global CS scores for Baltic regions
-------------------------------------------

We decided not to use this approach as Global CS scores could be misleading as either 0 or 100. We will leave CS scores as NA's instead to highlight the missing data.

``` r
rgn_id_gl <- read_csv('https://raw.githubusercontent.com/OHI-Science/ohi-webapps/dev/custom/bhi/sc_studies_custom_bhi.csv')

### Global CS status and trend scores

cs_status_gl <- read_csv('https://rawgit.com/OHI-Science/ohi-global/draft/eez2016/scores.csv'); head(cs_status_gl)

# filter BHI EEZs

cs_scores_bhi <- cs_status_gl %>% 
  filter(goal == 'CS', 
         dimension %in% c('status', 'trend')) %>% 
  dplyr::rename(gl_rgn_id = region_id) %>%
  left_join(rgn_id_gl %>%
              select(gl_rgn_id,
                     gl_rgn_name), by = 'gl_rgn_id') %>%
  filter(gl_rgn_id %in% rgn_id_gl$gl_rgn_id) %>%
  arrange(gl_rgn_name) %>%
  select(gl_rgn_name, gl_rgn_id, dimension, score)

as.data.frame(cs_scores_bhi)
 
#    gl_rgn_name gl_rgn_id dimension  score
# 1      Denmark       175    status 100.00
# 2      Denmark       175     trend     NA
# 3      Estonia        70    status 100.00
# 4      Estonia        70     trend   0.50
# 5      Finland       174    status     NA
# 6      Finland       174     trend     NA
# 7      Germany       176    status 100.00
# 8      Germany       176     trend   0.50
# 9       Latvia        69    status  50.00
# 10      Latvia        69     trend   0.00
# 11   Lithuania       189    status     NA
# 12   Lithuania       189     trend     NA
# 13      Poland       178    status  56.40
# 14      Poland       178     trend   0.00
# 15      Russia        73    status 100.00
# 16      Russia        73     trend     NA
# 17      Sweden       222    status  55.27
# 18      Sweden       222     trend   0.00 


# Global HAB trend 
hab_trend_gl <- read_csv('https://raw.githubusercontent.com/OHI-Science/ohi-global/draft/eez2016/layers/hab_trend.csv'); head(hab_trend_gl)

## filter BHI EEZs
hab_trend_bhi <- hab_trend_gl %>%
  dplyr::rename(gl_rgn_id = rgn_id) %>%
  left_join(rgn_id_gl %>%
              select(gl_rgn_id,
                     gl_rgn_name), by = 'gl_rgn_id') %>%
  filter(gl_rgn_id %in% rgn_id_gl$gl_rgn_id) %>%
  arrange(gl_rgn_name) %>%
  select(gl_rgn_name, gl_rgn_id, habitat, trend)

as.data.frame(hab_trend_bhi)

#    gl_rgn_name gl_rgn_id          habitat         trend
# 1      Denmark       175      soft_bottom  0.0479267225
# 2      Denmark       175      seaice_edge  0.0784982935
# 3      Denmark       175 seaice_shoreline  0.0384615385
# 4      Estonia        70        saltmarsh  0.5000000000
# 5      Estonia        70      soft_bottom  0.0000000000
# 6      Estonia        70      seaice_edge -0.2884057971
# 7      Estonia        70 seaice_shoreline -0.5269709544
# 8      Finland       174      soft_bottom  0.0000000000
# 9      Finland       174      seaice_edge -0.2682619647
# 10     Finland       174 seaice_shoreline -0.5802707930
# 11     Germany       176        saltmarsh  0.5000000000
# 12     Germany       176      soft_bottom  0.0923876208
# 13     Germany       176      seaice_edge -0.2184466019
# 14     Germany       176 seaice_shoreline -0.0362903226
# 15      Latvia        69        saltmarsh  0.0000000000
# 16      Latvia        69      soft_bottom  0.0000000000
# 17      Latvia        69      seaice_edge -0.2435064935
# 18      Latvia        69 seaice_shoreline -0.3571428571
# 19   Lithuania       189      soft_bottom  0.0000000000
# 20   Lithuania       189      seaice_edge -0.6326530612
# 21   Lithuania       189 seaice_shoreline -0.7058823529
# 22      Poland       178        saltmarsh  0.0000000000
# 23      Poland       178      soft_bottom  0.0002250377
# 24      Poland       178      seaice_edge -1.0000000000
# 25      Russia        73      soft_bottom  0.0012292280
# 26      Russia        73      seaice_edge -0.0581167073
# 27      Russia        73 seaice_shoreline  0.0062767475
# 28      Sweden       222        saltmarsh  0.0000000000
# 29      Sweden       222      soft_bottom  0.0017414934
# 30      Sweden       222      seaice_edge -0.0657894737
# 31      Sweden       222 seaice_shoreline -0.7022792023
```

### Temperary fix: leave all as NA

``` r
cs_status_NA = data.frame(rgn_id = seq(1, 42, by = 1), 
                          score = NA,
                          dimension = "status")

write_csv(cs_status_NA, file.path(dir_layers, "cs_status_placeholder_NA.csv"))

cs_trend_NA = data.frame(rgn_id = seq(1, 42, by = 1), 
                         score = NA,
                         dimension = "trend")

write_csv(cs_trend_NA, file.path(dir_layers, "cs_trend_placeholder_NA.csv"))
```
