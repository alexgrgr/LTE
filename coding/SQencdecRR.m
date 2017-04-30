function [i,y]=SQencdecRR(x,x_vec,y_vec);
% SQencdecRR	Scalar quantizer for variable X, with quantizer 
%		specified by boundary and representative value vectors.
%
% SYNPSIS	[i,y]=SQencdec(x,x_vec,y_vec)
%
% Input <-	x    = sample to be quantized
% Input <-	x_vec= vector of boundary levels of the quantizer intervals
% Input <-	y_vec= vector of representative values of quantizer intervals
% 
% Note:
%		Number of boundary levels is always =
%		= One less than Number of quantizer intervals (output levels)
% 
% Output ->	i    = quantizer interval index
% Output ->	y    = quantized sample value

% Copyright 2003 The MathWorks, Inc.

%
L_x=length(x_vec);
L_y=length(y_vec);
if L_x ~= L_y-1
	disp(['Number of Quantizer boundaries = ',int2str(L_x)]);
	disp(['Number of Quantizer intervals = ',int2str(L_y)]);
	error('Quantizer boundaries are one less than representative intervals');
end;
v_max=max(x_vec);
if x >= v_max
	i=L_y;
else
    if (x<0)
        i=min(find(x<x_vec));
    else
       i=min(find(x<x_vec));
   end;
end;
y=y_vec(i);