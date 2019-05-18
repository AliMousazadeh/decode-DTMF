clear; close; clc;

% Control parameters
% WARNING: Better left unchanged unless number of detected strokes
% does not match the expected value from signal plot or
% if envelopes are missing silent intervals (decrease insensitivity)
envelope_insensitivity = 100;
silent_amplitude_threshold = 0.01;
%

filename = input('Enter file address: ');
info = audioinfo(filename);
[y, Fs] = audioread(filename);

row_freq = [697; 770; 852; 941];
column_freq = [1209, 1336, 1477, 1633];
freqs = row_freq + column_freq;
chars = {{'1', '2', '3', 'A'}; {'4', '5', '6', 'B'}; ...
    {'7', '8', '9', 'C'}; {'*', '0', '#', 'D'}};

num_strokes = 0;
prev_size = 0;
while (~(prev_size == length(y)))
    prev_size = length(y);
    envelope = imdilate(abs(y), true(envelope_insensitivity, 1));
    
    if (num_strokes == 0)
        figure;
        plot(y); xlabel('Samples'); ylabel('Amplitude');
        title('Signal');
        hold on;
        plot(envelope, 'r-', 'LineWidth', 2);
        plot(-envelope, 'r-', 'LineWidth', 2);
        legend('Data', 'Envelope');
    end
    
    quiet_parts = envelope < silent_amplitude_threshold;
    stroke_num_samples = find(quiet_parts == 1, 1, 'first') - 1;
    quiet_parts_cut = quiet_parts; quiet_parts_cut(1:stroke_num_samples) = [];
    quiet_num_samples = find(quiet_parts_cut == 0, 1, 'first') - 1;
    stroke = y(1:stroke_num_samples, :);
    
    
    % the two frequencies that produce maximum power spectral density (PSD)
    % are almost equal to the dual frequencies
    [Pxx, F] = periodogram(stroke, rectwin(length(stroke)), length(stroke), Fs);
    [~, index] = max(Pxx);
    freq1 = F(index);
    Pxx(index) = [];   [~, index] = max(Pxx);
    freq2 = F(index);
    y(1:stroke_num_samples + quiet_num_samples, :) = [];
    num_strokes = num_strokes + 1;
    
    freq_estimated = round(freq1 + freq2);  %estimated dual tone frequency
    distance_squared = (freqs - freq_estimated) .^ 2;  %distance of estimated frequency from actual dual tone frequencies
    [row, column] = find(distance_squared == min(min(distance_squared)));   %nearest frequency to the estimation is selected
    fprintf('%c ', chars{row}{column});
end
fprintf('\nNumber of key strokes: %d\n', num_strokes);