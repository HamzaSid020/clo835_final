FROM ubuntu:20.04
RUN apt-get update -y && \
    apt-get install -y python3-pip mysql-client && \
    pip install --upgrade pip
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 8080
CMD ["python3", "app.py"]