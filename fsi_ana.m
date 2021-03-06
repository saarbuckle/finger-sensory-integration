function varargout = fsi_ana(what,varargin)
%% - - - - - - - - - -
% function varargout = fsi_ana(what,varargin)
% - - - - - - - - - -
%   'what'   : specific analysis case
%   varargin : variable input arguments accepted for specific analysis case
%   varargout: variable outputs
% - - - - - - - - - -
%
% Analyses code for the results published in:
%
%   Arbuckle, Pruszysnki, & Diedrichsen (2022). Mapping the integration off
%       sensory information acros fingers in human sensorimotor cortex.
%       Journal of Neuroscience.
%
% - - - - - - - - - -
%
% Requires the following toolboxes:
%   - RSA (https://github.com/rsagroup/rsatoolbox)
%   - PCM (https://github.com/jdiedrichsen/pcm_toolbox)
%   - dataframe (https://github.com/jdiedrichsen/dataframe)
%   - plotlib (https://github.com/nejaz1/plotlib)
% 
% - - - - - - - - - -
%
% ROI information:
%   #   |   name
% ---------------
%   1   | BA 4a (rostral M1) (left hemi)
%   2   | BA 4p (caudal M1) (left hemi)
%   3   | BA 3a (hand area) (left hemi)
%   4   | BA 3b (hand area) (left hemi)
%   5   | BA 1 (hand area) (left hemi)
%   6   | BA 2 (hand area) (left hemi)
%
% - - - - - - - - - -
%
% Representational model information:
%   #   |   name
% ---------------
%   1   | null
%   2   | linear
%   3   | 2finger (includes 2-finger interactions)
%   4   | 3finger (includes 2 & 3-finger interactions)
%   5   | 4finger (includes 2, 3, & 4-finger ....)
%   6   | linear-nonlinear model
%   7   | 2finger_distantPairs
%   8   | 2finger_adjacentPairs
%   9   | noise ceiling
%
% - - - - - - - - - -
%
% To determine which finger(s) were stimulated in each of the 31 finger
% combinations: X = fsi_ana('misc:chords')
% Each row in X denotes a finger combination, and each column a digit
% (first column is the thumb, last column is the little finger). Values of
% 0 and 1 indicate not stimulated and stimulated, respectively.
%
% - - - - - - - - - -
%
% Note that there are lots of code section markers (%%) in the comments 
% because Matlab 2021+ code folding no longer supports collapsing 
% of cases (.....).
%
% - - - - - - - - - -
%
% MIT License
% 
% Copyright (c) 2022 Spencer Arbuckle
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%
% - - - - - - - - - - 

% Define path to data folder:
dataDir = fullfile(fileparts(which('fsi_ana.m')),'data');

% Display verbose analysis progress to user?
verbose = 1;

% Degine region names:
roiNames = {'4a','4p','3a','3b','1','2'};

%% analysis cases
switch what
    %% plotting cases:
    case 'plot:selectivity'
        %% plot results for the single-finger selectivity analysis

        % check for datastructure
        try % check if user is supplying data for plotting
            D = varargin{1}; % plotting data
        catch % user did not provide data, so load the file
            D = load(fullfile(dataDir,'fmri_selectivity.mat'));
        end

        % define plotting styles
        sty1 = style.custom({'lightgray'}); % subject data
        sty2 = style.custom({'black'}); % group averaged data
        sty3 = style.custom({'black'});
        sty1.general.markertype = 'none';
        sty3.general.markertype = 'none';
        sty3.general.linestyle = ':';
        sty3.general.linewidth = 2;

        % plot in current axis
        plt.line(D.roi,D.sel_beta,'split',D.sn,'style',sty1,'errorfcn',''); % subject lines
        hold on
        plt.line(D.roi,D.sel_beta,'style',sty2); % group averaged data
        plt.line(D.roi,D.sel_random,'style',sty3,'errorfcn',''); % mean expected value for random tuning
        plt.line(D.roi,D.sel_selective,'style',sty3,'errorfcn',''); % mean expected value for selective tuing
        set(gca,'xticklabel',roiNames);
        xlabel('Brodmann area')
        ylabel('selectivity index');
        ylim([0.55 0.8]);
        hold off
        legend off
        
        % return data structure
        varargout = {D};
    case 'plot:modelFits'
        %% plot results for representational model analysis - regions
        
        % check for datastructure
        try % check if user is supplying data for plotting
            D = varargin{1}; % plotting data
        catch % user did not provide data, so load the file
            D = load(fullfile(dataDir,'fmri_modelFits.mat'));
        end

        % find the null and noise ceiling models:
        numModels  = numel(unique(D.model));
        modelNull  = unique(D.model(strcmp(D.modelName,'null')));
        modelNCeil = unique(D.model(strcmp(D.modelName,'noise_ceiling')));

        % normalize the model fits (pearson's R) (0=null, 1=lower noise ceiling fit)
        D.r_norm = D.r_test - kron(D.r_test(D.model==modelNull),ones(numModels,1));
        D.r_norm = D.r_norm ./ kron(D.r_norm(D.model==modelNCeil),ones(numModels,1));

        % define plotting style
        modelClrs={[0.12,0.3,0.58],...  % linear model
                   [0.8,0.15,0],...     % 2finger
                   [0.88,0.51,0.36],... % 3finger
                   [0.96,0.80,0.32],... % 4finger
                   [0.12,0.3, 0.58],... % linear-nonlinear
                   [0 0 0],...          % 2finger_distantPairs
                   [0 0 0]};            % 2finger_adjacentPairs
        sty = style.custom(modelClrs); 
        sty.general.linestyle = {'-','-','-','-','-.','-','-'};
        sty.general.markerfill = [{modelClrs{1:6}},{[1 1 1]}];


        % plot normalized model fits
        dataToPlot = ~ismember(D.model,[modelNull,modelNCeil]); % don't plot the normalized null (0) or noise ceiling (1) fits
        plt.line(D.roi,D.r_norm,'split',D.model,'plotfcn','mean','style',sty,'subset',dataToPlot);
        ylabel(sprintf('normalized model fits\n(Pearson''s R)'));
        xlabel('Brodmann area');
        ylim([0 1]);
        set(gca,'xticklabel',roiNames);
                
        varargout = {D};
    %% behavioural analysis:
    case 'beha:do_analysis'
        %% do behavioural analysis (performance rates, discriminability, & bias)

        % load behavioural data for all participants
        Dall = load(fullfile(dataDir,'beha_all.mat'));
        
        % count how many kinds of behavioural response types each participant made
        Dall.numTrials = ones(size(Dall.sn));
        D=tapply(Dall,{'sn','mismatch'},...
            {'resp_CR','sum'},{'resp_FA','sum'},...
            {'resp_hit','sum'},{'resp_miss','sum'},{'numTrials','sum'});
        
        % convert counts to rates rates per trial type (match or mismatch) per participant:
        D.prop_FA = D.resp_FA./D.numTrials;
        D.prop_CR = D.resp_CR./D.numTrials;
        D.prop_hit = D.resp_hit./D.numTrials;
        D.prop_miss = D.resp_miss./D.numTrials;

        % pull out the rates according to trial types
        % mismatch==0 are not mismatch trials (i.e., did not contain signal)
        % mismatch==1 are mismatch trials (i.e., contained signal)
        mismatchIdx = D.mismatch==1;
        S.prop_falseAlarm       = D.prop_FA(~mismatchIdx);
        S.prop_correctRejection = D.prop_CR(~mismatchIdx);
        S.prop_hit              = D.prop_hit(mismatchIdx);
        S.prop_miss             = D.prop_miss(mismatchIdx);
        S.prop_error            = (D.resp_miss(mismatchIdx) + D.resp_FA(~mismatchIdx)) ./ (D.numTrials(~mismatchIdx) + D.numTrials(mismatchIdx));
        S.prop_thumbPress       = (D.resp_FA(~mismatchIdx) + D.resp_hit(mismatchIdx)) ./ (D.numTrials(~mismatchIdx) + D.numTrials(mismatchIdx));
        % prop_falseAlarm - false alarm responses rate (of non-mismatch trials)
        % prop_correctRejection - correct rejection rate (of non-mismatch trials)
        % prop_hit - hit rate (of mismatch trials)
        % prop_miss - miss rate (of mismatch trials)
        % prop_error - overall error rate
        % prop_thumbPress - % of all trials (per participant) in which a thumb press response occurred

        % calculate discriminability (d-prime) & bias (c)
        % first, adjust hit rates and false alarm rates using log-linear rule in Hautus (1995)
        S.prop_hit_adj = (D.resp_hit(mismatchIdx) + 0.5) ./ (D.numTrials(mismatchIdx) + 1);
        S.prop_FA_adj  = (D.resp_FA(~mismatchIdx) + 0.5) ./ (D.numTrials(~mismatchIdx) + 1);
        zhr  = norminv(S.prop_hit_adj);
        zfar = norminv(S.prop_FA_adj);
        S.dprime_adj = zhr - zfar; % d-prime
        S.bias_c_adj = -(zhr + zfar)/2; % bias

        % add participant numbers to output structure
        S.sn = D.sn(mismatchIdx);

        % display behavioural performance to user
        fprintf('\nmean FALSE ALARM:       %1.2f \x00B1 %1.2f%% (of not mismatch trials) \n',mean(S.prop_falseAlarm)*100,stderr(S.prop_falseAlarm)*100);
        fprintf('mean CORRECT REJECTION: %1.2f \x00B1 %1.2f%% (of not mismatch trials) \n',mean(S.prop_correctRejection)*100,stderr(S.prop_correctRejection)*100);
        fprintf('mean HIT RATE:          %1.2f \x00B1 %1.2f%% (of     mismatch trials) \n',mean(S.prop_hit)*100,stderr(S.prop_hit)*100);
        fprintf('mean MISS RATE:         %1.2f \x00B1 %1.2f%% (of     mismatch trials) \n',mean(S.prop_miss)*100,stderr(S.prop_miss)*100);
        fprintf('\nmean ERROR rate (FA & misses): %1.2f \x00B1 %1.2f%% [of total trials]\n',mean(S.prop_error)*100,stderr(S.prop_error)*100);
        fprintf('mean THUMB PRESS rate: %1.2f \x00B1 %1.2f%% [of total trials]\n',mean(S.prop_thumbPress)*100,stderr(S.prop_thumbPress)*100);
        fprintf('\nmean d prime:          %1.2f \x00B1 %1.2f \n',mean(S.dprime_adj),stderr(S.dprime_adj));
        fprintf('mean bias (c):         %1.2f \x00B1 %1.2f \n',mean(S.bias_c_adj),stderr(S.bias_c_adj));

        % return data structures
        varargout = {S,D,Dall};
    %% single-finger selectivity analysis
    case 'selectivity:do_analysis'
        %% do single-finger selectivity analysis for all regions and participants
        
        % set analysis parameters
        rng(99); % specify seed for reproducability
        numSim = 1000; % # simulated datasets per model per participant (random and selective tuning models)
        conds  = 1:5;  % conditions to analyze (single finger conditions)
        numConds = numel(conds);
        fthres = 0.95; % % cutoff value for f-crit (take top 5% of voxels)

        T = [];
        for ii=1:6 % for each region...

            % load single-finger frmri activity patterns (univariately prewhitened)
            [Y,partVec,condVec,sn] = fsi_ana('misc:load_fmriPatterns',...
                                        'roi',ii,'betaType','univariate_whitened',...
                                        'conditions',conds);
            
            % unpack the patterns (each cell is one participant)
            for jj=1:numel(Y)
                t.beta = {Y{jj}};
                t.run  = {partVec{jj}};
                t.cond = {condVec{jj}};
                t.sn   = sn{jj};
                t.roi  = ii;
                T = addstruct(T,t);
            end
        end

        if verbose
            fprintf('\nsubj\troi\t%% sig voxels\tsvar\tevar\tselectivity');
            fprintf('\n----\t---\t-------------\t----\t----\t-----------\n');
        end

        % do single-finger selectivity analysis
        D = []; % output structure for selectivity values
        for ii = 1:numel(T.sn)
            % loop through each row (one region from one participant)
            t = getrow(T,ii);
            sn = t.sn;
            roi = t.roi;
            t = rmfield(t,{'sn','roi'});
            t.beta = t.beta{1};
            t.run  = t.run{1};
            t.cond = t.cond{1};

            % do voxel selection based on siginficant F-test
            [F,Fcrit]  = fsi_ana('selectivity:ftest',t.beta,t.cond,t.run,fthres);
            numVoxOrig = size(t.beta,2); % how many voxels from this region?
            numVoxSig  = sum(F>=Fcrit); % how many voxels are selected?
            t.beta     = t.beta(:,F>=Fcrit); % drop non-selected voxels

           
            % some simulation params for later
            numVoxSim = ceil(numVoxSig/numConds)*numConds; % small rounding so equal # of voxels per condition (for sparse patterns)
            numRun    = numel(unique(t.run));

            % zero-centre the voxel tuning curves in each run
            C0 = indicatorMatrix('identity',t.run);
            t.beta = t.beta -C0*pinv(C0)*t.beta;

            % calculate signal and noise strengths
            [var_noise,var_sig] = fsi_ana('selectivity:estVariances',t.beta,t.cond,t.run);
            if var_sig<0; var_sig = 0; end % negative signal is zero signal (not a common occurance)
            
            % calc avg. selectivity of voxels
            t = tapply(t,{'cond'},{'beta','mean'}); % avg. voxel tuning curves across runs
            sel_beta_voxel = fsi_ana('selectivity:estSelectivity',t.beta);
            sel_beta = mean(sel_beta_voxel);
            
            % calc expected selectivity under random tuning (with iid noise)
            sel_random = fsi_ana('selectivity:expectedValue_random',var_noise,var_sig,numVoxSim,numRun,numSim,fthres);
            sel_random = nanmean(sel_random);

            % calc expected selectivity under perfectly selective tuning (with iid noise) 
            sel_selective = fsi_ana('selectivity:expectedValue_selective',var_noise,var_sig,numConds,numVoxSim,numRun,numSim,fthres);
            sel_selective = nanmean(sel_selective);

            % normalize selectivity of the voxels by the expected values under
            % random (0) and selective (1) tuning (from simulations)
            sel_norm = (sel_beta - sel_random) / (sel_selective - sel_random);

            % add indexing fields to output structure
            d.sn        = sn;
            d.roi       = roi;
            d.roiName   = {['BA',roiNames{roi}]};
            
            % add voxel information to output structure
            d.fthres    = fthres;
            d.fcrit     = Fcrit;
            d.numVoxSig = numVoxSig;
            d.numVoxTot = numVoxOrig;
            d.propVox   = numVoxSig / numVoxOrig;
            d.var_signal = var_sig;
            d.var_noise  = var_noise;
            
            % add selectivity estimates to output structure
            d.sel_beta       = sel_beta;
            d.sel_random     = sel_random;
            d.sel_selective  = sel_selective;
            d.sel_normalized = sel_norm;

            D = addstruct(D,d);

            if verbose
                fprintf('s%02d\t%s\t%2.2f\t\t%2.4f\t%2.4f\t%1.5f\n',d.sn,roiNames{d.roi},d.propVox*100,var_sig,var_noise,sel_beta);
            end

        end

        % return output
        varargout = {D};
    %% cases to support single-finger selectivity analysis
    case 'selectivity:ftest'
        %% voxel f-tests

        % calculates F-statistic per voxel to determine if voxel is
        % significantly modulated by finger(s)

        % input handling
        Y  = varargin{1}; % N x P matrix of data. (N=numCond*numRun, P=numVox)
        cV = varargin{2}; % N x 1 vector of condition assignments
        pV = varargin{3}; % N x 1 vector of run assignments
        fthres = varargin{4}; % percent cutoff for F-stat (range 0-1)

        % housekeeping
        numVox   = size(Y,2);
        conds    = unique(cV)';
        numCond  = numel(conds);
        runs     = unique(pV)';
        numRun   = numel(runs);

        df1 = numCond-1;
        df2 = numCond*numRun - numCond - numRun;
        
        % compute mean and covariance matrices
        muK = zeros(numCond,numVox); % condition means
        SSR = zeros(1,numVox);       % ssr vector (common across conditions)
        n   = zeros(1,numCond);      % # observations per condition
        for ii=1:numCond
            c         = conds(ii);
            idx       = find(cV==c);
            n(ii)     = numel(idx);
            muK(ii,:) = sum(Y(idx,:),1) ./ n(ii); % condition means
            res = bsxfun(@minus,Y(idx,:),muK(ii,:)); % residuals from the grand mean across all observations of this condition
            SSR = SSR + sum(res.^2,1) ./ n(ii); % SSR (across observations) scaled by number of observations (in case # obs differ per condition)
        end
        SSB = sum(muK.^2,1); 

        % calc f-stats
        F   = (SSB./df1) ./ (SSR./df2);
        Fcrit = finv(fthres,df1,df2); % 95% cutoff for F-stat

        varargout = {F,Fcrit};
    case 'selectivity:estVariances'
        %% do variance estimation of signal and noise

        % empirically estimates error variance in activity patterns across
        % runs. 
        % Estimate is accurate when run means have been removed.

        % % NOTE: we integrate across conditions & voxels

        Y  = varargin{1};    % patterns   [regressors x voxels]
        cV = varargin{2};    % conditions [regressors x 1]
        pV = varargin{3};    % partitions [regressors x 1]

        nV = size(Y,2);         % # voxels
        nP = numel(unique(pV));  % # partitions
        nC = numel(unique(cV));  % # conditions
        Ya = zeros(nP,nV*nC);   % pre-allocate

        for pp = 1:nP
            y = Y(pV==pp,:);     % vectorize patterns across conditions per run
            Ya(pp,:) = y(:)';
        end

        take = logical(tril(ones(nP),-1)); % lower-triangular index
        G    = cov(Ya');  % covariances between runs (each row = one run, has zero mean)
        R    = corr(Ya'); % correlations between runs

        sig_var   = sum(G(take)) / sum(sum(take)); % signal variance (avg. across runs)
        r         = sum(R(take)) / sum(sum(take)); % signal correlation (avg. across runs)
        noise_var = sig_var / r - sig_var;             % error variance (avg. across runs)

        varargout = {noise_var,sig_var};
    case 'selectivity:estSelectivity'
        %% do voxel selectivity estimation

        % calculate single finger tuning using normalzied distance approach
        Y         = varargin{1}; % CxN matrix of data. (conds x voxels)
        numC      = size(Y,1);
        maxY      = max(Y,[],1);
        avgDistsN = (sum(maxY-Y)./(numC-1)) ./ (maxY-min(Y,[],1));
        varargout = {avgDistsN};
    case 'selectivity:expectedValue_random'
        %% calculate expected selectivty for voxels with random tuning

        % input handling
        var_noise = varargin{1}; % signal strength
        var_sig   = varargin{2}; % noise strength
        numVox    = varargin{3}; % number of voxels
        numRun    = varargin{4}; % number of runs
        numSim    = varargin{5}; % number of simulations
        fthres    = varargin{6}; % f-threshold for simulated voxel selection
        
        % group-average finger-by-finger correlation matrix from Ejaz et al., 2015:
        G = rsa_squareIPM([1,0.797,0.789,0.785,0.771,1,0.929,0.877,0.837,1,0.939,0.883,1,0.952,1]);

        % generate simulated voxel data under random tuning
        D = fsi_ana('selectivity:simulateRandom',G,numVox,numRun,numSim,var_sig,var_noise);
        
        % calc expected selectivity for each simulated dataset
        sel_random = nan(1,numSim); % pre-allocate
        for s = 1:numSim
            d  = getrow(D,D.simNum==s);
            % voxel selection
            [F,Fcrit] = fsi_ana('selectivity:ftest',d.Y,d.cond,d.run,fthres);
            sigIdx = F>=Fcrit;
            % mean-centre each voxel across runs
            C0  = indicatorMatrix('identity',d.run); 
            d.Y = d.Y -C0*pinv(C0)*d.Y; % remove run means
            % calc selectivity
            Cd = indicatorMatrix('identity',d.cond);
            Ysig = pinv(Cd)*d.Y(:,sigIdx); % avg. simulated tuning curves across runs for selected voxels
            sel_tmp = fsi_ana('selectivity:estSelectivity',Ysig);
            sel_random(s) = mean(sel_tmp); % mean selectivity for this simulated dataset
        end
        varargout = {sel_random};
    case 'selectivity:expectedValue_selective'
        %% calculate expected selectivty for voxels with selective tuning
        % calculates expected value (avg. sft across voxels) for voxels
        % with perfectly selective tuning plus some iid noise

        % input handling
        var_noise = varargin{1}; % signal strength
        var_sig   = varargin{2}; % noise strength
        numCond   = varargin{3}; % number of conditions
        numVox    = varargin{4}; % number of voxels
        numRun    = varargin{5}; % number of runs
        numSim    = varargin{6}; % number of simulations
        fthres    = varargin{7}; % f-threshold for simulated voxel selection
        

        % generate data
        D = fsi_ana('selectivity:simulateSelective',numCond,numVox,numRun,numSim,var_sig,var_noise); % selective tuning patterns with noise
        % calc expected tuning on simulated datasets
        sel_selective = nan(1,numSim);
        for s = 1:numSim
            d      = getrow(D,D.simNum==s);
            % voxel selection
            [F,Fcrit] = fsi_ana('selectivity:ftest',d.Y,d.cond,d.run,fthres);
            sigIdx = F>=Fcrit;
            % mean-centre each voxel across runs
            C0     = indicatorMatrix('identity',d.run); 
            d.Y    = d.Y -C0*pinv(C0)*d.Y; % remove run means
            % calc selectivity
            Cd = indicatorMatrix('identity',d.cond);
            Ysig = pinv(Cd)*d.Y(:,sigIdx); % avg. simulated tuning curves across runs for selected voxels
            sel_tmp = fsi_ana('selectivity:estSelectivity',Ysig);
            sel_selective(s)  = mean(sel_tmp); % mean selectivity for this simulated dataset
        end
        varargout = {sel_selective};
    case 'selectivity:simulateRandom'
        %% simulate voxel data with randomly tuning
        % true betas drawn from random distribution, with added i.i.d. noise
        G       = varargin{1}; % second moment of simulated data
        numVox  = varargin{2};
        numRun  = varargin{3};
        numSubj = varargin{4};
        signal  = varargin{5};
        noise   = varargin{6};

        noiseDist  = @(x) norminv(x,0,1);  % Standard normal inverse for Noise generation 
        signalDist = @(x) norminv(x,0,1);  % Standard normal inverse for Signal generation

        numCond = size(G,1);
        % need to scale all elements of G by mean of the diagonal elements
        % (variances) to ensure appropriate signal scaling:
        G = G./ (sum(diag(G)) / (numCond-1));

        D = []; % output structure
        for s = 1:numSubj
            pSignal    = unifrnd(0,1,numCond,numVox); 
            pNoise     = unifrnd(0,1,numCond*numRun,numVox); 
            % Generate true sparse patterns
            U = signalDist(pSignal); 
            E = (U*U'); 
            Z = E^(-0.5)*U;   % Make random orthonormal vectors
            A = pcm_diagonalize(G); 
            if (size(A,2)>numVox)
                error('not enough voxels to represent G'); 
            end
            trueU = A*Z(1:size(A,2),:)*sqrt(numVox); 
            trueU = bsxfun(@times,trueU,sqrt(signal));   % Multiply by signal scaling factor

            X = kron(ones(numRun,1),eye(numCond)); % design matrix

            % Now add the random noise 
            Noise  = noiseDist(pNoise); 
            Noise  = bsxfun(@times,Noise,sqrt(noise)); % Multiply by noise scaling factor
            d.Y    = X*trueU + Noise; % pull through condition specific patterns and add i.i.d. noise
            % indexing fields
            d.run   = kron([1:numRun],ones(1,numCond))';
            d.cond  = kron(ones(1,numRun),[1:numCond])';
            d.simNum= ones(size(d.run)).*s;
            D = addstruct(D,d);
        end
        varargout = {D};
    case 'selectivity:simulateSelective'
        %% simulate voxel data with selectivve tuning
        % true patterns are sparse (0's and 1's), with iid noise
        numCond = varargin{1};% sparsity level (1=totally sparse, 2-two conditions tuned, etc.)
        numVox  = varargin{2};
        numRun  = varargin{3};
        numSubj = varargin{4};
        signal  = varargin{5}; % signal variance
        noise   = varargin{6}; % noise variance
        
        % get # conditions based on sparsity level
        numVoxPerCond = ceil(numVox/numCond); % voxels tuned per chord
        numVox = numVoxPerCond*numCond;
        signal = signal*(numCond/1); % rescale the signal by # conditions (each condition contributes independent amount to signal)

        % define signal generation
        noiseDist  = @(x) norminv(x,0,1);  % Standard normal inverse for Noise generation 
        D = []; % output structure
        for s = 1:numSubj % per simulated dataset
            % draw uniform values for signal and noise (to be inverted
            % through any arbitrary function later)
            pNoise = unifrnd(0,1,numCond*numRun,numVox); 
            % Generate true sparse patterns
            U = kron(eye(numCond),ones(1,numVoxPerCond)); % true patterns are 1s for voxels tuned to fingers, 0s for non-tuned
            % scale patterns to match specified signal strength
            U = bsxfun(@times,U,sqrt(signal));
            X = kron(ones(numRun,1),eye(numCond)); % design matrix
            trueU = X*U;
            % Now add the random noise 
            Noise  = noiseDist(pNoise); 
            Noise  = bsxfun(@times,Noise,sqrt(noise)); % sacle noise
            d.Y    = trueU + Noise;
            % indexing fields
            d.run   = kron([1:numRun],ones(1,numCond))';
            d.cond  = kron(ones(1,numRun),[1:numCond])';
            d.simNum= ones(size(d.run)).*s;
            D = addstruct(D,d);
        end
        varargout = {D};
    %% representational model analysis:
    case 'model:do_analysis'
        %% do representational model analysis on region data

        % fit representational encoding models to data from BA regions
        roi = 1:6; % do all regions
        D = []; % output structure
        for rr=roi
            if verbose
                fprintf('REGION: BA %s \n',roiNames{rr});
            end
            % load subject data from region
            [Y,pV,cV,subjNum] = fsi_ana('misc:load_fmriPatterns','roi',rr,'betaType','multivariate_whitened','conditions',1:31);
            Gm        = fsi_ana('misc:load_fmriRegionG','roi',rr); % group-averaged region G (for ridge regression)
            d         = fsi_ana('model:fit_wrapper',Y,pV,cV,Gm,subjNum);
            % add roi indexing fields to datastructure:
            v  = ones(size(d.sn));
            d.roi = v.*rr;
            d.roiName = repmat({['BA',roiNames{rr}]},numel(v),1);
            D=addstruct(D,d);
        end
        
        % return model fits
        varargout = {D};
    %% cases to support representational model analysis
    case 'model:fit_wrapper'
        %% fit representational models to participant data

        % case to fit models to participant data
        Y      = varargin{1}; % cell array of activity patterns
        pV     = varargin{2}; % cell array of partition assignment (for each row of Y)
        cV     = varargin{3}; % cell array of condition assignment (for each row of Y)
        modelG = varargin{4}; % [31x31] model G (apply same G for all subjs)
        subjNum= varargin{5}; % participant number
        % define which models we are fitting:
        models = {'null','1finger','2finger','3finger','4finger','1finger_nonlinear',...
             '2finger_distantPairs','2finger_adjacentPairs','noise_ceiling'};
        
        numModels = numel(models);
        
        % get chord matrix (for faster calc of mean activity per # of fingers stimulated)
        chords   = fsi_ana('misc:chords');
        numD_inv = pinv(indicatorMatrix('identity',sum(chords,2)));
        
        % loop through participants and fit each individually:
        D=[]; % output
        for s=1:numel(Y)
            
            % split data into all possible leave-one-run-out partitions (for crossvalidation)
            % assign runs to each partition
            part = unique(pV{s});
            numPart = numel(part);
            partI = {};
            for ip=1:numPart
                partI{ip}=part(ip);
            end

            % pre-allocate space for predicted patterns
            numVox = size(Y{s},2);
            G_pred = zeros(31,31,numModels);
            Y_avg  = nan([numModels,5,numPart]); % avg. activity per # digits
            modelTheta = {};

            % pre-allocate space for model fit evaluations
            SS1 = nan(numPart,numModels);
            SS2 = SS1; SSC = SS1;
            SS1_train = SS1; SS2_train = SS1; SSC_train = SS1; 

            % loop through partitions and estimate patterns
            for ii=1:numel(partI)

                % estimate the true training condition activity patterns:
                trainIdx = ~ismember(pV{s},partI{ii}); 
                testIdx  = ismember(pV{s},partI{ii}); 
                Ytest    = Y{s}(testIdx,:);
                [Utrain,lambda0, thetaReg0] = fsi_ana('model:estFeaturePatterns',Y{s}(trainIdx,:),pV{s}(trainIdx),cV{s}(trainIdx),modelG,'condition');
                            
                % predict patterns under each model:
                for mm=1:numModels
                    modelName = models{mm};
                    if verbose
                        fprintf('Participant: s%02d  |  CVFold: %d  |  Model: %s\n',subjNum{s},ii,modelName); 
                    end
                    switch modelName
                        case 'null' % model 1
                            % model scaling of mean activity, independent
                            % of finger(s) stimulated
                            Ypred = fsi_ana('model:predictPatterns',Utrain,'null',[]);
                            thetaReg = thetaReg0;
                            lambdaReg = lambda0;
                            thetaEst = nan(1,4);  
                        case '1finger' % model 2 ("linear model")
                            [U,lambdaReg,thetaReg] = fsi_ana('model:estFeaturePatterns',Y{s}(trainIdx,:),pV{s}(trainIdx),cV{s}(trainIdx),modelG,'1finger');
                            Ypred = fsi_ana('model:predictPatterns',U,'1finger',[]);
                            thetaEst = nan(1,4);
                        case '2finger' % model 3
                            [U,lambdaReg,thetaReg] = fsi_ana('model:estFeaturePatterns',Y{s}(trainIdx,:),pV{s}(trainIdx),cV{s}(trainIdx),modelG,'2finger');
                            Ypred = fsi_ana('model:predictPatterns',U,'2finger',[]);
                            thetaEst = nan(1,4);
                        case '3finger' % model 4
                            [U,lambdaReg,thetaReg] = fsi_ana('model:estFeaturePatterns',Y{s}(trainIdx,:),pV{s}(trainIdx),cV{s}(trainIdx),modelG,'3finger');
                            Ypred = fsi_ana('model:predictPatterns',U,'3finger',[]);
                            thetaEst = nan(1,4);
                        case '4finger' % model 5
                            [U,lambdaReg,thetaReg] = fsi_ana('model:estFeaturePatterns',Y{s}(trainIdx,:),pV{s}(trainIdx),cV{s}(trainIdx),modelG,'4finger');
                            Ypred = fsi_ana('model:predictPatterns',U,'4finger',[]);
                            thetaEst = nan(1,4);
                        case '1finger_nonlinear' % model 6 ("linear-nonlinear model")
                            [U,lambdaReg,thetaReg] = fsi_ana('model:estFeaturePatterns',Y{s}(trainIdx,:),pV{s}(trainIdx),cV{s}(trainIdx),modelG,'1finger');
                            theta0 = [log(0.9) log(0.8) log(0.7) log(0.6)];
                            thetaFcn = @(x) modelLossRSS(x,U,Utrain,'1finger_nonlinear'); % minimize pattern RSS in parameter fitting
                            [thetaEst,feval,ef,fitInfo]= fminsearch(thetaFcn, theta0, optimset('MaxIter',50000));                        
                            Ypred = fsi_ana('model:predictPatterns',U,'1finger_nonlinear',thetaEst);
                        case '2finger_distantPairs' % model 7
                            [U,lambdaReg,thetaReg] = fsi_ana('model:estFeaturePatterns',Y{s}(trainIdx,:),pV{s}(trainIdx),cV{s}(trainIdx),modelG,'2finger_distantPairs');
                            Ypred = fsi_ana('model:predictPatterns',U,'2finger_distantPairs',[]);
                            thetaEst = nan(1,4);
                        case '2finger_adjacentPairs' % model 8
                            [U,lambdaReg,thetaReg] = fsi_ana('model:estFeaturePatterns',Y{s}(trainIdx,:),pV{s}(trainIdx),cV{s}(trainIdx),modelG,'2finger_adjacentPairs');
                            Ypred = fsi_ana('model:predictPatterns',U,'2finger_adjacentPairs',[]);
                            thetaEst = nan(1,4);   
                        case 'noise_ceiling' % model 9
                            Ypred     = Utrain; % use the true patterns (estimated from training data)
                            thetaReg  = thetaReg0;
                            lambdaReg = lambda0;
                            thetaEst  = nan(1,4);      
                        otherwise
                            error('no model named: %s',modelName)
                    end
                    modNames{mm,1} = modelName;
                    modelTheta{mm}(ii,:) = thetaEst;
                    regTheta{mm}(ii,:)   = thetaReg;
                    regLambda(mm,ii)     = lambdaReg;
                    % calculate model predicted avg. activity
                    Y_avg_cent(mm,:,ii)  = mean(numD_inv*(Ypred-mean(Ypred,1)),2)'; % avg. activity per # digits, mean-centred
                    Y_avg(mm,:,ii)       = mean(numD_inv*Ypred,2)'; % avg. activity per # digits
                    % calculate metrics for R of prediction against TRAINING data:
                    [SS1_train(ii,mm),SS2_train(ii,mm),SSC_train(ii,mm)] = fsi_ana('model:evaluateFit',Ypred,Utrain); % corr b/t pred and TRAINing patterns
                    % calculate metrics for R of prediction against TEST data:
                    [SS1(ii,mm), SS2(ii,mm), SSC(ii,mm)] = fsi_ana('model:evaluateFit',Ypred,Ytest); % corr b/t pred and TEST patterns
                end
            end

            % compile into output structure D:
            d = [];
            % for each model, avg. thetas across folds & save to ouptut struct:
            d.modelName  = modNames;
            d.modelTheta = cell2mat(cellfun(@(x) mean(x,1),modelTheta,'uni',0)');
            d.regTheta   = cellfun(@(x) mean(x,1),regTheta,'uni',0)';
            d.regLambda  = nanmean(regLambda,2);
            % Pearson's R:
            d.r_train = [mean(SSC_train ./ sqrt(SS1_train.*SS2_train))]'; % each row is one cv-fold, each column is a model
            d.r_test  = [mean(SSC ./ sqrt(SS1.*SS2))]';
            % arrange data into output structure:
            d.avgAct      = mean(Y_avg,3); % avg. activity per # digits
            d.avgAct_cent = mean(Y_avg_cent,3); % avg. activity per # digits
            d.model   = [1:numModels]';
            d.sn      = ones(numModels,1).*subjNum{s};
            
            D=addstruct(D,d);
        end
        
        % return model fits
        varargout = {D};
    case 'model:estFeaturePatterns'
        %% regularized regression estimate of feature patterns

        % Regularized regression estimate of feature patterns for representational model analysis
        % Use pcm with fixed model G to estimate signal and noise parameters

        % inputs
        Y    = varargin{1}; % matrix of activity patterns [#conds*#runs x #vox]
        pV   = varargin{2}; % partition vector (assume cV and pV are same across subjs)
        cV   = varargin{3}; % condition vector (chord #s)
        G    = varargin{4}; % feature prior (group-averaged second moment matrix from region under analysis)
        type = varargin{5}; % which features are we estimating?
        
        % create feature matrix and estimate model prior G according to 'type':
        switch type
            case 'condition' % i.e. full model (noise ceiling)
                Z  = pcm_indicatorMatrix('identity',cV); % feature design matrix for activity patterns
                Gprior = G;
            case '1finger'
                % create single finger feature matrix (linear & linear-nonlinear models)
                Z0 = fsi_ana('design:1finger'); % design matrix
                Gprior = pinv(Z0)*G*pinv(Z0)';
                Z  = kron(ones(numel(unique(pV)),1),Z0); % feature design matrix for activity patterns
            case '2finger'
                % create 2finger feature matrix
                Z0 = fsi_ana('design:2finger'); % design matrix
                Gprior = pinv(Z0)*G*pinv(Z0)';
                Z = kron(ones(numel(unique(pV)),1),Z0); % feature design matrix for activity patterns  
            case '3finger'
                % create 3finger feature matrix
                Z0 = fsi_ana('design:3finger'); % design matrix
                Gprior = pinv(Z0)*G*pinv(Z0)';
                Z = kron(ones(numel(unique(pV)),1),Z0); % feature design matrix for activity patterns
            case '4finger'
                % create 4finger feature matrix
                Z0 = fsi_ana('design:4finger'); % design matrix
                Gprior = pinv(Z0)*G*pinv(Z0)';
                Z = kron(ones(numel(unique(pV)),1),Z0); % feature design matrix for activity patterns
            case '2finger_distantPairs'
                % create finger feature matrix
                Z0 = fsi_ana('design:2finger_distantPairs'); % design matrix
                Gprior = pinv(Z0)*G*pinv(Z0)';
                Z = kron(ones(numel(unique(pV)),1),Z0); % feature design matrix for activity patterns
            case '2finger_adjacentPairs'
                % create finger feature matrix
                Z0 = fsi_ana('design:2finger_adjacentPairs'); % design matrix
                Gprior = pinv(Z0)*G*pinv(Z0)';
                Z = kron(ones(numel(unique(pV)),1),Z0); % feature design matrix for activity patterns
            otherwise
                error('no feature model of this type')
        end
        
        M{1}.type = 'component';
        M{1}.Gc = Gprior;
        M{1}.numGparams = 1;
        % fit model G to get noise and signal params:
        [~,theta_hat] = pcm_fitModelIndivid({Y},M,pV,Z,'runEffect','none','verbose',0,'fitScale',0);
        % reconstruct true patterns using regularized regression:
        U = pcm_estimateU(M{1},theta_hat{1},Y,Z,[]);

        lambda = exp(theta_hat{1}(2))/exp(theta_hat{1}(1)); %lambda is noise/scale
        
        varargout = {U,lambda,theta_hat{1}};  
    case 'model:predictPatterns'
        %% predict patterns under specified model
        % factorization of encoding models:
        U     = varargin{1}; % feature patterns
        model = varargin{2};
        theta = varargin{3}; % model params (only needed for linear-nonlinear model)
        
        % get design matrix for specified model 
        switch model
            case 'null'
                % Model predicts overall scaling of avg. activity with #
                % fingers. Scaling matches true mean scaling in training
                % data.
                % Ysf here are all 31 conditions from the training data
                % Set each condition pattern to the be mean pattern for all
                % chords with the same number of fingers.
                chords = fsi_ana('misc:chords'); 
                X0 = pcm_indicatorMatrix('identity',sum(chords,2)); % which patterns have the same # of fingers?
                X = X0*pinv(X0);
            case '1finger'
                X = fsi_ana('design:1finger'); % design matrix
            case '1finger_nonlinear'
                % theta(1:4) = finger combination param (per # fingers in
                % chords for 2:5 digits)
                X = fsi_ana('design:1finger');
                numD = sum(X,2);
                X = X.*[ones(1,5) exp(theta(numD(numD>1)-1))]'; % flexible scaling per # fingers stimulated (force positive values with exp)
            case '2finger'
                % model that includes 2-finger interaction components
                X = fsi_ana('design:2finger');
            case '3finger'
                X = fsi_ana('design:3finger');
            case '4finger'
                X = fsi_ana('design:4finger');
            case '5finger'
                X = fsi_ana('design:5finger');
            case '2finger_distantPairs'
                X = fsi_ana('design:2finger_distantPairs');
            case '2finger_adjacentPairs'
                X = fsi_ana('design:2finger_adjacentPairs');            
        end

        % predict patterns under the model
        Y_hat = X*U;

        % return model predicted patterns
        varargout = {Y_hat};
    case 'model:evaluateFit'
        %% evaluate model fits

        % Ypred and Ytest are assumed to be the same size [31xP]
        % Ypred and Ytest are assumed to be the same condition arrangement
        Ypred = varargin{1}; % predicted patterns [31xP]. Assume that condition 1 is row 1, etc..
        Ytest = varargin{2}; % test patterns. Should be [31xP]- leave-one-out evaluation
        
        Ypred = Ypred-mean(Ypred,1); % remove voxel means
        Ytest = Ytest-mean(Ytest,1);
        
        % get metrics for correlation
        SS1 = sum(sum(Ytest.*Ytest)); % test SS
        SS2 = sum(sum(Ypred.*Ypred)); % pred SS
        SSC = sum(sum(Ypred.*Ytest)); % cov
        
        varargout = {SS1,SS2,SSC};     
    %% design matrices for representational models
    case 'design:1finger'
        %%
        % make design matrix X for the single finger models (1finger and flexible)
        X = fsi_ana('misc:chords');
        varargout = {X};
    case 'design:2finger'
        %%
        % make design matrix X for the finger-pair model
        % single finger terms and 2-finger pair interaction terms
        X1 = fsi_ana('misc:chords');
        X2 = fsi_ana('misc:chord_pairs');
        X  = [X1 X2];
        varargout = {X};        
    case 'design:3finger'
        %%
        % make design matrix X for the finger-pair model
        % single finger terms and 2-finger pair interaction terms
        X1 = fsi_ana('misc:chords');
        X2 = fsi_ana('misc:chord_pairs');
        X3 = fsi_ana('misc:chord_triplets');
        X  = [X1 X2 X3];
        varargout = {X};        
    case 'design:4finger'
        %%
        % make design matrix X for the finger-pair model
        % single finger terms and 2-finger pair interaction terms
        X1 = fsi_ana('misc:chords');
        X2 = fsi_ana('misc:chord_pairs');
        X3 = fsi_ana('misc:chord_triplets');
        X4 = fsi_ana('misc:chord_quads');
        X  = [X1 X2 X3 X4];
        varargout = {X};        
    case 'design:2finger_adjacentPairs'
        %%
        % design matrix for 2-finger interaction model
        % only includes 2-finger pairs that are adjacent!
        X1 = fsi_ana('misc:chords');
        X2 = fsi_ana('misc:chord_pairs_adjacentPairs');
        X  = [X1 X2];
        varargout = {X};
    case 'design:2finger_distantPairs'
        %%
        % design matrix for 2-finger interaction model
        % only includes 2-finger pairs that are non-adjacent!
        X1 = fsi_ana('misc:chords');
        X2 = fsi_ana('misc:chord_pairs_distantPairs');
        X  = [X1 X2];
        varargout = {X};
    %% miscellaneous (helper) cases
    case 'misc:load_fmriPatterns'
        %% load fmri activity patterns  

        % Get betas for roi from subjects in PCM-friendly format.
        % Run means are NOT removed as this is a feature we want to retain.
        betaType = []; % raw ('raw'), univariately prewhitened ('univariate_whitened'), or multivariately prewhitened ('multivariate_whitened')
        roi = []; % only one roi supported
        conditions = []; % which condition numbers? (1:5 are single-finger stimulations, 6:31 are multi-finger combinations);
        vararginoptions(varargin,{'roi','betaType','conditions'});
        if length(roi)>1
            error('only 1 roi supported per call to case');
        end

        % load betas
        B = load(fullfile(dataDir,sprintf('fmri_BA%s_betas.mat',roiNames{roi})));

        % arrange betas into PCM-friendly outputs
        Y = {};
        partVec = {};
        condVec = {};
        for ii = 1:numel(B.sn)
            % get subject data
            s = B.sn(ii);
            b = getrow(B,B.sn==s);
            tmp = [];
            tmp.run   = cell2mat(b.run);
            tmp.chord = cell2mat(b.digitCombo);
            % get the specified beta types ("raw", univariate, or
            % multivariately-prewhitened first-level GLM betas)
            switch betaType
                case 'raw'
                    tmp.betas = cell2mat(b.beta_raw);
                case 'univariate_whitened'
                    % do univariate whitening
                    tmp.betas = bsxfun(@rdivide,b.beta_raw{1},sqrt(b.beta_resMS{1}));
                case 'multivariate_whitened'
                    tmp.betas = cell2mat(b.beta_multiwhite);
            end
            tmp = getrow(tmp,ismember(tmp.chord,conditions)); % restrict to passive stimulation conditions
            % put subj data into pcm variables
            Y{ii}         = tmp.betas;
            partVec{ii}   = tmp.run;
            condVec{ii}   = tmp.chord;
            subjNum{ii}   = s;
        end

        % return variables
        varargout = {Y,partVec,condVec,subjNum}; 
    case 'misc:load_fmriRegionG'
        %% load fmri second moments for region
        % Get Region G (G is avg. semi-positive definite crossval G across
        % participants from roi). Participants 2:11 are included in
        % estimate
        roi = []; % only one roi supported
        vararginoptions(varargin,{'roi'});
        
        D = load(fullfile(dataDir,'fmri_regionG.mat'));
        D = getrow(D,D.roi==roi);
        G = rsa_squareIPM(D.g);
        varargout={G}; 
    case 'misc:chords'
        %% finger combination ("chord") indicator matrix
        % returns indicator matrix for chords used in exp.
        % Each column denotes one digit (col 1=thumb...col 5=little finger)
        chords = [eye(5);...                                                       % singles            5
             1 1 0 0 0; 1 0 1 0 0; 1 0 0 1 0; 1 0 0 0 1;...                        % doubles (thumb)    4
             0 1 1 0 0; 0 1 0 1 0; 0 1 0 0 1;...                                   % doubles            3
             0 0 1 1 0; 0 0 1 0 1;...                                              % doubles            2
             0 0 0 1 1;...                                                         % doubles            1
             1 1 1 0 0; 1 1 0 1 0; 1 1 0 0 1; 1 0 1 1 0; 1 0 1 0 1; 1 0 0 1 1;...  % triples (thumb)    6
             0 1 1 1 0; 0 1 1 0 1; 0 1 0 1 1; 0 0 1 1 1;...                        % triples            4
             1 1 1 1 0; 1 1 1 0 1; 1 1 0 1 1; 1 0 1 1 1; 0 1 1 1 1;                % quadruples         5
             1 1 1 1 1];                                                           % all five           1
                                                                                   % total-------------31
        chord_strings = {'1','2','3','4','5',...
            '12','13','14','15','23','24','25','34','35','45',...
            '123','124','125','134','135','145','234','235','245','345',...
            '1234','1235','1245','1345','2345','12345'}; 
        varargout = {chords,chord_strings}; 
    case 'misc:chord_pairs'
        %% fingerpair indicator matrix
        % returns indicator matrix for pairs of fingers use in each config:
        X=fsi_ana('misc:chords');
        numD = sum(X,2);
        X(X==0)=nan;
        pairs = X(numD==2,:); % 2 finger pairs
        Xp = zeros(31,10);
        for ii=1:size(pairs,1) % for each pair, find where in chords it is used
            pidx = sum(X==pairs(ii,:),2)==2;
            Xp(pidx,ii) = 1;
        end
        varargout = {Xp};
    case 'misc:chord_triplets'
        %% fingertriplet indicator matrix
        % returns indicator matrix for sets of 3 fingers use in each config:
        X=fsi_ana('misc:chords');
        numD = sum(X,2);
        X(X==0)=nan;
        pairs = X(numD==3,:); % 3 finger triplets
        Xp = zeros(31,10);
        for ii=1:size(pairs,1) % for each pair, find where in chords it is used
            pidx = sum(X==pairs(ii,:),2)==3;
            Xp(pidx,ii) = 1;
        end
        varargout = {Xp};
    case 'misc:chord_quads'
        %% fingerquadruplet indicator matrix
        % returns indicator matrix for set of 4 fingers use in each config:
        X=fsi_ana('misc:chords');
        numD = sum(X,2);
        X(X==0)=nan;
        pairs = X(numD==4,:);
        Xp = zeros(31,5);
        for ii=1:size(pairs,1) % for each pair, find where in chords it is used
            pidx = sum(X==pairs(ii,:),2)==4;
            Xp(pidx,ii) = 1;
        end
        varargout = {Xp};
    case 'misc:chord_pairs_distantPairs'
        %% fingerpair indicator matrix (spatially distant finger pairs)
        % chord pairs, kicking out immediate neighours
        X=fsi_ana('misc:chords');
        numD = sum(X,2);
        X(X==0)=nan;
        pairs = X(numD==2,:); % 2 finger pairs
        nIdx = sum(diff(pairs,1,2)==0,2); % which pairs are neighbours?
        pairs = pairs(~nIdx,:); % drop neighbour pairs
        Xp = zeros(31,size(pairs,1));
        for ii=1:size(pairs,1) % for each pair, find where in chords it is used
            pidx = sum(X==pairs(ii,:),2)==2;
            Xp(pidx,ii) = 1;
        end
        varargout = {Xp};
    case 'misc:chord_pairs_adjacentPairs'
        %% fingerpair indicator matrix (neighbouring finger pairs)
        % chord pairs, kicking out non-immediate neighour pairs
        X=fsi_ana('misc:chords');
        numD = sum(X,2);
        X(X==0)=nan;
        pairs = X(numD==2,:); % 2 finger pairs
        nIdx = sum(diff(pairs,1,2)==0,2); % which pairs are neighbours?
        pairs = pairs(nIdx==1,:); % drop non-neighbour pairs
        Xp = zeros(31,size(pairs,1));
        for ii=1:size(pairs,1) % for each pair, find where in chords it is used
            pidx = sum(X==pairs(ii,:),2)==2;
            Xp(pidx,ii) = 1;
        end
        varargout = {Xp};
    otherwise
        %%
        fprintf('case %s does not exist\n',what);
        varargout = {[]};
        return
end % 'what' switch case of fsi_ana
end % fsi_ana function

%% local functions
function rss = modelLossRSS(theta,U,Utrain,modelName)
    % cost function for estimating linear-nonlinear model parameters
    % cost is residual sums of squared errors
    Ypred  = fsi_ana('model:predictPatterns',U,modelName,theta); % predict patterns under perscribed model
    Ypred  = Ypred-mean(Ypred,1); % rmv voxel means
    Utrain = Utrain-mean(Utrain,1);
    rss    = sum(sum((Utrain-Ypred).^2)); % calculate L2 loss (RSS)
end
function IPM=rsa_squareIPM(IPM_vec)
% converts set of CMs (stacked along the 3rd dimension)
% to lower-triangular form (set of row vectors)
if isstruct(IPM_vec)
   N=length(IPM)
   [n,m]=size(IPM_vec(1).IPM);
    if (n~=1)
        error('IPM need to be row-vectors'); 
    end; 
    K = floor(sqrt(m*2));
    if (K*(K-1)/2+K~=m) 
        error('bad vector size'); 
    end; 
    indx=tril(true(K),0);
    IPM=IPM_vec;
    for i=1:nIPM
        A            = zeros(K);                      % make matrix 
        A(indx>0)    = IPM_vec(1,:,i);                % Assign the lower triag
        Atrans       = A';                % Now make symmetric           
        A(A==0)      = Atrans(A==0);    
        IPM(i).IPM   = A; 
    end
else
    % bare
    [n,m,nIPM]=size(IPM_vec);
    if (n~=1)
        error('IPM need to be row-vectors'); 
    end; 
    K = floor(sqrt(m*2));
    if (K*(K-1)/2+K~=m) 
        error('bad vector size'); 
    end; 
    indx=tril(true(K),0);
    IPM=[];
    for i=1:nIPM
        A            = zeros(K);                      % make matrix 
        A(indx>0)    = IPM_vec(1,:,i);                % Assign the lower triag
        Atrans       = A';                % Now make symmetric           
        A(A==0)      = Atrans(A==0);    
        IPM(:,:,i)   = A; 
    end
end
end
