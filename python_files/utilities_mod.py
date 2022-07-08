from datetime import date
import os
import pandas as pd

file_name = 'on_ms_genpop_3004.tsv'
population = None
folder = str(population or '') + "_figures"

time_list = [5,10,20,68]


def select_file(file_name=file_name):
    current_dir = os.getcwd()

    if os.path.exists(os.path.join(current_dir, file_name)):
        file_path = current_dir + "/" + file_name

    else:
        print("File not accessbile, please define file_path manually")
    
    return(file_path)

#This funciton is to create dated labels for saved .png elements  
def create_png_label(png_descr, population = population, folder = folder):
     
    today = date.today().strftime("%m/%d/%y").replace("/", "_")
    
    if population is None:

        population = ""

        if "genpop" in file_name :
            population = "genpop"
            folder="genpop_figures"
            print("File containging general popualtion is used")

        elif "white_british" in file_name:
            population = "white_british"
            folder = "white_brit_figures"
            print("File containing white british is used")

        elif population == "":
            print("defining an appropriate string failed")


    if population is not None:
        counter =0
        if len(population)>0 & len(folder)==0:
            png_file_name = str(population) +"_"+str(png_descr)+"_"+str(today)+".svg"

        if len(folder) >0 & counter==0:

            png_file_name = str(population) +"_"+str(png_descr)+"_"+str(today)+".svg"
            cwd = os.getcwd()
            png_file_name = os.path.join(cwd, folder, png_file_name)
            counter +=1

            if not os.path.isdir(os.path.join(cwd, folder)):
                os.makedirs(os.path.join(cwd, folder))
                print("directory created: " ,os.path.join(cwd, folder))
    else:
        print("Population not defined")

        
    return(str(png_file_name))

def rename_sex_diagnosis(cph_dataframe):
    cph_dataframe['Sex'] = cph_dataframe.Sex_Female
    cph_dataframe.loc[cph_dataframe.Sex_Female ==0 ,'Sex' ] = 'Male'
    cph_dataframe.loc[cph_dataframe.Sex_Female ==1 ,'Sex' ] = 'Female'

    cph_dataframe.loc[cph_dataframe.first_ON ==0 ,"first_ON"] = 'ON only'
    cph_dataframe.loc[cph_dataframe.first_ON ==1 ,"first_ON"] = 'MS-ON'
    
    
    return(cph_dataframe)

# A function to create a pallette for seaborn violin plots

def create_palette(labels, colours):
    palette = {}
    for (label, colour) in zip(labels, colours):
        palette.update({label:colour})
    return(palette)