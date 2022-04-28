function [h] = drawResiduals(dim1,dim2,tspan,x_hat,truth,sig3,varargin)
    %@code{true}
    % Validate inputs:
    assert(size(x_hat,2) == size(tspan,2),'The length of tspan must be equal to length of x_hat')
    assert(all(size(x_hat) == size(truth)),'The inputs x_hat and truth must be the same size')
    assert(size(x_hat,1) == size(sig3,1),'The inputs x_hat and sig3 must have the same number of rows')
    assert(size(x_hat,1) <= dim1*dim2,'Not enough subplots defined for number of states given')
    assert(size(x_hat,2)==size(sig3,2) || size(sig3,2)==1,['The input sig3 must either be a column vector or have the same\n',...
                                                           'number of rows as the input x_hat'])

    % Generate the plots:
    h = cell(dim1*dim2,1);
    for ii = 1:(dim1*dim2)
        h{ii} = subplot(dim1,dim2,ii);
                    plot(tspan,x_hat(ii,:) - truth(ii,:),varargin{:}); hold on
                    if size(sig3,2) == 1
                        drawBounds(tspan,(sig3(ii)/3)*ones(size(tspan));
                    else
                        drawBounds(tspan,sig3(ii,:)/3);
                    end
                    xlim([0 inf]); grid on
    end
end