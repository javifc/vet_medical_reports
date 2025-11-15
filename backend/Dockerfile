FROM ruby:3.4.5

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-spa \
    tesseract-ocr-fra \
    tesseract-ocr-por \
    tesseract-ocr-ita \
    imagemagick \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install --jobs 4 --retry 3

# Copy the rest of the application
COPY . .

# Create directories for Active Storage and PID file
RUN mkdir -p tmp/pids tmp/storage

# Expose port 3000
EXPOSE 3000

# Start Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
