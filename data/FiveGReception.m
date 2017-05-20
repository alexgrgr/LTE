function [rxGrid] = FiveGReception(rxWaveform, enbRx, WaveMod)

switch WaveMod
    case 'FOFDM'
        rxGrid = commExamplePrivate('lteFOFDMRx', ...
            rxWaveform, ...
            enbRx.NDLRB, ...
            enbRx.FiveG.FOFDM.Nrb_sc,...
            enbRx.FiveG.FOFDM.Ndl_symb, ...
            enbRx.FiveG.FOFDM.FilterLenght,...
            enbRx.FiveG.FOFDM.toneOffset);
    case 'UFMC'
        rxGrid = commExamplePrivate('lteUFMCRx', rxWaveform, ...
            enbRx.NDLRB,...
            enbRx.FiveG.UFMC.Nrb_sc,...
            enbRx.FiveG.UFMC.Ndl_symb, ...
            enbRx.FiveG.UFMC.slobeAtten);
end