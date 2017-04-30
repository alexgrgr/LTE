function a=ALawEnc(lin, AencB,AencR)
% ALawEnc			Convert linear PCM values to the A-Law 8-bit PCM values
%
% Usage:			a=ALawEnc(lin, ABoundaries, AEncRepresentatives);
%
% Input 			lin = Scalar integer numbers between (-2^12) and (2^12 - 1)
%				      (13 bit dynamic range)
%                       ABoundaries = Boundary values for linear to A conversion
%                       AEncRepresentatives = Mapping table from boundaries to A law code
%
% Output			a  = A-Law PCM value between 0 to 255
%					(8 bit dynamic range)
% 

% Copyright 2003 The MathWorks, Inc.
val=zeros(size(lin));
L=length(lin);
% Use a classical SQ and use Mu Law outputs as representaives 
% Note that the SQ is of the "At boundary value, Choose next Interval" type.
for i=1:L
  [~,val(i)]=SQencdecRR(lin(i),AencB,AencR);
end;
a=val;