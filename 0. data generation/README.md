# STEP 0: Data Generation

## Prep before Using .ipynb File

Genrate Synthetic Patient Data through Synthea:

1. Go to link: [Synthea](https://github.com/synthetichealth/synthea "Synthea"), follow Developer Quick Start and install Synthea. </p>

2. Go to `.../synthea/src/main/resources/synthea.properties`, change `exporter.csv.export = true`.

3. Open cmd, input `cd .../synthea`, then `run_synthea -s 1256 -p 5000 Massachusetts`. Then, input `run_synthea -s 1256 -p 5000 California`. This generate 5000 patients' information located at Massachusetts/California with seed 1256.

4. In `.../synthea/output/csv`, locate following files: patients.csv, medications.csv, conditions.csv. These are required to run following .ipynb.


## Info for Existing .ipynb File   
`data generation.ipynb` aims to:    
1. Edit `patient.csv` from generated Synthea data (with multiple disease).    

2. Basic data localization: change address from US to ==Victoria, Australia== by editing CITY, STATE，COUNTY，ZIP，LAT，LON based on [Australian Postcodes](https://www.matthewproctor.com/australian_postcodes "Australian Postcodes") and [VIC Suburb](https://data.gov.au/dataset/ds-dga-bdf92691-c6fe-42b9-a0e2-a4cd716fa811/details "VIC Suburb"). change ETHNICITY from "hispanic" and "non-hispanic" to "Aboriginal and Torres Strait Islander" and "other".

3. Create a non-standard database by change 'COUNTY' to 'SUBURB'.

By modifying
```python
#Import genetrated Synthea data
patients_df = pd.read_csv('data/Synthetic data/project2and3/patients.csv')
```
and
```python
# Save the DataFrame to a new CSV file
patients_df.to_csv("data/modified data/project3/patients.csv", index=False)
```

You should be able to export different modified patient data.

==Note: This file is written in early stage. It output a dataset with mixed disease. Later we realized that Redcap project is more focus on one disease, which leads to `heart disease.ipynb`.==

`heart disease.ipynb`aims to:
1. Take two the generated dataset and filter out one disease. Here we are looking at Ischemic heart disease (disorder)  and Diabetes mellitus type 2 (disorder). Change this part to modify disease of interest:
```python
# Delete rows where DESCRIPTION is not "Ischemic heart disease (disorder)" / "Diabetes mellitus type 2 (disorder)"
condition_df = condition_df[condition_df['DESCRIPTION'] == 'Ischemic heart disease (disorder)']
```

2. Change address from US to ==Melbourne region only==. Remove the this part to cancel this change:
```python
#reasign address
melbourne_suburbs =[
  "Carlton", "Carlton North", "Docklands", "East Melbourne",
  "Flemington", "Kensington", "Melbourne", "North Melbourne",
  "Parkville", "Port Melbourne", "Southbank", "South Wharf",
  "South Yarra", "West Melbourne", "Albert Park", "Balaclava",
  "Elwood", "Middle Park", "Ripponlea", "St Kilda", "St Kilda East",
  "St Kilda West", "South Melbourne", "Abbotsford", "Alphington",
  "Burnley", "Clifton Hill", "Collingwood", "Cremorne", "Fairfield",
  "Fitzroy", "Fitzroy North", "Princes Hill", "Richmond"
]
patient_df["COUNTY"] = random.choices(melbourne_suburbs, k=len(patient_df))
```

==Note:  `data generation.ipynb` is run before `heart disease.ipynb` so there is no code for editting ETHNICITY in `heart disease.ipynb`.== 


