
FROM python:3.9-poetry

WORKDIR /app/flask-demo
COPY ./app /app/flask-demo

# install requirements
COPY ./requirements.txt /app/flask-demo/requirements.txt
RUN pip install -r requirements.txt

# set python / flask environment:
ENV PYTHONPATH="/app/flask-demo:$PYTHONPATH"
ENV FLASK_APP=flaskr

# generate database stub
RUN flask init-db
COPY ./instance /app/flask-demo/instance

# fix permissions
RUN chown -R 1000:1000 /app

EXPOSE 5000
USER 1000

CMD ["python", "/app/flask-demo/flaskr.py"]
