# Exercise 09B: Healthcare Encounters
# Approach: Pandas

import pandas as pd

# Setup

patients = pd.DataFrame({
    'patient_id': [1, 2, 3],
    'name': ['John', 'Mary', 'Sam'],
    'birth_year': [1980, 1975, 1990]
})

visits = pd.DataFrame({
    'visit_id': [2001, 2002],
    'patient_id': [1, 2],
    'visit_date': ['2024-02-01', '2024-02-03'],
    'provider_id': [10, 11]
})

providers = pd.DataFrame({
    'provider_id': [10, 11, 12],
    'provider_name': ['Dr. Smith', 'Dr. Lee', 'Dr. Patel'],
    'specialty': ['Cardiology', 'Primary Care', 'Oncology']
})


# Q1: Show each visit with patient and provider details
# Inner merge on both — only visits that actually occurred
q1 = (visits
      .merge(patients, on='patient_id')
      .merge(providers, on='provider_id')
      [['name', 'provider_name', 'visit_date']])
print("Q1: Visits with patient and provider details")
print(q1, "\n")


# Q2: Show all patients and any visits they may have had
# Left merge from patients — Sam shows up with NaN visit_id
q2 = patients.merge(visits, on='patient_id', how='left')[['name', 'visit_id']]
print("Q2: All patients with any visits")
print(q2, "\n")


# Q3: Show all providers and any visits they handled
# Left merge from providers — Dr. Patel shows up with no visits
q3 = providers.merge(visits, on='provider_id', how='left')[['provider_name', 'visit_id']]
print("Q3: All providers with any visits")
print(q3, "\n")


# Q4: Find patients who have never had a visit
# Anti-join — merge then filter for rows that didn't match
q4 = (patients
      .merge(visits, on='patient_id', how='left', indicator=True)
      .query('_merge == "left_only"')
      [['name']])
print("Q4: Patients with no visits")
print(q4, "\n")


# Q5: Show visits handled by cardiology providers
# Inner merge, then filter on specialty
q5 = (visits
      .merge(patients, on='patient_id')
      .merge(providers, on='provider_id')
      .query('specialty == "Cardiology"')
      [['name', 'provider_name', 'visit_date']])
print("Q5: Cardiology visits only")
print(q5)
