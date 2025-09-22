function  waveform = scalePower(waveform,desiredPower)
    % Scale input WAVEFORM to achieve the desiredPower in dBm
    K = sqrt((1/mean(rms(waveform).^2))*10^((desiredPower-30)/10));
    waveform = K*waveform;
end
