function stc = dwg_util
    stc.info = @info;
    stc.RollerMultiFigure = @RollerMultiFigure;
    stc.draw_arrow = @drawarrow;
end

%实用函数信息
function info
    disp(['绘图相关实用函数(dwg_util)', newline, ...
        '----------------------------------------------', newline, ...
        '1.RollerMultiFigure(pic_fun, pic_size) 带滚轮的多子图窗口', newline, ...
        '                     *规定pic_fun，第一个参数为图的编号，第二个参数为坐标系对象', newline, ...
        '----------------------------------------------', newline ...
        '最后一次更新：2022-08-29']);
end

%带滚轮的多子图窗口
function RollerMultiFigure(pic_fun, pic_size)
%规定绘图函数的第一个参数为图的编号，第二个参数为坐标系对象
    assert(length(pic_size) == 2);
    [row, column] = deal(pic_size(1), pic_size(2));
    assert(length(pic_fun) == 1 && class(pic_fun) == "function_handle");
 
    fMain  = figure("Name", string(datetime) + "   tip:线上编号为对应的返回颜色编号",  ...
        'NumberTitle', 'off', ...
        'Menubar', 'none', ...
        'Units', 'pixels', ...
        'Position', [500, 100, 1000, 500], ...
        'Resize', 'off');
    
    
    % 创建一个水平布局
    HBox = uiextras.HBox('Parent', fMain);
    
    % 创建一个Panel用于放 子坐标 的Panel
    Panel = uipanel('Parent', HBox);
    
    % 创建一个slider用于滚动subplot
    Slider = uicontrol('Style', 'slider', ...
        'Parent', HBox, ...
        'callback', {@callback_Slider, fMain});
    
    % Slider宽20pix，剩下的宽度都给Panel
    HBox.Widths = [-1, 20];
    
    % 计算一下子坐标的宽度，实际上不用算（因为放到布局里面了），
    % 这里算是为了大概算一下 子Panel的高度，
    width_axes = fix( Panel.Position(3) / column ); % hight_axes = width_axes;
    
    % 计算 子Panel的高度
    Panel_Sub_Height = width_axes * row;
    
    % 这里不考虑行数很少，以至于一个窗口就能放下的情况(也就是只考虑放坐标的子Panel比其父Panel高)
    % 计算高度差
    diff_Height = Panel_Sub_Height - Panel.Position(4);
    
    % 设置Slider的最大值为高度差
    Slider.Max = diff_Height;
    % 设置Slider的最小值为0
    Slider.Min = 0;
    % 设置Slider的当前值为Slider的最大值（把slider拿到上方去）
    Slider.Value = Slider.Max;
    % 初始化 上一次点击slider时slider的值 Slider_PreviousValue 为slider的最大值
    setappdata(fMain, 'Slider_PreviousValue', Slider.Max)
    
    % 创建 子Panel
    Panel_Sub = uipanel('Parent', Panel, ...
        'Units', 'pixels', ...
        'Position', [0, -diff_Height, Panel.Position(3), Panel_Sub_Height], ...
        'BackgroundColor', 'k');
    % 保存 子Panel
    setappdata(fMain, 'Panel_Sub', Panel_Sub)
    
    % 创建网格布局
    Grid_axes = uiextras.Grid('Parent', Panel_Sub);
    
    % 画各个子图
    for i = 1 : row * column
        ax = axes('Parent', Grid_axes);
        pic_fun(i, ax);
    end
    
    % 设置网格布局的参数
    Grid_axes.Heights = -ones(1, row);
    Grid_axes.Widths = -ones(1, column);

end

function drawarrow(x,y,lineType,ax)
    switch nargin
        case 2
            lineType='arrow';
            ax=gca;
        case 3
            ax=gca;
    end
    % 调整坐标大小以适应箭头长度
    xlim=ax.XLim;
    ylim=ax.YLim;
    xlimmin=xlim(1);xlimmax=xlim(2);
    ylimmin=ylim(1);ylimmax=ylim(2);
    if xlimmin>min(x(1),y(1))
        xlimmin=min(x(1),y(1));
    end
    if xlimmax<max(x(1),y(1))
        xlimmax=max(x(1),y(1));
    end
    if ylimmin>min(x(2),y(2))
        ylimmin=min(x(2),y(2));
    end
    if ylimmax<max(x(2),y(2)) 
        ylimmax=max(x(2),y(2));
    end
    ax.XLim = [xlimmin,xlimmax];
    ax.YLim = [ylimmin,ylimmax];
    xlim=ax.XLim;
    ylim=ax.YLim;
    pos=ax.Position;
    x_ratio = pos(3)/(xlim(2)-xlim(1));
    y_ratio = pos(4)/(ylim(2)-ylim(1)); % 缩放比例
    orig_pos=[-xlim(1)*x_ratio+pos(1),-ylim(1)*y_ratio+pos(2)]; % figure坐标系中的原点坐标
    x=x.*[x_ratio,y_ratio];y=y.*[x_ratio,y_ratio];
    x=x+orig_pos;y=y+orig_pos;
    annotation(lineType,[x(1),y(1)],[x(2),y(2)])
end


%% 相关函数

function callback_Slider(self, ~, fMain)
    % 获取Slider的上一次值
    Slider_PreviousValue = getappdata(fMain, 'Slider_PreviousValue');
    % 获取当前Slider的值
    current_SliderValue = self.Value;
    
    % 计算两者差值
    diff_SliderValue = current_SliderValue - Slider_PreviousValue;
    % 如果为负说明Slider向下滑，Panel_Sub应该向上动
    
    % 获取放坐标系的Panel
    Panel_Sub = getappdata(fMain, 'Panel_Sub');
    % 计算要移动的高度
    
    % 重置Panel_Sub的Position
    Panel_Sub.Position(2) = Panel_Sub.Position(2) - diff_SliderValue;
    
    % 保存当前Slider的Value
    setappdata(fMain, 'Slider_PreviousValue', current_SliderValue)
end

