% SETUP_REICHARDT_ARRAY_HYLES_GRATING_OSC - script to setup and run a
% Simulink model of the motion vision system of the hawkmoth Hyles lineata
%
% The Simulink model "reichardt_array_hyles_grating_osc.mdl" simulates the
% effect of head motions on the output of the motion vision system of the
% hawkmoth Hyles lineata. The model consists of a rotating circular 2D
% array of evenly spaced Reichardt detectors sampling a rotating sinusoidal
% grating.
%
% The first section of the script can be editted to change the different
% tests that will be run and what stimulus parameters will be tested.
%
% Outputs of the simulation are stored in the freqData, ampData and
% waveData data structures for the respective tests of oscillation
% frequency, oscillation amplitude and grating spatial frequency (which is
% equal to 1/wavelength of the sinusoidal grating)
%
% Calls: makeSineGrating.m
%        run_simulink_model_grating_osc.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set which experiments to run
testFreq        = true; % run oscillation frequency test

% Default stimulus parameters
ampDefault      = 5;  % [deg]
waveDefault     = 20; % [deg]
freqDefault     = 2;  % [Hz]

% Parameters for head motion
magHeadList     = [0.0 0.2 0.5 0.9]; % [gain]
phaseHeadList   = [0.0 0.0 0.0 0.0]; % [deg]

% Parameters for oscillation frequency test
freqList = logspace(-1,2,100); % [Hz]

% Parameters for oscillation amplitude test
ampList = logspace(-1,3,200); % [deg]

% Process parameters and create default stimulus grating
% Get parameter list size
nMagHead    = length(magHeadList);
nPhaseHead  = length(phaseHeadList);
nFreq       = length(freqList);
nAmp        = length(ampList);

% Create default simulus grating
imageData = makeSineGrating(waveDefault);

% Create first order high pass filter
HPcut           = 0.0075; % cut off frequency for 1 pole analogue high pass filter
[numHP,denHP]   = bilinear([1 0],[1 HPcut],1); % create digital version of filter

% High pass filter spatial data with repeats of grating at both ends to avoid end effects when filtering
len         = length(imageData);
temp        = repmat(imageData,1,3);
tempFilt    = filtfilt(numHP,denHP,temp);
imageData   = tempFilt(:,len+1:len*2);

% Test effect of oscillation frequency
if testFreq
    freqData = struct;
    disp('Testing frequency effects')
    for jj = 1:nPhaseHead
        disp(['Head phase = ' , num2str(phaseHeadList(jj))])
        disp(['Head mag = ' , num2str(magHeadList(jj))])
        
        % Store input variables
        freqData(jj,1).phaseHead	= phaseHeadList(jj);
        freqData(jj,1).magHead    	= magHeadList(jj);
        freqData(jj,1).freqList  	= freqList;
        freqData(jj,1).ampList      = ampDefault;
        freqData(jj,1).waveList  	= waveDefault;

        for iFreq = 1:nFreq
            disp(['Frequency ',num2str(iFreq),' of ',num2str(nFreq)])

            % Run simulink model
            output = run_simulink_model_grating_osc(freqList(iFreq), ampDefault, magHeadList(jj), phaseHeadList(jj));

            % Store output of model
            freqData(jj,1).output(iFreq) = output.get('logsout');
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Plots
clc
FREQ  	= cell(nPhaseHead,1);
MAG   	= cell(nPhaseHead,1);
PHASE 	= cell(nPhaseHead,1);
R2     	= cell(nPhaseHead,1);
pp = 1;
debug = false;
for jj = 1:nPhaseHead
    FREQ{jj,1}      = nan(102,length(freqData(jj,1).output));
    MAG{jj,1}   	= nan(1,length(freqData(jj,1).output));
    PHASE{jj,1} 	= nan(1,length(freqData(jj,1).output));
    R2{jj,1}     	= nan(1,length(freqData(jj,1).output));
    for ii = 1:length(freqData(jj,1).output)
        disp(pp)
        freq = freqData(jj,1).output(ii);
        FREQ{jj,1}(:,ii) = squeeze(freq{3}.Values.Data)';

        [fitresult, gof] = SS_fit_v3(FREQ{jj,1}(3:end,ii),false);

        MAG{jj,1}(ii)   	= fitresult.a1;
        PHASE{jj,1}(ii)     = fitresult.c1;
        R2{jj,1}(ii)        = gof.rsquare;

        if gof.rsquare<0.9
            disp('Here')
%             debug = true;
%             pause()
        end

    pp = pp + 1;
    end
end
disp('------------- DONE -------------')

%%
FIG = figure (11) ; clf ; hold on
FIG.Color = 'w';
FIG.Units = 'inches';
FIG.Position = [200 200 12 3.5];
movegui(FIG,'center')
pp = 1;
ax = axes;
for jj = 1:nPhaseHead
    ax(jj,1) = subplot(1,nMagHead,pp); hold on
    ylabel({['Phase = ' num2str(phaseHeadList(jj))],'Mag'})
    xlabel({'Frequency',['Gain = ' num2str(magHeadList(jj))]})
    plot(freqList,abs(MAG{jj,1}),'k','LineWidth',1)
    [mm,midx] = max(abs(MAG{jj,1}));
    plot([freqList(midx) , freqList(midx)] , [0 , mm] , '--g','LineWidth',1)
    plot([0 , freqList(midx)] , [mm , mm] , '--b','LineWidth',1)
    ylim([0 10])
    xlim([1e-1 1e2])
    grid on
    pp = pp + 1;
end
% set(ax,'XScale','log');
set(ax,'XLim',[0 10])

FIG = figure (12) ; clf ; hold on
FIG.Color = 'w';
FIG.Units = 'inches';
FIG.Position = [200 200 12 3.5];
movegui(FIG,'center')
pp = 1;
ax = axes;
for jj = 1:nPhaseHead
    ax(jj,1) = subplot(1,nMagHead,pp); hold on
    ylabel({['Phase = ' num2str(phaseHeadList(jj))],'r^{2}'})
    xlabel({'Frequency',['Gain = ' num2str(magHeadList(jj))]})
    plot(freqList,R2{jj,1},'k','LineWidth',1)
    ylim([0 1])
    xlim([1e-1 1e2])
    grid on
    pp = pp + 1;
end
set(ax,'XScale','log');

