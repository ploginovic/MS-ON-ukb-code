from lifelines import CoxPHFitter
from lifelines import KaplanMeierFitter
from lifelines.plotting import add_at_risk_counts
from lifelines.statistics import logrank_test
import pandas as pd
import os
import matplotlib.pyplot as plt 
import seaborn as sns
import numpy as np

from statannot import add_stat_annotation
from sklearn import metrics

from importlib import reload
import utilities_mod
reload( utilities_mod)
from utilities_mod import *

colours = ['darkorange','orangered','darkmagenta','steelblue']

cut_off_tertiles = {0:1/3, 1/3:2/3, 2/3:1}
cut_off_threequarts = {0:.25, .25:.75, .75:1}
cut_off_quarts = {0:.25, .25:.5, .5:.75, .75:1}



def stratify_kmf(data, cut_off_dict):
    
    """Requires data_frame and cut_off_dict, returns a tuple of groups"""
    vars_list = []
    
    for cut_off in cut_off_dict:
        if cut_off == 0:
            var = data[((data.cph_prediction >= data.cph_prediction.quantile(q=cut_off)) &
                   (data.cph_prediction <= data.cph_prediction.quantile(q=cut_off_dict.get(cut_off))))]
        elif cut_off >0:
            var = data[((data.cph_prediction > data.cph_prediction.quantile(q=cut_off)) &
                       (data.cph_prediction <= data.cph_prediction.quantile(q=cut_off_dict.get(cut_off))))]
        vars_list.append(var)
    return vars_list


def plot_km(data, cut_off_dict, save_label = 'Unnamed',plot_label='', figsize = [6,6], colours=colours):
    
    """Params: data_frame, cut_off_dict, plot_label, save_label and figsize. Returns a KM plot"""
    
    stratified_data = stratify_kmf(data, cut_off_dict)
    
    if cut_off_dict == cut_off_quarts:
        
        kmf_labels = ["1st qrt", "2nd qrt", "3rd qrt", '4th qrt']
        
        kmf_firstq, kmf_secondq, kmf_thirdq, kmf_fourthq = KaplanMeierFitter(), KaplanMeierFitter(), KaplanMeierFitter(), KaplanMeierFitter()
        models = [kmf_firstq, kmf_secondq, kmf_thirdq, kmf_fourthq]
        
        
    elif cut_off_dict == cut_off_threequarts:
        
        kmf_labels = ["1st quart", "2nd-3rd quart", "4th quart"]
        kmf_firstq, kmf_secondq, kmf_thirdq = KaplanMeierFitter(), KaplanMeierFitter(), KaplanMeierFitter()
        
        models = [kmf_firstq, kmf_secondq, kmf_thirdq]
        

    elif cut_off_dict == cut_off_tertiles:
        
        kmf_labels = ["1st tertile", "2nd tertile", "3rd tertile"]
        kmf_firstq, kmf_secondq, kmf_thirdq = KaplanMeierFitter(), KaplanMeierFitter(), KaplanMeierFitter()
        
        models = [kmf_firstq, kmf_secondq, kmf_thirdq]
        
    else:
        print("Cut off dictioniary invalid")
        end()
        
    plt.figure(figsize= figsize, dpi=300, facecolor=None)
    
    for (group, group_label, kmf_model, color) in zip(stratified_data, kmf_labels, models, colours):
        kmf_model.fit(group.ON_to_MS_years, group.first_ON, label = '{group}, n={i}'.format(
            group = group_label, i = len(group)))
        ax = kmf_model.plot(show_censors = True, censor_styles = {'ms': 1.3, 'marker': 'x'}, linewidth=0.9, color = color, fontsize=7)
    
    ax.set_xlim([0.0, 35.0])
    ax.set_ylim([0.0, 1.0])
    
    plt.title(plot_label, fontsize=7) 
    plt.xlabel("MS-free survival in years", fontsize=7)
    plt.ylabel("MS-free survival probability", fontsize=7)
    
    if len(cut_off_dict)==3:
        add_at_risk_counts(models[0], models[1], models[2], fontsize= 5)
    
    if len(cut_off_dict)==4:
        add_at_risk_counts(models[0], models[1], models[2],models[3], fontsize= 5)
    
    plt.tight_layout()
    

    
    plt.savefig(create_png_label(save_label))
    return(plt.show())

def proportion_ci(data, cut_off_dict, stratify = False):

    """ Calculates proportion and 95% CI using normal approximation to the binomial """
    mean_ci_df = pd.DataFrame()
    for y,i in enumerate(data):
        
        for ts, timepoint in enumerate(time_list):
            
            if len(i.loc[(i.first_ON=='MS-ON') & (i.ON_to_MS_years <=timepoint) ] )!=0:
            
                n = i.loc[(i.first_ON=='MS-ON') & (i.ON_to_MS_years <=timepoint) ].first_ON.value_counts()[0]
            elif len(i.loc[(i.first_ON=='MS-ON') & (i.ON_to_MS_years <=timepoint) ]) ==0:
                n=0
            
#             print(len(i), n)
            p = float(n/len(i))
            crit_z = 1.96
            ci_95 = crit_z* ((p*(1-p))/len(i))**.5
        
            if y ==0:
                ci_data = {("lower_ci"+str(timepoint)):round(p-ci_95,3),
                           ("proportion" + str(timepoint)):round(p,3),
                           ("upper_ci"+str(timepoint)) :round(p+ci_95,3)}



                ci_df = pd.DataFrame([ci_data])
                mean_ci_df = pd.concat([mean_ci_df, ci_df], axis=1)
            
            elif y>0:

                mean_ci_df.loc[y, ("lower_ci"+str(timepoint))] = round(p-ci_95,3)
                mean_ci_df.loc[y, ("proportion" + str(timepoint))] = round(p,3)
                mean_ci_df.loc[y, ("upper_ci"+str(timepoint))] = round(p+ci_95,3)  
            
        
    return(mean_ci_df)
    
