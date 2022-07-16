# Use ruby image to build our own image
FROM ruby:3.0.0

RUN apt update
RUN apt install libgnutls30 -y
RUN apt install ca-certificates -y
RUN apt-get install imagemagick libmagickwand-dev ghostscript libtiff-tools libmagic-dev -y

# We specify everything will happen within the /hpf_connector folder inside the container
WORKDIR /hpf_connector

# We copy these files from our current application to the /hpf_connector container
COPY Gemfile /hpf_connector/Gemfile
COPY Gemfile.lock /hpf_connector/Gemfile.lock

# We install all the dependencies
RUN gem install bundler && bundle install

# We copy all the files from our current application to the /hpf_connector directory in container
COPY . /hpf_connector

# We expose the port
EXPOSE 3000

# We start rails server
CMD bundle exec rails s -p 3000 -b '0.0.0.0' -e production