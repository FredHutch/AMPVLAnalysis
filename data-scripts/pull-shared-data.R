library(tidyverse)
library(haven)
library(lubridate)
library(here)

source(here("R", "directory-funs.R"))
if(!dir.exists(raw_data_here())) dir.create(raw_data_here())
if(!dir.exists(mlx_data_here())) dir.create(mlx_data_here())

pubid.703 = read.csv('/Volumes/trials/vaccine/p703/analysis/dsmb/2020_08/closed/adata/rx_v2.csv')
pubid.704 = read.csv('/Volumes/trials/vaccine/p704/analysis/dsmb/2020_08/closed/adata/rx_v2.csv')
pub_id_key = bind_rows(pubid.703, pubid.704) %>% select(ptid, pub_id)

# NOT PTIDS ON LOCAL MACHINE

# -------- rx data ------------------

rx_dat = read_sas("/Volumes/trials/vaccine/p703/analysis/NONMEM/case_control/data/raw/rx_v2.sas7bdat") %>%
  bind_rows(read_sas("/Volumes/trials/vaccine/p704/analysis/NONMEM/case_control/data/raw/rx_v2.sas7bdat")) %>%
  dplyr::select(pub_id, rx_code, rx) %>%
  mutate(rx_code2 = if_else(str_detect(rx_code, "C"), "C", rx_code))

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

pk_data_nm = pk_data %>%
  left_join(pk_key, by = "ID") 

pk_data_nm %>%
  write_csv(clean_data_here("pk-nm-data.csv")) %>%
  write_csv(mlx_data_here("pk-nm-data.csv"))

# --------- infusion date data - VRC01 ---------

dose703 = read_sas("/Volumes/trials/vaccine/p703/analysis/NONMEM/case_control/data/analysis/adex.sas7bdat")%>%
  mutate(SUBJID = as.integer(SUBJID))
dose704 = read_sas("/Volumes/trials/vaccine/p704/analysis/NONMEM/case_control/data/analysis/adex.sas7bdat") %>%
  mutate(SUBJID = as.integer(SUBJID))

dose_data = bind_rows(dose703, dose704) %>%
  dplyr::select(-USUBJID) %>%
  left_join(pub_id_key, by = c("SUBJID" = "ptid")) %>%
  mutate(
    infusiondt = as.Date(ymd_hms(ASTDTM)),
    infusion_durn_days = as.numeric(interval(ymd_hms(ASTDTM), ymd_hms(AENDTM)), "days"),
    RATE = AEXDOSE/infusion_durn_days
  ) %>%
  group_by(pub_id) %>%
  mutate(
    enrdt = min(infusiondt),
    TIME = as.numeric(difftime(infusiondt, enrdt, units = "days"))
  ) 


dose_check = pk_data_nm %>%
  dplyr::filter(DV == ".") %>%
  select(pub_id, RATE, TIME, AMT, DOSENO) %>%
  full_join(select(dose_data, pub_id, TIME, AEXDOSE, ASEQ, RATE, infusion_durn_days), by = c("pub_id",  "DOSENO" = "ASEQ")) 

# after some sleuthing, the differences in rate comes from rounding the hourly RATE calculation Karan makes then converted to days
# the differences are small, like < 1 minute in the end
head(dose_check)

# biggest difference is 10%, most are small
hist(10^(log10(as.numeric(dose_check$RATE.x)) - log10(dose_check$RATE.y)))

# the dose data should be inclusive
stopifnot(all(!is.na(dose_check$TIME.y)))

# manually check, a bunch of later infusions, probably post-infection
missing_dose = dplyr::filter(dose_check, is.na(TIME.x))

with(subset(dose_check, !is.na(TIME.x)), all(round(as.numeric(AMT)) == round(AEXDOSE)))
with(subset(dose_check, !is.na(TIME.x)), all(round(TIME.x) == round(TIME.y)))

dose_data %>%
  dplyr::select(pub_id, infusion_no = ASEQ, infusiondt, dose_mg = AEXDOSE, infusion_durn_days, RATE, TVLDL, IVREST) %>%
  write_csv(raw_data_here("pk-dosing-info.csv"))


# --------- placebos date data - VRC01 ---------

placebo_id = subset(rx_dat, rx_code2 == "C")$pub_id

idt.703 = read.csv('/Volumes/trials/vaccine/p703/analysis/dsmb/2020_08/closed/adata/v703_infusion_dates.csv')
idt.704 = read.csv('/Volumes/trials/vaccine/p704/analysis/dsmb/2020_08/closed/adata/v704_infusion_dates.csv')
bind_rows(idt.703, idt.704) %>% 
  mutate(
    ptid = as.integer(gsub('-','', ptid))
  ) %>%
  left_join(pub_id_key, by = "ptid") %>%
  filter(pub_id %in% placebo_id) %>%
  mutate(
    infusiondt = as.Date(dmy(idt))
  ) %>%
  group_by(pub_id) %>%
  mutate(
    infusion_no = as.numeric(factor(visit))
  ) %>%
  dplyr::select(pub_id, infusion_no, infusiondt) %>%
  write_csv(raw_data_here("placebo-dosing-all.csv"))



