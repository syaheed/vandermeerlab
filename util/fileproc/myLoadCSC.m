function csc = myLoadCSC(fname,varargin)

TimeConvFactor = 10^-6; % from nlx units to seconds
VoltageConvFactor = 10^6; % from volts to microvolts
handleMissing = true; % exclude (true) the invalid samples or not 
bits = 512;

extract_varargin;

csc_invalid_timestamps = [];

% load data
[Timestamps, ~, SampleFrequencies, NumberOfValidSamples, Samples, Header] = Nlx2MatCSC(fname, [1 1 1 1 1], 1, 1, []);

%% csc_info/ header

csc_info = [];

for hline = 1:length(Header)
   
    line = strtrim(Header{hline});
    
    if isempty(line) | ~strcmp(line(1),'-') % not an informative line, skip
        continue;
    end
    
    a = regexp(line(2:end),'(?<key>\w+)\s+(?<val>\S+)','names');
    
    % deal with characters not allowed by MATLAB struct
    if strcmp(a.key,'DspFilterDelay_µs')
        a.key = 'DspFilterDelay_us';
    end
    
    csc_info = setfield(csc_info,a.key,a.val);
    
    % convert to double if possible
    if ~isnan(str2double(a.val))
        csc_info = setfield(csc_info,a.key,str2double(a.val));
    end
end


%% shape data

csc_data = reshape(Samples,[size(Samples,1)*size(Samples,2) 1]);
csc_data = csc_data.*VoltageConvFactor.*csc_info.ADBitVolts;

csc_timestamps = repmat(Timestamps,[size(Samples,1) 1]).*TimeConvFactor;
dtvec = (0:size(Samples,1)-1)*(1/csc_info.SamplingFrequency);
dtmat = repmat(dtvec',[1 size(Samples,2)]);
csc_timestamps = csc_timestamps+dtmat;
csc_timestamps = reshape(csc_timestamps,[size(csc_timestamps,1)*size(csc_timestamps,2) 1]);

%% clean data

if handleMissing == true
    invalid_columns = find(NumberOfValidSamples ~= bits)';
    invalid_rows = [];
    
    for n = 1:length(invalid_columns)
        col_no = invalid_columns(n);
        invalid_rows = [invalid_rows;[(bits*col_no)-bits+1:bits*col_no]'];
    end
    
    zero_rows = find(csc_data == 0);
    invalid_rows = intersect(invalid_rows,zero_rows);
    
    csc_invalid_timestamps = csc_timestamps(invalid_rows);
    csc_timestamps(invalid_rows) = [];
    csc_data(invalid_rows) = [];
    
    fprintf('\n%d invalid samples (from %d blocks) were discarded\n', length(csc_invalid_timestamps), length(invalid_columns));

end

csc = mytsd(csc_timestamps, csc_data, csc_info, csc_invalid_timestamps);