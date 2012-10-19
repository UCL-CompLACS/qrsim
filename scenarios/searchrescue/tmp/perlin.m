function s = perlin (m)
  s = zeros(m);    % output image
  w = m;           % width of current layer
  i = 0;           % iterations
  while (w > 3)
    i = i + 1;
    d = interp2(randn(w), i-1, 'spline');
    if(i>5)
    s = s + i * d(1:m, 1:m);
    end
    w = w - ceil(w/2 - 1);
  end
end