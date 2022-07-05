# Snowflake Data Test - Starter Project

### Prerequisites

#### Python 3.8.* or later.

See installation instructions at: https://www.python.org/downloads/

Check you have python3 installed:

```bash
python3 --version
```

### Dependencies and data

#### Creating a virtual environment

Ensure your pip (package manager) is up to date:

```bash
pip3 install --upgrade pip
```

To check your pip version run:

```bash
pip3 --version
```

Create the virtual environment in the root of the cloned project:

```bash
python3 -m venv .venv
```

#### Activating the newly created virtual environment

You always want your virtual environment to be active when working on this project.

```bash
source ./.venv/bin/activate
```

#### Installing Python requirements

This will install some of the packages you might find useful:

```bash
pip3 install -r ./requirements.txt
```


#### Generating the data

A data generator is included as part of the project in `./input_data_generator/main_data_generator.py`
This allows you to generate a configurable number of months of data.
Although the technical test specification mentions 6 months of data, it's best to generate
less than that initially to help improve the debugging process.

To run the data generator use:

```bash
python ./input_data_generator/main_data_generator.py
```

This should produce customers, products and transaction data under `./input_data/starter`



#### Getting started

Please save Snowflake model code in `snowflake` and infrastructure code in `infra` folder.

Update this README as code evolves.

#### Environmental variables
To run terraform and upload files to s3 set the following environmental variables:
- SNOWFLAKE_USER
- SNOWFLAKE_PRIVATE_KEY_PATH
- SNOWFLAKE_ACCOUNT
- SNOWFLAKE_REGION
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION

Instructions for setting Snowflake variables can be found here: https://quickstarts.snowflake.com/guide/terraforming_snowflake/index.html#0

#### Prefect config file

To successfully run data pipeline, create the following file:

```bash
touch ~/.prefect/config.toml
```

The structure of the mentioned file should look like this:

```
[context.secrets]
SNOWFLAKE_ACCOUNT="<YOUR-ACCOUNT-ID>.<YOUR-REGION-ID>"
SNOWFLAKE_USER="<YOUR-USERNAME>"
SNOWFLAKE_PASSWORD="<YOUR-PASSWORD>"
```

#### Run

To run terraform file navigate to:

```bash
cd ./infra/dev/
```

and run following commands:

```bash
terraform init
terraform apply
```

If you want to revert changes made by terraform run:

```bash
terraform destroy
```

To generate and export sample files use:

```bash
python ./input_data_generator/main_data_generator.py
```

To start the data load pipeline use:

```bash
python ./input_data_generator/data-flow.py
```

After data load pipeline finishes, tables in Snowflake should contain generated sample data.