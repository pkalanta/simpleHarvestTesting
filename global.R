
# =============================================================================
# SpaDES Forest Landscape Simulation – Thompson-Okanagan Plateau
# Author: Parvin Kalantari
# Date: Summer 2025
# 
# Overview:
#   This script sets up and runs a forest landscape simulation using the SpaDES
#   framework. It combines multiple modules that represent key ecological 
#   processes, such as biomass growth, forest regeneration, harvesting, and 
#   fire spread, to model the dynamics of the study area (e.g.Thompson-Okanagan Plateau region).
#
# Workflow:
#   1. Clean the workspace and ensure all required packages are installed.
#   2. Set up the project structure, including inputs, outputs, cache, and 
#      module directories.
#   3. Download and prepare spatial data for the study area, including ecoregion
#      boundaries and species distributions.
#   4. Configure modules and their parameters, including harvest targets and 
#      plotting options.
#   5. Initialize and run the simulation for the period 2011–2021.
#   6. Optionally, use local development versions of packages for testing 
#      changes.
#
# Purpose:
#   This script is intended to provide a reproducible and flexible workflow
#   for running forest landscape simulations, facilitating testing, calibration,
#   and further development of SpaDES modules.
# =============================================================================
rm(list = ls())  # clears all objects
gc()             # clears memory


repos <- c("https://predictiveecology.r-universe.dev", getOption("repos"))
if (!require("SpaDES.project")) {
  install.packages(c("SpaDES.project", "Require"), repos = repos)
}

out <- SpaDES.project::setupProject(
  paths = list(
    projectPath = getwd(),
    inputPath = file.path("inputs"),
    outputPath = file.path("outputs"),
    cachePath = file.path("cache"),
    modulePath = file.path("modules")
  ),
  
  # useGit = TRUE,
  restart = TRUE,
  modules = c(
    "PredictiveEcology/Biomass_borealDataPrep@development",
    "PredictiveEcology/Biomass_core@development",
    "ianmseddy/LandR_reforestation@parvindev",
    "PredictiveEcology/scfm@development",
    "PredictiveEcology/Biomass_regeneration@development"
    , "pkalanta/simpleHarvest@parvintesting"
  ),
  
  packages = c(
    'RCurl', 'XML', 'snow', 'googledrive', 
    'httr2', "gert", "remotes", "terra", "data.table"
  ),
  
  require = c(
    "PredictiveEcology/LandR@development",
    "PredictiveEcology/SpaDES.core@box"
  ),
  
  times = list(start = 2011, end = 2021),
  # options = options(reproducible.useMemoise = TRUE),
  options = list(reproducible.useMemoise = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 spades.allowInitDuringSimInit = TRUE),
  params = list(
    globals = list(
      sppEquivCol = "LandR", 
      .plots = "png",
      .plotInterval = 1,
      .useCache = c(".inputObjects", "init"),
      cohortDefinitionCols = c("speciesCode", "age", "foo")
    ), 
    simpleHarvest = list(.useCache = ".inputObjects",
                         harvestTarget = c("1" = 0.05, "2" = 0.02, "3"= 0.01, "4"= 0.008)),
    Biomass_core = list(.plots = NA)
  ),
  
  studyArea = {
    sa <- prepInputs(
      url = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/region/ecoregion_shp.zip", 
      destinationPath = "inputs"
    )
    sa <- sa[sa$REGION_NAM == "Thompson-Okanagan Plateau",]
    sa <- sf::st_transform(sa, sf::st_crs(paste("+proj=lcc +lat_1=49 +lat_2=77 +lat_0=0 +lon_0=-95 +x_0=0 +y_0=0", 
                                                "+datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0")))
    sa <- sf::st_buffer(sa, 5000)
    sa <- terra::vect(sa)
  },
  sppEquiv = {
    spp <- LandR::speciesInStudyArea(studyArea = sa, dPath = "inputs", sppEquivCol = "LandR")
    spp <- spp$speciesList
    sppEquiv <- LandR::sppEquivalencies_CA[LandR %in% spp,]
    sppEquiv <- sppEquiv[!LANDIS_traits == "",]
  },
  rasterToMatch = {
    rtm <- terra::rast(studyArea, vals = 1, res = c(250, 250)) |>
      terra::mask(mask = studyArea)
  }
)

pkgload::load_all("~/git/LandR")
#annoying steps because scfm is annoying:
out$paths$modulePath <- c("modules", "modules/scfm/modules")
out$modules <- setdiff(c(out$modules, 
                         c("scfmDataPrep", "scfmIgnition", "scfmEscape", "scfmSpread")), 
                       "scfm")
out$params$scfmDataPrep$targetN <- 1000 #quick calibration while testing

outSim <- do.call(SpaDES.core::simInitAndSpades, out)



