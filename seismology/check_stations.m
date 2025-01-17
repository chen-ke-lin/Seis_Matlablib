function stations=check_stations(folder,file_stations,day1,day2)
% This function is used to check the availability of the input stations.
%
% Seismic data must be HDF5 format.
% Station file must be IRIS text format.
%
% The name of the seismic data should be 'folder/day_xxx.h5'. 'xxx' means
% it is the seismic data of the xxx-th day in the year.
%
% INPUT--------------------------------------------------------------------
% folder: the path to the folder of the seismic data;
% file_stations: file name of the station file in IRIS text format;
% day1: the start date in this year;
% day2: the end date in this year;
%
% OUTPUT-------------------------------------------------------------------
% stations: structure, contains the stations information;
% stations.name: cell array, the name of the stations;
% stations.ava: stations availabilities, 2D array, shape: n_days*n_stations;


% number of days to calculate
n_days=day2-day1+1;

% read in the name of the stations
stations=read_stations(file_stations);

% the number of stations in the station file
n_stations=length(stations.name);

% initial outputs
stations.ava=NaN(n_days,n_stations);


for iday=day1:day2
    
    % the index of this day
    id=iday-day1+1;
    
    % obtain the name of the seismic data
    file_seismic=[folder sprintf('/day_%03d',iday) '.h5'];
    
    % read in the names of stations/trace in the seismic file
    [seismic.name, ~]=read_staname(file_seismic);
    
    % check if stations are avaiable in the sesimic data file
    for ii=1:n_stations
        if ismember(stations.name{ii},seismic.name)
            % this station is present in the seismic file
            stations.ava(id,ii)=1;
        else
            % this stations is not present in the seismic file
            stations.ava(id,ii)=0;
        end
    end
    
end


end