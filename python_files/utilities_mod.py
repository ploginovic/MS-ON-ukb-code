from datetime import date
import os
import pandas as pd

file_name = 'on_ms_undif_on_0709.tsv'
# Make choose from pre-defined populations (all_of_UKBB, EUR_british, nonEUR_british, strict_diag, wo_early_diag), and ddefine appropriate population
population = "genpop"
folder = str(population or 'genpop') + '_replication_1607'

time_list = [5,10,20,68]


def select_file(file_name=file_name):
    """
    Selects a file based on the provided file name.
    
    Parameters:
        file_name (str): The name of the file to be selected.
        
    Returns:
        str: The file path of the selected file.
    """
    current_dir = os.getcwd()

    if os.path.exists(os.path.join(current_dir, file_name)):
        file_path = current_dir + "/" + file_name
    else:
        print("File not accessible, please define file_path manually")
    
    return file_path


#This funciton is to create dated labels for saved .png/.svg elements  
def create_png_label(png_descr, population=population, folder=folder):
    """
    Creates a dated label for saved .png elements.
    
    Parameters:
        png_descr (str): Description for the PNG file label.
        population (str, optional): Population identifier. Defaults to the value of the 'population' variable.
        folder (str, optional): Folder name. Defaults to the value of the 'folder' variable.
        
    Returns:
        str: Dated label for the PNG/SVG file.
    """
    today = date.today().strftime("%m/%d/%y").replace("/", "_")
    
    if population is None:
        population = ""
        
        if "genpop" in file_name:
            population = "genpop"
            folder = "genpop_figures"
            print("File containing general population is used")
        elif "white_british" in file_name:
            population = "white_british"
            folder = "white_brit_figures"
            print("File containing white British is used")
        elif population == "":
            print("Defining an appropriate string failed")

    if population is not None:
        counter = 0
        if len(population) > 0 and len(folder) == 0:
            png_file_name = str(population) + "_" + str(png_descr) + "_" + str(today) + ".svg"

        if len(folder) > 0 and counter == 0:
            png_file_name = str(population) + "_" + str(png_descr) + "_" + str(today) + ".svg"
            cwd = os.getcwd()
            png_file_name = os.path.join(cwd, folder, png_file_name)
            counter += 1

            if not os.path.isdir(os.path.join(cwd, folder)):
                os.makedirs(os.path.join(cwd, folder))
                print("Directory created:", os.path.join(cwd, folder))
    else:
        print("Population not defined")
        
    return str(png_file_name)



# Function to duplicate and modify a DataFrame for easier plotting
def rename_sex_diagnosis(cph_dataframe):
    """
    Creates a duplicate of the given dataframe and modifies it for easier plotting.
    
    Parameters:
        cph_dataframe (DataFrame): The input dataframe containing the CoxPH data.
        
    Returns:
        DataFrame: A modified copy of the input dataframe.
    """
    df = cph_dataframe.copy()  # Make a copy of the input dataframe
    df['Sex'] = df.Sex_Female
    df.loc[df.Sex_Female == 0, 'Sex'] = 'Male'  # Update 'Sex' column values
    df.loc[df.Sex_Female == 1, 'Sex'] = 'Female'

    df.loc[df.first_ON == 0, "first_ON"] = 'ON only'  # Update 'first_ON' column values
    df.loc[df.first_ON == 1, "first_ON"] = 'MS-ON'
    
    return df

def create_palette(labels, colours):
    """
    Creates a palette dictionary for mapping labels to colors in seaborn plots.
    
    Parameters:
        labels (list): List of labels for different categories.
        colours (list): List of color values corresponding to the labels.
        
    Returns:
        dict: A dictionary mapping labels to color values.
    """
    palette = {}  # Initialize an empty dictionary for the palette
    for (label, colour) in zip(labels, colours):
        palette.update({label: colour})  # Add label-color pairs to the palette dictionary
    return palette  # Return the created palette dictionary