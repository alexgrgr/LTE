function channel=lteSetChannel(txInfo, PDSCH)

% params.Rs = txInfo.SamplingRate;
% params.numAntenna = PDSCH.NLayers ;
%%
% channel.DelayProfile = params.profile;

% channel.DopplerFreq = params.doppler;
% channel.MIMOCorrelation = params.corrProfile;


channel.ModelType = 'GMEDS';
channel.DelayProfile = 'EVA';
channel.DopplerFreq = 70;
channel.MIMOCorrelation = 'Medium';
channel.NRxAnts = PDSCH.NLayers;
channel.InitTime = 0;
channel.InitPhase = 'Random';
channel.Seed = 17;
channel.NormalizePathGains = 'On';
channel.NormalizeTxAnts = 'On';
channel.SamplingRate = txInfo.SamplingRate;
channel.NTerms = 16;