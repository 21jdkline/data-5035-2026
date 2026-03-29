# Exercise 09D: Marketing Campaign Performance
# Approach: Pandas

import pandas as pd

# Setup

customers = pd.DataFrame({
    'customer_id': [1, 2, 3],
    'email': ['a@email.com', 'b@email.com', 'c@email.com']
})

campaign_sends = pd.DataFrame({
    'send_id': ['S1', 'S2', 'S3'],
    'customer_id': [1, 2, 1],
    'campaign_id': ['C1', 'C1', 'C2'],
    'send_date': ['2024-01-01', '2024-01-01', '2024-02-01']
})

clicks = pd.DataFrame({
    'click_id': ['CL1'],
    'send_id': ['S1'],
    'click_date': ['2024-01-02']
})


# Q1: Show all campaign sends with customer emails
# Inner merge — only sends that exist (all of them here, but still the right join type)
q1 = campaign_sends.merge(customers, on='customer_id')[['email', 'campaign_id', 'send_date']]
print("Q1: Campaign sends with customer emails")
print(q1, "\n")


# Q2: Identify whether each send resulted in a click
# Left merge sends to clicks, then flag
q2 = campaign_sends.merge(clicks, on='send_id', how='left')
q2['clicked'] = q2['click_id'].notna()
q2 = q2[['send_id', 'clicked']]
print("Q2: Each send flagged for clicks")
print(q2, "\n")


# Q3: Show all customers and any campaigns they received
# Left merge from customers — c@email.com has no sends
q3 = customers.merge(campaign_sends, on='customer_id', how='left')[['email', 'campaign_id']]
print("Q3: All customers with any campaigns")
print(q3, "\n")


# Q4: Find campaign sends that were never clicked
# Anti-join
q4 = (campaign_sends
      .merge(clicks, on='send_id', how='left', indicator=True)
      .query('_merge == "left_only"')
      [['send_id']])
print("Q4: Sends never clicked")
print(q4, "\n")


# Q5: Find customers who never received a campaign
# Anti-join
q5 = (customers
      .merge(campaign_sends, on='customer_id', how='left', indicator=True)
      .query('_merge == "left_only"')
      [['email']])
print("Q5: Customers with no campaign sends")
print(q5)
