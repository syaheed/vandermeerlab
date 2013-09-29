function h = plot(tsd_in,varargin)
h = plot(tsd_in.timestamps,tsd_in.data,varargin{:});