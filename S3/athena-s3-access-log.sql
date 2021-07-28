https://aws.amazon.com/premiumsupport/knowledge-center/analyze-logs-athena/


Resolution
Amazon S3 stores server access logs as objects in an S3 bucket. You can use Athena to quickly analyze and query server access logs.

1.    Enable server access logging for your S3 bucket, if you haven't already. Note the values for Target bucket and Target prefix—you need both to specify the Amazon S3 location in an Athena query.

2.    Open the Amazon Athena console.

3.    In the Query editor, run a DDL statement to create a database. It's a best practice to create the database in the same Region as your S3 bucket.

create database s3_access_logs_db
4.    Create a table schema in the database. In the following example, the STRING and BIGINT data type values are the access log properties. You can query these properties in Athena. For LOCATION, enter the S3 bucket and prefix path from step 1. Be sure to include a forward slash (/) at the end of the prefix (for example, s3://doc-example-bucket/prefix/).

CREATE EXTERNAL TABLE `s3_access_logs_db.mybucket_logs`(
  `bucketowner` STRING,
  `bucket_name` STRING,
  `requestdatetime` STRING,
  `remoteip` STRING,
  `requester` STRING,
  `requestid` STRING,
  `operation` STRING,
  `key` STRING,
  `request_uri` STRING,
  `httpstatus` STRING,
  `errorcode` STRING,
  `bytessent` BIGINT,
  `objectsize` BIGINT,
  `totaltime` STRING,
  `turnaroundtime` STRING,
  `referrer` STRING,
  `useragent` STRING,
  `versionid` STRING,
  `hostid` STRING,
  `sigv` STRING,
  `ciphersuite` STRING,
  `authtype` STRING,
  `endpoint` STRING,
  `tlsversion` STRING)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
  'input.regex'='([^ ]*) ([^ ]*) \\[(.*?)\\] ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) (\"[^\"]*\"|-) (-|[0-9]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) (\"[^\"]*\"|-) ([^ ]*)(?: ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*))?.*$')
STORED AS INPUTFORMAT
  'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://awsexamplebucket1-logs/prefix/'
5.    In the left pane, under Tables, choose Preview table from the menu button that's next to the table name. If you see data from the server access logs in the Results window (such as bucketowner, bucket, and requestdatetime), you successfully created the Athena table. You can now query the Amazon S3 server access logs.

Example queries
To find the log for a deleted object:

SELECT * FROM s3_access_logs_db.mybucket_logs WHERE
key = 'images/picture.jpg' AND operation like '%DELETE%';
To show who deleted an object and when, including the timestamp, IP address, and AWS Identity and Access Management (IAM) user:

SELECT requestdatetime, remoteip, requester, key FROM s3_access_logs_db.mybucket_logs WHERE
key = 'images/picture.jpg' AND operation like '%DELETE%';
To show all operations performed by an IAM user:

SELECT * FROM s3_access_logs_db.mybucket_logs WHERE
requester='arn:aws:iam::123456789123:user/user_name';
To show all operations performed on an object in a specific time period:

SELECT *
FROM s3_access_logs_db.mybucket_logs
WHERE Key='prefix/images/picture.jpg' AND
parse_datetime(requestdatetime,'dd/MMM/yyyy:HH:mm:ss Z')
BETWEEN parse_datetime('2020-09-18:07:00:00','yyyy-MM-dd:HH:mm:ss')
AND
parse_datetime('2020-09-18:08:00:00','yyyy-MM-dd:HH:mm:ss');
To show how much data a specific IP address transferred in a specific time period:

SELECT SUM(bytessent) as uploadtotal,
SUM(objectsize) as downloadtotal,
SUM(bytessent + objectsize) AS total FROM s3_access_logs_db.mybucket_logs WHERE remoteIP='1.2.3.4' and parse_datetime(requestdatetime,'dd/MMM/yyyy:HH:mm:ss Z') BETWEEN parse_datetime('2020-07-01','yyyy-MM-dd') and parse_datetime('2020-08-01','yyyy-MM-dd');
It's a best practice to create a lifecycle policy for your server access logs bucket. Configure the lifecycle policy to periodically remove log files. This reduces the amount of data that Athena analyzes for each query.

