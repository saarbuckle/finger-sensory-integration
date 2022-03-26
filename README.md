# Finger Sensory Integration

This repository contains matlab code and pre-processed data to reprodce key analyses and figures in the paper: 

Arbuckle, Pruszynski, & Diedrichsen (2022). *Mapping the integration of sensory information across fingers in human sensorimotor cortex.* Journal of Neuroscience. [[link to paper]()]

## Data
The [data folder]() contains the following files:
* `beha_all.mat` : behavioural data for all trials and participants
* `fmri_BAxx_betas.mat` : activity patterns from brodmann area *xx*
* `fmri_selectivity.mat` : single-finger selectivity results
* `fmri_modelFits.mat` : representational model results
* `fmri_regionG.mat` : group-average second-moment matrices for each region (used in model analyses)

## Code
The analysis code is in the following file:
* `fsi_ana.m` (*finger sensory integration analysis*)

This code can reproduce the key analyses reportd in the paper, namely the single-finger selectivity and representational model analyses and plots from the first-level GLM activity patterns. See the Usage section for more information.

## External dependencies
The code in this repo uses functions from these (freely) available toolboxes. Be sure to add them to your path.
* [PCM toolbox](https://github.com/jdiedrichsen/pcm_toolbox)
* [RSA toolbox](https://github.com/rsagroup/rsatoolbox)
* [Plotlib toolbox](https://github.com/nejaz1/plotlib) - for plotting
* [Dataframe toolbox](https://github.com/jdiedrichsen/dataframe) - for pandas-like functionality

## Usage
Please download the entire repository to use. The variable `dataDir` in `fsi_ana.m` must point to the data folder. If you pull this repo, the default path for `dataDir` should be correct (by default, it assumes there is a subfolder called `data` wherever `fsi_ana.m` is saved).

Please note that, by default, verbose updates about analysis progress will be displayed to the user. To turn this off, please set `verbose = 0;` in `fsi_ana.m`.

**Behaviour:** To calculate behavioural performance on the detection mismatch task, execute the following matlab commands:
```
fsi_ana('beha:do_analysis');
```

**Single-finger selectivity:** To produce the single-finger selectivity plot, execute the following matlab commands:
```
D = load('data/fmri_selectivity.mat');
fsi_ana('plot:selectivity',D);
```
You can also reproduce the selectivity analysis yourself:
```
D = fsi_ana('selectivity:do_analysis');
```
To speed up the analysis, you can change how many simulated datasets are generated by adjusting the `numSim` variable under the `selectivity:do_analysis` case (default is 1000). These simulated datasets are used to estimate the influence of measurement noise (see paper methods).

**Representational model analysis:** To produce the representational model fit plot, execute the following matlab commands:
```
D = load('data/fmri_modelFits.mat');
fsi_ana('plot:modelFits',D);
```
You can also reproduce the representational model analysis:
```
D = fsi_ana('model:do_analysis');
```
The default is to re-do the analysis for all six regions. To adjust this, edit the `roi` variable in the `model:do_analysis` case. 