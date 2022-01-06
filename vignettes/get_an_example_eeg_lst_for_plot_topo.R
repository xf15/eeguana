library(dplyr)
library(ggplot2)
library(stringr)
library(eeguana)
set.seed(123) # ICA will always find the same components

faces <- read_vhdr("s1_faces.vhdr")


# if biosemi
faces$.signal = faces$.signal %>% 
  mutate(AF3 = faces$.signal$Fp1,
         AF4 = faces$.signal$Fp1,
         PO3 = faces$.signal$Fp1,
         PO4 = faces$.signal$Fp1)

channels_tbl(faces) <- select(channels_tbl(faces), .channel) %>%
  # left_join(layout_32_1020)
  left_join(layout_biosemi_32_1020)

faces <- eeg_rereference(faces, -VEOG, -HEOG, .ref = c("M1", "M2"))

faces_filt <- eeg_filt_band_pass(faces, -HEOG, -VEOG, .freq = c(.1, 30)) 

faces_ls <- eeg_segment(faces_filt, .description == "s111", .end = .description == "s121") %>%
  eeg_artif_minmax(-HEOG, -VEOG, .threshold = 200, .window = 200, .unit = "ms")

faces_icaed = faces_ls

events_tbl(faces_icaed) <- events_tbl(faces_icaed) %>%
  filter(!.type %in% "artifact")
faces_seg <- faces_icaed %>%
  select(-description, -type) %>%
  eeg_segment(.description %in% c("s70", "s71"), .lim = c(-.1, .5))
faces_seg_artif <- faces_seg %>%
  eeg_artif_minmax(-HEOG, -VEOG, .threshold = 100, .window = 150, .unit = "ms") %>%
  eeg_artif_step(-HEOG, -VEOG, .threshold = 50, .window = 200, .unit = "ms")
## extracts the ids of the segments with artifacts
bad <- filter(events_tbl(faces_seg_artif), .type == "artifact") %>% 
  pull(.id) %>% 
  unique()
## Show the segment with artifact and one before and after:
faces_seg_artif %>%
  filter(.id %in% c(bad-1, bad, bad+1)) %>%
  select(-VEOG, -HEOG) %>%
  plot() +
  annotate_events() +
  theme(legend.position = "bottom")
faces_seg <- faces_seg_artif %>%
  eeg_events_to_NA(.type == "artifact", .entire_seg = TRUE, .all_chs = FALSE, .drop_events = TRUE)

faces_seg <- faces_seg %>% eeg_baseline()

faces_seg <- faces_seg %>%
  mutate(
    condition =
      if_else(description == "s70", "faces", "non-faces")
  ) %>%
  select(-type)

a = faces_seg %>%
  filter(between(as_time(.sample, .unit = "s"), .1, .2)) %>%
  group_by(condition) %>%
  summarize_at(channel_names(.), mean, na.rm = TRUE) 

saveRDS(a, 'example_eeg_lst_biosemi32.rds')
# saveRDS(a, 'example_eeg_lst_brainvision32.rds')


a %>% plot_topo() +
  annotate_head() +
  geom_contour() +
  geom_text(colour = "black") +
  facet_grid(~condition)


