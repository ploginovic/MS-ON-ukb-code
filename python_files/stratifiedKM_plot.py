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
    """
    Stratifies the data_frame based on specified cut-off points using the Cox predicted hazard values.
    
    Args:
        data (DataFrame): The DataFrame containing the data to be stratified.
        cut_off_dict (dict): A dictionary with cut-off points for stratification.
        
    Returns:
        list: A list of stratified groups based on the cut-off points.
    """
    vars_list = []  # Initialize an empty list to store stratified groups
    
    for cut_off in cut_off_dict:
        if cut_off == 0:
            # For cut_off == 0, include values between the lower and upper quantiles
            var = data[((data.cph_prediction >= data.cph_prediction.quantile(q=cut_off)) &
                        (data.cph_prediction <= data.cph_prediction.quantile(q=cut_off_dict.get(cut_off))))]
        elif cut_off > 0:
            # For cut_off > 0, include values between the lower quantile (exclusive) and upper quantile
            var = data[((data.cph_prediction > data.cph_prediction.quantile(q=cut_off)) &
                        (data.cph_prediction <= data.cph_prediction.quantile(q=cut_off_dict.get(cut_off))))]
        vars_list.append(var)  # Add the stratified group to the list
        
    return vars_list  # Return the list of stratified groups


def plot_km(data, cut_off_dict, save_label='Unnamed', plot_label='', figsize=[6, 6], colours=colours):
    """
    Plots Kaplan-Meier survival curves based on the stratified data using specified cut-off points.
    
    Args:
        data (DataFrame): The DataFrame containing the data to be plotted.
        cut_off_dict (dict): A dictionary with cut-off points for stratification.
        save_label (str): A label for saving the plot.
        plot_label (str): A label for the plot title.
        figsize (list): A list specifying the dimensions of the plot.
        colours (list): A list of colors for different groups.
        
    Returns:
        None
    """
    
    # Stratify the data based on the cut-off points
    stratified_data = stratify_kmf(data, cut_off_dict)
    
    # Check the type of cut-off dictionary and set labels and models accordingly
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
        print("Cut off dictionary invalid")
        return
    
    # Create the plot with specified dimensions and resolution
    plt.figure(figsize=figsize, dpi=300, facecolor=None)
    
    # Plot Kaplan-Meier survival curves for each group using stratified data
    for (group, group_label, kmf_model, color) in zip(stratified_data, kmf_labels, models, colours):
        kmf_model.fit(group.ON_to_MS_years, group.first_ON, label='{group}, n={i}'.format(
            group=group_label, i=len(group)))
        ax = kmf_model.plot(show_censors=True, censor_styles={'ms': 1.3, 'marker': 'x'}, linewidth=0.9, color=color, fontsize=7)
    
    # Set plot limits and labels
    ax.set_xlim([0.0, 35.0])
    ax.set_ylim([0.0, 1.0])
    plt.title(plot_label, fontsize=7) 
    plt.xlabel("MS-free survival in years", fontsize=7)
    plt.ylabel("MS-free survival probability", fontsize=7)
    
    # Add at-risk counts to the plot if necessary
    if len(cut_off_dict) == 3:
        add_at_risk_counts(models[0], models[1], models[2], fontsize=5)
    elif len(cut_off_dict) == 4:
        add_at_risk_counts(models[0], models[1], models[2], models[3], fontsize=5)
    
    # Adjust layout and save the plot as a PNG file
    plt.tight_layout()
    plt.savefig(create_png_label(save_label))
    plt.show()
    
    


Here's the annotated explanation of the function proportion_ci:

python
Copy code
def proportion_ci(data, cut_off_dict, stratify=False):
    """
    Calculates proportions and their 95% confidence intervals using the normal approximation to the binomial distribution.
    
    Args:
        data (list): A list of DataFrames containing the data to be analyzed.
        cut_off_dict (dict): A dictionary with cut-off points for analysis.
        stratify (bool): Whether to stratify the data (default is False).
        
    Returns:
        DataFrame: A DataFrame containing calculated proportions and confidence intervals for each group and time point.
    """
    
    mean_ci_df = pd.DataFrame()  # Initialize an empty DataFrame to store results
    
    for y, i in enumerate(data):
        
        for ts, timepoint in enumerate(time_list):  # Iterate over time points
            
            if len(i.loc[(i.first_ON == 'MS-ON') & (i.ON_to_MS_years <= timepoint)]) != 0:
                n = i.loc[(i.first_ON == 'MS-ON') & (i.ON_to_MS_years <= timepoint)].first_ON.value_counts()[0]
            else:
                n = 0
                
            p = float(n / len(i))  # Calculate the proportion
            crit_z = 1.96  # Critical value for a 95% confidence interval
            ci_95 = crit_z * ((p * (1 - p)) / len(i)) ** 0.5  # Calculate the confidence interval
            
            if y == 0:
                # Create a dictionary for the confidence interval values
                ci_data = {
                    ("lower_ci" + str(timepoint)): round(p - ci_95, 3),
                    ("proportion" + str(timepoint)): round(p, 3),
                    ("upper_ci" + str(timepoint)): round(p + ci_95, 3)
                }
                
                # Create a DataFrame for the current time point
                ci_df = pd.DataFrame([ci_data])
                mean_ci_df = pd.concat([mean_ci_df, ci_df], axis=1)
            
            elif y > 0:
                # Update the DataFrame for additional time points
                mean_ci_df.loc[y, ("lower_ci" + str(timepoint))] = round(p - ci_95, 3)
                mean_ci_df.loc[y, ("proportion" + str(timepoint))] = round(p, 3)
                mean_ci_df.loc[y, ("upper_ci" + str(timepoint))] = round(p + ci_95, 3)
        
    return mean_ci_df  # Return the DataFrame with calculated proportions and confidence intervals