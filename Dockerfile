FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies required by OpenCV and ffmpeg
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	   build-essential \
	   ffmpeg \
	   libgl1 \
	   libglib2.0-0 \
	   libsm6 \
	   libxrender1 \
	   libxext6 \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only requirements first to leverage Docker cache
COPY requirements.txt /app/requirements.txt

# Install Python dependencies and gunicorn for production
RUN pip install --no-cache-dir -r /app/requirements.txt gunicorn

# Copy application source
COPY . /app

# Ensure writable directories exist
RUN mkdir -p /app/uploads /app/outputs /app/outputs/logs /app/models

# If there are model files in the repo's `models/` directory, copy them explicitly
# into the image so deployments that include a model will have it available at
# runtime under `/app/models`.
COPY models /app/models

# Copy entrypoint and make it executable
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Expose default Flask port; hosting platforms often set $PORT at runtime
EXPOSE 5000

# Use entrypoint to optionally download a model at startup then exec the CMD
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["gunicorn","--workers","2","--threads","2","--bind","0.0.0.0:${PORT:-5000}","run:app"]

