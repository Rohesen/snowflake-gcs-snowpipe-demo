-- @author : rohesen maurya

-- Use role
use role accountadmin;

-- Create database
create or replace database snowpipe_demo;

-- Create table 
create or replace table orders_data_lz(
    order_id int,
    product varchar(20),
    quantity int,
    order_status varchar(30),
    order_date date
);

-- Create a Cloud Storage Integration in Snowflake
-- Integration means creating config based secure access
create or replace storage integration gcs_bucket_read_int
 type = external_stage
 storage_provider = gcs
 enabled = true
 storage_allowed_locations = ('gcs://data_for_snowpipe12/');

-- drop integration gcd_bucket_read_int;

-- Retrieve the Cloud Storage Service Account for your snowflake account
desc storage integration gcs_bucket_read_int;

-- Service account info for storage integration
-- kkni00000@gcpuscentral1-1dfa.iam.gserviceaccount.com

-- A stage in Snowflake refers to a location (internal or external) 
-- where data files are uploaded, stored, and prepared before being loaded into Snowflake tables.
create or replace stage snowpipe_stage
  url = 'gcs://data_for_snowpipe12/'
  storage_integration = gcs_bucket_read_int;

-- Show stages
show stages;

list @snowpipe_stage;

-- Create PUB-SUB Topic and Subscription
-- gsutil notification create -t snowpipe_pubsub_topic -f json gs://data_for_snowpipe/

-- create notification integration
create or replace notification integration notification_from_pubsub_int
 type = queue
 notification_provider = gcp_pubsub
 enabled = true
 gcp_pubsub_subscription_name = 'projects/horizontal-data-464415-v6/subscriptions/snowpipe_pubsub_topic-sub-sub';

-- Describe integration
desc integration notification_from_pubsub_int;

-- Service account for PUB-SUB
-- kwwh20000@gcpuscentral1-1dfa.iam.gserviceaccount.com

-- Create Snow Pipe
Create or replace pipe gcs_to_snowflake_pipe
auto_ingest = true
integration = notification_from_pubsub_int
as
copy into orders_data_lz
from @snowpipe_stage
file_format = (type = 'CSV');

-- Show pipes
show pipes;

-- Check the status of pipe
select system$pipe_status('gcs_to_snowflake_pipe');

Select * 
from table(information_schema.copy_history(table_name=>'orders_data_lz', start_time=> dateadd(hours, -1, current_timestamp())));

select * from orders_data_lz;

-- Start snowpipe
ALTER PIPE gcs_to_snowflake_pipe SET PIPE_EXECUTION_PAUSED = false;

-- Stop snowpipe
ALTER PIPE gcs_to_snowflake_pipe SET PIPE_EXECUTION_PAUSED = true;


-- Terminate a pipe
drop pipe gcs_snowpipe;


