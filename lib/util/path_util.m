%{
    Path-related usage functions:

    1.add_path(path_array)  Add path to matlab search path
        argin:  
            path_array:string vector or  string for path
        e.g.    add_path(["./folder1", "./folder2"])

    2.rm_path(path_array)  Remove path from matlab search path
        argin:  
            path_array:string vector or  string for path
        e.g.    rm_path(["./folder1", "./folder2"])

    3.value = make_dir(path)    create path
        argin:
            path: string for path
        argout:
           Path created successfully : value = true
           Failed to create path:  value = false
        e.g. make_dir("./newfolder")

    4.value = chk_pf(paths, files)    Check if a path or file exists
        argin:
            paths: string vector or  string for path,  if none, use []
            files:  string vector or  string including path,  if none, use []
        argout:
            value : true\false
                true: All input paths or files exist
                false:At least one of the entered path or file does not exist
%}

function stc = path_util
    stc.add_paths = @add_paths;
    stc.rm_paths = @rm_paths;
    stc.make_dir = @make_dir;
    stc.chk_pf = @chk_pf;
end


%add path
function add_paths(path_array)
    for i = 1:length(path_array)
        if class(path_array(i)) ~= "string"
            continue;
        end
        if ~chk_pf(path_array(i), [])
            warning(['path:', char(path_array(i)), ' doesnot exist']);
            continue;
        end
        addpath(genpath(path_array(i)));
    end
end

%remove path
function rm_paths(path_array)
    for i = 1:length(path_array)
        if class(path_array(i)) ~= "string"
            continue;
        end
        if ~chk_pf(path_array(i), [])
            warning(['path:', char(path_array(i)), 'doesnot exist']);
            continue;
        end
        rmpath(genpath(path_array(i)));
    end
end

%create folder
function value = make_dir(path)
    if ~exist(path, "dir")
        mkdir(path);
        value = true;
        return;
    end
    value = false;
end

%Check if path/file exists
function value = chk_pf(paths, files)
    value = true;
    for i = 1:length(paths)
        if ~exist(paths(i), "dir")
            value = false;
            return;
        end
    end
    for i = 1:length(files)
        if ~exist(files(i), "file")
            value = false;
            return;
        end
    end
end