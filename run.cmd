docker build --tag=c9rtmp .
docker run -p 1935:1935 -p 8080:8080 -v "C:\projects\c9live\server\data:/data" --detach c9rtmp
