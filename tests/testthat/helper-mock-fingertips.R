# Offline stand-ins for the three fingertipsR calls used by the package.

fake_ft_indicators <- function() {
  data.frame(
    IndicatorID = c(101L, 101L, 102L, 103L, 104L, 105L),
    IndicatorName = c(
      "Percentage of E. coli blood specimens resistant to co-amoxiclav; rolling quarterly average",
      "Percentage of E. coli blood specimens resistant to co-amoxiclav; rolling quarterly average",
      "Percentage of community E. coli urine specimens resistant to trimethoprim; by quarter",
      "E. coli bacteraemia case counts and rates, by financial year",
      "Total antibiotic items prescribed: 12-month rolling total by month",
      "Antibiotic Guardians per 100,000 population per quarter"
    ),
    DomainName = c("Resistance ", "Overview", "Resistance", "Cases", "Prescribing", "Stewardship"),
    stringsAsFactors = FALSE
  )
}

fake_ft_metadata <- function() {
  data.frame(
    IndicatorID = 101:105,
    Definition = paste("definition of", 101:105),
    Unit = "%",
    stringsAsFactors = FALSE
  )
}

# One indicator's download, with the quirks of the real thing: numeric columns
# sometimes arrive as character, Count is suppressed (NA) for some rows, and
# area names carry the ODS code and trailing whitespace.
fake_ft_data <- function(indicator_id, profile_id) {
  nm <- fake_ft_indicators()$IndicatorName[match(indicator_id, fake_ft_indicators()$IndicatorID)]
  periods <- switch(as.character(indicator_id),
    "103" = c("2022/23", "2023/24"),
    "104" = c("Jan 2024", "Feb 2024"),
    c("2024 Q1", "2024 Q2")
  )
  areas <- data.frame(
    AreaCode = c("E38000001", "E92000001"),
    AreaName = c("NHS Somewhere ICB - 02P ", "England"),
    AreaType = c("ICBs", "England"),
    stringsAsFactors = FALSE
  )
  out <- merge(areas, data.frame(Timeperiod = periods), by = NULL)
  out$IndicatorID <- indicator_id
  out$IndicatorName <- nm
  out$ParentCode <- "E40000001"
  out$ParentName <- "Region"
  out$Value <- as.character(seq_len(nrow(out)) * 1.5) # character on purpose
  out$Count <- c(NA, seq_len(nrow(out) - 1) * 10)
  out$Denominator <- 100
  out$`LowerCI95.0limit` <- 1
  out$`UpperCI95.0limit` <- 2
  out$Sex <- "Persons" # an extra column that must be passed through
  out
}

# Install the fake fingertipsR layer for the calling test.
local_fake_fingertips <- function(data = fake_ft_data, .env = parent.frame()) {
  fake_state$ft_calls <- integer()
  testthat::local_mocked_bindings(
    .ft_indicators = function(profile_id) fake_ft_indicators(),
    .ft_metadata = function(profile_id) fake_ft_metadata(),
    .ft_data = function(indicator_id, profile_id) {
      fake_state$ft_calls <- c(fake_state$ft_calls, indicator_id)
      data(indicator_id, profile_id)
    },
    .env = .env
  )
  invisible(NULL)
}
