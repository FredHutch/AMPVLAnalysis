
# this was ported, .funs are intentionally notated as invisible until explicitly used

#--------------- convenience wrappers for navigating directory------------

structural_model_here <- function(file = "", list_files = F) {
  if(list_files) list.files(here("models", "structural-model"))
  here("models", "structural-model", file)
}

mlx_data_here <- function(file = "", list_files = F) {
  if(list_files) list.files(here("data", "mlx-data"))
  here("data", "mlx-data", file)
}

raw_data_here = function(file = ""){
  here("data", "raw-data", file)
}

clean_data_here <- function(file = "", list_files = F) {
  if(list_files) print(list.files(here("data", "processed-data")))
  here("data", "processed-data", file)
}

# glimpse silently returns the data, so it can be saved to an object
check_data = function(file = NULL){
  if(is.null(file)) {
    print(list.files(mlx_data_here()))
    return(invisible(0))
  }
  glimpse(read_csv(mlx_data_here(file)))
}

mlx_model_here <- function(file = "", mlxtran = F) {
  if(mlxtran) file = glue("{file}.mlxtran")
  here("models", file)
}

list_mlx_models = function(mlx_sub_dir = "", names_only = F){
  models = str_remove(str_subset(list.files(mlx_model_here(mlx_sub_dir)), ".mlxtran"), ".mlxtran")
  if(names_only) return(models)
  paste0(mlx_sub_dir, models)
}

.simulx_here = function(file = ""){
  here("inst", "extdata", "simulx-output", file)
}
