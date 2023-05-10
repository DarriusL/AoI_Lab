%{
    File-related utility functions:

1.convert(filenameArray, outputnameArray),  file format conversion
    Switch to the corresponding path before using
    It is recommended to use when converting matlab files to other formats
    e.g.  convert("file.mlx", "file.pdf")

%}

function stc = file_util
    stc.convert = @convert;
end


function convert(filenameArray, outputnameArray)
    assert(length(filenameArray) == length(outputnameArray));
    for i = 1:length(filenameArray)
        matlab.internal.liveeditor.openAndConvert(char(filenameArray(i)), char(outputnameArray(i)));
    end
end
