function [txInfo] = txInfoConformation(PDSCH, enb, params)

txInfo = lteOFDMInfo(enb);
%txInfo.TMN = ;
txInfo.BW = lteDLRBtoBW(enb.NDLRB);
txInfo.NDLRB = enb.NDLRB;
txInfo.CellRefP = enb.CellRefP;
txInfo.NCellID = enb.NCellID;
txInfo.CyclicPrefix = enb.CyclicPrefix;
txInfo.CFI = enb.CFI;
txInfo.Ng = enb.Ng;
txInfo.PHICHDuration = enb.PHICHDuration;
txInfo.NSubframe = enb.NSubframe;
txInfo.TotFrames = params.numFrames;
txInfo.TotSubframes = params.numFrames*10;
%txInfo.Windowing = txInfo.Windowing;
txInfo.DuplexMode = enb.DuplexMode;
txInfo.PDSCH = PDSCH;
txInfo.DuplexMode = enb.DuplexMode;
txInfo.SNR = params.SNR;
% txInfo.CellRSPower = ;
% txInfo.PSSPower = ;
% txInfo.SSSPower = ;
% txInfo.PBCHPower = ;
% txInfo.PCFICHPower = ;
% txInfo.NAllocatedPDCCHREG = ;
% txInfo.PDCCHPower = ;
% txInfo.PDSCHPowerBoosted = ;
% txInfo.PowerDeboosted = ;
% txInfo.AllocatedPRB = ;
% txInfo.SamplingRate = txInfo.SamplingRate;
% txInfo.Nfft = txInfo.Nfft;

end

