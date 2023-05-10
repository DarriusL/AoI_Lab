function check_lab
    zipfile = dir("*.zip");
    if ~isempty(zipfile)
        for i = 1:length(zipfile)  
            delete(zipfile(i).name);
        end
    end


end