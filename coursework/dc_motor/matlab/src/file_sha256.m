function digest=file_sha256(file)
%FILE_SHA256 Hash exact bytes for configuration and source provenance.
fid=fopen(file,'rb'); assert(fid>=0,'Cannot read file for checksum');
cleanup=onCleanup(@() fclose(fid)); bytes=fread(fid,Inf,'*uint8');
engine=java.security.MessageDigest.getInstance('SHA-256'); engine.update(bytes);
digest=lower(reshape(dec2hex(typecast(engine.digest(),'uint8'),2)',1,[]));
end
