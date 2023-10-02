#This function performs Repeated K Fold cross-validation
from sklearn.metrics import roc_curve
from sklearn.metrics import roc_auc_score
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import RepeatedKFold
import numpy as np
import pandas as pd


def crossval_logreg_rocauc(x, y):
    """
 Perform Repeated K Fold cross-validation for logistic regression and return ROC data and average AUC.

 Parameters:
 x (pd.DataFrame): Input features.
 y (pd.Series): Target variable (labels).

 Returns:
 tuple: A tuple containing FPR DataFrame, TPR DataFrame, average AUC, and array of all AUCs.
 """

fpr_dict = {}
tpr_dict = {}
auc_arr = []

index = 0
rkf = RepeatedKFold(n_splits=3, n_repeats=10)

    for train_index, test_index in rkf.split(x):
X_train, X_test = x.loc[train_index], x.loc[test_index]
y_train, y_test = np.ravel(y.loc[train_index]), np.ravel(y.loc[test_index])

logreg = LogisticRegression(max_iter=700).fit(X_train, y_train)
pred_prob1 = logreg.predict_proba(X_test)

fpr1, tpr1, thresh1 = roc_curve(y_test, pred_prob1[:, 1], pos_label=1)
fpr_dict.update({str('take_{i}'.format(i=index)): fpr1})
tpr_dict.update({str('take_{i}'.format(i=index)): tpr1})
index += 1

auc_score1 = roc_auc_score(y_test, pred_prob1[:, 1])
auc_arr.append(auc_score1)

fpr_df = pd.DataFrame(dict([(k, pd.Series(v)) for k, v in fpr_dict.items()]))
fpr_df["avg"] = fpr_df.mean(axis=1)

tpr_df = pd.DataFrame(dict([(k, pd.Series(v)) for k, v in tpr_dict.items()]))
tpr_df["avg"] = tpr_df.mean(axis=1)

avg_auc = np.mean(auc_arr)

    return fpr_df, tpr_df, avg_auc, auc_arr




#Calculating ROC-AUC without the cross-validation

def empirical_fpr_tpr(x, y):
    """
 Calculate empirical FPR, TPR, and AUC for logistic regression without cross-validation.

 Parameters:
 x (pd.DataFrame): Input features.
 y (pd.Series): Target variable (labels).

 Returns:
 tuple: FPR, TPR, and AUC.
 """
logreg = LogisticRegression(max_iter=700).fit(x, np.ravel(y))
pred_prob1 = logreg.predict_proba(x)

fpr_emp, tpr_emp, _ = roc_curve(y, pred_prob1[:, 1], pos_label=1)
auc_score_emp = roc_auc_score(y, pred_prob1[:, 1])

    return fpr_emp, tpr_emp, auc_score_emp


def print_ci_rocauc(null_crossval):
    """
 Print confidence intervals and statistics for ROC-AUC scores.

 Parameters:
 null_crossval (tuple): A tuple containing FPR DataFrame, TPR DataFrame, average AUC, and array of all AUCs.
 """
null_std = np.std(null_crossval[3])
null_n_sqrt = len(null_crossval[3])**0.5
null_mean = np.mean(null_crossval[3])
null_ci = 1.96 * null_std / null_n_sqrt

    print(null_ci, null_std, null_mean, null_crossval[2])
    print("Avg AUC is", round(null_mean, 3))
    print("Confidence intervals:", round(null_mean - null_ci, 3), "-", round(null_mean + null_ci, 3))
