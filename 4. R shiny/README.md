# STEP 4: Build R Shiny 

## Info for Existing .R File  
`Fetch Data From Redcap API.R` aims to:
1. Get data from Redcap API and save at local directory for testing purpose.

`app.R` aims to:
1. Include 3 sample dataset to preview the effect. Present Redcap Links to these dataset.

2. Create Geo-map: allow user to view info of the disease of interest by click on suburbs. Display map for melbourn region only. In order to view the entire Victoria region, remove this part:
```python
melbourne_suburbs <- melbourne_suburbs[melbourne_suburbs$LOC_NAME
                                       %in% melbourne_suburbs_name, ] #enable this line to view only melbourne county
```

3. Create Kaplan Meier Plot: allow user to compare survive rate between two most popular medicines on the disease of interest. Calculate p-value. Edit this part for showning more medicine or your customized medicine of interest:
```python
#filter out two most common group for comperation
sorted_km_data <- sort(table(km_data$group), decreasing = TRUE)
drugs_of_interest <- names(sorted_km_data)[1:2]
filtered_km_data <- km_data[km_data$group %in% drugs_of_interest, ]
```

In order to run this website locally, open `app.R`, install required packages and library, and click `Run App`.

_Note: currently it is build on local dataset. When MongoDB is finalized, this website should pull data from MongoDB directly_