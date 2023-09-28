serial = false;
dummy = false;
data_p = 'C:\Users\setup2\source\guanyao\data';

vi = AsyncVideoInterface( dummy, data_p, serial );
initialize( vi );

t = tic;
last_t = nan;
while ( true )
  if ( toc(t) > 20 )
    break
  end
  if ( isnan(last_t) || toc(t) - last_t > 1 )
    fprintf( '\n Updating ...' );
    last_t = toc( t );
  end
end

fprintf( '\n Waiting ...' );
res = wait( vi );
fprintf( ' Done.' );
delete( vi );