FROM python:3.12-alpine

ENV TERRAFORM_VERSION=1.13.5

RUN apk add --no-cache ca-certificates unzip wget \
  && update-ca-certificates \
  && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && mv terraform /usr/local/bin/terraform \
  && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && pip install --no-cache-dir flask

COPY server.py /app/server.py
COPY terraform/*.tf /app/terraform/
COPY terraform/*.lock.hcl /app/terraform/

WORKDIR /app/terraform
RUN terraform init

WORKDIR /app

EXPOSE 8080
CMD ["python3", "server.py"]