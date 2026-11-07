FROM python:3.12-alpine
WORKDIR /app
COPY app.py start.sh /app/
RUN chmod +x /app/start.sh
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["python", "/app/app.py"]
