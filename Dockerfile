# Use ruby image to build our own image
FROM ruby:3.0.0

RUN apt update
RUN apt install libgnutls30 -y
RUN apt install ca-certificates -y
RUN apt-get install imagemagick libmagickwand-dev ghostscript libtiff-tools libmagic-dev -y

# We specify everything will happen within the /tiff_to_pdf folder inside the container
WORKDIR /tiff_to_pdf

# We copy these files from our current application to the /tiff_to_pdf container
COPY Gemfile /tiff_to_pdf/Gemfile
COPY Gemfile.lock /tiff_to_pdf/Gemfile.lock

# We install all the dependencies
RUN gem install bundler && bundle install

# We copy all the files from our current application to the /tiff_to_pdf directory in container
COPY . /tiff_to_pdf

# We expose the port
EXPOSE 3000

# We start rails server
CMD TIFF_PROCESSOR=pdf bundle exec rails s -p 3000 -b '0.0.0.0' -e production