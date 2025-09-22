

function [txWaveform,pdschSymbols,pdschIndices,dmrsSymbols,dmrsIndices,waveformInfo,pdschGrid] ...
    = generateTxWaveform(carrier,pdsch,wtx,txPower)

    nTxAnts = length(wtx);

    % PDSCH and PDSCH DM-RS
    [pdschIndices,pdschInfo] = hpre6GPDSCHIndices(carrier,pdsch);
    pdschBits = randi([0 1],pdschInfo.G,1);
    pdschSymbols = hpre6GPDSCH(carrier,pdsch,pdschBits);
    
    dmrsSymbols = hpre6GPDSCHDMRS(carrier,pdsch);
    dmrsIndices = hpre6GPDSCHDMRSIndices(carrier,pdsch);
    
    % PDSCH precoding
    pdschSymbolsPrecoded = pdschSymbols*wtx;
    
    % Grid
    pdschGrid = hpre6GResourceGrid(carrier,nTxAnts);
    
    [~,pdschAntIndices] = nrExtractResources(pdschIndices,pdschGrid);
    pdschGrid(pdschAntIndices) = pdschSymbolsPrecoded;
    
    % PDSCH DM-RS precoding and mapping
    for p = 1:size(dmrsSymbols,2)
        [~,dmrsAntIndices] = nrExtractResources(dmrsIndices(:,p),pdschGrid);
        pdschGrid(dmrsAntIndices) = pdschGrid(dmrsAntIndices) + dmrsSymbols(:,p)*wtx(p,:);
    end
    
    % OFDM Modulation
    [txWaveform,waveformInfo] = hpre6GOFDMModulate(carrier,pdschGrid);

    % Scale power of transmitted signal to desired value.
    txWaveform = scalePower(txWaveform,txPower);
end