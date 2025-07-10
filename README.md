# Habitat suitability model

## About the model/project
Task5.1.2 of the MARCO-BOLO project aims to understand the current and predict the future habitat suitability of several species protected under the Habitats and Bird directive. This workflow can be used to better understand overall monthly trends of a species and assess the evolution of habitat suitability under different climate scenarios.

## How to use
The scripts of the different workflow steps can be found in the code/ folder. The 01_setup.R script is used to define several user choices e.g species. After running each of the chunks in TotalWorkflow.Rmd, run 12_report.Rmd to get more information on the input data and the model performance (currently still a placeholder). 

## License
Contact johannes.nowe@vliz.be for more information.


## Mylifewatch 

To crated mylifewatch warps you need to run the wrapper library scripts. 
In the folder mylifewatch you can find the scripts to create the mylifewatch warps.
For example to create the mylifewatch warp 01_setup.R go to folder mylifewatch/01_setup and run the warper script:

Here we assume that the mylifewatch-wrapper-development-kit is in ~/workspace/mylifewatch-wrapper-development-kit

```bash
cd mylifewatch/01_setup
~/workspace/mylifewatch-wrapper-development-kit/bin/build-image 
```

Next to test the warp you can run the following command:

```bash
~/workspace/mylifewatch-wrapper-development-kit/bin/execute
```


To test all warps you can use the mylifewatch/run-pipeline.sh script.:

```bash
~/workspace/mylifewatch-wrapper-development-kit/bin/run-pipeline.sh
```
The script assumes that the mylifewatch-wrapper-development-kit is in ~/workspace/mylifewatch-wrapper-development-kit

