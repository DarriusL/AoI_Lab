%{
Mathematical Utility Functions:

1.stc = test_function(level)  Optimization Algorithm Test Function
    argin:
        level:   level of test function, string
            includes "primary", "medium", "advanced", "precision"
    argout:
        stc:
            stc.unimodal:  Unimodal test function
                `stc.unimodal.funx.function: function expression handle  ,
                x:1~7
                `stc.unimodal.funx.min: Optimal value within the range of the function
            stc.multimodal： multimodal test function  x:1~6
            stc.dim: Dimensions, number of variables
            stc.var_range: variable scope



%}
function stc = math_util
    stc.test_function = @test_function;
end


%优化算法测试函数
function stc = test_function(level)
    stc.unimodal = @unimodal;
    stc.multimodal = @multimodal;
    switch level
        case "primary"
            varset.dim = 30;
            varset.var_range = repmat([-100, 100], 30, 1);
        case "medium"
            varset.dim = 100;
            varset.var_range = repmat([-1000, 1000], 100, 1);
        case "advanced"
            varset.dim = 1000;
            varset.var_range = repmat([-10000, 10000], 1000, 1);
        case "precision"
            stcp.precision.function = @(x) -20 * exp( -0.2 * sqrt(mean((x - 1e+4).^2)) ) - exp(mean(cos(2*pi*(x - 1e+4)))) + 20 + exp(1);
            stcp.precision.min = 0;
            stcp.varset.dim = 1000;
            stcp.varset.var_range = repmat([9994.88, 10005.12], 1000, 1);
            stc = stcp;
            return;
    end
    
    stc.varset = varset;
end

%% 相关函数

%常用的单峰优化算法测试函数
function stc = unimodal
    stc.fun1.function = @(x) sum(x.^2);
    stc.fun1.min = 0;

    stc.fun2.function = @(x) sum(abs(x)) + prod(abs(x));
    stc.fun2.min = 0;
    
    stc.fun3.function = @(x) sum(cumsum(x) .^2);
    stc.fun3.min = 0;

    stc.fun4.function = @(x) max(abs(x));
    stc.fun4.min = 0;

    stc.fun5.function = @(x) 100*sum( (x(2:end) - x(1:end-1).^2).^2  + (x(1:end-1) - 1).^2 );
    stc.fun5.min = 0;

    stc.fun6.function = @(x) sum((x + 0.5).^2);
    stc.fun6.min = 0;

    stc.fun7.function =  @(x)sum((1:length(x))' .* x.^4) + rand(1);
    stc.fun7.min = 0;
end

%常用的多峰优化算法测试函数
function stc = multimodal
    stc.fun1.function = @(x) - sum(x .* sin(sqrt(abs(x))));
    stc.fun1.min = nan;%暂时不知道 

    stc.fun2.function = @(x)sum( x.^2 - 10 * cos(2*pi*x) + 10 );
    stc.fun2.min = 0;

    stc.fun3.function = @(x) -20 * exp( -0.2 * sqrt(mean(x.^2)) ) - exp(mean(cos(2*pi*x))) + 20 + exp(1);
    stc.fun3.min = 0;

    stc.fun4.function = @(x) 1/4000 * sum(x.^2) - prod(cos(x ./ sqrt((1:length(x))') )) + 1;
    stc.fun4.min = 0;

    stc.fun5.function = @multimodal_fun5;
    stc.fun5.min = 0;

    stc.fun6.function = @(x) 0.1 * (sin(3*pi*x(1))^2 + sum((x(1:end - 1) - 1).^2 .* (1 + sin(3*pi*x(2:end)).^2) ) + ...
        (x(end) - 1)*(1 + sin(2*pi*x(end))^2) ) + sum(multimodal_fun_u(x, 5, 100, 4));
    stc.fun6.min = 0;
end

function value = multimodal_fun5(x)
    y = (x + 5)/4;
    value = pi/length(x) * (10 * sin(pi*y(1))^2 + sum( (y(1:end - 1).^2 .* ( 1 + 10 * sin(pi*y(2:end)).^2) ) ) ...
        + (y(end) - 1)^2) + sum(multimodal_fun_u(x, 10, 100, 4));
end

function value = multimodal_fun_u(x, a, k, m)
    logindx1 = x > a;
    logindx2 = x < -a;
    value = zeros(size(x));
    value(logindx1) = k * (x(logindx1) - a) .^m;
    value(logindx2) = k * (-x(logindx2) - a) .^m;
end