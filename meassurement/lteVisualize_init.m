function [Hsa, Hber, Hconst, Hconst2, EVM, Hsa2]=lteVisualize_init(PDSCH, txInfo)

myTitle= ['Modo LTE/LTE-A ',PDSCH.TxScheme,'. Ancho de Banda ',txInfo.BW, ' MHz con ', num2str(PDSCH.NLayers), ' capas'];  
%'SpectrumType', 'Spectrogram',...
Hsa = dsp.SpectrumAnalyzer(...
    'SampleRate',txInfo.SamplingRate, ...
    'ShowLegend',true, ...
    'Window', 'Rectangular', ...
    'SpectralAverages',10, ...
    'YLimits',[-90 -10], ...
    'Position' ,[6 200 800 450], ...
    'Title', myTitle, ...
    'ChannelNames',...
    {'Transmitido','Recibido No-Ecualizado','Recibido Ecualizado'});
Hber=comm.ErrorRate;
Hconst = comm.ConstellationDiagram ('Title', 'Tx Constellation');
Hconst2= comm.ConstellationDiagram ('Title', 'Rx Constellation');
Hconst.Position = [6 37 640 460];
Hconst2.Position= [600 37 640 460];
EVM = comm.EVM;
EVM.Normalization = 'Average constellation power';
Hsa2=clone(Hsa);