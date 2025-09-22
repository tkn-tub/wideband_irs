function [risElementCoeff,w,Htot] = calculateRISCoeff(enableRIS,risCh,carrier)
    
    % Initialize RIS element coefficients (gain = 1 and random phase)
    numRISElements = prod(risCh.RISSize);
    theta = 2*pi*rand(1,numRISElements); % uniformly distributed phases in [0, 2*pi]
    risElementCoeff = exp(1i*theta);
    % If the RIS algorithm is disabled, this is the value used in the
    % simulation

    [G,h] = getRISChannelFreqResponse(risCh,carrier);

    H = h*diag(risElementCoeff)*G;

    % Calculate precoding weights using MRT (maximum ratio transmission)
    w = H'/norm(H);

    if enableRIS
        numIter = 10;  % Number of iterations
        Htot = zeros(numIter+1,1); % Total channel H*wf. Used to check convergence
        Htot(1) = H*w;
        for n = 1:numIter
            % Need to calculate B = h*diag(G*w), where w is the transmitter
            % precoding vector, G is the transmitter to RIS channel matrix and
            % h is the RIS to receiver channel matrix. B is used to calculate
            % the new RIS phase values theta as -angle(B)
            B = h*diag(G*w);

            % Calculate the new phase vector phi that compensates for the phase changes in hr, G and w
            theta = -angle(B);

            % New RIS coefficients
            risElementCoeff = exp(1i*theta); 

            % New combined channel matrix H
            H = h*diag(risElementCoeff)*G;            

            % Get new weights w based on new channel matrix H
            w = H'/norm(H);

            % Overall channel response for this iteration. Used to check
            % convergence
            Htot(n+1) = H*w;
        end
    else
        Htot = H*w;
    end
end