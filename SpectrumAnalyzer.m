% Received signal spectrum
spectrumAnalyzer = dsp.SpectrumAnalyzer();
spectrumAnalyzer.Name = 'Received signal spectrum';
spectrumAnalyzer.SampleRate = 30e6;
spectrumAnalyzer.ReducePlotRate = false;
spectrumAnalyzer.PlotMaxHoldTrace = true;
spectrumAnalyzer.PlotMinHoldTrace = true;
spectrumAnalyzer.ShowGrid = true;
spectrumAnalyzer.ViewType = 'Spectrum and Spectrogram';

while 1
   spectrumAnalyzer(rxWaveform); 
end