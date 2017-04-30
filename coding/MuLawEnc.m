function mu=MuLawEnc(lin, MuencB, MuencR)
% MuLawEnc			Convert linear PCM values to the Mu-Law 8-bit PCM values
%
% Usage:			mu=MuLawEnc(lin, MuBoundaries, MuEncRepresentatives);
%
% Input 			lin = Scalar integer numbers between (-2^13) and (2^13 - 1)
%				      (14 bit dynamic range)
%                       MuBoundaries = Boundary values for linear to Mu conversion
%                       MuEncRepresentatives = Mapping table from boundaries to Mu law code
%
% Output			mu  = Mu-Law PCM value between 0 to 255
%					(8 bit dynamic range)
% 
% Copyright 2003 The MathWorks, Inc.
val=zeros(size(lin));
L=length(lin);
% Use a classical SQ and use Mu Law outputs as representaives 
% Note that the SQ is of the "At boundary value, Choose next Interval" type.
for i=1:L
  [~,val(i)]=SQencdecLR(lin(i),MuencB, MuencR);
end;
mu=val;