# 1. Settings
options(stringsAsFactors = FALSE)

# User-selected download option
# Supported values: "package" and "direct"
download_method <- "package"

# Project root should be resolved relative to the repository root,
# not to the current shell working directory.
# The script is expected to live under posts/fama-french-data/.
# This requires the here package to be available in the project environment.

# 2. Directory checks
required_packages <- c("here", "frenchdata")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0L) {
  stop("Missing required package(s): ", paste(missing_packages, collapse = ", "))
}

project_root <- here::here()
data_dir <- file.path(project_root, "posts", "fama-french-data", "data")
processed_dir <- file.path(data_dir, "processed")

if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

if (!dir.exists(processed_dir)) {
  dir.create(processed_dir, recursive = TRUE)
}

# 3. Download method selection
if (!download_method %in% c("package", "direct")) {
  stop("download_method must be either 'package' or 'direct'.")
}

# 4. Downloading the data
if (download_method == "package") {
  raw <- frenchdata::download_french_data("Fama/French 3 Factors")
} else {
  source_url <- "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors.CSV.zip"
  zip_path <- tempfile(fileext = ".zip")
  extract_dir <- tempfile("fama_french_")

  on.exit({
    if (file.exists(zip_path)) unlink(zip_path, force = TRUE)
    if (dir.exists(extract_dir)) unlink(extract_dir, recursive = TRUE, force = TRUE)
  }, add = TRUE)

  download.file(source_url, destfile = zip_path, quiet = TRUE)
  unzip(zip_path, exdir = extract_dir)

  csv_files <- list.files(
    extract_dir,
    pattern = "\\.csv$",
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(csv_files) == 0L) {
    stop("No CSV file found in the extracted archive.")
  }

  csv_file <- csv_files[1]
  raw <- read.csv(csv_file, header = FALSE, stringsAsFactors = FALSE, check.names = FALSE)

  if (nrow(raw) < 2L) {
    stop("Downloaded CSV file appears to be too short to contain a usable data table.")
  }

  # A simple metadata filter aimed at removing non-data rows from the downloaded file.
  keep_rows <- grepl("^[0-9]{6}$", trimws(as.character(raw[[1]])))
  if (!any(keep_rows)) {
    stop("No monthly date rows were detected in the downloaded CSV file.")
  }

  raw <- raw[keep_rows, , drop = FALSE]
}

# 5. Standardizing column names
if (!is.data.frame(raw)) {
  stop("Downloaded data did not result in a data frame.")
}

if (ncol(raw) < 5L) {
  stop("Downloaded data table has fewer than five columns.")
}

# The exact raw column order can vary by source and package; standardize after extraction.
colnames(raw)[1:5] <- c("date_raw", "market_excess_raw", "size_raw", "value_raw", "risk_free_raw")

# 6. Converting dates
raw$date <- as.character(raw$date_raw)
raw$date <- ifelse(
  nchar(raw$date) == 6,
  paste0(substr(raw$date, 1, 4), "-", substr(raw$date, 5, 6), "-01"),
  raw$date
)

raw$date <- as.Date(raw$date)

# 7. Converting percentage returns to decimals
raw$market_excess <- suppressWarnings(as.numeric(gsub(",", "", raw$market_excess_raw))) / 100
raw$size <- suppressWarnings(as.numeric(gsub(",", "", raw$size_raw))) / 100
raw$value <- suppressWarnings(as.numeric(gsub(",", "", raw$value_raw))) / 100
raw$risk_free <- suppressWarnings(as.numeric(gsub(",", "", raw$risk_free_raw))) / 100

# 8. Validation checks
required_cols <- c("date", "market_excess", "size", "value", "risk_free")
if (!all(required_cols %in% names(raw))) {
  stop("Required columns are missing after the standardization step.")
}

if (anyNA(raw$date)) {
  stop("Date column contains missing values.")
}

if (anyDuplicated(raw$date)) {
  stop("Duplicate dates were detected in the factor data.")
}

if (any(!is.finite(raw$market_excess), !is.finite(raw$size), !is.finite(raw$value), !is.finite(raw$risk_free))) {
  stop("One or more factor columns contain non-finite values.")
}

if (!all(vapply(raw[, c("market_excess", "size", "value", "risk_free")], is.numeric, logical(1)))) {
  stop("Factor columns are not numeric.")
}

if (anyNA(raw[, c("market_excess", "size", "value", "risk_free")])) {
  stop("Factor columns contain missing values.")
}

if (any(diff(raw$date) <= 0)) {
  stop("Dates are not strictly increasing.")
}

if (any(abs(raw$market_excess) > 1, abs(raw$size) > 1, abs(raw$value) > 1, abs(raw$risk_free) > 1)) {
  stop("Factor values appear to still be in percentage form or otherwise outside expected decimal range.")
}

# 9. Saving the processed dataset
processed <- raw[, c("date", "market_excess", "size", "value", "risk_free")]
processed_path <- file.path(processed_dir, "fama_french_3_monthly.csv")
write.csv(processed, file = processed_path, row.names = FALSE)

message("Processed factor dataset saved to: ", processed_path)
