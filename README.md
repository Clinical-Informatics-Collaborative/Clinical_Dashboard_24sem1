# Clinical_Dashboard_24sem1
Welcome to the Clinical Dashboard repository.        

For details on the goals and implementation of this project visit the [Clinical Dashboard wiki](https://github.com/Clinical-Informatics-Collaborative/Clinical_Dashboard_24sem1/wiki "Clinical Dashboard wiki") page.       

This project is building with Python and R Shiny.

## Directory Structure
For details on prep before each step refer to `Readme.md` within each folder.       

### STEP 0: Data Generation
Code:      
   - `data generation.ipynb`: localize address to Austalia and change ETHNICITY  to "Aboriginal and Torres Strait Islander" and "other". Create a non-standard database by change 'COUNTY' to 'SUBURB'.             

   - `heart disease.ipynb`: filter out Ischemic heart disease (disorder) and Diabetes mellitus type 2 (disorder) and save to three databases accordingly. Change address from US to Melbourne region only. 

### STEP 1: Upload File to Redcap        
Code:      
   - `data generation.ipynb`: merge `patient.csv`, `condition.csv`, `medication.csv` into one. Modify their format based on Redcap upload template.Upload file that exceed the website's limit.    

Data:      
   - `TESTIschemicHeartDis_2024-03-24_2246.REDCap.xml`: Template for creating standard Redcap project.           

   - `ClinicalDashboardsDataset_ImportTemplate.csv`: Template for uploading standard dataset.           

   - `ClinicalDashboardsDataset_ImportNonstandardTemplate.csv`: Template for uploading non-standard dataset.        


### STEP 2: Connect Redcap to R through API
This step is mainly carry out on Redcap.

### STEP 3: External Database (MongoDB)
Code:       
   - `import2mongodb.ipynb`: export the three databases from Redcap API and import them to mongoDB dataset.

### STEP 4: Build R Shiny 
Code:     
   - `Fetch Data From Redcap API.R`: get data from Redcap API and save at local directory for testing purpose          

   - `app.R`: use downloaded local data, create Geo-map and Kaplan Meier Plot on website.        

   - `app_v1.R`: use data from MongoDB, create Geo-map and Kaplan Meier Plot on website.         

Data:      
   - `data/diabetes_data.csv`, `data/heart_disease_data.csv`, `data\non_standard_data.csv`: csv file download through `Fetch Data From Redcap API.R`          

   - `data/sf`: victoria map shape file.         

## Running This Application
Method 1: **go to launched website [Clinical Dashboard](http://115.146.87.171:3838/sample-apps/Clinical_Dashboard/ "Clinical Dashboard")**             

Method 2：**run Shiny app locally**        
1. download release v1.0.0.           
2. Prerequisites: R, RStudio.           
3. navigate to `app.R` or `app_v1.R`, open with R studio and click 'Run App'.          
   ![run app](https://github.com/Clinical-Informatics-Collaborative/Clinical_Dashboard_24sem1/blob/main/Picture/App.png "run app")

