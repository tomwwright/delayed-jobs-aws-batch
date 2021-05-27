# Delayed Job on AWS Batch

## Sample Mongoid & Rails API Application

This repository contains a sample Ruby on Rails API application using Mongoid.

It has been developed following the
[Mongoid getting started guide with Rails](https://docs.mongodb.com/mongoid/master/tutorials/getting-started-rails/).

Sourced from https://github.com/mongoid/mongoid-demo

## Dejayed Job in AWS Batch

This repository has had Delayed Job added for the purposes of a proof-of-concept around offloading execution of the Delayed Job itself to AWS Batch.

The motivation of this proof-of-concept are:

- a compute environment for the job that is separate to the worker -- to safely run idempotent or interruptible jobs without needing to protect the worker process itself
- control over the compute environment for the job
- avoid code changes to an existing Delayed Job code base in regards to the job code itself or the calling code that schedules the jobs

![Infrastructure Diagram](./doc/infrastructure.png)

1. Rails application is packaged and pushed to an ECR Repository. This image will be used for the other Fargate-based components of the solution.
2. Fargate service runs a Delayed Job worker but with the AWS Batch plugin applied:
   ```
   # task uses the following as command

   bin/delayed_job_aws_batch
   ```
   This Delayed Job worker picks up Delayed Job jobs from the collection in MongoDB as per normal, but the worker behaviour for the job is overriden as per (3) below.
3. The Delayed Job worker, instead of performing job as normal, submits a job to AWS Batch with the Job ID. It then simply polls the status of the AWS Batch job until it completes.

   It also inserts a marker item into a collection in MongoDB that simply correlates the Delayed Job ID and the AWS Batch Job ID. This is used to protect against duplicating a running job on AWS Batch if the Delayed Job worker restarts and picks up the same job.
4. AWS Batch executes the job via Fargate, using the same container image. This job executes with a different command that executes Delayed Job against the provided Job ID:
   ```
   bin/run_delayed_job <JobID>
   ```
5. Delayed Job execution handles running job as per normal. Being within the Delayed Job execution context, success and failure are appropriately handled: i.e. successful jobs are deleted, failed jobs are rescheduled as per `max_attempts` configuration, etc.

## Setup

### MongoDB

Copy `config/mongoid.yml.sample` to `config/mongoid.yml` and adjust the
settings within as needed:

- If you are using a MongoDB Atlas cluster, remove the hosts and database
sections from `config/mongoid.yml`, uncomment the URI section and paste the
URI to your cluster from the Atlas console.
- You may want to adjust the server selection timeout, increasing it for
a deployment used over Internet such as Atlas and decreasing it for a
local deployment.

#### Run MongoDB in Docker

```
docker run --name mongodb -d -p 27017:27017 mongo:latest
```

### Bootstrap Delayed Jobs

Added gems to `Gemfile`

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

### AWS Batch

TBC

## Run

To run the application, use the standard Rails commands (``rails s``,
``rails c``).

Access the application endpoints:

    curl http://localhost:3000/posts
    curl -d 'post[title]=hello&post[body]=world' http://localhost:3000/posts
    curl -d 'comment[post_id]=5d9f5e4a026d7c4e4a71cbdf&comment[name]=Bob&comment[message]=Hi' http://localhost:3000/comments
    curl 'http://localhost:3000/comments?post_id=5d9f5e4a026d7c4e4a71cbdf'

Run the Delayed Job worker

```
bin/delayed_job
```

Run the Delayed Job in AWS Batch worker

```
bin/delayed_job_aws_batch
```

### Docker

Build and push

```
docker build -t delayed-job-aws-batch . 
docker run --rm -it delayed-job-aws-batch:latest rails console

docker tag delayed-job-aws-batch:latest 000011112222.dkr.ecr.us-west-2.amazonaws.com/delayed-job-aws-batch:latest
docker push 000011112222.dkr.ecr.us-west-2.amazonaws.com/delayed-job-aws-batch:latest                            
```

Run 

```
docker run --rm -t delayed-job-aws-batch:latest bin/delayed_job_aws_batch
docker run --rm -it delayed-job-aws-batch:latest rails console
```