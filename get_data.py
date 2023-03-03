# -*- coding: utf-8 -*-
"""
Spyder Editor

Python 3.8
"""

import pandas as pd
import numpy as np
import os
import datetime
import Haver

# download haver whl from:
# http://www.haver.com/Python/Haver/

#os.chdir('')
# %%

# your haver data path here
Haver.path('Y:\DLX\DATA')
startdate = '1981-01-01'
save_name = datetime.datetime.now().strftime('%Y-%m-%d.xlsx')

key = pd.read_excel('spec_euro_area.xlsx')
# have to split by frequency, other Haver.data() aggregates to the lower freq
key_m = key[key.Frequency=='m']
key_q = key[key.Frequency=='q']

# create mnemonics for Haver functions
db_series_m = []
db_series_q = []
for i in range(key_m.shape[0]): 
    db_series_m.append(key_m.database.iloc[i] + ':' + key_m.series.iloc[i])
for i in range(key_q.shape[0]): 
    db_series_q.append(key_q.database.iloc[i] + ':' + key_q.series.iloc[i])
    

# %% this is actually very easy!
df_m = Haver.data(db_series_m, startdate=startdate)
df_q = Haver.data(db_series_q, startdate=startdate)

# %%
# rename cols
df_m.columns = key_m.SeriesID.to_list()
df_q.columns = key_q.SeriesID.to_list()
df_m.index.name = 'date'
df_q.index.name = 'date'

# create date col and drop indexes
df_m = df_m.assign(date=df_m.index.strftime('%m/01/%Y'))
df_q = df_q.assign(date=df_q.index.strftime('%m/01/%Y'))
df_m.reset_index(drop=True, inplace=True)
df_q.reset_index(drop=True, inplace=True)

# merge freq df's
df = df_m.merge(df_q, on='date', how='outer')
# %%
# organize to be the same or our key
order_df = ['date'] + key.SeriesID.to_list()
df[order_df].to_excel(save_name, sheet_name='data', index=False)

