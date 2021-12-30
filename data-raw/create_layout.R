library(eeguana)

layout_32_1020 <- readr::read_csv("data-raw/layout_32_1020.csv")

usethis::use_data(layout_32_1020, overwrite = TRUE)


layout_biosemi_32_1020 <- readr::read_csv("data-raw/noisyP6_channelcoords.csv") %>%
  mutate(.x = X, .y = Y, .z = Z, .channel=labels) 
# Error in MBA::mba.surf(xyz = xyz, .diam_points, .diam_points, sp = FALSE,  : 
#                          error: xyz must have 3 columns corresponding to x, y, z and at least one row
#                        In addition: Warning message:
#                          In change_coord(channels_tbl(data), .projection) :
#                          Z coordinates are missing, using 'ortographic' .projection

usethis::use_data(layout_biosemi_32_1020, overwrite = TRUE)
