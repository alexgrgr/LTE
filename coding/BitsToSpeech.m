delete *.wav
Fs=8000;
DataType='int16';
FrameSize=427;
numBitsPerSample = 8;
LawG711='Mu';
params = initializeSpeechCoding(LawG711);
numBitsPerFrame = FrameSize * numBitsPerSample;
numTotalFrames = numel(rxBitsAll)/numBitsPerFrame;
myAudioPlayer=dsp.AudioPlayer('SampleRate', Fs);
RxAudioFile = dsp.AudioFileWriter(...
    'Filename', 'RxSpeech.wav', 'SampleRate', Fs);
prev=0;
gain=(2^-params.DR);
fprintf(1,'Speech decoding and playing your received voice ...  ');
rxpcm=[];
gain=2^(15-params.DR);
for index=1:numTotalFrames
    rxBits=rxBitsAll(prev+(1:numBitsPerFrame)');
    pcm = speechDecode(rxBits, LawG711, params);
%     rxpcm=[rxpcm;pcm];    
%     step(myAudioPlayer,gain*pcm);
    step(RxAudioFile, int16(gain*pcm));
    prev=prev+numBitsPerFrame;
end
fprintf(1,'   Done.\nFile Name = RxSpeech.wav \n');
release(myAudioPlayer);
release(RxAudioFile);