library(tidyverse)
library(haven)
library(here)

source(here("R", "directory-funs.R"))


# -------- neut data ---------------
#this is locally stored but has some mild processing

ic_cols = c("gmt50ms", "gmt80ms", "gmt50ls", "gmt80ls", "gmt50mf", "gmt80mf")

read_csv(raw_data_here("AMP Data for Modeling files/amp_survival_wk80_tau_neut_blinded.csv"),
         col_types = cols(), guess_max = 5000) %>%
  dplyr::filter(!is.na(nisolates) & nisolates > 0) %>%
  select(pub_id, nisolates, contains("gmt")) %>%
  mutate(across(all_of(ic_cols), parse_number)) %>%
  write_csv(clean_data_here("amp-neut-blinded.csv"))

# -------- rx data ------------------

rx_dat = read_sas("/Volumes/trials/vaccine/p703/analysis/NONMEM/case_control/data/raw/rx_v2.sas7bdat") %>%
  bind_rows(read_sas("/Volumes/trials/vaccine/p704/analysis/NONMEM/case_control/data/raw/rx_v2.sas7bdat")) %>%
  dplyr::select(pub_id, rx_code, rx) %>%
  mutate(rx_code2 = if_else(str_detect(rx_code, "C"), "C", rx_code))
pk_key = read_csv("/Volumes/trials/vaccine/p704/analysis/NONMEM/case_control/data/nonmem/id_pubid.csv", col_types = cols()) %>%
  bind_rows(
    read_csv("/Volumes/trials/vaccine/p703/analysis/NONMEM/case_control/data/nonmem/id_pubid.csv", col_types = cols())
  ) %>%
  rename(pub_id = PUB_ID)

write_csv(rx_dat, raw_data_here("rx_dat.csv"))

# -------- pk data -----------------

pk_data = read_csv("/Volumes/trials/vaccine/p704/analysis/NONMEM/case_control/data/nonmem/dat_amp_caseCtl_monolix.csv") %>%
  dplyr::select(ID, AMT, DV, RATE, TIME, dose, AVISITN, DOSENO, weight, study) %>%
  write_csv(raw_data_here("pk-nm-raw.csv"))

pk_key = read_csv("/Volumes/trials/vaccine/p704/analysis/NONMEM/case_control/data/nonmem/id_pubid.csv", col_types = cols()) %>%
  bind_rows(
    read_csv("/Volumes/trials/vaccine/p703/analysis/NONMEM/case_control/data/nonmem/id_pubid.csv", col_types = cols())
  ) %>%
  rename(pub_id = PUB_ID) %>%
  write_csv(raw_data_here("pk-key.csv"))

stopifnot(n_distinct(pk_key$pub_id) == n_distinct(pk_data$ID))

pk_data %>%
  left_join(pk_key, by = "ID") %>%
  write_csv(clean_data_here("pk-data.csv")) 

