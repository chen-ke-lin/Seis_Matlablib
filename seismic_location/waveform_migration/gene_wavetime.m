function trace=gene_wavetime(seismic,stations,ffilter,precision,fname_d,fname_p,fname_s)
% This function is used to generate the binary files for the inputs of MCM.
% The binary files are waveforms and traveltimes (if needed).
%
% Note the structure 'seismic' (contain waveforms) and the structure
% 'stations' (contain station information) may have different number of
% stations. This program is used to select and output the waveforms
% that are also in the structure 'stations'.
%
% If three-component data are avaliable, the program will also do the same
% process (i.e. filtering) on these components. e.g.:
% seismic.zdata: Z component;
% seismic.ndata: N component;
% seismic.edata: E component;
%
% If empty file names ([]) are given, then do not output the corresponding
% binary files.
%
% INPUT--------------------------------------------------------------------
% seismic: matlab structure, contains waveform information;
% seismic.data: nrec*nt, seismic data;
% seismic.name: cell array, 1*nrec, station names;
% seismic.dt: scaler, the time sample interval of the data, in second;
% seismic.fe: scaler, the sampling frequency of the data, in Hz;
% seismic.t0: matlab datetime, the starting time of seismic data;
% stations: matlab structure, contains station information;
% stations.name: cell array, 1*nr, station names;
% stations.north: vector, 1*nr, north coordinates of all stations;
% stations.east: vector, 1*nr, east coordinates of all stations;
% stations.depth: vector, 1*nr, depth coordinates of all stations;
% stations.travelp: P-wave traveltime table, in second, 2D array, ns*nr;
% stations.travels: S-wave traveltime table, in second, 2D array, ns*nr;
% ffilter: matlab structure, contains filtering information;
% ffilter.freq: frequency band used to filter the seismic data, a vector containing 1 or 2 elements, in Hz
% ffilter.type: filter type, can be 'low', 'bandpass', 'high', 'stop'
% ffilter.order: order of Butterworth filter, for bandpass and bandstop designs are of order 2n
% ffilter.method : filtering method, can be 'BW' (Butterworth) or 'DF' (digital filter);
% precision: string, 'single' or 'double', specifiy the outout presicion;
% fname_d: output filename for waveform data;
% fname_p: output binary file name for P-wave traveltimes;
% fname_s: output binary file name for S-wave traveltimes.
%
% OUTPUT-------------------------------------------------------------------
% trace: matlab structure, contain selected data information;
% trace.data: seismic data for migration, 2D array, n_sta*nt;
% trace.fe: sampling frequency of seismic data, in Hz, scalar;
% trace.dt: time sampling interval of seismic data, in second, scalar;
% trace.name: name of selected stations, vector, 1*n_sta;
% trace.north: north coordinates of selected stations, vector, 1*n_sta;
% trace.east: east coordinates of selected stations, vector, 1*n_sta;
% trace.depth: depth coordinates of selected stations, vector, 1*n_sta;
% trace.t0: matlab datetime, the starting time of traces;
% trace.travelp: P-wave traveltime table, 2D array, ns*n_sta;
% trace.travels: S-wave traveltime table, 2D array, ns*n_sta;
% trace.zdata: Z component data if exist, 2D array, n_sta*nt;
% trace.ndata: N component data if exist, 2D array, n_sta*nt;
% trace.edata: E component data if exist, 2D array, n_sta*nt;



folder='./data'; % name of the folder where output data are stored

% check if the output folder exists, if not, then create it
if ~exist(folder,'dir')
    mkdir(folder);
end

% set default values
if nargin<3
    ffilter=[];
    precision='double';
    fname_d='waveform.dat';
    fname_p='travelp.dat';
    fname_s='travels.dat';
elseif nargin==3
    precision='double';
    fname_d='waveform.dat';
    fname_p='travelp.dat';
    fname_s='travels.dat';
elseif nargin==4
    fname_d='waveform.dat';
    fname_p='travelp.dat';
    fname_s='travels.dat';
end

if isempty(precision)
    precision='double';
end

if ~isempty(fname_d)
    fname_d=[folder '/' fname_d];
end

if ~isempty(fname_p)
    fname_p=[folder '/' fname_p];
end

if ~isempty(fname_s)
    fname_s=[folder '/' fname_s];
end


nr=length(stations.name); % number of stations in the station file

trace.t0=seismic.t0; % starting time of seismic data (traces)

% initialize
trace.data=[];
trace.travelp=[];
trace.travels=[];

n_sta=0; % total number of effective stations

for ir=1:nr
    
    indx=strcmp(stations.name{ir},seismic.name); % index of this station in the 'seismic' file
    
    if sum(indx)==1
        % find seismic data for this station
        fprintf("Found seismic data for the station '%s'.\n",stations.name{ir});
        n_sta=n_sta+1;
        trace.data(n_sta,:)=seismic.data(indx,:); % seismic data
        trace.name{n_sta}=stations.name{ir}; % station name
        trace.north(n_sta)=stations.north(ir); % north coordinate of station
        trace.east(n_sta)=stations.east(ir); % east coordinate of station
        trace.depth(n_sta)=stations.depth(ir); % depth coordinate of station
        if ~isempty(stations.travelp)
            trace.travelp(:,n_sta)=stations.travelp(:,ir); % P-wave traveltime table
        end
        if ~isempty(stations.travels)
            trace.travels(:,n_sta)=stations.travels(:,ir); % S-wave traveltime table
        end
        % if three-component data are avaliable, do it!
        if isfield(seismic,'zdata')
            trace.zdata(n_sta,:)=seismic.zdata(indx,:);
        end
        if isfield(seismic,'ndata')
            trace.ndata(n_sta,:)=seismic.ndata(indx,:);
        end
        if isfield(seismic,'edata')
            trace.edata(n_sta,:)=seismic.edata(indx,:);
        end
        
    elseif sum(indx)==0
        % no seismic data for this station is found.
        fprintf("No seismic data are found for the station '%s'.\n",stations.name{ir});
    else
        error("Something wrong in the seismic structure! As least two traces have the same station name!");
    end
    
end

if n_sta==0
    warning("No seismic data in the 'sations' file is found!");
    return;
else
    fprintf("In total %d traces are found and stored.\n", n_sta);
end

% check if need filter seismic data
f_nyqt=0.5*seismic.fe; % Nyquist frequency of seismic data
if ~isempty(ffilter)
    % apply filtering in frequency domain
    
    nfreq=length(ffilter.freq);
    switch nfreq
        case 1
            if ~isfield(ffilter,'type')
                ffilter.type='high';
            end
            fprintf('Apply a %d-order %spass Butterworth filter with cutoff frequency %f Hz.\n',ffilter.order,ffilter.type,ffilter.freq);
        case 2
            if ~isfield(ffilter,'type')
                ffilter.type='bandpass';
            end
            fprintf('Apply a %d-order %s Butterworth filter of %f - %f Hz.\n',2*ffilter.order,ffilter.type,ffilter.freq);
        otherwise
            error('Incorrect input for frequency filter parameters.\n');
    end
    
    if strcmp(ffilter.method, 'BW')
        % set Butterworth filter parameters
        if ~isfield(ffilter,'order')
            ffilter.order=4; % default filter order is 4
        end
        [bb,aa]=butter(ffilter.order,ffilter.freq/f_nyqt,ffilter.type);
    end
    
    for ir=1:n_sta
        if strcmp(ffilter.method,'DF')
            % digital filter
            if strcmp(ffilter.type,'bandpass')
                trace.data(ir,:)=bandpass(trace.data(ir,:), ffilter.freq, seismic.fe);
            elseif strcmp(ffilter.type,'high')
                trace.data(ir,:)=highpass(trace.data(ir,:), ffilter.freq, seismic.fe);
            end
        elseif strcmp(ffilter.method,'BW')
            % Butterworth filter
            trace.data(ir,:)=filter(bb,aa,trace.data(ir,:));
        else
            error('Incorrect input for frequency filter method.\n');
        end
        % if three-component data exist, do it!
        if isfield(trace,'zdata')
            if strcmp(ffilter.method,'DF')
                % digital filter
                if strcmp(ffilter.type,'bandpass')
                    trace.zdata(ir,:) = bandpass(trace.zdata(ir,:), ffilter.freq, seismic.fe);
                elseif strcmp(ffilter.type,'high')
                    trace.zdata(ir,:) = highpass(trace.zdata(ir,:), ffilter.freq, seismic.fe);
                end
            elseif strcmp(ffilter.method,'BW')
                % Butterworth filter
                trace.zdata(ir,:)=filter(bb,aa,trace.zdata(ir,:));
            else
                error('Incorrect input for frequency filter method.\n');
            end
        end
        if isfield(trace,'ndata')
            if strcmp(ffilter.method,'DF')
                % digital filter
                if strcmp(ffilter.type,'bandpass')
                    trace.ndata(ir,:) = bandpass(trace.ndata(ir,:), ffilter.freq, seismic.fe);
                elseif strcmp(ffilter.type,'high')
                    trace.ndata(ir,:) = highpass(trace.ndata(ir,:), ffilter.freq, seismic.fe);
                end
            elseif strcmp(ffilter.method,'BW')
                % Butterworth filter
                trace.ndata(ir,:)=filter(bb,aa,trace.ndata(ir,:));
            else
                error('Incorrect input for frequency filter method.\n');
            end
        end
        if isfield(trace,'edata')
            if strcmp(ffilter.method,'DF')
                % digital filter
                if strcmp(ffilter.type,'bandpass')
                    trace.edata(ir,:) = bandpass(trace.edata(ir,:), ffilter.freq, seismic.fe);
                elseif strcmp(ffilter.type,'high')
                    trace.edata(ir,:) = highpass(trace.edata(ir,:), ffilter.freq, seismic.fe);
                end
            elseif strcmp(ffilter.method,'BW')
                % Butterworth filter
                trace.edata(ir,:)=filter(bb,aa,trace.edata(ir,:));
            end
        end
    end
end

% obtain time sampling interval of seismic data
trace.dt=seismic.dt;

% sampling frequency
trace.fe=seismic.fe;

% output binary files
% seismic data
if ~isempty(fname_d) && ~isempty(trace.data)
    fid=fopen(fname_d,'w');
    fwrite(fid,trace.data,precision);
    fclose(fid);
end

% P-wave traveltime table
if ~isempty(fname_p) && ~isempty(trace.travelp)
    fid=fopen(fname_p,'w');
    fwrite(fid,trace.travelp,precision);
    fclose(fid);
end

% S-wave traveltime table
if ~isempty(fname_s) && ~isempty(trace.travels)
    fid=fopen(fname_s,'w');
    fwrite(fid,trace.travels,precision);
    fclose(fid);
end

end