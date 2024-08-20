FROM ruby:3.3

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    nodejs \
    npm \
    masscan \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile ./
RUN bundle install

COPY package.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 1234

CMD ["ruby", "app.rb"]
