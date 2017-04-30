function lin=ALawDec(a, ADecRepresentatives)
% ALawDec			Convert A-Law 8-bit PCM values into linear PCM values
%
% Usage:			lin=ALawDec(a,ADEcRepresentatives);
%
% Input 			a  = A-Law PCM values between 0 to 255
%					(8 bit dynamic range)
%                       ADecRepresentatives = Lookup table for A to linear conversion
%
% Output			lin = Scalar integer numbers between (-2^12) and (2^12 - 1)
%				      (13 bit dynamic range)
% 

% Copyright 2003 The MathWorks, Inc.

%Now look up the decoder representative table using the same index
lin=ADecRepresentatives(a+1);