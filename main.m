clc; clearvars; close all;

%% Parameters
fs = 360;
ts = 1/fs;
rng('default');


%% Train & Evaluate SVM
recs_all = ["100", "105", "106", "209", "220"];
[SVMModel, XTest, YTest] = train_svm_classifier(recs_all);

YPred = predict(SVMModel, XTest);
accuracy = mean(YPred == YTest);
fprintf("\n=== Performance Metrics ===\nAccuracy: %.2f%%\n", 100*accuracy);

TP = sum((YTest==1)&(YPred==1));
TN = sum((YTest==0)&(YPred==0));
FP = sum((YTest==0)&(YPred==1));
FN = sum((YTest==1)&(YPred==0));

fprintf("\n=== Classification Report ===\n");
fprintf("TP (Normal => Normal): %.2f%%\n",100*TP/(TP+FN));
fprintf("TN (Abnormal=>Abnormal): %.2f%%\n",100*TN/(TN+FP));
fprintf("FN (Normal=>Abnormal): %.2f%%\n",100*FN/(TP+FN));
fprintf("FP (Abnormal=>Normal): %.2f%%\n",100*FP/(TN+FP));
fprintf("Overall Accuracy: %.2f%%\n",100*accuracy);

figure;
confusionchart(YTest, YPred, ...
    'Title', 'Confusion Matrix: SVM Beat Classification', ...
    'RowSummary','row-normalized', ...
    'ColumnSummary','column-normalized', ...
    'FontSize', 14);

%% Visualize ECG & Beat Labels (first 20 seconds)
record_name = "105";
baseFolder = fullfile("dataset");
matPath = fullfile(baseFolder, record_name, record_name + "m.mat");
data = load(matPath); ecg_full = data.val(1,:);
sec_to_plot = 20;
ecg = ecg_full(1:fs*sec_to_plot);

[n_abnorm, n_total, labels, R_loc, P_loc, Q_loc, S_loc, T_loc] = classify_beats(ecg, SVMModel);

t = (1:length(ecg)) / fs;
figure;
plot(t, ecg, 'k', 'DisplayName', 'ECG'); hold on;

plot(R_loc(labels==1)/fs, ecg(R_loc(labels==1)), 'go', ...
     'DisplayName','Normal', ...
     'LineWidth', 2, ...
     'MarkerSize', 6, ...
     'MarkerFaceColor','g');  

plot(R_loc(labels==0)/fs, ecg(R_loc(labels==0)), 'ro', ...
     'DisplayName','Abnormal', ...
     'LineWidth', 2, ...
     'MarkerSize', 6, ...
     'MarkerFaceColor','r');  


xlabel('Time (s)'); ylabel('Amplitude');
title('ECG with SVM-Labelled Beats');
legend('Location','best'); grid on;

%% 2-second ECG with P-Q-R-S-T & Intervals

i_beat = 21;  % signal range
fs = 360;

% Extract 2-second window around R-peak
start_idx = max(1, R_loc(i_beat) - fs);
end_idx   = min(length(ecg), R_loc(i_beat) + fs);
t_zoom    = (start_idx:end_idx) / fs;
ecg_zoom  = ecg(start_idx:end_idx);
toLocal   = @(idx) idx - start_idx + 1;

P = toLocal(P_loc(i_beat));
Q = toLocal(Q_loc(i_beat));
R = toLocal(R_loc(i_beat));
S = toLocal(S_loc(i_beat));
T = toLocal(T_loc(i_beat));

if all([P Q R S T] > 0) && all([P Q R S T] <= length(ecg_zoom))
    figure;
    hECG = plot(t_zoom, ecg_zoom, 'k', 'DisplayName', 'ECG'); hold on;

    % Plot all peaks with a single handle for legend
    hPeaks = plot(t_zoom([P Q R S T]), ecg_zoom([P Q R S T]), 'ro', ...
                  'MarkerFaceColor', 'r', 'MarkerSize', 12, 'LineWidth', 2, ...
                  'DisplayName', 'Peaks (P-Q-R-S-T)');

    % Label peaks individually above markers
    text(t_zoom(P), ecg_zoom(P) + 0.5, 'P', 'FontWeight','bold', 'FontSize',12, 'HorizontalAlignment','center');
    text(t_zoom(Q), ecg_zoom(Q) + 0.5, 'Q', 'FontWeight','bold', 'FontSize',12, 'HorizontalAlignment','center');
    text(t_zoom(R), ecg_zoom(R) + 0.5, 'R', 'FontWeight','bold', 'FontSize',12, 'HorizontalAlignment','center');
    text(t_zoom(S), ecg_zoom(S) + 0.5, 'S', 'FontWeight','bold', 'FontSize',12, 'HorizontalAlignment','center');
    text(t_zoom(T), ecg_zoom(T) + 0.5, 'T', 'FontWeight','bold', 'FontSize',12, 'HorizontalAlignment','center');

    xlabel('Time (s)');
    ylabel('Amplitude');
    title('ECG Segment with Peaks (P–Q–R–S–T)');
    legend([hECG, hPeaks], 'Location', 'best');
    grid on;
end

                    