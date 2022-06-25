FROM ruby:2.7.1

ARG WORKDIR=/var/www/api
# デフォルトの locale `C` を `C.UTF-8` に変更する
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
# タイムゾーンを日本時間に変更
ENV TZ Asia/Tokyo

RUN apt-get update && apt-get install -y nodejs npm mariadb-client
RUN npm install -g yarn@1

RUN mkdir -p $WORKDIR
WORKDIR $WORKDIR

COPY Gemfile $WORKDIR/Gemfile
COPY Gemfile.lock $WORKDIR/Gemfile.lock
RUN bundle install

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3333

# Start the main process
CMD ["rails", "server", "-p", "3333", "-b", "0.0.0.0"]