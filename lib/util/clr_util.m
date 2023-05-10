%{
Color-related usage functions:

1. [all_clrs, all_thms] = allclrs()  Get colors and themes
    
2. demo_plot() show all the color and its idx
%}

function stc  = clr_util
    stc.allclrs = @get_allclrs;
    stc.demo_plot = @demo_plot;
end


function [all_clrs, all_thms] = get_allclrs()
    clr_strcell{1} = ["#FD6D5A", "#FEB40B", "#6DC354", "#994487", "#518CD8", "#443295"];
    clr_strcell{2} = ["#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51", "#253777"];
    clr_strcell{3} = ["#C1C976", "#C8A9A1", "#FEC2E4", "#77CCE0", "#FFD372", "#F88078"];
    clr_strcell{4} = ["#104FFF", "#2FD151", "#64C7B8", "#FF1038", "#45CAFF", "#B913FF"];
    clr_strcell{5} = ["#4C87D6", "#F38562", "#F2B825", "#D4C114", "#88B421", "#199FE0"];
    clr_strcell{6} = ["#037CD2", "#00AAAA", "#927FD3", "#E54E5D", "#EAA700", "#F57F4B"];
    clr_strcell{7} = ["#64B6EA", "#FB8857", "#A788EB", "#80D172", "#FC7A77", "#61D4D5"];
    clr_strcell{8} = ["#F1787D", "#F8D889", "#69CDE0", "#5EB7F1", "#EDA462", "#F6C4E6"];
    clr_strcell{9} = ["#8C8FD5", "#C0E5BC", "#8C8FD5", "#BDF4FC", "#C3BCE6", "#F48FB1"];
    clr_strcell{10} = ["#B04A7A", "#171433", "#B6342E", "#DBB9DB", "#FAB4AC", "#EFB9C1"];
    clr_strcell{11} = ["#E74745", "#FB7857", "#FBCD60", "#FEFB66", "#1AC0C6", "#FB7857"];
    clr_strcell{12} = ["#361D32", "#543C52", "#F65A53", "#EED2CB", "#DBD873", "#F1E8E8"];
    clr_strcell{13} = ["#454D66", "#319975", "#58B368", "#DBD873", "#FAC46C", "#F1ECB7"];
    clr_strcell{14} = ["#112E92", "#112E92", "#48D6D2", "#81EAE6", "#F8F6BA", "#E3F5F6"];
    clr_strcell{15} = ["#134036", "#103232", "#34C0B8", "#7A27FF", "#FFCA7B", "#F8A427"];
    clr_strcell{16} = ["#FF0000", "#F65A53", "#34C0B8", "#7A27FF", "#FF98A4", "#D7BCE7"];
    clr_strcell{17} = ["#F84D4D", "#FF6B42", "#5BA3EB", "#06BB9A", "#8E7EF0", "#F4B919"];
    clr_strcell{18} = ["#406196", "#F4B414", "#77649B", "#385D77", "#576270", "#778495"];
    clr_strcell{19} = ["#4C6CFF", "#18C1FF", "#3DEF2D", "#9818BC", "#CB1E86", "#FC564B"];
    clr_strcell{20} = ["#0E9DFF", "#FF0000", "#800080", "#FFA500", "#ECE70B", "#979797"];
    clr_strcell{21} = ["#313BD0", "#9A22F8", "#00F2F2", "#00B2FC", "#5EAFFA", "#81E0D7"];
    clr_strcell{22} = ["#55EFC4", "#81ECEC", "#74B9FF", "#A29BFE", "#7F8C8D", "#C9C9C9"];
    clr_strcell{23} = ["#FAD390", "#F8C291", "#3742FA", "#70A1FF", "#82CCDD", "#B8E994"];
    clr_strcell{24} = ["#F8E0F1", "#DEC8CC", "#B87D9C", "#82447F", "#0B174E", "#C9C9C9"];
    clr_strcell{25} = ["#0063C3", "#408AD2", "#3396CF", "#A0D284", "#F5CD39", "#BEBEBE"];
    clr_strcell{26} = ["#4316F3", "#8769F7", "#FA807C", "#EFC09D", "#A5A5A5", "#C9C9C9"];
    clr_strcell{27} = ["#104382", "#0A8CB2", "#448CE1", "#1BB5E1", "#FF6155", "#C9C9C9"];
    clr_strcell{28} = ["#14BF96", "#1865F2", "#FFB100", "#073587", "#5F9ABC", "#BCBCBC"];
    clr_strcell{29} = ["#16B99A", "#1F7CC1", "#1686F8", "#3EC5E0", "#93D06A", "#BABABA"];
    clr_strcell{30} = ["#014AE0", "#1587FD", "#2DD3FB", "#FA6766", "#F8B613", "#BD55F9"];
    clr_strcell{31} = ["#1987D7", "#5B73CD", "#1FBF79", "#3BB9C1", "#F86B0D", "#FAA900"];
    clr_strcell{32} = ["#4071EC", "#FA3279", "#1096FA", "#35B9E4", "#2DCC97", "#A0B2BA"];
    clr_strcell{33} = ["#007EB4", "#00A7FC", "#FFC85C", "#ED326C", "#A84269", "#BC4715"];
    clr_strcell{34} = ["#F79F1F", "#A3CB38", "#1289A7", "#D980FA", "#FDA7DF", "#B53471"];
    clr_strcell{35} = ["#FA983A", "#EB2F06", "#1E3799", "#3C6382", "#38ADA9", "#C9C9C9"];
    clr_strcell{36} = ["#2ED573", "#1E90FF", "#3742FA", "#70A1FF", "#2F3542", "#C9C9C9"];
    clr_strcell{37} = ["#FC5C65", "#FD9644", "#FED330", "#26DE81", "#079992", "#2BCBBA"];
    clr_strcell{38} = ["#F3A683", "#F7D794", "#778BEB", "#70A1FF", "#E77F67", "#CF6A87"];
    clr_strcell{39} = ["#F6B93B", "#E55039", "#4A69BD", "#60A3BC", "#78E08F", "#BBEA99"];
    clr_strcell{40} = ["#00ADD7", "#00668A", "#F1C900", "#FFF1CE", "#E01706", "#C9C9C9"];
    clr_strcell{41} = ["#D3DE9E", "#004965", "#17C0EB", "#FF7F78", "#3D3D3D", "#FFF200"];
    clr_strcell{42} = ["#CD84F1", "#FFCCCC", "#FF4D4D", "#FFAF40", "#2F3542", "#FFFA65"];
    clr_strcell{43} = ["#F53B57", "#3C40C6", "#3C40C6", "#00D8D6", "#05C46B", "#C9C9C9"];
    clr_strcell{44} = ["#50514F", "#F45E58", "#FFE15B", "#1D7AA2", "#6DC1B3", "#A5B1C2"];
    clr_strcell{45} = ["#FFC312", "#12CBC4", "#C4E538", "#1289A7", "#FDA7DF", "#ED4C67"];
    clr_strcell{46} = ["#FFC000", "#EA3C6E", "#1B73A7", "#2C946E", "#A5B1C2", "#303952"];
    clr_strcell{47} = ["#A589C6", "#FD91A0", "#F2E9DA", "#DFE384", "#39BFCB", "#A6E3E8"];
    clr_strcell{48} = ["#CC99FF", "#FFAFD7", "#9BCDFF", "#FFD0A1", "#99FFCC", "#CCFF9A"];
    clr_strcell{49} = ["#3F48CC", "#B83DBA", "#FF7F27", "#0ED145", "#EC1C24", "#A76E4E"];
    clr_strcell{50} = ["#385261", "#7298AB", "#4F9A73", "#74878B", "#86AEA6", "#D1F0F3"];
    clr_strcell{51} = ["#ED5736", "#C61D34", "#F30D00", "#DD5A6C", "#F00057", "#FE0096"];
    clr_strcell{52} = ["#4B59C2", "#5A77BB", "#4A94C5", "#3B2E7E", "#013370", "#1A2946"];
    clr_strcell{53} = ["#08DE9E", "#01E400", "#21A576", "#BDDD20", "#9DBC20", "#67945B"];
    clr_strcell{54} = ["#7F1EAC", "#815377", "#57004F", "#4C211B", "#CBA4E5", "#A5A9D6"];
    clr_strcell{55} = ["#2D445F", "#3F4D50", "#494263", "#2279B6", "#7B9067", "#B56B62"];
    clr_strcell{56} = ["#101420", "#4C000A", "#1A5599", "#8E2961", "#407D53", "#8E2961"];
    clr_strcell{57} = ["#0095B6", "#4FA485", "#81D8D0", "#E2AF42", "#B8CE8E", "#9AB4CD"];
    clr_strcell{58} = ["#005EAD", "#AF6DE5", "#719FFB", "#1CAC99", "#FE9499", "#4A8FDE"];
    clr_strcell{58} = ["#4DE890", "#2178B8", "#77A2E8", "#F86067", "#26C4B8", "#0094C5"];
    clr_strcell{58} = ["#5AE7E4", "#2E9F79", "#3638AE", "#FF7F00", "#FA9B97", "#30A02D"];
    clr_strcell{58} = ["#B0E188", "#2077B5", "#05B9C7", "#A8CBE4", "#F5FFB3", "#BEECAF"];
    clr_strcell{59} = ["#FFA1C4", "#8770E0", "#01AFEE", "#4574C6", "#FDC100", "#BAD0C4"];
    clr_strcell{60} = ["#4AB9EE", "#FF178D", "#FF178D", "#FFD600", "#00B1A1", "#97D601"];

    all_thms = cellfun(@strmat_pcs, clr_strcell, "UniformOutput", false);
    all_clrs = nan(sum(cellfun(@length, clr_strcell)), 3);
    for i = 1:length(clr_strcell)
        all_clrs((i - 1)*6 + 1 : i*6, :) = all_thms{i};
    end
end

%draw a picture
function demo_plot
    dwg_util().RollerMultiFigure(@demo_plot_fun, [20, 3]);
end


%% related functions

%matlab default color drawing
function default_plot
    x = (1 : 100)';
    y = repmat(log(x), 1, 6) + repmat(1:6, 100, 1);
    plot(x, y, 'LineWidth', 5);
end

%pcs
function val = strmat_pcs(strmat)
    val = nan(length(strmat), 3);
    for i = 1:length(strmat)
        val(i, :) = RGB2MatlabColor(Hex2RGB(char(strmat(i))));
    end
end

%Convert hexadecimal color to RGB color array
function c = Hex2RGB(str)
    c = zeros(1, 3);
    [c(1), c(2), c(3)] = deal(hex2dec(str(2:3)), hex2dec(str(4:5)), hex2dec(str(6:7)));
end

%Convert RGB values to Matlab color vectors
function c = RGB2MatlabColor(rgb)
    c = round(100 * rgb/255) / 100;
end

function demo_plot_fun(i, ax)
    text_pst = (1:6) + 4; 
    persistent thms
    if isempty(thms)
        [~, thms] = get_allclrs();
    end
    default_plot;
    text(50*ones(size(text_pst)), text_pst, string(6*(i - 1) + (1:6)));
    xlabel(['第',num2str(i),'组']);
    set(ax, 'colororder', thms{i});
end