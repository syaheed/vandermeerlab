function tsa = mytsd(timestamps, data, info, invalid)

tsa.timestamps = timestamps;
tsa.data = data;
tsa.info= info;
tsa.invalid= invalid;

tsa = class(tsa, 'mytsd');
   
