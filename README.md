# Sample Mongoid & Rails API Application

This repository contains a sample Ruby on Rails API application using Mongoid.

It has been developed following the
[Mongoid getting started guide with Rails](https://docs.mongodb.com/mongoid/master/tutorials/getting-started-rails/).

## Configure

Copy `config/mongoid.yml.sample` to `config/mongoid.yml` and adjust the
settings within as needed:

- If you are using a MongoDB Atlas cluster, remove the hosts and database
sections from `config/mongoid.yml`, uncomment the URI section and paste the
URI to your cluster from the Atlas console.
- You may want to adjust the server selection timeout, increasing it for
a deployment used over Internet such as Atlas and decreasing it for a
local deployment.

## MongoDB in Docker

```
docker run --name mongodb -d -p 27017:27017 mongo:latest
```

## Bootstrap Delayed Jobs

Add gems to `Gemfile`

```
# Delayed Job
gem 'delayed_job_mongoid'
gem 'daemons'
```

Install

```
bundle install
```

Generate `bin` files

```
bundle exec rails generate delayed_job
```

Create MongoDB index

```
bin/rails runner 'Delayed::Backend::Mongoid::Job.create_indexes'
```
## Run

To run the application, use the standard Rails commands (``rails s``,
``rails c``).

Access the application endpoints:

    curl http://localhost:3000/posts
    curl -d 'post[title]=hello&post[body]=world' http://localhost:3000/posts
    curl -d 'comment[post_id]=5d9f5e4a026d7c4e4a71cbdf&comment[name]=Bob&comment[message]=Hi' http://localhost:3000/comments
    curl 'http://localhost:3000/comments?post_id=5d9f5e4a026d7c4e4a71cbdf'

Run in Docker

```
docker build -t delayed-job-aws-batch . 
docker run --rm -it delayed-job-aws-batch:latest rails console

docker tag delayed-job-aws-batch:latest 529105607725.dkr.ecr.us-west-2.amazonaws.com/delayed-job-testing:latest
docker push 529105607725.dkr.ecr.us-west-2.amazonaws.com/delayed-job-testing:latest                            
```
