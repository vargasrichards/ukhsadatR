# Script to retrieve all datasets for the theme "infectious_disease" and save them as CSV files.

# Sub-themes
# antimicrobial_resistance
# bloodborne
# bloodstream_infection
# childhood_illness
# contact
# gastrointestinal
# invasive_bacterial_infections
# respiratory
# vaccine_preventable
# vector_borne



antimicrobial_resistance <- get_data(theme = "infectious_disease",
sub_theme = "antimicrobial_resistance", topic = "*",
geography_type = "UKHSA Region", geography = "*",
metric = "*" , max_datasets = 1e5)  

write.csv(antimicrobial_resistance, "antimicrobial_resistance.csv", row.names = FALSE)


invasive_bacterial <- get_data(theme = "infectious_disease", 
sub_theme = "invasive_bacterial_infections", topic = "*", 
geography_type = "UKHSA Region", geography = "*", 
metric = "*" , max_datasets = 1e5)

write.csv(invasive_bacterial, "invasive_bacterial.csv", row.names = FALSE)

bloodstream_infection <- get_data(theme = "infectious_disease", 
sub_theme = "bloodstream_infection", topic = "*", 
geography_type = "UKHSA Region", geography = "*", 
metric = "*" , max_datasets = 1e5)

write.csv(bloodstream_infection, "bloodstream_infection.csv", row.names = FALSE)

bloodborne <- get_data(theme = "infectious_disease", 
sub_theme = "bloodborne", topic = "*", 
geography_type = "UKHSA Region", geography = "*", 
metric = "*" , max_datasets = 1e5)

write.csv(bloodborne, "bloodborne.csv", row.names = FALSE)

childhood_illness <- get_data(theme = "infectious_disease", 
sub_theme = "childhood_illness", topic = "*", 
geography_type = "UKHSA Region", geography = "*", 
metric = "*" , max_datasets = 1e5)

write.csv(childhood_illness, "childhood_illness.csv", row.names = FALSE)


contact <- get_data(theme = "infectious_disease",
sub_theme = "contact", topic = "*",
geography_type = "Nation", geography = "*",
metric = "*" , max_datasets = 1e5       )

write.csv(contact, "contact.csv", row.names = FALSE)

gastrointestinal <- get_data(theme = "infectious_disease",
sub_theme = "gastrointestinal", topic = "*",
geography_type = "UKHSA Region", geography = "*",
metric = "*" , max_datasets = 1e5       )

write.csv(gastrointestinal, "gastrointestinal.csv", row.names = FALSE)


respiratory <- get_data(theme = "infectious_disease",
sub_theme = "respiratory", topic = "*",
geography_type = "UKHSA Region", geography = "*",
metric = "*" , max_datasets = 1e5       )

write.csv(respiratory, "respiratory.csv", row.names = FALSE)

vaccine_preventable <- get_data(theme = "infectious_disease",
sub_theme = "vaccine_preventable", topic = "*",
geography_type = "UKHSA Region", geography = "*",
metric = "*" , max_datasets = 1e5       )   

write.csv(vaccine_preventable, "vaccine_preventable.csv", row.names = FALSE)



vector_borne <- get_data(theme = "infectious_disease",
sub_theme = "vector_borne", topic = "*",
geography_type = "Nation", geography = "*",       
metric = "*" , max_datasets = 1e5       )

write.csv(vector_borne, "vector_borne.csv", row.names = FALSE)

