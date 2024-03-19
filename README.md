# Clinical_Dashboard_24sem1

This project is building with Python and R Shiny.

## Purpose and Goal

This project aims to developing a clinical dashboard utilizing R Shiny, designed display the visualization of a certain clinical database sourced from Redcap. The dashboard offers users the ability to select specific diseases of interest and explore their distribution across Victoria, comparisons of death rates associated with popular medications, as well as analyses of disease prevalence across various variables, including ethnicity and income levels.

Key functionalities include a user-friendly dropdown menu for disease selection, alongside interactive visual tools—ranging from dynamic maps to Kaplan-Meier survival plots, and comprehensive pie and bar charts. This project allow clinical workers to access and interpret data without the need for coding. Please note that throughout the development, all utilized databases are simulated data to ensure privacy and confidentiality.

![Project Dashboard Preview](https://github.com/miayokka0926/Clinical_Dashboard_24sem1/blob/main/dashboard%20preview.png "Project Dashboard Preview")

Please note that the attached visual is an early-stage preview and does not represent the final appearance of the dashboard.

## How to achieve this
![Project Process](https://github.com/miayokka0926/Clinical_Dashboard_24sem1/blob/main/development%20process.png "Project Process")

## Method and Steps
To achieve this, this project is splited into following steps. The related files are named accordingly. View jupyter notebook and R markdown inside the folder for details.

  0. Generate stimulated data through Synthea and modify patients' ethnecity group and address information to suit Australia's situation. (Idealy, users should use their own database. This process is only for developers.)
  1. Create Redcap project, fit the generated data into redcap upload template and upload to the desired project through API. For merging and uploading data, refer to 1st intake's work [Link text]([URL](https://github.com/Clinical-Informatics-Collaborative/clinical_dashboards/tree/main/Redcap "Redcap Upload"). There are 3 project in total for demostration: 2 standard project and 1 non-standard project (with wrong column name).
  2. Connect to WEHI R Shiny server and fetch data from Redcap Project using API.
  3. Data tidying and visualization based on the existing code from 1st intake (Kaplan-Meier) and 2nd intake (Geomap), add extra pie chart or bar chart if possible.
  4. Build R Shiny UI and Server and launch the website.
  5. If possible, figure out how to map non-standard project to correct column name so that it can show visualization.

## Q&A
tbc
