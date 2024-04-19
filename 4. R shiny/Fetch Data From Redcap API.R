
#get radcap project records
get_redcap_data <- function(token){
  url <- "https://redcap.wehi.edu.au/api/"
  formData <- list("token"=token,
                   content='record',
                   action='export',
                   format='csv',
                   type='flat',
                   csvDelimiter='',
                   rawOrLabel='raw',
                   rawOrLabelHeaders='raw',
                   exportCheckboxLabel='false',
                   exportSurveyFields='false',
                   exportDataAccessGroups='false',
                   returnFormat='csv'
  )
  response <- httr::POST(url, body = formData, encode = "form")
  result <- httr::content(response)
  return(result)
}

#save three example projects to local
diabetes_data <- get_redcap_data("4657DF053B6B6310081C870C6DB0F20E")
heart_disease_data <- get_redcap_data("2071190726F5AC9298E1DD1C3BEC19BA")
non_standard_data <- get_redcap_data("4F6F55CCF7F1766932E293F5EB5AD728")

write.csv(diabetes_data, "Clinical Dashboard/data/diabetes_data.csv", row.names = FALSE)
write.csv(heart_disease_data, "Clinical Dashboard/data/heart_disease_data.csv", row.names = FALSE)
write.csv(non_standard_data, "Clinical Dashboard/data/non_standard_data.csv", row.names = FALSE)
