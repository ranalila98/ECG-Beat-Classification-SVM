% === Setup paths ===
datasetFolder = "dataset\220";
txtFile = fullfile(datasetFolder, "annotations.txt");
csvFile = fullfile(datasetFolder, "annotations.csv");

% === Read annotation lines ===
fid = fopen(txtFile, 'r');
if fid == -1
    error("Cannot open: %s", txtFile);
end
lines = textscan(fid, '%s', 'Delimiter', '\n');
lines = lines{1};
fclose(fid);

% === Initialize arrays ===
sample = [];
type = [];

% === Parse annotation lines ===
% for i = 1:length(lines)
%     line = strtrim(lines{i});
%     if isempty(line) || startsWith(line, 'Elapsed')
%         continue;
%     end
% 
%     tokens = regexp(line, '(\d+:\d+\.\d+)\s+(\d+)\s+(\S)', 'tokens');
%     if ~isempty(tokens)
%         t = tokens{1};
%         sample_num = str2double(t{2});
%         if sample_num == 0
%             continue;  % Skip sample 0
%         end
%         sample(end+1,1) = sample_num;
%         type(end+1,1) = double(t{3} == 'N');  % Type: 1 if 'N', else 0
%     end
% end

for i = 1:length(lines)
    line = strtrim(lines{i});
    if isempty(line) || startsWith(line, 'Elapsed')
        continue;
    end

    tokens = regexp(line, '(\d+:\d+\.\d+)\s+(\d+)\s+(\S)', 'tokens');
    if ~isempty(tokens)
        t = tokens{1};
        sample_num = str2double(t{2});
        if sample_num == 0
            continue;  % Skip sample 0
        end

        if t{3} == 'N'
            type(end+1,1) = 1;
            sample(end+1,1) = sample_num;
        elseif t{3} == 'A'
            type(end+1,1) = 0;
            sample(end+1,1) = sample_num;
        else
            continue;  % Skip other beat types
        end
    end
end


% === Save to CSV ===
T = table(sample, type);
writetable(T, csvFile, 'WriteVariableNames', false);
fprintf(' Saved CSV without sample 0 and without header: %s\n', csvFile);