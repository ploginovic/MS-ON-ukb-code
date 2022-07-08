from lifelines import CoxPHFitter
import numpy as np
import pandas as pd

def create_dummies(data):
    for col in data:
        print(col)
        if data[col].isnull().values.any() or data[col].dtype =='O':
            print(col, ' needs a dummy variable: empty data')

            column_to_drop = str(col)+"_"+str(data[col].value_counts().idxmax())
            print("The column will be dropped: ",column_to_drop)
            data = pd.get_dummies(data, columns = [col], drop_first=False)
            data = data.loc[:, data.columns!=str(column_to_drop)]
            
            
        if data[col].dtype=='int64' and (data[col].min!=0 or data[col].max!=1):
            print(col, ' needs a dummy variable: categorical intigers suspected')
            
            column_to_drop = str(col)+"_"+str(0)
            print("The column will be dropped: ",column_to_drop)
            data = pd.get_dummies(data, columns = [col], drop_first=False)
            data = data.loc[:, data.columns!=str(column_to_drop)]  
            
    return(data)


def backward_elimination_AIC(data, significance_level = 0.05):
    
    data=create_dummies(data)
    
    features = data.columns.tolist()
    print(" Initial variable list in the model: ", data.loc[:,((data.columns!='first_ON') & (data.columns!='ON_to_MS_years'))].columns.tolist(), '\n')


    while(len(features)>0):
        
        AIC_dict = {}
        model = CoxPHFitter().fit(data, duration_col='ON_to_MS_years', event_col='first_ON')
        current_AIC = model.AIC_partial_
        
        for i in features:
            if (i!='first_ON') and i!='ON_to_MS_years':
            
                new_model = CoxPHFitter().fit(data.loc[:, data.columns !=i], duration_col='ON_to_MS_years', event_col='first_ON')
                AIC_dict[i] = round(new_model.AIC_partial_,3)               

        print('AIC after removing each variable:', AIC_dict)    
        min_new_AIC= min(AIC_dict.values())
        removed_var = list(AIC_dict.keys())[list(AIC_dict.values()).index(min_new_AIC)]
        
        if min_new_AIC < current_AIC: 
            
            print('Current model: ')
            #model.print_summary()
            
            features.remove(str(removed_var))            
            current_AIC = min_new_AIC
            print('\n','Removed variable: ', removed_var, "\n", "New AIC is ", min_new_AIC, '\n')
            data=data.loc[:, features]
            
        elif min_new_AIC >=current_AIC:
            print("\n" , "Model optimised: no lower AIC can be achieved")
            print("The final set of variables is: ", features)
            model = CoxPHFitter().fit(data, duration_col='ON_to_MS_years', event_col='first_ON')
            print("\n")
            #model.print_summary()
            break

    return features, model


def backward_elimination_p(data, significance_level = 0.05):
    features = data.columns.tolist()
    
    while(len(features)>0):
        model = CoxPHFitter().fit(data, duration_col='ON_to_MS_years', event_col='first_ON')
        p_values = model.summary.loc[:,'p']
        max_p_value = p_values.max()
        
        if(max_p_value >= significance_level):
            excluded_feature = CoxPHFitter().summary[(CoxPHFitter().summary.p == max(CoxPHFitter().summary.p))].index[0]
            features.remove(str(excluded_feature))
            data = data.loc[:,features]
        else:
            break 
    return features


def stepwise_selection(data, target,SL_in=0.05,SL_out = 0.05):
    initial_features = data.columns.tolist()
    best_features = []
    while (len(initial_features)>0):
        remaining_features = list(set(initial_features)-set(best_features))
        new_pval = pd.Series(index=remaining_features)
        for new_column in remaining_features:
            model = sm.OLS(target, sm.add_constant(data[best_features+[new_column]])).fit()
            new_pval[new_column] = model.pvalues[new_column]
        min_p_value = new_pval.min()
        if(min_p_value<SL_in):
            best_features.append(new_pval.idxmin())
            while(len(best_features)>0):
                best_features_with_constant = sm.add_constant(data[best_features])
                p_values = sm.OLS(target, best_features_with_constant).fit().pvalues[1:]
                max_p_value = p_values.max()
                if(max_p_value >= SL_out):
                    excluded_feature = p_values.idxmax()
                    best_features.remove(excluded_feature)
                else:
                    break 
        else:
            break
    return best_features
