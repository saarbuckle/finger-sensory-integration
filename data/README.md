# Data structures 
This folder contains all necessary pre-processed data. Please find below details about the datastructures and their subfields.

---
## beha_all
This data structure contains the behavioural responses for each trial for each participant. To calculate the behavioural task performance reported in the paper, run the following matlab command: `fsi_ana('beha:do_analysis');`. This datastructure has the following subfields:
| 	fieldname 			       | comment  
|:-----------------------------|:-------------------------------
| `sn`| participant number
| `session`| scanning session number (each participant was scanned twice)
| `run`| scanning run number (cummulative across sessions)
| `trialNum` | trial # of current run (62 trials per run)
| `digitComboID` | finger combination # (of 31 possible combos)
| `digitStimulate` | vector denoting which digit(s) were stimulated (thumb:little, 0-no, 1-yes)
| `digitScreen` | vector denoting what visual combo was highlighted on screen after the stimulation occurred
| `mismatch` | was the trial a perceptual mismatch?
| `rxntime`	| how quickly did they respond to mismatch trials?
| `correct` | was the response correct?
| `points` | points gained/lost for response
| `resp_CR` | was this trial a correct rejection?
| `resp_FA` | was this trial a false alarm?
| `resp_hit` | was this trial a hit?
| `resp_miss` | was this trial a miss?
---
## fmri_BAxx_betas
These data structures contain the activity patterns (first-level GLM beta weights) from each Brodmann area (BA). Each datastructure contains the following subfields:
| 	fieldname 			       | comment  
|:-----------------------------|:-------------------------------
| `sn`| participant number
| `roi`| roi number
| `roiName` | Brodmann area name
| `session`| scanning session number
| `run`| scanning run number (cummulative across sessions)
| `digitCombo` | finger combination # (of 31 possible combos)
| `beta_raw` | cell array containing activity patterns [combo\*run x #voxels]
| `beta_multiwhite` | cell array containing multivariately-whitened activity patterns [combo\*run x #voxels]
| `beta_resMS` | array containing each voxel's mean (across conditions) of the squared residuals from the first-level GLM (used for pre-whitening)
| `voxel_xyz` | voxel coordinates in mm [xyz x # voxels]

### roi information
| 	# | 	region name 
|:----|:--------------------
| 1 | BA 4a
| 2 | BA 4p
| 3 | BA 3a
| 4 | BA 3b
| 5 | BA 1
| 6 | BA 2
---
## fmri_selectivity
This data structure contains the single-finger selectivity results from the paper. To re-produce this analysis, run the following matlab command: `D=fsi_ana('selectivity:do_analysis');`. This datastructure has the following subfields:
| 	fieldname 			       | comment  
|:-----------------------------|:-------------------------------
| `sn`| participant number
| `roi`| roi number
| `roiName` | Brodmann area name
| `fthres` | percentile threshold for f-test (in paper, was 95%)
| `fcrit` | f-value corresponding to `fthres`
| `numVoxTot` | # of voxels from this region in this participant
| `numVoxSig` | # of voxels that surpass `fcrit` criterion
| `propVox`	| proportion of significant voxels
| `var_signal` | estimate of signal strength
| `var_noise` | estimate of noise strength
| `sel_beta` | average voxel selectivity from real data
| `sel_random` | average selectivity for randomly tuned data (simulated)
| `sel_selective` | average selectivity for selectively tuned data (simulated)
| `sel_normalized` | `sel_beta` after normalization between `sel_random`(0) & `sel_selective`(1)
---
## fmri_modelFits
This data structure contains the representational model fits. To re-produce this analysis, run the following matlab command: `D=fsi_ana('model:do_analysis');`. This datastructure has the following subfields:
| 	fieldname 			       | comment  
|:-----------------------------|:-------------------------------
| `sn`| participant number
| `roi`| roi number
| `roiName` | Brodmann area name
| `model` | model number
| `modelName` | name of model (see table below)
| `modelTheta` | log model parameters for linear-nonlinear model
| `regTheta` | log of {signal strength, noise strength} for feature pattern estimation with Tikhonov regularization
| `regLambda` | regularization shrinkage toward feature prior: exp(modelTheta{2})/exp(modelTheta{1})
| `r_train` | correlation across voxels between training data and model predicted patterns
| `r_test` | correlation across voxels between test data and model predicted patterns
| `r_norm` | `r_test` normalized between the null model fit (0) and noise ceiling model fit (1)
| `avgAct` | average (activity) of predicted patterns binned according to the number of fingers per combination
| `avgAct_cent` | as above, but with voxel means removed
| `sel_selective` | average selectivity for selectively tuned data (simulated)
| `sel_normalized` | `sel_beta` after normalization between `sel_random`(0) & `sel_selective`(1)
*Note that all data fields have been averaged across all cross-validation fold for each region in each participant.*

### representational model names
| 	# | 	model name  | 	comment
|:----|:----------------|:-------------------------------
| 1 | null model | predicts univariate scaling of overall activity
| 2 | 1finger | linear model in paper - summation of constituent single finger patterns
| 3 | 2finger | includes features for single fingers and finger-pairs
| 4 | 3finger | includes features for ", ", & finger-triplets
| 5 | 4finger | includes features for ", ", ", & finger-quadruplets
| 6 | 1finger_nonlinear | linear-nonlinear model in paper - 1finger model where predicted patterns containing the same # of fingers are scaled by a parameter
| 7 | 2finger_distantPairs | includes features for single fingers and non-neighbouring finger-pairs
| 8 | 2finger_adjacentPairs | includes features for single fingers and neighbouring finger-pairs
| 9 | noise_ceiling | models each condition as a separate feature - fully saturated model

### fmri_regionG
This datastructure contains the group-averaged, cross-validated second-moment matricies for each region. These matrices are used to estimate the feature model priors for Tikhonov regularization (i.e. the *G*s in the paper equations).
| 	fieldname 			       | comment  
|:-----------------------------|:-------------------------------
| `roi`| roi number
| `roiName` | Brodmann area name
| `g` | vectorized second-moment matrix. To square this use `rsa_squareIPM(g)`