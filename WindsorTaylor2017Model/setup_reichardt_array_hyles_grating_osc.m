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
testAmp         = true; % run oscillation amplitude test
testWave        = true; % run spatial frequency (1/wavelength) test

% Default stimulus parameters
ampDefault      = 5;  % [deg]
waveDefault     = 20; % [deg]
freqDefault     = 2;  % [Hz]

% Parameters for head motion
magHeadList     = 0; % [gain]
phaseHeadList   = 0; % [deg]

% Parameters for oscillation frequency test
freqList = logspace(-1,2,100); % [Hz]

% Parameters for oscillation amplitude test
ampList = logspace(-1,3,200); % [deg]

% Parameters for spatial frequency test
spatialFreqList = logspace(-2,0,100); % [1/deg]

% Process parameters and create default stimulus grating

% Round spatial frequencies to give whole numbers of cycles around sphere
numberCyclesList = round(360*spatialFreqList); 
spatialFreqList  = numberCyclesList/360;

% Get parameter list size
nMagHead    = length(magHeadList);
nPhaseHead  = length(phaseHeadList);
nFreq       = length(freqList);
nAmp        = length(ampList);
nWave       = length(spatialFreqList);

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

freqData = struct;
% Test effect of oscillation frequency
if testFreq
    disp('Testing frequency effects');
    for iPhaseHead = 1:nPhaseHead
        disp(['Head phase = ',num2str(phaseHeadList(iPhaseHead))]);
        for iMagHead = 1:nMagHead
            disp(['Head gain = ',num2str(magHeadList(iMagHead))]);
            
            % Store input variables
            freqData(iPhaseHead,iMagHead).phaseHead     = phaseHeadList(iPhaseHead);
            freqData(iPhaseHead,iMagHead).magHead       = magHeadList(iMagHead);
            freqData(iPhaseHead,iMagHead).freqList      = freqList;
            freqData(iPhaseHead,iMagHead).ampList       = ampDefault;
            freqData(iPhaseHead,iMagHead).waveList      = waveDefault;
            
            for iFreq = 1:nFreq
                disp(['Frequency ',num2str(iFreq),' of ',num2str(nFreq)]);
                
                % Run simulink model
                tic
                output = run_simulink_model_grating_osc(freqList(iFreq), ampDefault, magHeadList(iMagHead), phaseHeadList(iPhaseHead));
                toc
                
                % Store output of model
                freqData(iPhaseHead,iMagHead).output(iFreq) = output.get('logsout');
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Test effect of oscillation amplitude
ampData = struct;
if testAmp
    disp('Testing amplitude effects');
    for iPhaseHead = 1:nPhaseHead
        disp(['Head phase = ',num2str(phaseHeadList(iPhaseHead))]);
        for iMagHead = 1:nMagHead
            disp(['Head gain = ',num2str(magHeadList(iMagHead))]);
            
            % Store input variables
            ampData(iPhaseHead,iMagHead).phaseHead  = phaseHeadList(iPhaseHead);
            ampData(iPhaseHead,iMagHead).magHead    = magHeadList(iMagHead);
            ampData(iPhaseHead,iMagHead).freqList   = freqDefault;
            ampData(iPhaseHead,iMagHead).ampList    = ampList;
            ampData(iPhaseHead,iMagHead).waveList   = waveDefault;
            
            for iAmp = 1:nAmp
                disp(['Amplitude ',num2str(iAmp),' of ',num2str(nAmp)]);
                
                % Run simulink model
                tic
                output = run_simulink_model_grating_osc(freqDefault, ampList(iAmp), magHeadList(iMagHead), phaseHeadList(iPhaseHead));
                toc
                
                % Store output of model
                ampData(iPhaseHead,iMagHead).output(iAmp) = output.get('logsout');
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Test effect of spatial frequency (wavelength of grating)
waveData = struct;
% clear existing grating pattern
clear imageData
if testWave
    disp('Testing wavelength effects');
    for iPhaseHead = 1:nPhaseHead
        disp(['Head phase = ',num2str(phaseHeadList(iPhaseHead))]);
        for iMagHead = 1:nMagHead
            disp(['Head gain = ',num2str(magHeadList(iMagHead))]);
            
            % Store input variables
            waveData(iPhaseHead,iMagHead).phaseHead = phaseHeadList(iPhaseHead);
            waveData(iPhaseHead,iMagHead).magHead   = magHeadList(iMagHead);
            waveData(iPhaseHead,iMagHead).freqList  = freqDefault;
            waveData(iPhaseHead,iMagHead).ampList   = ampDefault;
            waveData(iPhaseHead,iMagHead).waveList  = 1./spatialFreqList;
            
            for iWave = 1:nWave
                disp(['Wavelength ',num2str(iWave),' of ',num2str(nWave)]);
                
                % Create simulus grating of given spatial frequency
                imageData=makeSineGrating(1./spatialFreqList(iWave));
                
                % High pass filter spatial data with repeats of grating at both ends to avoid end effects when filtering
                len         = length(imageData);
                temp        = repmat(imageData,1,3);
                tempFilt    = filtfilt(numHP,denHP,temp);
                imageData   = tempFilt(:,len+1:len*2);
                
                % Run simulink model
                tic
                output = run_simulink_model_grating_osc(freqDefault, ampDefault, magHeadList(iMagHead), phaseHeadList(iPhaseHead));
                toc
                
                % Store output of model
                waveData(iPhaseHead,iMagHead).output(iWave) = output.get('logsout');
            end
        end
    end
end

%% Plots
% AMP  = ampData.output(2);
% FREQ = freqData.output(1);
% WAVE = waveData.output(1);
% xx = freqData.freqList;
% DATA = squeeze(FREQ{3}.Values.Data)';
% plot(DATA)

AMP     = nan(102,length(ampData.output));
mag     = nan(1,length(ampData.output));
phase   = nan(1,length(ampData.output));
r       = nan(1,length(ampData.output));
for kk = 1:length(ampData.output)
	amp = ampData.output(kk);
    AMP(:,kk) = squeeze(amp{3}.Values.Data)';
    
    [fitresult, gof] = SS_fit(AMP(:,kk));

    mag(kk)   = fitresult.a1;
    phase(kk) = fitresult.c1;
    r(kk)     = gof.rsquare;
end
%%
figure (11) ; clf ; hold on
ax = gca;
plot(ampList,r)
ax.XScale = 'log';

%%
FREQ  	= nan(102,length(freqData.output));
mag     = nan(1,length(freqData.output));
phase   = nan(1,length(freqData.output));
r       = nan(1,length(freqData.output));
for kk = 1:length(freqData.output)
	freq = freqData.output(kk);
    FREQ(:,kk) = squeeze(freq{3}.Values.Data)';
    
    [fitresult, gof] = SS_fit(FREQ(:,kk));

    mag(kk)   = fitresult.a1;
    phase(kk) = fitresult.c1;
    r(kk)     = gof.rsquare;
end
%%
figure (11) ; clf ; hold on
ax = gca;
plot(freqList,mag)
ax.XScale = 'log';

%%
WAVE  	= nan(102,length(freqData.output));
mag     = nan(1,length(freqData.output));
phase   = nan(1,length(freqData.output));
r       = nan(1,length(freqData.output));
for kk = 1:length(waveData.output)
	wave = freqData.output(kk);
    WAVE(:,kk) = squeeze(wave{3}.Values.Data)';
    
    [fitresult, gof] = SS_fit(WAVE(:,kk));

    mag(kk)   = fitresult.a1;
    phase(kk) = fitresult.c1;
    r(kk)     = gof.rsquare;
end
%%
figure (11) ; clf ; hold on
ax = gca;
plot(spatialFreqList,r)
ax.XScale = 'log';




