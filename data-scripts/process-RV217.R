library(tidyverse)
library(usethis)
library(here)
source(here("R", "directory-funs.R"))

rv217 =  read_csv(raw_data_here("RV217-VL_APTIMA.csv"), col_types = cols()) %>%
  rename(days_dx = time, DV_log = y)

rv217_out = rv217 %>%
  dplyr::filter(!is.na(DV_log)) %>%
  group_by(ID) %>%
  mutate(
    rel_enroll_day = abs(min(days_dx)),
    rel_first_pos = min(days_dx[DV_log > 1.2])
  ) %>%
  ungroup() %>%
  mutate(
    pub_id = paste0("RV217-", ID),
    TIME = days_dx + rel_enroll_day,
    DV = 10^DV_log,
    days_fp = days_dx - rel_first_pos,
    limit = if_else(cens == 1, "0", ".")
  ) %>%
  relocate(DV_log, .after = DV) %>%
  relocate(cens, .after = days_fp)

stopifnot(sum(rv217_out$days_fp == 0) == n_distinct(rv217_out$pub_id))

with(rv217_out, ftable(days_fp == 0, DV_log < 1.181))

rv217_out %>%
  dplyr::select(-ID, -days_dx, -contains("rel")) %>%
  write_csv(file = clean_data_here("rv217-vl.csv"))
