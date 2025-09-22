
function [pdschEq,pdschRx] = decodePDSCH(rxWaveform,carrier,pdsch,pdschIndices,dmrsSymbols,dmrsIndices)
    
    % OFDM demodulation
    rxGrid = hpre6GOFDMDemodulate(carrier,rxWaveform);
    
    % Channel estimation
    [estChGridLayers,noiseEst] = hpre6GChannelEstimate(carrier,rxGrid,dmrsIndices,dmrsSymbols,...
        'CDMLengths',pdsch.DMRS.CDMLengths);
    
    % Equalization
    [pdschRx,pdschHest] = nrExtractResources(pdschIndices,rxGrid,estChGridLayers);
    [pdschEq,~] = nrEqualizeMMSE(pdschRx,pdschHest,noiseEst);
end

