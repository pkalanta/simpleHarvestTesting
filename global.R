
repos <- c("https://predictiveecology.r-universe.dev", getOption("repos"))
if (!require("SpaDES.project")) {
  install.packages("SpaDES.project", repos = repos)
}

out <- SpaDES.project::setupProject(
  paths = list(
    projectPath = getwd()
  ),
  useGit = TRUE,
  restart = TRUE,
  modules = c("PredictiveEcology/Biomass_core@development", 
              "ianmseddy/simpleHarvest@development"),
  packages = c(
    'RCurl', 'XML', 'snow', 'googledrive', 
    'httr2', "gert", "remotes"
  ),
  require = c("PredictiveEcology/LandR"),
  times = list(start = 2011, end = 2012),
  options = options(reproducible.useMemoise = TRUE),
  params = list(
    globals = list(
      "sppEquivCol" = "LandR"
    )
  ),
  studyArea = {
   sa <- LandR::randomStudyArea(size = 10000 * 6.25 * 15000, seed = 99)
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

