FROM crystallang/crystal:1.19.1-alpine AS build

WORKDIR /app

# Add static LLVM and system libs needed for static linking.
RUN apk add --update --no-cache --force-overwrite \
      llvm18-dev llvm18-static g++ libxml2-static zstd-static

COPY . /app/

RUN shards build crystalline \
      --no-debug --progress --stats --production --static --release \
      -Dpreview_mt

FROM alpine:3.21

COPY --from=build /app/bin/crystalline /usr/local/bin/crystalline

ENTRYPOINT ["crystalline"]
