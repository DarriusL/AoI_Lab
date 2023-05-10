function SetCurrentFile
    filep = mfilename('fullpath'); 
    [pathstr,~] = fileparts(filep);
    cd(pathstr);
end