function search=modelgeo_show(file_stations,file_velocity,search,earthquake,select,para)
% This function is used to dispaly the geometries of the model and
% stations.
% Units: meter, m/s, degree;
% Input null values ([]) will lead to not plot that parameter.
%
% INPUT--------------------------------------------------------------------
% file_stations: file name (including path) of the stations;
% file_velocity: file name (including path) of the velocity model;
% search: matlab structure, describe the imaging area,
% search.north: 1*2, imaging area in the north direction, in meter,
% search.east: 1*2, imaging area in the east direction, in meter,
% search.depth: 1*2, imaging area in the depth direction, in meter;
% earthquake: matlab structure, contains earthquake location information,
% earthquake.latitude: vector, latitude of earthquakes, in degree,
% earthquake.longitude: vector, longitude of earthquakes, in degree,
% earthquake.depth: vector, depth of earthquakes below the sea-level, in meter;
% select: structure, select stations that fullfill the requirements;
% select.name: only select the named stations;
%
% OUTPUT-------------------------------------------------------------------
% search: imaging area;
% a figure that show the geometries.

if nargin < 5
    select=[];
end

% obtain station information
if isstruct(file_stations)
    % input is a structure array, contain everything about station
    % information, no need to load from file
    stations = file_stations;
else
    % input is the file name of station data, need to load information
    % from file
    stations=read_stations(file_stations,select); % read in station information in IRIS text format
end

% obtain model information
if isstruct(file_velocity)
    % input is a structure array, contain everything about velocity
    % model, no need to load from file
    model = file_velocity;
else
    % input is the file name of velocity model, need to load
    % information from file
    model=read_velocity(file_velocity); % read in velocity model, now only accept homogeneous and layered model
end
lydp=callyifdp(model.thickness,model.rsd0); % obtain depth of each layer interface


% set default values
if nargin == 2
    warning('Using default values to set the imaging area!');
    sfac=0.1;
    
    d_min=min(stations.north);
    d_max=max(stations.north);
    dist=sfac*abs(d_max-d_min);
    search.north=[d_min-dist d_max+dist];
    
    d_min=min(stations.east);
    d_max=max(stations.east);
    dist=sfac*abs(d_max-d_min);
    search.east=[d_min-dist d_max+dist];
    
    d_min=max(stations.depth);
    d_max=lydp(end);
    search.depth=[d_min d_max];
    
    fprintf('Imaging area for the north direction: %f -- %f m;\n',search.north(1),search.north(2));
    fprintf('Imaging area for the east direction: %f -- %f m;\n',search.east(1),search.east(2));
    fprintf('Imaging area for the depth direction: %f -- %f m;\n',search.depth(1),search.depth(2));
    
    earthquake=[];
    
elseif nargin == 3
    earthquake=[];
    
end


% get earthquake positions, can be more than one earthquake, each row shows
% positions of an earthquake
if ~isempty(earthquake) && ~isfield(earthquake,'east')
    [seast,snorth,sdepth]=geod2cart(earthquake.latitude,earthquake.longitude,-earthquake.depth);
    seisp=[snorth,seast,sdepth]; % earthquake positions
elseif isfield(earthquake,'east')
    seisp = [earthquake.north(:),earthquake.east(:),earthquake.depth(:)];
else
    seisp=[];
end

% MCM searching area
if ~isempty(search)
    % reformat the 'search' parameters
    search.north=reshape(search.north,[1,2]);
    search.east=reshape(search.east,[1,2]);
    search.depth=reshape(search.depth,[1,2]);
    srar=[search.north;search.east;search.depth];
else
    srar=[];
end

para.sname = stations.name;
% plot the model geometry
plotgeo([],[],[],lydp,stations.north,stations.east,stations.depth,[],[],srar,seisp,12,10,4,para);


end