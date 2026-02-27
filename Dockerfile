FROM ghcr.io/ministryofjustice/analytical-platform-airflow-r-base:1.17.3@sha256:0f44a5cd4880414074f86e6e13a04848c7fc2a46f232b6e31c85ec1de330e633



ARG MOJAP_IMAGE_VERSION="default"
ENV MOJAP_IMAGE_VERSION=${MOJAP_IMAGE_VERSION}

USER root


RUN <<EOF
apt-get update # Refresh APT package lists
apt-get install --yes libcurl4-openssl-dev libssl-dev libxml2-dev # Install packages
apt-get clean --yes # Clear APT cache
rm --force --recursive /var/lib/apt/lists/* # Clear APT package lists
EOF

USER ${CONTAINER_UID} 

# Create a working directory
#WORKDIR /pocketbook

# Add R package requirements and scripts
COPY renv.lock renv.lock
COPY scripts/ scripts/

# Give working directory permissions to everyone
#RUN chmod -R 777 .

# Use the latest repos for R
RUN R -e "options(repos = 'cran.rstudio.com')"
# Install renv globally
RUN R -e "install.packages('renv')"

# Create a user with a home directory, which is necessary for renv
# The user id must be the same as defined in the Airflow DAG
#RUN adduser --uid 1337 daguser
#USER daguser

# Inititalise renv...
RUN R -e "renv::init()"

# RUN R -e 'options(repos = c(CRAN = "https://p3m.dev/cran/__linux__/jammy/latest"))'

RUN R -e 'install.packages("curl", type = "binary")'

# ... and restore the R environment
RUN R -e 'renv::restore()'

# Run the DAG task
ENTRYPOINT Rscript scripts/run.R

# Below is an example of how to use the base image
# COPY renv.lock renv.lock
# RUN <<EOF
# R -e "install.packages('renv')"
# R -e "renv::init()"
# R -e "renv::restore()"
# EOF

# COPY --chown=nobody:nobody --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh
# ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
