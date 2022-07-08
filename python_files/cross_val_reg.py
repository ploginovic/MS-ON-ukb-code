#This function performs Repeated K Fold cross-validation
from sklearn.metrics import roc_curve
from sklearn.metrics import roc_auc_score
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import RepeatedKFold
import numpy as np
import pandas as pd


def crossval_logreg_rocauc(x,y):
    
    """Takes x and y of data, and returns fpr, tpr, avg_auc and array of all AUCs in a tuple"""
    
    
    fpr_dict = {}
    tpr_dict = {}
    auc_arr = []

    index=0

    rkf = RepeatedKFold(n_splits=3, n_repeats=10)
    
#rkf.split generates indices to split data into training and test sets
    for train_index, test_index in rkf.split(x):

    #The following assigns instances to either Train or Test based on indixes derived before
    
    
        X_train, X_test = x.loc[train_index], x.loc[test_index]
        y_train, y_test = np.ravel(y.loc[train_index]), np.ravel(y.loc[test_index])
    
        #This is just to check that it's working
        #print(("TRAIN:", train_index[0:10], "TEST:", test_index[0:10]))
        

    #Fit logistic regression with train data and predict probabilities using X_test
        logreg = LogisticRegression(max_iter=700).fit(X_train, y_train)
        pred_prob1 = logreg.predict_proba(X_test)

    #ROC-AUC calculation, and saving them to a dictionary
        fpr1, tpr1, thresh1 = roc_curve(y_test, pred_prob1[:,1], pos_label=1)
        fpr_dict.update({str('take_{i}'.format(i=index)):fpr1})
        tpr_dict.update({str('take_{i}'.format(i=index)):tpr1})
        index +=1

    #Calculating ROC-AUC score for each iteraiton/fold
        auc_score1 = roc_auc_score(y_test, pred_prob1[:,1])
        auc_arr.append(auc_score1)
    

#Transforming dictionary with false-positive and true-positive rates (fpr, tpr) into a DataFrame
    fpr_df = pd.DataFrame(dict([(k,pd.Series(v)) for k,v in fpr_dict.items()]))
    fpr_df["avg"] = fpr_df.mean(axis = 1)

    tpr_df = pd.DataFrame(dict([(k,pd.Series(v)) for k,v in tpr_dict.items()]))
    tpr_df["avg"] = tpr_df.mean(axis = 1)

#Calculating mean ROC-AUC from cross-validation
    avg_auc = np.mean(auc_arr)
    avg_auc
    
    
    
    return(fpr_df, tpr_df, avg_auc, auc_arr)

#Calculating ROC-AUC without the cross-validation

def empirical_fpr_tpr(x,y):
    
    logreg = LogisticRegression(max_iter=700).fit(x,np.ravel(y))
    pred_prob1 = logreg.predict_proba(x)
    
    fpr_emp, tpr_emp, _ = roc_curve(y, pred_prob1[:,1], pos_label=1)
    
    auc_score_emp = roc_auc_score(y, pred_prob1[:,1])
    
    return(fpr_emp, tpr_emp, auc_score_emp)


def print_ci_rocauc(null_crossval):
    
    null_std =np.std(null_crossval[3]) 
    null_n_sqrt = len(null_crossval[3])**.5
    null_mean = np.mean(null_crossval[3]) 
    null_ci = 1.96*null_std/null_n_sqrt
    
    print(null_ci, null_std, null_mean, null_crossval[2])
    print("Avg AUC is ", round(null_mean,3))
    print("Confidence intervals: ", round(null_mean-null_ci, 3), "-", (round(null_mean+null_ci, 3)))