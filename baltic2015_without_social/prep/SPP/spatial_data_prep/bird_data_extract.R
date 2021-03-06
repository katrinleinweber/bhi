#######################################
## Extracting the bird data
## MRF Mar 18 2016
#######################################

#NOTE: one bird species fell out of the bhi polygon areas and was excluded
# I would probably ignore....but it might be worth figuring out.

## These data are very annoying, the data consist of the "raster-style" polygons and other
## polygons.  Given this, I just reextracted the data.

library(sp)
library(rgdal)
library(raster)
library(rgeos)
library(maptools)

source('../ohiprep/src/R/common.R')

# function to get rid of extensions
no.extension <- function(astring) {
  if (substr(astring, nchar(astring), nchar(astring))==".") {
    return(substr(astring, 1, nchar(astring)-1))
  } else {
    no.extension(substr(astring, 1, nchar(astring)-1))
  }
}

#### BHI map
bhi <- readOGR(dsn = "/var/data/ohi/git-annex/clip-n-ship/bhi/spatial", layer = "rgn_offshore_gcs")

bird <- readOGR(dsn = "/var/data/ohi/git-annex/Baltic/spp/Birds/Vanellus vanellus (NT)",
                layer = "vanellusvanellus_pro")

#### transform the sp_map data to have the same
#### coordinate reference system as the Helcom data
bhi <- spTransform(bhi, CRS(proj4string(bird)))

### Extracting bird data
all_birds <- list.files('/var/data/ohi/git-annex/Baltic/spp/Birds')
all_birds <- all_birds[-(which(all_birds %in% c("Actitis hypoleucos (NT)"))) ] # this bird falls outside the polygons (appears to be only one cell)

bird_data <- data.frame()


for(birdy in all_birds){  #birdy <- "Actitis hypoleucos (NT)"
  print(birdy)
  tmp <- list.files(sprintf('/var/data/ohi/git-annex/Baltic/spp/Birds/%s', birdy))
  tmp <- tmp[1]
  tmp <- no.extension(tmp)
  bird <- readOGR(dsn = sprintf('/var/data/ohi/git-annex/Baltic/spp/Birds/%s', birdy),
                  layer = tmp)

  ## this code came from here:
  ## http://gis.stackexchange.com/questions/140504/extracting-intersection-areas-in-r
  pi <- raster::intersect(bird, bhi)
  areas <- data.frame(area=sapply(pi@polygons, FUN=function(x) {slot(x, 'area')}))
  row.names(areas) <- sapply(pi@polygons, FUN=function(x) {slot(x, 'ID')})
  # Combine attributes info and areas
  attArea <- spCbind(pi, areas)
  data <- aggregate(area_km2 ~ rgn_id, data=attArea, FUN=sum)
  data <- data %>%
    dplyr::select(rgn_id) %>%
    dplyr::mutate(species = birdy)
bird_data <- rbind(bird_data, data)
}


bird_data_tmp <- bird_data %>%
  separate(species, c("species_name", "IUCN"), -5) %>%
  mutate(IUCN = gsub('[()]', '', IUCN))

write.csv(bird_data_tmp, "baltic2015/prep/SPP/intermediate/birds.csv", row.names=FALSE)




all_birds
