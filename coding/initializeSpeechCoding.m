function params = initializeSpeechCoding(law)
load g711tables.mat
if strcmp(law,'A'), params.DR=12; else params.DR=13;end
%
params.Adec = ADecRepresentatives;
params.AencB = ABoundaries;
params.AencR = AEncRepresentatives;
%
params.Mudec = MuDecRepresentatives;
params.MuencB = MuBoundaries;
params.MuencR = MuEncRepresentatives;