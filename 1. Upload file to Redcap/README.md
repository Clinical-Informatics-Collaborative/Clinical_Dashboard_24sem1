# STEP 1: Upload File to Redcap

Code for this part is from the first intake. Go to their github page for more info: [Redcap Upload](https://github.com/Clinical-Informatics-Collaborative/clinical_dashboards/tree/main/Redcap "Redcap Upload")

## Redcap Walkthrough
Please refer to this recording to get a basic idea of what Redcap does and looks like (while you waiting for its access).
[Redcap Intro](https://wehieduau-my.sharepoint.com/:v:/r/personal/anhha_s_wehi_edu_au/Documents/Recordings/Clinical%20Dashboard%20Members%20Weekly%20Meeting-20240409_143618-Meeting%20Recording.mp4?csf=1&web=1&e=1eMouq&nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJTdHJlYW1XZWJBcHAiLCJyZWZlcnJhbFZpZXciOiJTaGFyZURpYWxvZy1MaW5rIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXcifX0%3D "Redcap Intro")

## Info for Existing File  
`data generation.ipynb` aims to:
1. Merge three Synthea csv into one. Modify their format based on Redcap upload template.

2. Upload file that exceed the website's limit.

_Note: if your file size is below 200 MB you can ignore the second part. Just run the first part and upload through Redcap's website._

`TESTIschemicHeartDis_2024-03-24_2246.REDCap.xml` aims to:
1. Template for creating standard Redcap project.

`ClinicalDashboardsDataset_ImportTemplate.csv` aims to:
1. Template for uploading standard dataset.

`ClinicalDashboardsDataset_ImportNonstandardTemplate.csv` aims to:
1. Template for uploading non-standard dataset.
