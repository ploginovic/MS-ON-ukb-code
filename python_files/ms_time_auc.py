import pickle
import lifelines
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import lines


# define necessary functions
def cumulative_dynamic_auc(test_events, test_times, surv_probs, risk_scores, time_points, tied_tol=1e-8):
    """
    Parameters
    ----------
        test_events :
            an np.array of booleans
        test_times :
            an np.array of times to event
        surv_probs : 
            an np.array of ave survival probabilities at each time point
        risk_scores :
            an np.array of risk scores for each individual
        time_points : 
            an np.array of time points
    Returns
    -------
        scores :
            an np.array of scores to evaluate a given model
        mean_auc
        a time-dependent AUC plot
        """

    n_samples = risk_scores.shape[0]
    n_times = time_points.shape[0]

    # convert risk_scores from a 1xn_samples array to an n_samplesxn_times matrix
    # where each row i has n_times risk_scores[i]
    risk_scores = np.broadcast_to(risk_scores[:, np.newaxis], (n_samples, n_times))

    # expand arrays to (n_samples, n_times) shape
    test_times = np.broadcast_to(test_times[:, np.newaxis], (n_samples, n_times))
    test_events = np.broadcast_to(test_events[:, np.newaxis], (n_samples, n_times))
    times_2d = np.broadcast_to(time_points, (n_samples, n_times))

    # sort each time point (columns) by risk score (descending)
    o = np.argsort(-risk_scores, axis=0)
    test_times = np.take_along_axis(test_times, o, axis=0)
    test_events = np.take_along_axis(test_events, o, axis=0)
    risk_scores = np.take_along_axis(risk_scores, o, axis=0)

    is_case = (test_times <= times_2d) & test_events
    is_control = test_times > times_2d
    n_controls = is_control.sum(axis=0)

    # prepend row of infinity values
    estimate_diff = np.concatenate((np.broadcast_to(np.infty, (1, n_times)), risk_scores))
    is_tied = np.absolute(np.diff(estimate_diff, axis=0)) <= tied_tol

    cumsum_tp = np.cumsum(is_case, axis=0)
    cumsum_fp = np.cumsum(is_control, axis=0)
    true_pos = cumsum_tp / cumsum_tp[-1]
    false_pos = cumsum_fp / n_controls

    scores = np.empty(n_times, dtype=float)
    it = np.nditer((true_pos, false_pos, is_tied), order="F", flags=["external_loop"])
    with it:
        for i, (tp, fp, mask) in enumerate(it):
            idx = np.flatnonzero(mask) - 1
            # only keep the last estimate for tied risk scores
            tp_no_ties = np.delete(tp, idx)
            fp_no_ties = np.delete(fp, idx)
            # Add an extra threshold position
            # to make sure that the curve starts at (0, 0)
            tp_no_ties = np.r_[0, tp_no_ties]
            fp_no_ties = np.r_[0, fp_no_ties]
            scores[i] = np.trapz(tp_no_ties, fp_no_ties)

    # compute integral of AUC over survival function
    d = -np.diff(np.r_[1.0, surv_probs])
    integral = (scores * d).sum()
    mean_auc = integral / (1.0 - surv_probs[-1])

    return scores, mean_auc

def plot_time_auc(data, model_dict, times):
    '''
    Parameters
    ----------
    	data :
    		a pd.DataFrame with all necessary columns at individual level
        model_dict : 
            a dictionary with format - {'<model names>':{'model': '<model>', 'color': '<color>'}}
        times : 
            a list of time points
    Returns
    -------
        a time-dependent AUC plot
    '''
    events = data.first_ON.astype(bool)
    years = data.ON_to_MS_years.values
    # handles and labels for legend
    handles, labels = [], []
    
    for model_name, model_and_color in model_dict.items():
        # prepare numbers for plotting
        model = model_and_color['model']
        surv_probs = model.predict_survival_function(data, times).mean(axis=1).values
        risk_scores = np.dot(data[model.summary.index.tolist()], model.params_)
        scores, mean_auc = cumulative_dynamic_auc(events, years, surv_probs, risk_scores, times)
        # add contents to the plot
        color = model_and_color['color']
        plt.plot(times, scores, marker=".", c=color)
        plt.axhline(mean_auc, linestyle="--", c=color)
        plt.text(times[-1]*0.94, mean_auc+0.005, str(round(mean_auc, 3)), c=color)
        # prepare for legend
        handles.append(lines.Line2D([0], [0], marker='.', ls='-', c=color))
        labels.append(model_name+' (AUC='+str(round(mean_auc, 3))+')')

    plt.xlabel("MS-free survival in years")
    plt.ylabel("time-dependent AUC")
    plt.ylim(0.51,.72)
    plt.legend(handles, labels, loc='lower right')
    #plt.grid(True)
    plt.savefig('time_roc_auc_05182023.svg')
    plt.show()
